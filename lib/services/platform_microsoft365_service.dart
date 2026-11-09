import 'dart:convert';
import '../config.dart';
import 'authenticated_http_client.dart';

class Microsoft365PlatformConfig {
  final String environment;
  final String clientId;
  final String redirectUri;
  final bool clientSecretConfigured;
  final bool configured;

  const Microsoft365PlatformConfig({required this.environment, required this.clientId,
    required this.redirectUri, required this.clientSecretConfigured, required this.configured});

  factory Microsoft365PlatformConfig.fromJson(Map<String, dynamic> json) => Microsoft365PlatformConfig(
    environment: '${json['environment'] ?? ''}',
    clientId: '${json['clientId'] ?? ''}',
    redirectUri: '${json['redirectUri'] ?? ''}',
    clientSecretConfigured: json['clientSecretConfigured'] == true,
    configured: json['configured'] == true,
  );
}

/// A safe diagnostic for the platform-only Microsoft configuration endpoint.
/// Never includes response bodies or secret values in the UI.
class Microsoft365PlatformHttpException implements Exception {
  const Microsoft365PlatformHttpException(this.statusCode, this.code);

  final int statusCode;
  final String? code;

  @override
  String toString() {
    final endpoint = 'Microsoft 365 platform configuration';
    final suffix = code == null ? '' : ' ($code)';
    switch (statusCode) {
      case 401:
        return 'Your MAWA Admin session has expired (HTTP 401). Sign in again.$suffix';
      case 403:
        return 'Access to $endpoint was denied (HTTP 403). Check the PLATFORM_OWNER role.$suffix';
      case 404:
        return '$endpoint endpoint not found (HTTP 404). Verify that mawa-admin-bes HOTFIX includes the Microsoft 365 controller.$suffix';
      case 502:
      case 503:
      case 504:
        return '$endpoint backend is unavailable (HTTP $statusCode). Check Cloud Run and Secret Manager permissions.$suffix';
      default:
        return 'Could not access $endpoint (HTTP $statusCode). Review mawa-admin-bes HOTFIX logs.$suffix';
    }
  }

  static Microsoft365PlatformHttpException fromResponse(int statusCode, String body) {
    String? code;
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) {
        final value = parsed['code']?.toString();
        if (value != null && RegExp(r'^[A-Z][A-Z0-9_]{1,79}$').hasMatch(value)) {
          code = value;
        }
      }
    } catch (_) { /* HTTP error bodies need not be JSON. */ }
    return Microsoft365PlatformHttpException(statusCode, code);
  }
}

class PlatformMicrosoft365Service {
  final AuthenticatedHttpClient _http = AuthenticatedHttpClient();
  Uri get _uri => Uri.parse('${AppConfig.apiBaseUrl}/platform-integrations/microsoft365');
  static const _headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};

  Future<Microsoft365PlatformConfig> get() async {
    final response = await _http.get(_uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Microsoft365PlatformHttpException.fromResponse(response.statusCode, response.body);
    }
    return Microsoft365PlatformConfig.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Microsoft365PlatformConfig> save({required String clientId, required String redirectUri, String? clientSecret}) async {
    final response = await _http.put(_uri, headers: _headers, body: jsonEncode({
      'clientId': clientId.trim(),
      'redirectUri': redirectUri.trim(),
      'clientSecret': (clientSecret?.isNotEmpty == true) ? clientSecret : null,
    }));
    if (response.statusCode != 200) {
      throw Microsoft365PlatformHttpException.fromResponse(response.statusCode, response.body);
    }
    return Microsoft365PlatformConfig.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
