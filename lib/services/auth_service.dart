import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

class AuthService {
  static const String _legacyTokenKey = 'auth_token';
  static const String _accessTokenKey = 'admin_access_token';
  static const String _refreshTokenKey = 'admin_refresh_token';

  static Future<bool>? _refreshInProgress;

  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/v2/authenticate'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode != 200) {
        await clearSession();
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = _readToken(data, const ['accessToken', 'token']);
      final refreshToken = _readToken(data, const ['refreshToken']) ?? accessToken;

      if (accessToken == null || accessToken.isEmpty) {
        await clearSession();
        return false;
      }

      await _saveTokens(accessToken, refreshToken);
      return true;
    } catch (_) {
      await clearSession();
      return false;
    }
  }

  Future<bool> refreshAccessToken() {
    final existing = _refreshInProgress;
    if (existing != null) return existing;

    final operation = _performRefresh();
    _refreshInProgress = operation;
    return operation.whenComplete(() {
      if (identical(_refreshInProgress, operation)) {
        _refreshInProgress = null;
      }
    });
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await clearSession();
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/v2/refreshtoken'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
          // Retained for compatibility with older mawa-admin-bes deployments.
          'isRefreshToken': 'true',
        },
      );

      if (response.statusCode != 200) {
        await clearSession();
        return false;
      }

      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> data = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'token': decoded?.toString()};
      final accessToken = _readToken(data, const ['accessToken', 'token']);
      final rotatedRefreshToken =
          _readToken(data, const ['refreshToken']) ?? refreshToken;

      if (accessToken == null || accessToken.isEmpty) {
        await clearSession();
        return false;
      }

      await _saveTokens(accessToken, rotatedRefreshToken);
      return true;
    } catch (_) {
      await clearSession();
      return false;
    }
  }

  Future<void> logout() => clearSession();

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyTokenKey);
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_accessTokenKey);
    if (accessToken != null && accessToken.isNotEmpty) return accessToken;

    // One-time migration from the old single-token storage key.
    final legacyToken = prefs.getString(_legacyTokenKey);
    if (legacyToken != null && legacyToken.isNotEmpty) {
      await _saveTokens(legacyToken, legacyToken);
      await prefs.remove(_legacyTokenKey);
      return legacyToken;
    }
    return null;
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshTokenKey);
    if (refreshToken != null && refreshToken.isNotEmpty) return refreshToken;
    return getAccessToken();
  }

  // Backwards-compatible alias used by existing services.
  Future<String?> getToken() => getAccessToken();

  Future<void> _saveTokens(String accessToken, String? refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    } else {
      await prefs.remove(_refreshTokenKey);
    }
    await prefs.remove(_legacyTokenKey);
  }

  String? _readToken(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') return value;
    }
    return null;
  }
}
