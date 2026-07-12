import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/env_config.dart';
import '../../core/telemetry/api_call_context.dart';
import '../models/api_dtos.dart';
import '../models/meal_plan.dart';
import '../models/recipe.dart';

/// Central API service for all backend and session-related calls.
class ApiService {
  ApiService({
    String? baseUrl,
    this.getCallContext,
    this.onApiCompleted,
  }) : _baseUrl = baseUrl ?? EnvConfig.baseUrl;

  final String _baseUrl;

  /// Resolves Firebase uid or guest anonymous id for metrics.
  final Future<ApiCallContext> Function()? getCallContext;

  final void Function(ApiCallMetrics metrics)? onApiCompleted;

  static const _unknownActor = 'unknown';

  String _url(String path) =>
      '$_baseUrl${path.startsWith('/') ? path : '/$path'}';

  Future<ApiCallContext> _resolveContext() async {
    if (getCallContext == null) {
      return const ApiCallContext(
        actorId: _unknownActor,
        actorType: ApiActorType.anonymous,
      );
    }
    try {
      return await getCallContext!();
    } catch (_) {
      return const ApiCallContext(
        actorId: _unknownActor,
        actorType: ApiActorType.anonymous,
      );
    }
  }

  Future<http.Response> _execute(
    String method,
    String metricPath,
    Future<http.Response> Function() send,
  ) async {
    final ctx = await _resolveContext();
    final sw = Stopwatch()..start();
    try {
      final r = await send();
      sw.stop();
      onApiCompleted?.call(
        ApiCallMetrics(
          path: metricPath,
          method: method,
          statusCode: r.statusCode,
          durationMs: sw.elapsedMilliseconds,
          actorId: ctx.actorId,
          actorType: ctx.actorType,
        ),
      );
      return r;
    } catch (e) {
      sw.stop();
      onApiCompleted?.call(
        ApiCallMetrics(
          path: metricPath,
          method: method,
          statusCode: 0,
          durationMs: sw.elapsedMilliseconds,
          actorId: ctx.actorId,
          actorType: ctx.actorType,
          errorMessage: e.toString(),
        ),
      );
      rethrow;
    }
  }

