import 'dart:convert';
import '../config.dart';
import '../models/tenant.dart';
import '../models/tenant_property.dart';
import '../models/erp_handoff.dart';
import '../models/platform_management.dart';
import '../models/industry_profile.dart';
import 'authenticated_http_client.dart';
import 'package:mawa_erp_admin/utils/app_error.dart';

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
      throw AppException('Failed to load tenants');
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
          primaryIndustryCode: request.primaryIndustryCode,
          additionalIndustryCodes: request.additionalIndustryCodes,
        );
      }
      return Tenant.fromJson(jsonDecode(response.body));
    } else {
      throw AppException(response.body.isNotEmpty ? response.body : 'Failed to create tenant');
    }
  }

  Future<List<IndustryProfile>> getIndustryProfiles({bool activeOnly = false}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/industry-profile').replace(
      queryParameters: {'activeOnly': activeOnly.toString()},
    );
    final response = await _client.get(uri, headers: await _getHeaders());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((item) => IndustryProfile.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    throw AppException(response.body.isNotEmpty ? response.body : 'Failed to load industry profiles');
  }

  Future<IndustryProfile> getIndustryProfile(String code) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/industry-profile/$code'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return IndustryProfile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw AppException(response.body.isNotEmpty ? response.body : 'Failed to load industry profile');
  }

  Future<IndustryProfile> saveIndustryProfile(IndustryProfile profile, {bool create = false}) async {
    final uri = create
        ? Uri.parse('${AppConfig.apiBaseUrl}/industry-profile')
        : Uri.parse('${AppConfig.apiBaseUrl}/industry-profile/${profile.code}');
    final response = create
        ? await _client.post(uri, headers: await _getHeaders(), body: jsonEncode(profile.toJson()))
        : await _client.put(uri, headers: await _getHeaders(), body: jsonEncode(profile.toJson()));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return IndustryProfile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw AppException(response.body.isNotEmpty ? response.body : 'Failed to save industry profile');
  }

  Future<TenantIndustryProfile> getTenantIndustryProfile(String tenantId) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/industry-profile'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return TenantIndustryProfile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw AppException(response.body.isNotEmpty ? response.body : 'Failed to load tenant industry profile');
  }

  Future<TenantIndustryProfile> saveTenantIndustryProfile(
    String tenantId, {
    required String primaryIndustryCode,
    required List<String> additionalIndustryCodes,
  }) async {
    final response = await _client.put(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/industry-profile'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'primaryIndustryCode': primaryIndustryCode,
        'additionalIndustryCodes': additionalIndustryCodes,
      }),
    );
    if (response.statusCode == 200) {
      return TenantIndustryProfile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw AppException(response.body.isNotEmpty ? response.body : 'Failed to update tenant industry profile');
  }

  Future<TenantExperience> getTenantExperiencePreview(String tenantId) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/experience-preview'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return TenantExperience.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw AppException(response.body.isNotEmpty ? response.body : 'Failed to load tenant experience preview');
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
      throw AppException('Failed to load tenant properties');
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
      throw AppException('Failed to load tenant properties');
    }
  }

  Future<String> getGeneratedTenantSecretName(String tenantId, String property) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/secret-name').replace(
      queryParameters: {'property': property},
    );
    final response = await _client.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['secretName']?.toString() ?? '';
    }
    throw AppException(response.body.isNotEmpty ? response.body : 'Failed to generate tenant secret name');
  }

  Future<void> addTenantProperty(TenantPropertyRequest request) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/${request.tenant}/property'),
      headers: await _getHeaders(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AppException(response.body.isNotEmpty ? response.body : 'Failed to add tenant property');
    }
  }

  Future<void> syncTenantErp(String tenantId) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/sync-erp'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw AppException(response.body.isNotEmpty ? response.body : 'Failed to sync tenant ERP configuration');
    }
  }

  Future<void> syncTenantModules(String tenantId) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/billing/tenants/$tenantId/entitlements/sync-plan'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw AppException(response.body.isNotEmpty ? response.body : 'Failed to sync tenant billing modules');
    }
  }

  Future<void> setTenantModule(String tenantId, String moduleCode, bool enabled) async {
    final response = await _client.put(
      Uri.parse('${AppConfig.apiBaseUrl}/billing/tenants/$tenantId/entitlements'),
      headers: await _getHeaders(),
      body: jsonEncode({'moduleCode': moduleCode, 'enabled': enabled}),
    );

    if (response.statusCode != 200) {
      throw AppException(response.body.isNotEmpty ? response.body : 'Failed to update tenant billing module');
    }
  }

  Future<ErpHandoff> openTenantErp(
    String tenantId, {
    String redirectPath = '/home',
    required String accessReason,
    String? ticketReference,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/open-erp'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'redirectPath': redirectPath,
        'accessReason': accessReason,
        'ticketReference': ticketReference,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ErpHandoff.fromJson(data as Map<String, dynamic>);
    }
    throw AppException(response.body.isNotEmpty ? response.body : 'Failed to create ERP handoff');
  }

  Future<AdminDashboardSummary> getDashboardSummary() async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/admin-dashboard/summary'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return AdminDashboardSummary.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw AppException(response.body.isNotEmpty ? response.body : 'Failed to load dashboard summary');
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
    throw AppException(response.body.isNotEmpty ? response.body : 'Failed to update tenant');
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
    throw AppException(response.body.isNotEmpty ? response.body : 'Failed to update tenant status');
  }

  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/billing/plans'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((item) => _subscriptionPlanFromBilling(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    throw AppException(response.body.isNotEmpty ? response.body : 'Failed to load billing plans');
  }

  Future<SubscriptionPlan> saveSubscriptionPlan(SubscriptionPlan plan) async {
    final create = plan.code.isEmpty;
    final uri = create
        ? Uri.parse('${AppConfig.apiBaseUrl}/billing/plans')
        : Uri.parse('${AppConfig.apiBaseUrl}/billing/plans/${Uri.encodeComponent(plan.code)}');
    final response = create
        ? await _client.post(uri, headers: await _getHeaders(), body: jsonEncode(_subscriptionPlanToBilling(plan)))
        : await _client.put(uri, headers: await _getHeaders(), body: jsonEncode(_subscriptionPlanToBilling(plan)));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _subscriptionPlanFromBilling(Map<String, dynamic>.from(jsonDecode(response.body) as Map));
    }
    throw AppException(response.body.isNotEmpty ? response.body : 'Failed to save billing plan');
  }

  Future<TenantSubscription?> getTenantSubscription(String tenantId) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/billing/tenants/$tenantId/subscription'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body == 'null') return null;
      return _tenantSubscriptionFromBilling(Map<String, dynamic>.from(jsonDecode(response.body) as Map));
    }
    throw AppException(response.body.isNotEmpty ? response.body : 'Failed to load tenant billing subscription');
  }

  Future<TenantSubscription> saveTenantSubscription(String tenantId, TenantSubscription subscription) async {
    final response = await _client.put(
      Uri.parse('${AppConfig.apiBaseUrl}/billing/tenants/$tenantId/subscription'),
      headers: await _getHeaders(),
      body: jsonEncode(_tenantSubscriptionToBilling(subscription)),
    );

    if (response.statusCode == 200) {
      return _tenantSubscriptionFromBilling(Map<String, dynamic>.from(jsonDecode(response.body) as Map));
    }
    throw AppException(response.body.isNotEmpty ? response.body : 'Failed to save tenant billing subscription');
  }

  Future<List<TenantModule>> getTenantModules(String tenantId) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/billing/tenants/$tenantId/entitlements'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((item) {
        final json = Map<String, dynamic>.from(item as Map);
        return TenantModule(
          code: json['moduleCode']?.toString() ?? '',
          name: json['moduleName']?.toString() ?? json['moduleCode']?.toString() ?? '',
          enabled: json['enabled'] == true,
          description: null,
        );
      }).toList();
    }
    throw AppException(response.body.isNotEmpty ? response.body : 'Failed to load tenant billing modules');
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
    throw AppException(response.body.isNotEmpty ? response.body : 'Failed to load tenant activity');
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
    throw AppException(response.body.isNotEmpty ? response.body : 'Failed to load tenant schedules');
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
    throw AppException(response.body.isNotEmpty ? response.body : 'Failed to save tenant schedule');
  }

  Future<TenantSchedule> runTenantScheduleNow(
    String tenantId,
    String jobCode, {
    String? afterId,
    int limit = 25,
  }) async {
    final queryParameters = <String, String>{
      'limit': limit.clamp(1, 50).toString(),
    };
    if (afterId != null && afterId.trim().isNotEmpty) {
      queryParameters['afterId'] = afterId.trim();
    }

    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/tenant/$tenantId/schedules/$jobCode/run-now',
    ).replace(queryParameters: queryParameters);

    final response = await _client.post(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return TenantSchedule.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw AppException(
      response.body.isNotEmpty ? response.body : 'Failed to run tenant schedule',
    );
  }

  Future<Map<String, dynamic>> getTenantPosPrinting(String tenantId) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/pos-printing'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    }
    throw AppException(response.body.isNotEmpty ? response.body : 'Failed to load POS printing');
  }

  Future<Map<String, dynamic>> createPosPrintEnrollment(
    String tenantId, {
    required String agentName,
    String? location,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/pos-printing/enrollments'),
      headers: await _getHeaders(),
      body: jsonEncode({'agentName': agentName, 'location': location, 'validMinutes': 30}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    }
    throw AppException(response.body.isNotEmpty ? response.body : 'Failed to create print agent enrollment');
  }

  Future<void> revokePosPrintAgent(String tenantId, String agentId) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/pos-printing/agents/$agentId/revoke'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) throw AppException(response.body.isNotEmpty ? response.body : 'Failed to revoke print agent');
  }

  Future<void> setPosTerminalEnabled(String tenantId, String terminalId, bool enabled) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/pos-printing/terminals/$terminalId/enabled'),
      headers: await _getHeaders(),
      body: jsonEncode({'enabled': enabled}),
    );
    if (response.statusCode != 200) {
      throw AppException(response.body.isNotEmpty ? response.body : 'Failed to update POS terminal');
    }
  }

  Future<void> retryPosPrintJob(String tenantId, String jobId) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/tenant/$tenantId/pos-printing/jobs/$jobId/retry'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) throw AppException(response.body.isNotEmpty ? response.body : 'Failed to retry print job');
  }


  SubscriptionPlan _subscriptionPlanFromBilling(Map<String, dynamic> json) {
    int? cents(dynamic value) {
      if (value == null) return null;
      final amount = value is num ? value.toDouble() : double.tryParse(value.toString());
      return amount == null ? null : (amount * 100).round();
    }

    return SubscriptionPlan(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      currency: json['currency']?.toString() ?? 'ZAR',
      monthlyPriceCents: cents(json['baseMonthlyAmount']),
      annualPriceCents: cents(json['annualBaseAmount']),
      maxUsers: int.tryParse(json['maxUsers']?.toString() ?? ''),
      maxBranches: int.tryParse(json['maxBranches']?.toString() ?? ''),
      maxDevices: int.tryParse(json['maxDevices']?.toString() ?? ''),
      displayOrder: int.tryParse(json['displayOrder']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> _subscriptionPlanToBilling(SubscriptionPlan plan) => {
        'code': plan.code,
        'name': plan.name,
        'description': plan.description,
        'currency': plan.currency,
        'baseMonthlyAmount': (plan.monthlyPriceCents ?? 0) / 100,
        'annualBaseAmount': (plan.annualPriceCents ?? 0) / 100,
        'status': plan.status,
        'taxCode': 'ZA_VAT',
        'maxUsers': plan.maxUsers,
        'maxBranches': plan.maxBranches,
        'maxDevices': plan.maxDevices,
        'displayOrder': plan.displayOrder,
      };

  TenantSubscription _tenantSubscriptionFromBilling(Map<String, dynamic> json) {
    int? cents(dynamic value) {
      if (value == null) return null;
      final amount = value is num ? value.toDouble() : double.tryParse(value.toString());
      return amount == null ? null : (amount * 100).round();
    }

    return TenantSubscription(
      id: json['id']?.toString(),
      tenantId: json['tenantId']?.toString(),
      planCode: json['planCode']?.toString() ?? '',
      planName: json['planName']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      billingCycle: json['billingCycle']?.toString() ?? 'MONTHLY',
      currency: json['currency']?.toString() ?? 'ZAR',
      amountCents: cents(json['amountOverride']),
      startDate: json['startDate']?.toString(),
      trialEndsAt: json['trialEndDate']?.toString(),
      nextBillingDate: json['nextBillingDate']?.toString(),
      endDate: json['endDate']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> _tenantSubscriptionToBilling(TenantSubscription subscription) => {
        'planCode': subscription.planCode,
        'status': subscription.status,
        'billingCycle': subscription.billingCycle,
        'currency': subscription.currency,
        'amountOverride': subscription.amountCents == null ? null : subscription.amountCents! / 100,
        'startDate': subscription.startDate,
        'trialEndDate': subscription.trialEndsAt,
        'nextBillingDate': subscription.nextBillingDate,
        'endDate': subscription.endDate,
        'notes': subscription.notes,
      };

}
