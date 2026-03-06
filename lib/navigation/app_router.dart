import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/login_handler_screen.dart';
import '../screens/home_screen.dart';
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
        builder: (_, __) => LoginHandlerScreen(loginViewModel: loginViewModel),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => HomeScreen(
          homeViewModel: homeViewModel,
          recipeViewModel: recipeViewModel,
          sessionManager: sessionManager,
        ),
      ),
      GoRoute(
        path: '/recipe-flow',
        builder: (_, state) {
          final userData = state.extra as UserData?;
          return RecipeFlowScreen(
            userData: userData,
            recipeViewModel: recipeViewModel,
            sessionManager: sessionManager,
          );
        },
      ),
      GoRoute(
        path: '/show-recipe',
        builder: (_, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            final recipe = extra['recipe'] as Recipe;
            final vm = extra['recipeViewModel'] as dynamic;
            return ShowRecipeScreen(recipe: recipe, recipeViewModel: vm);
          }
          final recipe = extra as Recipe;
          return ShowRecipeScreen(recipe: recipe);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, __) => ProfileScreen(
          homeViewModel: homeViewModel,
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, __) => FavoritesScreen(
          homeViewModel: homeViewModel,
          recipeViewModel: recipeViewModel,
          onBack: () => context.pop(),
        ),
      ),
    ],
  );
}