  /// GET get_user_profile. Pass [idToken] (Firebase ID token) if your backend
  /// expects Authorization: Bearer <token>.
  Future<UserProfileResponse> getUserProfile({String? idToken}) async {
    const metricPath = 'get_user_profile';
    final url = _url('get_user_profile');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final r = await _execute('GET', metricPath, () async {
      return http.get(Uri.parse(url), headers: headers);
    });
    final map = _decodeBody(r.body, url);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return UserProfileResponse.fromJson(map as Map<String, dynamic>);
    }
    throw ApiException(r.statusCode, _extractError(map));
  }

  /// PATCH user-onboarding (Firebase ID token).
  Future<Map<String, dynamic>> patchUserOnboarding(
    PatchUserOnboardingRequest request, {
    String? idToken,
  }) async {
    const metricPath = 'user-onboarding';
    final url = _url('user-onboarding');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final r = await _execute('PATCH', metricPath, () async {
      return http.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );
    });
    final map = _decodeBody(r.body, url);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return map as Map<String, dynamic>;
    }
    throw ApiException(r.statusCode, _extractError(map));
  }

  /// PATCH user-lifestyle (Firebase ID token). Partial merge on Firestore user doc.
  Future<Map<String, dynamic>> patchUserLifestyle(
    UpdateUserLifestyleRequest request, {
    String? idToken,
  }) async {
    const metricPath = 'user-lifestyle';
    final url = _url('user-lifestyle');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final r = await _execute('PATCH', metricPath, () async {
      return http.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );
    });
    final map = _decodeBody(r.body, url);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return map as Map<String, dynamic>;
    }
    throw ApiException(r.statusCode, _extractError(map));
  }

  /// POST suggest-prompts — personalized short prompts (auth).
  Future<SuggestPromptsResponse> suggestPrompts({
    String? idToken,
    String? clientRequestId,
  }) async {
    const metricPath = 'suggest-prompts';
    final url = _url('suggest-prompts');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final now = DateTime.now();
    final body = <String, dynamic>{
      'requestedAt': now.toUtc().toIso8601String(),
      // Server uses 1=Mon..7=Sun (same as DateTime.weekday) for meal-time hints.
      'localHour': now.hour,
      'localWeekday': now.weekday,
      if (clientRequestId != null && clientRequestId.trim().isNotEmpty)
        'clientRequestId': clientRequestId.trim(),
    };
    final r = await _execute('POST', metricPath, () async {
      return http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
    });
    final decoded = _decodeBody(r.body, url);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return SuggestPromptsResponse.fromJson(decoded);
    }
    throw ApiException(r.statusCode, _extractError(decoded));
  }

  Future<SessionCheckResponse> checkSession(SessionCheckRequest request) async {
    const metricPath = 'check-session';
    final url = _url('check-session');
    final r = await _execute('POST', metricPath, () async {
      return http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );
    });
    final map = _decodeBody(r.body, url);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return SessionCheckResponse.fromJson(map as Map<String, dynamic>);
    }
    throw ApiException(r.statusCode, _extractError(map));
  }

  /// POST save-favorites. Pass [idToken] (Firebase ID token) for auth, same as generate-recipe.
  Future<SaveFavoriteRecipesResponse> saveFavoriteRecipes(
    SaveFavoriteRecipesRequest request, {
    String? idToken,
  }) async {
    const metricPath = 'save-favorites';
    final url = _url('save-favorites');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final r = await _execute('POST', metricPath, () async {
      return http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );
    });
    final map = _decodeBody(r.body, url);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return SaveFavoriteRecipesResponse.fromJson(map as Map<String, dynamic>);
    }
    throw ApiException(r.statusCode, _extractError(map));
  }

  /// POST generate-recipe (recipe preferences body; server builds LLM prompt). Pass [idToken] if auth.
  Future<GenerateRecipeResponse> generateRecipe(
    GenerateRecipeRequest request, {
    String? idToken,
  }) async {
    const metricPath = 'generate-recipe';
    final url = _url('generate-recipe');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final r = await _execute('POST', metricPath, () async {
      return http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );
    });
    if (kDebugMode) {
      debugPrint(
          '[ApiService] generate-recipe response: statusCode=${r.statusCode}');
      debugPrint('[ApiService] generate-recipe raw body:\n${r.body}');
    }
    final body = _decodeBody(r.body, url);
    if (kDebugMode) {
      debugPrint('[ApiService] generate-recipe decoded: $body');
    }
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return GenerateRecipeResponse.fromJson(body);
    }
    throw ApiException(
      r.statusCode,
      _extractError(body),
      code: body is Map ? body['code']?.toString() : null,
    );
  }

  /// POST resolve-recipe-hero.
  /// Returns corpus image URL, or empty URL when placeholder should be shown.
  Future<ResolveRecipeHeroResponse> resolveRecipeHero({
    required String recipeName,
    String? cuisine,
    String? idToken,
    String? clientRequestId,
    double? threshold,
  }) async {
    const metricPath = 'resolve-recipe-hero';
    final url = _url('resolve-recipe-hero');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final body = <String, dynamic>{
      'recipeName': recipeName,
      if (cuisine != null && cuisine.trim().isNotEmpty)
        'cuisine': cuisine.trim(),
      if (clientRequestId != null && clientRequestId.trim().isNotEmpty)
        'clientRequestId': clientRequestId.trim(),
      if (threshold != null) 'threshold': threshold.clamp(0.0, 1.0),
    };
    final r = await _execute('POST', metricPath, () async {
      return http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
    });
    final map = _decodeBody(r.body, url);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return ResolveRecipeHeroResponse.fromJson(map as Map<String, dynamic>);
    }
    throw ApiException(r.statusCode, _extractError(map));
  }

  /// POST generate-recipes-stream.
  /// Emits each recipe as it arrives via SSE events.
  /// [onAssistantMessage] fires once when the server sends an intent-aware intro.
  Stream<Recipe> generateRecipeStream(
    GenerateRecipeRequest request, {
    String? idToken,
    void Function(String message)? onAssistantMessage,
  }) async* {
    const metricPath = 'generate-recipes-stream';
    final url = _url('generate-recipes-stream');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };

    final ctx = await _resolveContext();
    final sw = Stopwatch()..start();
    final client = http.Client();
    var statusCode = 0;
    String? errorMessage;

    try {
      final req = http.Request('POST', Uri.parse(url));
      req.headers.addAll(headers);
      req.body = jsonEncode(request.toJson());

      final streamed = await client.send(req);
      statusCode = streamed.statusCode;

      if (statusCode < 200 || statusCode >= 300) {
        final body = await streamed.stream.bytesToString();
        final decoded = _decodeBody(body, url);
        throw ApiException(
          statusCode,
          _extractError(decoded),
          code: decoded is Map ? decoded['code']?.toString() : null,
        );
      }

      String currentEvent = '';
      final dataLines = <String>[];

      dynamic parsePayload(List<String> lines) {
        final payload = lines.join('\n').trim();
        if (payload.isEmpty) return <String, dynamic>{};
        return jsonDecode(payload);
      }

      await for (final rawLine in streamed.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        final line = rawLine.trimRight();

        if (line.isEmpty) {
          final event = currentEvent.isEmpty ? 'message' : currentEvent;
          final payload = parsePayload(dataLines);

          if (event == 'recipe') {
            if (payload is Map<String, dynamic>) {
              yield Recipe.fromJson(payload);
            }
          } else if (event == 'assistant') {
            if (payload is Map<String, dynamic>) {
              final msg = payload['message'] as String?;
              if (msg != null && msg.trim().isNotEmpty) {
                onAssistantMessage?.call(msg.trim());
              }
            }
          } else if (event == 'error') {
            throw ApiException(
              statusCode,
              _extractError(payload),
              code: payload is Map ? payload['code']?.toString() : null,
            );
          } else if (event == 'done') {
            return;
          }

          currentEvent = '';
          dataLines.clear();
          continue;
        }

        if (line.startsWith(':')) continue;

        if (line.startsWith('event:')) {
          currentEvent = line.substring(6).trim();
          continue;
        }

        if (line.startsWith('data:')) {
          dataLines.add(line.substring(5).trimLeft());
        }
      }
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      sw.stop();
      onApiCompleted?.call(
        ApiCallMetrics(
          path: metricPath,
          method: 'POST',
          statusCode: statusCode,
          durationMs: sw.elapsedMilliseconds,
          actorId: ctx.actorId,
          actorType: ctx.actorType,
          errorMessage: errorMessage,
        ),
      );
      client.close();
    }
  }

  /// GET fetch-saved (auth). Legacy alias [fetchFavorites] hits the same merged list.
  Future<List<Recipe>> fetchSavedRecipes({String? idToken}) async {
    const metricPath = 'fetch-saved';
    final url = _url('fetch-saved');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final r = await _execute('GET', metricPath, () async {
      return http.get(Uri.parse(url), headers: headers);
    });
    final body = _decodeBody(r.body, url);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return _parseRecipeList(body);
    }
    throw ApiException(r.statusCode, _extractError(body));
  }

  /// Backward compatible: same as [fetchSavedRecipes] (merges `saved` + legacy `favorites`).
  Future<List<Recipe>> fetchFavorites({String? idToken}) =>
      fetchSavedRecipes(idToken: idToken);

  /// POST /toggle-public-favorite — public heart + [favoriteCount] (auth).
  Future<void> togglePublicFavorite({
    required String recipeId,
    required bool favorited,
    String? idToken,
  }) async {
    const metricPath = 'toggle-public-favorite';
    final url = _url('toggle-public-favorite');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final r = await _execute('POST', metricPath, () async {
      return http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'recipeId': recipeId,
          'favorited': favorited,
        }),
      );
    });
    final map = _decodeBody(r.body, url);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return;
    }
    throw ApiException(r.statusCode, _extractError(map));
  }

  /// GET /latest-recipes — auth + premium.
  Future<List<Recipe>> fetchLatestRecipes({
    int limit = 20,
    String? idToken,
  }) async {
    const metricPath = 'latest-recipes';
    final raw = limit.clamp(1, 50);
    final url = _url('latest-recipes?limit=$raw');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final r = await _execute('GET', metricPath, () async {
      return http.get(Uri.parse(url), headers: headers);
    });
    final body = _decodeBody(r.body, url);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return _parseRecipeList(body);
    }
    throw ApiException(r.statusCode, _extractError(body));
  }

  /// POST /verify-subscription — validates store purchase and updates Firestore.
  Future<Map<String, dynamic>> verifySubscription({
    required String platform,
    required String productId,
    String? purchaseToken,
    String? receiptData,
    String? idToken,
  }) async {
    const metricPath = 'verify-subscription';
    final url = _url('verify-subscription');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final r = await _execute('POST', metricPath, () async {
      return http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'platform': platform,
          'productId': productId,
          if (purchaseToken != null) 'purchaseToken': purchaseToken,
          if (receiptData != null) 'receiptData': receiptData,
        }),
      );
    });
    final map = _decodeBody(r.body, url);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return map as Map<String, dynamic>;
    }
    throw ApiException(r.statusCode, _extractError(map));
  }

  /// GET /trending-recipes — no auth. Recipes with highest [favoriteCount].
  Future<List<Recipe>> fetchTrendingRecipes({int limit = 20}) async {
    const metricPath = 'trending-recipes';
    final raw = limit.clamp(1, 50);
    final url = _url('trending-recipes?limit=$raw');
    final r = await _execute('GET', metricPath, () async {
      return http.get(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
      );
    });
    final body = _decodeBody(r.body, url);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return _parseRecipeList(body);
    }
    throw ApiException(r.statusCode, _extractError(body));
  }

  /// POST import-recipe (auth). [mode] is `url` or `text` (structured parse only, no generation).
  Future<Recipe> importRecipe({
    required String mode,
    String? url,
    String? plainText,
    String? idToken,
  }) async {
    const metricPath = 'import-recipe';
    final urlPath = _url('import-recipe');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final body = <String, dynamic>{
      'mode': mode,
      if (url != null && url.trim().isNotEmpty) 'url': url.trim(),
      if (plainText != null && plainText.trim().isNotEmpty)
        'plainText': plainText.trim(),
    };
    final r = await _execute('POST', metricPath, () async {
      return http.post(
        Uri.parse(urlPath),
        headers: headers,
        body: jsonEncode(body),
      );
    });
    final map = _decodeBody(r.body, urlPath);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (map is! Map<String, dynamic>) {
        throw ApiException(0, 'Invalid import-recipe response');
      }
      final raw = map['recipe'];
      if (raw is! Map<String, dynamic>) {
        throw ApiException(0, 'Missing recipe in import response');
      }
      return Recipe.fromJson(raw);
    }
    throw ApiException(r.statusCode, _extractError(map));
  }

  /// POST analyze-pantry-image (auth). [imageBase64] raw base64 or a `data:<mime>;base64,` data URL.
  Future<PantryScanResponse> analyzePantryImage({
    required String imageBase64,
    String? mimeType,
    String? idToken,
  }) async {
    const metricPath = 'analyze-pantry-image';
    final url = _url('analyze-pantry-image');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final body = <String, dynamic>{
      'imageBase64': imageBase64,
      if (mimeType != null && mimeType.trim().isNotEmpty)
        'mimeType': mimeType.trim(),
    };
    final r = await _execute('POST', metricPath, () async {
      return http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
    });
    final map = _decodeBody(r.body, url);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (kDebugMode) {
        final u = map is Map ? map['usage'] : null;
        debugPrint('[ApiService] analyze-pantry-image usage: $u');
      }
      return PantryScanResponse.fromJson(map as Map<String, dynamic>);
    }
    throw ApiException(r.statusCode, _extractError(map));
  }

  /// GET get-recipe/:recipeId (auth: Firebase ID token). Full document from Firestore `recipes`.
  Future<Recipe> getRecipe(String recipeId, {String? idToken}) async {
    const metricPath = 'get-recipe';
    final encoded = Uri.encodeComponent(recipeId);
    final url = _url('get-recipe/$encoded');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final r = await _execute('GET', metricPath, () async {
      return http.get(Uri.parse(url), headers: headers);
    });
    final body = _decodeBody(r.body, url);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final map = body as Map<String, dynamic>;
      final recipeJson = map['recipe'];
      if (recipeJson is! Map<String, dynamic>) {
        throw ApiException(0, 'Invalid get-recipe response: missing recipe');
      }
      return Recipe.fromJson(recipeJson);
    }
    throw ApiException(r.statusCode, _extractError(body));
  }

  /// POST /generate-recipe-step-image (Premium). Persists onto recipe when [recipeId] set.
  Future<GenerateRecipeStepImageResponse> generateRecipeStepImage({
    required String recipeName,
    required String stepText,
    required int stepIndex,
    String? cuisine,
    String? recipeId,
    String? clientRequestId,
    String? idToken,
  }) async {
    const metricPath = 'generate-recipe-step-image';
    final url = _url('generate-recipe-step-image');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final body = <String, dynamic>{
      'recipeName': recipeName,
      'stepText': stepText,
      'stepIndex': stepIndex,
      if (cuisine != null && cuisine.trim().isNotEmpty) 'cuisine': cuisine.trim(),
      if (recipeId != null && recipeId.trim().isNotEmpty) 'recipeId': recipeId.trim(),
      if (clientRequestId != null && clientRequestId.trim().isNotEmpty)
        'clientRequestId': clientRequestId.trim(),
    };
    final r = await _execute('POST', metricPath, () async {
      return http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
    });
    final decoded = _decodeBody(r.body, url);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return GenerateRecipeStepImageResponse.fromJson(
        decoded as Map<String, dynamic>,
      );
    }
    throw ApiException(
      r.statusCode,
      _extractError(decoded),
      code: decoded is Map ? decoded['code']?.toString() : null,
    );
  }

  Future<RecipeQuestionResponse> askRecipe(
    RecipeQuestionRequest request, {
    String? idToken,
  }) async {
    const metricPath = 'ask-recipe';
    final url = _url('ask-recipe');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final r = await _execute('POST', metricPath, () async {
      return http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );
    });
    final body = _decodeBody(r.body, url);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return RecipeQuestionResponse.fromJson(body as Map<String, dynamic>);
    }
    throw ApiException(
      r.statusCode,
      _extractError(body),
      code: body is Map ? body['code']?.toString() : null,
    );
  }

  static List<Recipe> _parseRecipeList(dynamic json) {
    if (json is List) {
      return json
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final map = json as Map<String, dynamic>;
    final list = map['favorite_recipes'] ??
        map['favorites'] ??
        map['saved'] ??
        map['recipes'] ??
        map['data'];
    if (list is! List) return [];
    return list.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Decodes response body as JSON. Throws a clear error if server returned HTML
  /// (e.g. 404/502 page) so the app doesn't show raw FormatException.
  static dynamic _decodeBody(String body, String requestUrl) {
    if (body.isEmpty) return <String, dynamic>{};
    final trimmed = body.trimLeft();
    if (trimmed.startsWith('<') ||
        trimmed.toLowerCase().startsWith('<!doctype')) {
      throw ApiException(
        0,
        'Server returned an HTML page instead of JSON. '
        'Check that the API base URL is correct and the backend is running. '
        'Requested: $requestUrl',
      );
    }
    try {
      return jsonDecode(body);
    } catch (e) {
      throw ApiException(
        0,
        'Invalid JSON from server: ${e.toString().split('\n').first}. '
        'URL: $requestUrl',
      );
    }
  }

  static String _extractError(dynamic map) {
    if (map is! Map) return 'Request failed';
    final m = map;
    for (final key in [
      'message',
      'error',
      'detail',
      'details',
      'msg',
      'description'
    ]) {
      final v = m[key];
      if (v != null) {
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    return 'Request failed';
  }

  /// POST /generate-meal-plan
  Future<MealPlanResult> generateMealPlan(
    GenerateMealPlanRequest request, {
    String? idToken,
  }) async {
    const metricPath = 'generate-meal-plan';
    final url = _url('generate-meal-plan');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final r = await _execute('POST', metricPath, () async {
      return http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );
    });
    final map = _decodeBody(r.body, url);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return MealPlanResult.fromJson(map as Map<String, dynamic>);
    }
    throw ApiException(
      r.statusCode,
      _extractError(map),
      code: map is Map ? map['code']?.toString() : null,
    );
  }

  /// POST /regenerate-meal-plan-slot
  Future<MealPlanResult> regenerateMealPlanSlot(
    RegenerateMealPlanSlotRequest request, {
    String? idToken,
  }) async {
    const metricPath = 'regenerate-meal-plan-slot';
    final url = _url('regenerate-meal-plan-slot');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final r = await _execute('POST', metricPath, () async {
      return http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );
    });
    final map = _decodeBody(r.body, url);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return MealPlanResult.fromJson(map as Map<String, dynamic>);
    }
    throw ApiException(
      r.statusCode,
      _extractError(map),
      code: map is Map ? map['code']?.toString() : null,
    );
  }

  /// PATCH user-timezone — silent device IANA timezone sync.
  Future<void> patchUserTimezone({
    required String timezone,
    String? idToken,
  }) async {
    const metricPath = 'user-timezone';
    final url = _url('user-timezone');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final r = await _execute('PATCH', metricPath, () async {
      return http.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({'timezone': timezone.trim()}),
      );
    });
    final map = _decodeBody(r.body, url);
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    throw ApiException(r.statusCode, _extractError(map));
  }

  /// POST user-app-open — records local app-open day for daily-ideas eligibility.
  Future<void> postUserAppOpen({String? idToken}) async {
    const metricPath = 'user-app-open';
    final url = _url('user-app-open');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final r = await _execute('POST', metricPath, () async {
      return http.post(Uri.parse(url), headers: headers, body: '{}');
    });
    final map = _decodeBody(r.body, url);
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    throw ApiException(r.statusCode, _extractError(map));
  }

  /// GET daily-ideas — shared categorized catalog (auth).
  Future<DailyIdeasResponse> fetchDailyIdeas({
    String? idToken,
    String slot = 'dinner',
    String? date,
  }) async {
    const metricPath = 'daily-ideas';
    final q = <String, String>{'slot': slot};
    if (date != null && date.trim().isNotEmpty) {
      q['date'] = date.trim();
    }
    final url = Uri.parse(_url('daily-ideas')).replace(queryParameters: q);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final r = await _execute('GET', metricPath, () async {
      return http.get(url, headers: headers);
    });
    if (r.statusCode == 304) {
      throw ApiException(
        304,
        'Daily ideas response was not modified (cached). Retry without cache.',
      );
    }
    final map = _decodeBody(r.body, url.toString());
    if (r.statusCode == 200) {
      return DailyIdeasResponse.fromJson(map as Map<String, dynamic>);
    }
    throw ApiException(r.statusCode, _extractError(map));
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message, {this.code});
  final int statusCode;
  final String message;
  final String? code;
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ResolveRecipeHeroResponse {
  const ResolveRecipeHeroResponse({
    required this.recipeImageUrl,
    required this.source,
    this.bestScore = 0,
  });

  final String recipeImageUrl;
  final String source;
  final double bestScore;

  factory ResolveRecipeHeroResponse.fromJson(Map<String, dynamic> json) {
    final scoreRaw = json['bestScore'];
    final double score = scoreRaw is num ? scoreRaw.toDouble() : 0.0;
    return ResolveRecipeHeroResponse(
      recipeImageUrl: (json['recipeImageUrl'] ?? '').toString(),
      source: (json['source'] ?? 'placeholder').toString(),
      bestScore: score,
    );
  }
}

