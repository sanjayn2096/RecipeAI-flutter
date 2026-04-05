import 'dart:io';

import 'package:http/http.dart' show ClientException;

import '../data/api/api_service.dart';

/// User-facing copy when [generateRecipe] or parsing fails (no stack traces).
String recipeFetchErrorMessage(Object error) {
  if (error is ApiException) {
    return _fromApiException(error);
  }
  if (error is SocketException) {
    return 'We couldn’t reach the recipe server. Check your internet connection, '
        'then tap Refresh to try again.';
  }
  if (error is HttpException) {
    return 'There was a network problem loading recipes. Please try again.';
  }
  if (error is ClientException) {
    return 'We couldn’t connect to the recipe service. Check your connection and try again.';
  }
  if (error is FormatException) {
    return 'The recipe response wasn’t in the expected format. Please try again in a moment.';
  }

  final raw = error.toString();
  final lower = raw.toLowerCase();
  if (lower.contains('timeout')) {
    return 'The request timed out. Check your connection and tap Refresh to try again.';
  }
  if (lower.contains('connection refused') ||
      lower.contains('connection reset') ||
      lower.contains('network') ||
      lower.contains('socket')) {
    return 'Network problem. Check your connection and try again.';
  }

  return 'Something went wrong while creating recipes. Tap Refresh to try again, '
      'or use Back to change your preferences.';
}

String _fromApiException(ApiException e) {
  final code = e.statusCode;
  final raw = e.message.trim();
  final rawLower = raw.toLowerCase();

  if (code == 0) {
    if (rawLower.contains('html')) {
      return 'The server returned an unexpected page. The API address may be wrong, '
          'or the service may be down. Try again later or check your configuration.';
    }
    if (rawLower.contains('json')) {
      return 'The recipe service sent data we couldn’t read. Please try again in a moment.';
    }
    if (raw.isNotEmpty && raw.length <= 200 && !_looksTooTechnical(raw)) {
      return raw;
    }
    return 'Couldn’t complete the recipe request. Please try again.';
  }

  switch (code) {
    case 400:
      if (rawLower.contains('anonymousid')) {
        return _friendlyWithOptionalDetail(
          'Guest mode couldn’t be verified. Try again, or sign up for an account.',
          raw,
        );
      }
      return _friendlyWithOptionalDetail(
        'The recipe service couldn’t use this request. Try changing what you asked for, then try again.',
        raw,
      );
    case 401:
      return 'We couldn’t verify your account for recipe generation. Try signing out and signing in again.';
    case 403:
      if (rawLower.contains('free limit') ||
          rawLower.contains('create an account')) {
        if (raw.isNotEmpty && raw.length <= 220 && !_looksTooTechnical(raw)) {
          return raw;
        }
        return 'Free limit reached for today. Create an account to keep generating recipes.';
      }
      return 'We couldn’t verify your account for recipe generation. Try signing out and signing in again.';
    case 404:
      return 'The recipe endpoint wasn’t found. The service may be unavailable or misconfigured. Try again later.';
    case 408:
    case 429:
      return 'The service is busy or you’ve hit a limit. Wait a moment, then tap Refresh.';
    case 500:
    case 502:
    case 503:
    case 504:
      return 'The recipe service is temporarily unavailable. Please try again in a few minutes.';
    default:
      if (raw.isNotEmpty && raw.length <= 200 && !_looksTooTechnical(raw)) {
        return raw;
      }
      return 'The recipe service returned an error (HTTP $code). Tap Refresh to try again.';
  }
}

bool _looksTooTechnical(String s) {
  final l = s.toLowerCase();
  return l.contains('stack') ||
      l.contains('traceback') ||
      l.contains('exception:') ||
      l.contains('at ');
}

String _friendlyWithOptionalDetail(String friendly, String raw) {
  if (raw.isEmpty || raw.length > 160 || _looksTooTechnical(raw)) {
    return friendly;
  }
  return '$friendly\n\nDetails: $raw';
}
