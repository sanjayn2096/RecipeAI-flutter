import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

/// Max width/height for resized files stored on disk by [ImageCacheManager].
const int kRecipeImageMaxDiskCachePx = 800;

/// Shared disk cache for recipe hero/step images (Firebase Storage download URLs).
class RecipeImageCacheManager extends CacheManager with ImageCacheManager {
  RecipeImageCacheManager._()
      : super(
          Config(
            _cacheKey,
            stalePeriod: const Duration(days: 30),
            maxNrOfCacheObjects: 200,
            fileService: RetryHttpFileService(),
          ),
        );

  static const _cacheKey = 'recipeImageCache';

  static final RecipeImageCacheManager instance = RecipeImageCacheManager._();
}

/// Retries transient Firebase Storage download failures (connection closed, etc.).
class RetryHttpFileService extends HttpFileService {
  RetryHttpFileService({super.httpClient});

  static const _maxAttempts = 3;
  static const _backoffMs = [250, 500, 1000];

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    Object? lastError;
    StackTrace? lastStack;

    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      try {
        final response = await super.get(url, headers: headers);
        final code = response.statusCode;
        if (code >= 200 && code < 300) {
          return response;
        }
        throw HttpExceptionWithStatus(code, 'HTTP $code for $url');
      } on http.ClientException catch (e, st) {
        lastError = e;
        lastStack = st;
      } on SocketException catch (e, st) {
        lastError = e;
        lastStack = st;
      } on HttpExceptionWithStatus catch (e, st) {
        if (e.statusCode >= 500 && attempt < _maxAttempts - 1) {
          lastError = e;
          lastStack = st;
        } else {
          rethrow;
        }
      } on HttpException catch (e, st) {
        lastError = e;
        lastStack = st;
      }

      if (attempt < _maxAttempts - 1) {
        await Future<void>.delayed(
          Duration(milliseconds: _backoffMs[attempt]),
        );
      }
    }

    Error.throwWithStackTrace(lastError!, lastStack ?? StackTrace.current);
  }
}

/// Logical layout pixels → decode/cache pixel size for the current device.
int? recipeImageMemCachePx(double? logicalPx, double devicePixelRatio) {
  if (logicalPx == null || !logicalPx.isFinite || logicalPx <= 0) {
    return null;
  }
  return (logicalPx * devicePixelRatio).ceil();
}