class GenerateRecipeStepImageResponse {
  const GenerateRecipeStepImageResponse({
    required this.stepIndex,
    required this.imageUrl,
    this.clientRequestId,
    this.recipeId,
  });

  final int stepIndex;
  final String imageUrl;
  final String? clientRequestId;
  final String? recipeId;

  factory GenerateRecipeStepImageResponse.fromJson(Map<String, dynamic> json) {
    final idxRaw = json['stepIndex'];
    final idx = idxRaw is num ? idxRaw.toInt() : int.tryParse('$idxRaw') ?? 0;
    return GenerateRecipeStepImageResponse(
      stepIndex: idx,
      imageUrl: (json['imageUrl'] ?? '').toString(),
      clientRequestId: json['clientRequestId']?.toString(),
      recipeId: json['recipeId']?.toString(),
    );
  }
}

class DailyIdeasCategory {
  const DailyIdeasCategory({
    required this.id,
    required this.label,
    required this.recipe,
  });

  final String id;
  final String label;
  final Recipe recipe;

  factory DailyIdeasCategory.fromJson(Map<String, dynamic> json) {
    final rawRecipe = json['recipe'];
    final recipe = rawRecipe is Map
        ? Recipe.fromJson(Map<String, dynamic>.from(rawRecipe))
        : Recipe.fromJson(const <String, dynamic>{});
    return DailyIdeasCategory(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      recipe: recipe,
    );
  }
}

