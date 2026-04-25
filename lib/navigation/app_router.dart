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
import '../screens/tutorial_screen.dart';
import '../screens/grocery_list_screen.dart';
import '../data/models/recipe.dart';
import '../data/models/user_data.dart';
import '../core/telemetry/app_telemetry.dart';
import '../view_models/grocery_list_view_model.dart';

class AppRouter {
  AppRouter({
    required this.loginViewModel,
    required this.homeViewModel,
    required this.recipeViewModel,
    required this.groceryListViewModel,
    required this.appTelemetry,
    required this.sessionManager,
    this.analytics,
  });

  final dynamic loginViewModel;
  final dynamic homeViewModel;
  final dynamic recipeViewModel;
  final GroceryListViewModel groceryListViewModel;
  final AppTelemetry appTelemetry;
  final dynamic sessionManager;
  final FirebaseAnalytics? analytics;

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    observers: [
      if (analytics != null)
        FirebaseAnalyticsObserver(analytics: analytics!),
    ],
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => SplashScreen(loginViewModel: loginViewModel),
      ),
      GoRoute(
        path: '/login',
        builder: (_, state) {
          final extra = state.extra;
          final openSignup =
              extra == true || extra == 'signup' || extra == 'Signup';
          return LoginHandlerScreen(
            loginViewModel: loginViewModel,
            openSignup: openSignup,
          );
        },
      ),
      GoRoute(
        path: '/verify-email',
        builder: (_, __) =>
            VerifyEmailScreen(loginViewModel: loginViewModel as LoginViewModel),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => HomeShellScreen(
          homeViewModel: homeViewModel,
          loginViewModel: loginViewModel,
          recipeViewModel: recipeViewModel,
          groceryListViewModel: groceryListViewModel,
          appTelemetry: appTelemetry,
          sessionManager: sessionManager,
        ),
      ),
      GoRoute(
        path: '/recipe-flow',
        builder: (_, state) {
          final extra = state.extra;
          UserData? userData;
          String? initialPrompt;
          if (extra is Map<String, dynamic>) {
            userData = extra['userData'] as UserData?;
            initialPrompt = extra['initialPrompt'] as String?;
          } else {
            userData = extra as UserData?;
          }
          return RecipeFlowScreen(
            userData: userData,
            initialPrompt: initialPrompt,
            recipeViewModel: recipeViewModel,
            groceryListViewModel: groceryListViewModel,
            sessionManager: sessionManager,
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
        path: '/profile',
        builder: (context, __) => ProfileScreen(
          homeViewModel: homeViewModel,
          loginViewModel: loginViewModel,
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
