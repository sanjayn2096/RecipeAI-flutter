import '../data/api/api_service.dart' show ApiException;

/// True when the backend rejected a recipe generation due to free/guest daily quota.
bool isRecipeGenerationQuotaError(Object error) {
  if (error is ApiException) {
    if (error.code == 'recipe_quota_exceeded') return true;
    final rawLower = error.message.toLowerCase();
    if (error.statusCode == 403 &&
        (rawLower.contains('daily recipe limit') ||
            rawLower.contains('free limit'))) {
      return true;
    }
  }
  return false;
}
