import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/login_handler_screen.dart';
import '../screens/verify_email_screen.dart';
import '../view_models/login_view_model.dart';
import '../screens/home_shell_screen.dart';
import '../screens/recipe_flow_screen.dart';
import '../screens/show_recipe_screen.dart';
import '../screens/cook_recipe_flow_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/trending_recipes_screen.dart';
import '../screens/latest_recipes_screen.dart';
import '../screens/premium_paywall_screen.dart';
import '../screens/tutorial_screen.dart';
import '../onboarding/onboarding_flow_screen.dart';
import '../screens/grocery_list_screen.dart';
import '../screens/pantry_scan_screen.dart';
import '../screens/meal_plan_hub_screen.dart';
import '../screens/meal_plan_wizard_screen.dart';
import '../screens/meal_plan_review_screen.dart';
import '../data/api/api_service.dart';
import '../data/models/recipe.dart';
import '../data/models/user_data.dart';
import '../core/recipe_generation_entry_point.dart';
import '../core/telemetry/app_telemetry.dart';
import '../view_models/grocery_list_view_model.dart';
import '../view_models/home_view_model.dart';
import '../view_models/subscription_view_model.dart';
import '../view_models/meal_plan_view_model.dart';
import '../onboarding/onboarding_session_extension.dart';
import '../services/session_manager.dart';

class AppRouter {
  AppRouter({
    required this.loginViewModel,
    required this.homeViewModel,
    required this.recipeViewModel,
    required this.groceryListViewModel,
    required this.mealPlanViewModel,
    required this.subscriptionViewModel,
    required this.apiService,
    required this.appTelemetry,
    required this.sessionManager,
    this.analytics,
  });

