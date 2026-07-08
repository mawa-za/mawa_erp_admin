import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/tenant.dart';
import '../models/tenant_property.dart';
import 'auth_service.dart';

class TenantService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Tenant>> getTenants() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Tenant.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load tenants');
    }
  }

  Future<Tenant> createTenant(CreateTenantRequest request) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant'),
      headers: await _getHeaders(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      if (response.body.isEmpty) {
        return Tenant(
          id: request.id ?? request.host,
          name: request.name,
          host: request.host,
          url: request.url,
          status: request.status,
        );
      }
      return Tenant.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body.isNotEmpty ? response.body : 'Failed to create tenant');
    }
  }

  Future<Map<String, String>> getTenantProperties(String tenantId) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/property'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      return data.map((key, value) => MapEntry(key, value.toString()));
    } else {
      throw Exception('Failed to load tenant properties');
    }
  }

  Future<List<TenantProperty>> getTenantPropertyDetails(String tenantId) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/property-details'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TenantProperty.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load tenant properties');
    }
  }

  Future<void> addTenantProperty(TenantPropertyRequest request) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/${request.tenant}/property'),
      headers: await _getHeaders(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(response.body.isNotEmpty ? response.body : 'Failed to add tenant property');
    }
  }
}