class DailyIdeasResponse {
  const DailyIdeasResponse({
    required this.batchId,
    required this.localDate,
    required this.slot,
    required this.status,
    required this.recipes,
    this.categories = const [],
    this.timezone = '',
    this.error,
    this.isFallback = false,
    this.fallbackBatchId,
  });

  final String batchId;
  final String localDate;
  final String slot;
  final String timezone;
  final String status;
  final List<Recipe> recipes;
  final List<DailyIdeasCategory> categories;
  final String? error;
  final bool isFallback;
  final String? fallbackBatchId;

  bool get isReady =>
      status == 'ready' && (categories.isNotEmpty || recipes.isNotEmpty);

  bool get hasDisplayRecipes =>
      categories.isNotEmpty || recipes.isNotEmpty;

  factory DailyIdeasResponse.fromJson(Map<String, dynamic> json) {
    final rawCats = json['categories'];
    final categories = rawCats is List
        ? rawCats
            .whereType<Map>()
            .map((e) => DailyIdeasCategory.fromJson(Map<String, dynamic>.from(e)))
            .where((c) => c.recipe.recipeName.trim().isNotEmpty)
            .toList()
        : <DailyIdeasCategory>[];

    final raw = json['recipes'];
    var list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => Recipe.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <Recipe>[];
    if (list.isEmpty && categories.isNotEmpty) {
      list = categories.map((c) => c.recipe).toList();
    }

    return DailyIdeasResponse(
      batchId: (json['batchId'] ?? json['date'] ?? '').toString(),
      localDate: (json['localDate'] ?? json['date'] ?? json['utcDate'] ?? '')
          .toString(),
      slot: (json['slot'] ?? 'dinner').toString(),
      timezone: (json['timezone'] ?? 'UTC').toString(),
      status: (json['status'] ?? 'missing').toString(),
      recipes: list,
      categories: categories,
      error: json['error']?.toString(),
      isFallback: json['isFallback'] == true,
      fallbackBatchId: json['fallbackBatchId']?.toString(),
    );
  }
}

