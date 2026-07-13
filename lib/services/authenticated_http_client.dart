import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class AuthenticatedHttpClient {
  AuthenticatedHttpClient({AuthService? authService, http.Client? client})
      : _authService = authService ?? AuthService(),
        _client = client ?? http.Client();

  final AuthService _authService;
  final http.Client _client;

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
      _send('GET', url, headers: headers);

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) =>
      _send('POST', url, headers: headers, body: body, encoding: encoding);

  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) =>
      _send('PUT', url, headers: headers, body: body, encoding: encoding);

  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) =>
      _send('DELETE', url, headers: headers, body: body, encoding: encoding);

  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) =>
      _send('PATCH', url, headers: headers, body: body, encoding: encoding);

  Future<http.Response> _send(
    String method,
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    await _authService.ensureFreshAccessToken();
    var response = await _execute(
      method,
      url,
      headers: await _headersWithCurrentToken(headers),
      body: body,
      encoding: encoding,
    );

    if (response.statusCode != 401) return response;

    final refreshed = await _authService.ensureFreshAccessToken(force: true);
    if (!refreshed) return response;

    return _execute(
      method,
      url,
      headers: await _headersWithCurrentToken(headers),
      body: body,
      encoding: encoding,
    );
  }

  Future<Map<String, String>> _headersWithCurrentToken(
    Map<String, String>? original,
  ) async {
    final headers = <String, String>{...?original};
    final accessToken = await _authService.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    } else {
      headers.remove('Authorization');
    }
    return headers;
  }

  Future<http.Response> _execute(
    String method,
    Uri url, {
    required Map<String, String> headers,
    Object? body,
    Encoding? encoding,
  }) {
    switch (method) {
      case 'GET':
        return _client.get(url, headers: headers);
      case 'POST':
        return _client.post(url, headers: headers, body: body, encoding: encoding);
      case 'PUT':
        return _client.put(url, headers: headers, body: body, encoding: encoding);
      case 'DELETE':
        return _client.delete(url, headers: headers, body: body, encoding: encoding);
      case 'PATCH':
        return _client.patch(url, headers: headers, body: body, encoding: encoding);
      default:
        throw UnsupportedError('Unsupported HTTP method: $method');
    }
  }

  void close() => _client.close();
}
