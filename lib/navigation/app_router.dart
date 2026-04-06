import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/login_handler_screen.dart';
import '../screens/verify_email_screen.dart';
import '../view_models/login_view_model.dart';
import '../screens/home_shell_screen.dart';
import '../screens/recipe_flow_screen.dart';
import '../screens/show_recipe_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/favorites_screen.dart';
import '../data/models/recipe.dart';
import '../data/models/user_data.dart';

class AppRouter {
  AppRouter({
    required this.loginViewModel,
    required this.homeViewModel,
    required this.recipeViewModel,
    required this.sessionManager,
  });

  final dynamic loginViewModel;
  final dynamic homeViewModel;
  final dynamic recipeViewModel;
  final dynamic sessionManager;

  late final GoRouter router = GoRouter(
    initialLocation: '/',
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
            sessionManager: sessionManager,
          );
        },
      ),
      GoRoute(
        path: '/show-recipe',
        builder: (_, state) {
          final extra = state.extra;
          final isGuest = sessionManager.isGuestMode();
          if (extra is Map<String, dynamic>) {
            final recipe = extra['recipe'] as Recipe;
            final vm = extra['recipeViewModel'] as dynamic;
            return ShowRecipeScreen(
              recipe: recipe,
              recipeViewModel: vm,
              isGuest: isGuest,
            );
          }
          final recipe = extra as Recipe;
          return ShowRecipeScreen(recipe: recipe, isGuest: isGuest);
        },
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
          sessionManager: sessionManager,
          onBack: () => context.pop(),
        ),
      ),
    ],
  );
}