/// One detected item from POST /analyze-pantry-image (user must confirm before adding).
class PantryScanItem {
  const PantryScanItem({
    required this.name,
    this.quantity = '',
    this.unit = '',
    this.confidence,
    this.notes = '',
  });

  final String name;
  final String quantity;
  final String unit;
  final double? confidence;
  final String notes;

  factory PantryScanItem.fromJson(Map<String, dynamic> json) {
    final cRaw = json['confidence'];
    double? conf;
    if (cRaw is num) {
      conf = cRaw.toDouble().clamp(0.0, 1.0);
    }
    return PantryScanItem(
      name: (json['name'] ?? '').toString().trim(),
      quantity: (json['quantity'] ?? '').toString().trim(),
      unit: (json['unit'] ?? '').toString().trim(),
      confidence: conf,
      notes: (json['notes'] ?? '').toString().trim(),
    );
  }

  /// Ingredient line for [GroceryIngredientNormalize.normalizeRecipeIngredientLine].
  String toIngredientLine() {
    final parts = <String>[];
    if (quantity.isNotEmpty) parts.add(quantity);
    if (unit.isNotEmpty) parts.add(unit);
    parts.add(name);
    return parts.join(' ');
  }
}

/// Token usage from Gemini (for cost estimation in logs / debug).
class PantryScanUsage {
  const PantryScanUsage({
    required this.model,
    this.promptTokenCount = 0,
    this.candidatesTokenCount = 0,
    this.totalTokenCount = 0,
    this.estimatedCostUsd,
  });

