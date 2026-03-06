import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/api_dtos.dart';
import '../models/recipe.dart';
import '../models/user_data.dart';
import '../../core/env_config.dart';

/// Central API service for all backend and session-related calls.
class ApiService {
  ApiService({String? baseUrl})
      : _baseUrl = baseUrl ?? EnvConfig.baseUrl;

  final String _baseUrl;

  String _url(String path) =>
      '$_baseUrl${path.startsWith('/') ? path : '/$path'}';

  Future<LoginResponse> login(LoginRequest request) async {
    final r = await http.post(
      Uri.parse(_url('login')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    final map = _decodeBody(r.body);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return LoginResponse.fromJson(map);
    }
    throw ApiException(r.statusCode, _extractError(map));
  }

  Future<SessionCheckResponse> checkSession(SessionCheckRequest request) async {
    final r = await http.post(
      Uri.parse(_url('check-session')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    final map = _decodeBody(r.body);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return SessionCheckResponse.fromJson(map);
    }
    throw ApiException(r.statusCode, _extractError(map));
  }

  Future<SignupResponse> signup(SignupRequest request) async {
    final r = await http.post(
      Uri.parse(_url('signup')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    final map = _decodeBody(r.body);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return SignupResponse.fromJson(map);
    }
    throw ApiException(r.statusCode, _extractError(map));
  }

  Future<SignoutResponse> signout(SignoutRequest request) async {
    final r = await http.post(
      Uri.parse(_url('signout')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    final map = _decodeBody(r.body);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return SignoutResponse.fromJson(map);
    }
    throw ApiException(r.statusCode, _extractError(map));
  }

  Future<UserData> fetchUserDetails(String? email) async {
    final uri = Uri.parse(_url('fetch-user-details')).replace(
      queryParameters: email != null ? {'email': email} : null,
    );
    final r = await http.get(uri);
    final map = _decodeBody(r.body);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return UserData.fromJson(map as Map<String, dynamic>);
    }
    throw ApiException(r.statusCode, _extractError(map));
  }

  Future<SaveFavoriteRecipesResponse> saveFavoriteRecipes(
    SaveFavoriteRecipesRequest request,
  ) async {
    final r = await http.post(
      Uri.parse(_url('save-favorites')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    final map = _decodeBody(r.body);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return SaveFavoriteRecipesResponse.fromJson(map);
    }
    throw ApiException(r.statusCode, _extractError(map));
  }

  static dynamic _decodeBody(String body) {
    if (body.isEmpty) return <String, dynamic>{};
    return jsonDecode(body);
  }

  static String _extractError(dynamic map) {
    if (map is Map && map['error'] != null) return map['error'].toString();
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
