import 'dart:convert';
import '../config.dart';
import '../models/tenant.dart';
import '../models/tenant_property.dart';
import '../models/erp_handoff.dart';
import '../models/platform_management.dart';
import 'authenticated_http_client.dart';

class TenantService {
  final AuthenticatedHttpClient _client = AuthenticatedHttpClient();

  Future<Map<String, String>> _getHeaders() async => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<List<Tenant>> getTenants() async {
    final response = await _client.get(
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
    final response = await _client.post(
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
          erpAppUrl: request.erpAppUrl ?? request.url,
          status: request.status,
          subscriptionPlanCode: request.subscriptionPlanCode,
          subscriptionStatus: request.subscriptionStatus,
        );
      }
      return Tenant.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body.isNotEmpty ? response.body : 'Failed to create tenant');
    }
  }

  Future<Map<String, String>> getTenantProperties(String tenantId) async {
    final response = await _client.get(
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
    final response = await _client.get(
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
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/${request.tenant}/property'),
      headers: await _getHeaders(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(response.body.isNotEmpty ? response.body : 'Failed to add tenant property');
    }
  }

  Future<void> syncTenantErp(String tenantId) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/sync-erp'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body.isNotEmpty ? response.body : 'Failed to sync tenant ERP configuration');
    }
  }

  Future<void> syncTenantModules(String tenantId) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/modules/sync'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body.isNotEmpty ? response.body : 'Failed to sync tenant modules');
    }
  }

  Future<void> setTenantModule(String tenantId, String moduleCode, bool enabled) async {
    final action = enabled ? 'enable' : 'disable';
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/modules/$moduleCode/$action'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body.isNotEmpty ? response.body : 'Failed to update tenant module');
    }
  }

  Future<ErpHandoff> openTenantErp(String tenantId, {String redirectPath = '/home'}) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/open-erp'),
      headers: await _getHeaders(),
      body: jsonEncode({'redirectPath': redirectPath}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ErpHandoff.fromJson(data as Map<String, dynamic>);
    }
    throw Exception(response.body.isNotEmpty ? response.body : 'Failed to create ERP handoff');
  }

  Future<AdminDashboardSummary> getDashboardSummary() async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/admin-dashboard/summary'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return AdminDashboardSummary.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(response.body.isNotEmpty ? response.body : 'Failed to load dashboard summary');
  }

  Future<Tenant> updateTenant(String tenantId, Tenant tenant) async {
    final response = await _client.put(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId'),
      headers: await _getHeaders(),
      body: jsonEncode(tenant.toJson()),
    );

    if (response.statusCode == 200) {
      return Tenant.fromJson(jsonDecode(response.body));
    }
    throw Exception(response.body.isNotEmpty ? response.body : 'Failed to update tenant');
  }

  Future<Tenant> updateTenantStatus(String tenantId, String status, {String? reason}) async {
    final response = await _client.put(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/status'),
      headers: await _getHeaders(),
      body: jsonEncode({'status': status, 'reason': reason}),
    );

    if (response.statusCode == 200) {
      return Tenant.fromJson(jsonDecode(response.body));
    }
    throw Exception(response.body.isNotEmpty ? response.body : 'Failed to update tenant status');
  }

  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/subscription/plans'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => SubscriptionPlan.fromJson(json as Map<String, dynamic>)).toList();
    }
    throw Exception(response.body.isNotEmpty ? response.body : 'Failed to load subscription plans');
  }

  Future<SubscriptionPlan> saveSubscriptionPlan(SubscriptionPlan plan) async {
    final uri = plan.code.isEmpty
        ? Uri.parse('${AppConfig.apiBaseUrl}/subscription/plans')
        : Uri.parse('${AppConfig.apiBaseUrl}/subscription/plans/${plan.code}');
    final response = plan.code.isEmpty
        ? await _client.post(uri, headers: await _getHeaders(), body: jsonEncode(plan.toJson()))
        : await _client.put(uri, headers: await _getHeaders(), body: jsonEncode(plan.toJson()));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return SubscriptionPlan.fromJson(jsonDecode(response.body));
    }
    throw Exception(response.body.isNotEmpty ? response.body : 'Failed to save subscription plan');
  }

  Future<TenantSubscription?> getTenantSubscription(String tenantId) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/subscription'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body == 'null') return null;
      return TenantSubscription.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(response.body.isNotEmpty ? response.body : 'Failed to load tenant subscription');
  }

  Future<TenantSubscription> saveTenantSubscription(String tenantId, TenantSubscription subscription) async {
    final response = await _client.put(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/subscription'),
      headers: await _getHeaders(),
      body: jsonEncode(subscription.toJson()),
    );

    if (response.statusCode == 200) {
      return TenantSubscription.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(response.body.isNotEmpty ? response.body : 'Failed to save tenant subscription');
  }

  Future<List<TenantModule>> getTenantModules(String tenantId) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/modules'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => TenantModule.fromJson(json as Map<String, dynamic>)).toList();
    }
    throw Exception(response.body.isNotEmpty ? response.body : 'Failed to load tenant modules');
  }

  Future<List<TenantActivityLog>> getTenantActivity(String tenantId) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/activity'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => TenantActivityLog.fromJson(json as Map<String, dynamic>)).toList();
    }
    throw Exception(response.body.isNotEmpty ? response.body : 'Failed to load tenant activity');
  }

  Future<List<TenantSchedule>> getTenantSchedules(String tenantId) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/schedules'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => TenantSchedule.fromJson(json as Map<String, dynamic>)).toList();
    }
    throw Exception(response.body.isNotEmpty ? response.body : 'Failed to load tenant schedules');
  }

  Future<TenantSchedule> saveTenantSchedule(String tenantId, TenantSchedule schedule) async {
    final response = await _client.put(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/schedules/${schedule.jobCode}'),
      headers: await _getHeaders(),
      body: jsonEncode(schedule.toJson()),
    );

    if (response.statusCode == 200) {
      return TenantSchedule.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(response.body.isNotEmpty ? response.body : 'Failed to save tenant schedule');
  }

  Future<TenantSchedule> runTenantScheduleNow(String tenantId, String jobCode) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/schedules/$jobCode/run-now'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return TenantSchedule.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(response.body.isNotEmpty ? response.body : 'Failed to run tenant schedule');
  }

}
