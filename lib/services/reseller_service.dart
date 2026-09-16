import 'dart:convert';

import '../config.dart';
import '../models/reseller.dart';
import '../utils/app_error.dart';
import 'authenticated_http_client.dart';

class ResellerService {
  final AuthenticatedHttpClient _client = AuthenticatedHttpClient();
  Future<Map<String, String>> _headers() async => const {'Content-Type': 'application/json', 'Accept': 'application/json'};

  Future<List<ResellerProfile>> profiles() async {
    final response = await _client.get(Uri.parse('${AppConfig.apiBaseUrl}/v2/resellers'), headers: await _headers());
    if (response.statusCode != 200) throw AppException(_message(response.body, 'Failed to load resellers'));
    return (jsonDecode(response.body) as List).map((item) => ResellerProfile.fromJson(Map<String, dynamic>.from(item))).toList();
  }

  Future<ResellerProfile> saveProfile(ResellerProfile profile) async {
    final response = await _client.put(
      Uri.parse('${AppConfig.apiBaseUrl}/v2/resellers/${profile.tenantId}'),
      headers: await _headers(), body: jsonEncode(profile.toJson()),
    );
    if (response.statusCode != 200) throw AppException(_message(response.body, 'Failed to save reseller'));
    return ResellerProfile.fromJson(jsonDecode(response.body));
  }

  Future<List<ResellerTenantAssignment>> assignments(String resellerTenantId) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/v2/resellers/$resellerTenantId/tenants'), headers: await _headers(),
    );
    if (response.statusCode != 200) throw AppException(_message(response.body, 'Failed to load reseller clients'));
    return (jsonDecode(response.body) as List)
        .map((item) => ResellerTenantAssignment.fromJson(Map<String, dynamic>.from(item))).toList();
  }

  Future<ResellerTenantAssignment> assign(ResellerTenantAssignment assignment) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/v2/resellers/${assignment.resellerTenantId}/tenants'),
      headers: await _headers(), body: jsonEncode(assignment.toJson()),
    );
    if (response.statusCode != 200) throw AppException(_message(response.body, 'Failed to assign client tenant'));
    return ResellerTenantAssignment.fromJson(jsonDecode(response.body));
  }

  Future<List<ResellerEmployeeAccess>> employeeAccess(String resellerTenantId) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/v2/resellers/$resellerTenantId/employees'), headers: await _headers(),
    );
    if (response.statusCode != 200) throw AppException(_message(response.body, 'Failed to load employee access'));
    return (jsonDecode(response.body) as List)
        .map((item) => ResellerEmployeeAccess.fromJson(Map<String, dynamic>.from(item))).toList();
  }

  Future<ResellerEmployeeAccess> saveEmployeeAccess(ResellerEmployeeAccess access) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/v2/resellers/${access.resellerTenantId}/employees'),
      headers: await _headers(), body: jsonEncode(access.toJson()),
    );
    if (response.statusCode != 200) throw AppException(_message(response.body, 'Failed to save employee access'));
    return ResellerEmployeeAccess.fromJson(jsonDecode(response.body));
  }

  String _message(String body, String fallback) {
    if (body.isEmpty) return fallback;
    try { return (jsonDecode(body) as Map<String, dynamic>)['message']?.toString() ?? fallback; } catch (_) { return body; }
  }
}