  final dynamic loginViewModel;
  final HomeViewModel homeViewModel;
  final dynamic recipeViewModel;
  final GroceryListViewModel groceryListViewModel;
  final MealPlanViewModel mealPlanViewModel;
  final SubscriptionViewModel subscriptionViewModel;
  final ApiService apiService;
  final AppTelemetry appTelemetry;
  final dynamic sessionManager;
  final FirebaseAnalytics? analytics;

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    observers: [
      if (analytics != null) FirebaseAnalyticsObserver(analytics: analytics!),
    ],
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => SplashScreen(
          loginViewModel: loginViewModel,
          sessionManager: sessionManager as SessionManager,
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (_, state) {
          final extra = state.extra;
          final openSignup =
              extra == true || extra == 'signup' || extra == 'Signup';
          return LoginHandlerScreen(
            loginViewModel: loginViewModel,
            sessionManager: sessionManager as SessionManager,
            openSignup: openSignup,
          );
        },
      ),
      GoRoute(
        path: '/verify-email',
        builder: (_, __) => VerifyEmailScreen(
          loginViewModel: loginViewModel as LoginViewModel,
          sessionManager: sessionManager as SessionManager,
        ),
      ),
      GoRoute(
        path: '/onboarding',
        redirect: (context, state) {
          final sm = sessionManager as SessionManager;
          if (sm.isGuestMode() || sm.getOnboardingCompleteSync()) {
            return '/home';
          }
          if (loginViewModel.isLoggedIn != true) {
            return '/login';
          }
          return null;
        },
        builder: (_, __) => OnboardingFlowScreen(
          sessionManager: sessionManager as SessionManager,
          homeViewModel: homeViewModel,
          subscriptionViewModel: subscriptionViewModel,
          appTelemetry: appTelemetry,
        ),
      ),
      GoRoute(
        path: '/home',
        redirect: (context, state) {
          final sm = sessionManager as SessionManager;
          if (sm.isGuestMode()) return null;
          if (loginViewModel.isLoggedIn == true &&
              !sm.getOnboardingCompleteSync()) {
            return '/onboarding';
          }
          return null;
        },
        builder: (_, __) => HomeShellScreen(
          homeViewModel: homeViewModel,
          loginViewModel: loginViewModel,
          recipeViewModel: recipeViewModel,
          groceryListViewModel: groceryListViewModel,
          subscriptionViewModel: subscriptionViewModel,
          apiService: apiService,
          appTelemetry: appTelemetry,
          sessionManager: sessionManager,
        ),
      ),
      GoRoute(
        path: '/premium',
        builder: (context, state) {
          final source = state.uri.queryParameters['source'] ??
              (state.extra is String ? state.extra as String : 'unknown');
          return PremiumPaywallScreen(
            source: source,
            subscriptionViewModel: subscriptionViewModel,
            sessionManager: sessionManager,
            loginViewModel: loginViewModel as LoginViewModel,
            appTelemetry: appTelemetry,
          );
        },
      ),
      GoRoute(
        path: '/recipe-flow',
        builder: (_, state) {
          final extra = state.extra;
          UserData? userData;
          String? initialPrompt;
          RecipeGenerationEntryPoint generationEntryPoint =
              RecipeGenerationEntryPoint.createRecipes;
          if (extra is Map) {
            final map = Map<String, dynamic>.from(
              extra.map((k, v) => MapEntry(k.toString(), v)),
            );
            userData = map['userData'] as UserData?;
            final prompt = map['initialPrompt'];
            if (prompt is String) initialPrompt = prompt;
            final g = map['generationEntryPoint'];
            if (g is String) {
              for (final e in RecipeGenerationEntryPoint.values) {
                if (e.name == g) {
                  generationEntryPoint = e;
                  break;
                }
              }
            } else if (g is RecipeGenerationEntryPoint) {
              generationEntryPoint = g;
            }
          } else {
            userData = extra as UserData?;
          }
          return RecipeFlowScreen(
            userData: userData,
            initialPrompt: initialPrompt,
            recipeViewModel: recipeViewModel,
            groceryListViewModel: groceryListViewModel,
            sessionManager: sessionManager,
            generationEntryPoint: generationEntryPoint,
          );
        },
      ),
      GoRoute(
        path: '/show-recipe',
        builder: (_, state) {
          final extra = state.extra;
          final isGuest = sessionManager.isGuestMode();
          // go_router [extra] is often `Map<String, Object?>`, not `Map<String, dynamic>`.
          final Recipe recipe;
          if (extra is Map) {
            final raw = Map<dynamic, dynamic>.from(extra);
            recipe = raw['recipe'] as Recipe;
          } else {
            recipe = extra as Recipe;
          }
          return ShowRecipeScreen(
            recipe: recipe,
            apiService: apiService,
            appTelemetry: appTelemetry,
            subscriptionViewModel: subscriptionViewModel,
            recipeViewModel: recipeViewModel,
            groceryListViewModel: groceryListViewModel,
            isGuest: isGuest,
          );
        },
      ),
      GoRoute(
        path: '/cook-recipe',
        builder: (_, state) {
          final extra = state.extra;
          final Recipe recipe;
          final GroceryListViewModel? groceryVm;
          if (extra is Map) {
            final m = Map<dynamic, dynamic>.from(extra);
            recipe = m['recipe'] as Recipe;
            groceryVm = m['groceryListViewModel'] as GroceryListViewModel?;
          } else {
            recipe = extra as Recipe;
            groceryVm = null;
          }
          return CookRecipeFlowScreen(
            recipe: recipe,
            apiService: apiService,
            appTelemetry: appTelemetry,
            subscriptionViewModel: subscriptionViewModel,
            groceryListViewModel: groceryVm ?? groceryListViewModel,
          );
        },
      ),
      GoRoute(
        path: '/shopping-list',
        redirect: (context, state) => '/grocery-list',
      ),
      GoRoute(
        path: '/grocery-list',
        builder: (context, __) => GroceryListScreen(
          groceryListViewModel: groceryListViewModel,
          appTelemetry: appTelemetry,
        ),
      ),
      GoRoute(
        path: '/pantry-scan',
        builder: (context, __) => PantryScanScreen(
          apiService: apiService,
          sessionManager: sessionManager as SessionManager,
          subscriptionViewModel: subscriptionViewModel,
          appTelemetry: appTelemetry,
        ),
      ),
      GoRoute(
        path: '/meal-plan',
        builder: (context, __) => MealPlanHubScreen(
          mealPlanViewModel: mealPlanViewModel,
          appTelemetry: appTelemetry,
        ),
        routes: [
          GoRoute(
            path: 'wizard',
            builder: (context, __) => MealPlanWizardScreen(
              mealPlanViewModel: mealPlanViewModel,
              subscriptionViewModel: subscriptionViewModel,
              sessionManager: sessionManager as SessionManager,
              appTelemetry: appTelemetry,
            ),
          ),
          GoRoute(
            path: 'review',
            builder: (context, __) => MealPlanReviewScreen(
              mealPlanViewModel: mealPlanViewModel,
              groceryListViewModel: groceryListViewModel,
              appTelemetry: appTelemetry,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, __) => ProfileScreen(
          homeViewModel: homeViewModel,
          loginViewModel: loginViewModel,
          subscriptionViewModel: subscriptionViewModel,
          appTelemetry: appTelemetry,
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, __) => FavoritesScreen(
          homeViewModel: homeViewModel,
          recipeViewModel: recipeViewModel,
          groceryListViewModel: groceryListViewModel,
          sessionManager: sessionManager,
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/trending',
        builder: (context, __) => TrendingRecipesScreen(
          homeViewModel: homeViewModel,
          recipeViewModel: recipeViewModel,
          groceryListViewModel: groceryListViewModel,
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/latest-recipes',
        builder: (context, __) => LatestRecipesScreen(
          homeViewModel: homeViewModel,
          recipeViewModel: recipeViewModel,
          groceryListViewModel: groceryListViewModel,
          subscriptionViewModel: subscriptionViewModel,
          appTelemetry: appTelemetry,
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/saved',
        redirect: (context, state) => '/favorites',
      ),
      GoRoute(
        path: '/tutorial',
        builder: (_, __) => const TutorialScreen(),
      ),
    ],
  );
}
