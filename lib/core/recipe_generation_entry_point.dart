/// Which surface initiated the current recipe generation batch (drives Change search settings UX).
enum RecipeGenerationEntryPoint {
  /// Home quick prompt / pantry → pushed `/recipe-flow` or equivalent.
  home,

  /// Create Recipes tab questionnaire path.
  createRecipes,
}
