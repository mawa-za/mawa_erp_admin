import 'dart:convert';
import '../config.dart';
import '../utils/app_error.dart';
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

class PlatformMicrosoft365Service {
  final AuthenticatedHttpClient _http = AuthenticatedHttpClient();
  Uri get _uri => Uri.parse('${AppConfig.apiBaseUrl}/platform-integrations/microsoft365');
  static const _headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};

  Future<Microsoft365PlatformConfig> get() async {
    final response = await _http.get(_uri, headers: _headers);
    if (response.statusCode != 200) throw AppException('Unable to load Microsoft 365 configuration: ${response.statusCode}');
    return Microsoft365PlatformConfig.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Microsoft365PlatformConfig> save({required String clientId, required String redirectUri, String? clientSecret}) async {
    final response = await _http.put(_uri, headers: _headers, body: jsonEncode({
      'clientId': clientId.trim(),
      'redirectUri': redirectUri.trim(),
      'clientSecret': (clientSecret?.isNotEmpty == true) ? clientSecret : null,
    }));
    if (response.statusCode != 200) {
      String message = 'Unable to save Microsoft 365 configuration: ${response.statusCode}';
      try { message = (jsonDecode(response.body) as Map<String, dynamic>)['message']?.toString() ?? message; }
      catch (_) { /* Use fallback error. */ }
      throw AppException(message);
    }
    return Microsoft365PlatformConfig.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
