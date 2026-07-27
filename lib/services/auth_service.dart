import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mawa_erp_admin/utils/app_error.dart';

import '../config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _legacyTokenKey = 'auth_token';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  Completer<bool>? _refreshCompleter;
  Timer? _keepAliveTimer;
  String? lastLoginError;

  Future<bool> login(String username, String password) async {
    lastLoginError = null;
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/v2/authenticate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode != 200) {
        lastLoginError = friendlyErrorMessage(
          response.body,
          statusCode: response.statusCode,
          fallback: response.statusCode == 401 || response.statusCode == 403
              ? 'The username or password is incorrect.'
              : 'We could not sign you in. Please try again.',
        );
        return false;
      }

      final tokens = _readTokenResponse(response.body);
      if (tokens.accessToken.isEmpty) {
        lastLoginError = 'The sign-in response was incomplete. Please try again.';
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, tokens.accessToken);
      await prefs.setString(_legacyTokenKey, tokens.accessToken);
      if (tokens.refreshToken.isNotEmpty) {
        await prefs.setString(_refreshTokenKey, tokens.refreshToken);
      }
      startKeepAlive();
      return true;
    } catch (error) {
      debugPrint('Admin login failed: $error');
      lastLoginError = friendlyErrorMessage(
        error,
        fallback: 'We could not sign you in. Please try again.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    stopKeepAlive();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyTokenKey);
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  Future<bool> isLoggedIn() async {
    final access = await getAccessToken();
    if (access == null || access.isEmpty) return false;
    if (_tokenExpired(access)) {
      return ensureFreshAccessToken(force: true);
    }
    await ensureFreshAccessToken();
    startKeepAlive();
    return true;
  }

  Future<String?> getToken() => getAccessToken();

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getString(_accessTokenKey);
    if (current != null && current.isNotEmpty) return current;

    final legacy = prefs.getString(_legacyTokenKey);
    if (legacy != null && legacy.isNotEmpty) {
      await prefs.setString(_accessTokenKey, legacy);
      return legacy;
    }
    return null;
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  DateTime? _tokenExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map || payload['exp'] is! num) return null;
      return DateTime.fromMillisecondsSinceEpoch(
        (payload['exp'] as num).toInt() * 1000,
        isUtc: true,
      );
    } catch (_) {
      return null;
    }
  }

  bool _tokenExpired(String token) {
    final expiry = _tokenExpiry(token);
    return expiry != null && !expiry.isAfter(DateTime.now().toUtc());
  }

  bool _tokenExpiresSoon(
    String token, {
    Duration margin = const Duration(minutes: 3),
  }) {
    final expiry = _tokenExpiry(token);
    return expiry != null &&
        !expiry.isAfter(DateTime.now().toUtc().add(margin));
  }

  void startKeepAlive() {
    if (_keepAliveTimer != null) return;
    unawaited(ensureFreshAccessToken());
    _keepAliveTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(ensureFreshAccessToken()),
    );
  }

  void stopKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
  }

  Future<bool> ensureFreshAccessToken({bool force = false}) async {
    final access = (await getAccessToken() ?? '').trim();
    if (access.isEmpty) return false;
    if (!force && !_tokenExpiresSoon(access)) return true;
    return refreshAccessToken();
  }

  Future<bool> refreshAccessToken() async {
    final existing = _refreshCompleter;
    if (existing != null) return existing.future;

    final completer = Completer<bool>();
    _refreshCompleter = completer;
    try {
      final result = await _performRefresh();
      completer.complete(result);
      return result;
    } catch (error) {
      debugPrint('Admin token refresh failed: $error');
      completer.complete(false);
      return false;
    } finally {
      if (identical(_refreshCompleter, completer)) {
        _refreshCompleter = null;
      }
    }
  }

  Future<bool> _performRefresh() async {
    final refreshToken = (await getRefreshToken() ?? '').trim();
    if (refreshToken.isEmpty) {
      final access = (await getAccessToken() ?? '').trim();
      if (access.isNotEmpty && _tokenExpired(access)) {
        await logout();
      }
      return false;
    }

    try {
      var response = await _postRefresh('/v2/refresh-token', refreshToken);
      if (response.statusCode == 404) {
        response = await _postRefresh('/refresh-token', refreshToken);
      }

      if (response.statusCode == 200) {
        final tokens = _readTokenResponse(response.body);
        if (tokens.accessToken.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_accessTokenKey, tokens.accessToken);
          await prefs.setString(_legacyTokenKey, tokens.accessToken);
          await prefs.setString(
            _refreshTokenKey,
            tokens.refreshToken.isNotEmpty
                ? tokens.refreshToken
                : refreshToken,
          );
          return true;
        }
      }

      if (response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 403) {
        await logout();
      }
      return false;
    } on TimeoutException catch (error) {
      debugPrint('Admin token refresh timed out: $error');
      return false;
    } catch (error) {
      // Keep the existing credentials on temporary network/server failures.
      debugPrint('Temporary admin token refresh failure: $error');
      return false;
    }
  }

  Future<http.Response> _postRefresh(String path, String refreshToken) {
    return http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}$path'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $refreshToken',
          },
          body: jsonEncode({'refreshToken': refreshToken}),
        )
        .timeout(const Duration(seconds: 45));
  }

  _TokenPair _readTokenResponse(String body) {
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map) {
        return _TokenPair(
          accessToken: (decoded['accessToken'] ??
                  decoded['token'] ??
                  decoded['jwttoken'] ??
                  '')
              .toString()
              .trim(),
          refreshToken: (decoded['refreshToken'] ?? '').toString().trim(),
        );
      }
      if (decoded is String) {
        return _TokenPair(accessToken: decoded.trim(), refreshToken: '');
      }
    } catch (_) {
      final raw = body.trim();
      if (raw.isNotEmpty) {
        return _TokenPair(accessToken: raw, refreshToken: '');
      }
    }
    return const _TokenPair(accessToken: '', refreshToken: '');
  }
}

class _TokenPair {
  const _TokenPair({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}