  final String model;
  final int promptTokenCount;
  final int candidatesTokenCount;
  final int totalTokenCount;
  final double? estimatedCostUsd;

  factory PantryScanUsage.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PantryScanUsage(model: '');
    }
    double? est;
    final e = json['estimatedCostUsd'];
    if (e is num) est = e.toDouble();
    return PantryScanUsage(
      model: (json['model'] ?? '').toString(),
      promptTokenCount: (json['promptTokenCount'] is num)
          ? (json['promptTokenCount'] as num).toInt()
          : 0,
      candidatesTokenCount: (json['candidatesTokenCount'] is num)
          ? (json['candidatesTokenCount'] as num).toInt()
          : 0,
      totalTokenCount: (json['totalTokenCount'] is num)
          ? (json['totalTokenCount'] as num).toInt()
          : 0,
      estimatedCostUsd: est,
    );
  }
}

class PantryScanResponse {
  const PantryScanResponse({
    required this.items,
    this.usage,
  });

  final List<PantryScanItem> items;
  final PantryScanUsage? usage;

  factory PantryScanResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final list = <PantryScanItem>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          final item = PantryScanItem.fromJson(e);
          if (item.name.isNotEmpty) list.add(item);
        }
      }
    }
    final u = json['usage'];
    return PantryScanResponse(
      items: list,
      usage: u is Map<String, dynamic> ? PantryScanUsage.fromJson(u) : null,
    );
  }
}
