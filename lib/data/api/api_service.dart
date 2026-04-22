import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/env_config.dart';
import '../../core/telemetry/api_call_context.dart';
import '../models/api_dtos.dart';
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
    final body = <String, dynamic>{
      'requestedAt': DateTime.now().toUtc().toIso8601String(),
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
      debugPrint('[ApiService] generate-recipe response: statusCode=${r.statusCode}');
      debugPrint('[ApiService] generate-recipe raw body:\n${r.body}');
    }
    final body = _decodeBody(r.body, url);
    if (kDebugMode) {
      debugPrint('[ApiService] generate-recipe decoded: $body');
    }
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return GenerateRecipeResponse.fromJson(body);
    }
    throw ApiException(r.statusCode, _extractError(body));
  }

  /// POST generate-recipes-stream.
  /// Emits each recipe as it arrives via SSE events.
  Stream<Recipe> generateRecipeStream(
    GenerateRecipeRequest request, {
    String? idToken,
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
        throw ApiException(statusCode, _extractError(decoded));
      }

      String currentEvent = '';
      final dataLines = <String>[];

      dynamic parsePayload(List<String> lines) {
        final payload = lines.join('\n').trim();
        if (payload.isEmpty) return <String, dynamic>{};
        return jsonDecode(payload);
      }

      await for (final rawLine
          in streamed.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        final line = rawLine.trimRight();

        if (line.isEmpty) {
          final event = currentEvent.isEmpty ? 'message' : currentEvent;
          final payload = parsePayload(dataLines);

          if (event == 'recipe') {
            if (payload is Map<String, dynamic>) {
              yield Recipe.fromJson(payload);
            }
          } else if (event == 'error') {
            throw ApiException(statusCode, _extractError(payload));
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

  /// GET fetch-favorites (auth: Firebase ID token).
  Future<List<Recipe>> fetchFavorites({String? idToken}) async {
    const metricPath = 'fetch-favorites';
    final url = _url('fetch-favorites');
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

  static List<Recipe> _parseRecipeList(dynamic json) {
    if (json is List) {
      return json
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final map = json as Map<String, dynamic>;
    final list = map['favorite_recipes'] ??
        map['favorites'] ??
        map['recipes'] ??
        map['data'];
    if (list is! List) return [];
    return list
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();
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
    for (final key in ['message', 'error', 'detail', 'msg', 'description']) {
      final v = m[key];
      if (v != null) {
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    return 'Request failed';
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => 'ApiException($statusCode): $message';
}
