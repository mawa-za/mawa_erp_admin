import 'dart:convert';

import '../config.dart';
import '../models/billing.dart';
import 'authenticated_http_client.dart';
import 'package:mawa_erp_admin/utils/app_error.dart';

class BillingService {
  final AuthenticatedHttpClient _http = AuthenticatedHttpClient();

  Map<String, String> get _jsonHeaders => const {'Content-Type': 'application/json', 'Accept': 'application/json'};

  Future<BillingDashboardSummary> dashboard() async {
    final response = await _http.get(Uri.parse('${AppConfig.apiBaseUrl}/billing/dashboard'));
    _ensureSuccess(response.statusCode, response.body);
    return BillingDashboardSummary.fromJson(_map(response.body));
  }

  Future<Map<String, dynamic>> migrateLegacyBilling() async {
    final response = await _http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/billing/migrate-legacy'),
      headers: _jsonHeaders,
    );
    _ensureSuccess(response.statusCode, response.body);
    return _map(response.body);
  }

  Future<List<BillingModule>> modules() async {
    final response = await _http.get(Uri.parse('${AppConfig.apiBaseUrl}/billing/modules'));
    _ensureSuccess(response.statusCode, response.body);
    return _list(response.body).map(BillingModule.fromJson).toList();
  }

  Future<BillingModule> saveModule(BillingModule module, {bool create = false}) async {
    final uri = create
        ? Uri.parse('${AppConfig.apiBaseUrl}/billing/modules')
        : Uri.parse('${AppConfig.apiBaseUrl}/billing/modules/${Uri.encodeComponent(module.code)}');
    final response = create
        ? await _http.post(uri, headers: _jsonHeaders, body: jsonEncode(module.toJson()))
        : await _http.put(uri, headers: _jsonHeaders, body: jsonEncode(module.toJson()));
    _ensureSuccess(response.statusCode, response.body);
    return BillingModule.fromJson(_map(response.body));
  }

  Future<List<BillingPlan>> plans() async {
    final response = await _http.get(Uri.parse('${AppConfig.apiBaseUrl}/billing/plans'));
    _ensureSuccess(response.statusCode, response.body);
    return _list(response.body).map(BillingPlan.fromJson).toList();
  }

  Future<BillingPlan> savePlan(BillingPlan plan, {bool create = false}) async {
    final uri = create
        ? Uri.parse('${AppConfig.apiBaseUrl}/billing/plans')
        : Uri.parse('${AppConfig.apiBaseUrl}/billing/plans/${Uri.encodeComponent(plan.code)}');
    final response = create
        ? await _http.post(uri, headers: _jsonHeaders, body: jsonEncode(plan.toJson()))
        : await _http.put(uri, headers: _jsonHeaders, body: jsonEncode(plan.toJson()));
    _ensureSuccess(response.statusCode, response.body);
    return BillingPlan.fromJson(_map(response.body));
  }

  Future<List<BillingSubscription>> subscriptions() async {
    final response = await _http.get(Uri.parse('${AppConfig.apiBaseUrl}/billing/subscriptions'));
    _ensureSuccess(response.statusCode, response.body);
    return _list(response.body).map(BillingSubscription.fromJson).toList();
  }

  Future<BillingSubscription?> subscription(String tenantId) async {
    final response = await _http.get(Uri.parse('${AppConfig.apiBaseUrl}/billing/tenants/$tenantId/subscription'));
    _ensureSuccess(response.statusCode, response.body);
    if (response.body.isEmpty || response.body == 'null') return null;
    return BillingSubscription.fromJson(_map(response.body));
  }

  Future<BillingSubscription> saveSubscription(String tenantId, Map<String, dynamic> request) async {
    final response = await _http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/billing/tenants/$tenantId/subscription'),
      headers: _jsonHeaders,
      body: jsonEncode(request),
    );
    _ensureSuccess(response.statusCode, response.body);
    return BillingSubscription.fromJson(_map(response.body));
  }

  Future<TenantBillingSummary> tenantSummary(String tenantId) async {
    final response = await _http.get(Uri.parse('${AppConfig.apiBaseUrl}/billing/tenants/$tenantId/summary'));
    _ensureSuccess(response.statusCode, response.body);
    return TenantBillingSummary.fromJson(_map(response.body));
  }

  Future<List<TenantEntitlement>> entitlements(String tenantId) async {
    final response = await _http.get(Uri.parse('${AppConfig.apiBaseUrl}/billing/tenants/$tenantId/entitlements'));
    _ensureSuccess(response.statusCode, response.body);
    return _list(response.body).map(TenantEntitlement.fromJson).toList();
  }

  Future<TenantEntitlement> setEntitlement(String tenantId, String moduleCode, bool enabled) async {
    final response = await _http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/billing/tenants/$tenantId/entitlements'),
      headers: _jsonHeaders,
      body: jsonEncode({'moduleCode': moduleCode, 'enabled': enabled}),
    );
    _ensureSuccess(response.statusCode, response.body);
    return TenantEntitlement.fromJson(_map(response.body));
  }

  Future<List<TenantEntitlement>> syncEntitlements(String tenantId) async {
    final response = await _http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/billing/tenants/$tenantId/entitlements/sync-plan'),
      headers: _jsonHeaders,
    );
    _ensureSuccess(response.statusCode, response.body);
    return _list(response.body).map(TenantEntitlement.fromJson).toList();
  }

  Future<List<BillingInvoice>> invoices({String? tenantId}) async {
    var uri = Uri.parse('${AppConfig.apiBaseUrl}/billing/invoices');
    if (tenantId != null && tenantId.isNotEmpty) uri = uri.replace(queryParameters: {'tenant': tenantId});
    final response = await _http.get(uri);
    _ensureSuccess(response.statusCode, response.body);
    return _list(response.body).map(BillingInvoice.fromJson).toList();
  }

  Future<BillingInvoice> generateInvoice(String tenantId, DateTime periodStart, DateTime periodEnd, DateTime dueDate) async {
    final response = await _http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/billing/tenants/$tenantId/invoices/generate'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'periodStart': _date(periodStart),
        'periodEnd': _date(periodEnd),
        'dueDate': _date(dueDate),
      }),
    );
    _ensureSuccess(response.statusCode, response.body);
    return BillingInvoice.fromJson(_map(response.body));
  }

  Future<BillingInvoice> updateInvoiceStatus(int invoiceId, String status) async {
    final response = await _http.patch(
      Uri.parse('${AppConfig.apiBaseUrl}/billing/invoices/$invoiceId/status'),
      headers: _jsonHeaders,
      body: jsonEncode({'status': status}),
    );
    _ensureSuccess(response.statusCode, response.body);
    return BillingInvoice.fromJson(_map(response.body));
  }

  Future<List<BillingAdjustment>> adjustments({String? tenantId}) async {
    var uri = Uri.parse('${AppConfig.apiBaseUrl}/billing/adjustments');
    if (tenantId != null && tenantId.isNotEmpty) uri = uri.replace(queryParameters: {'tenant': tenantId});
    final response = await _http.get(uri);
    _ensureSuccess(response.statusCode, response.body);
    return _list(response.body).map(BillingAdjustment.fromJson).toList();
  }

  Future<BillingAdjustment> createAdjustment({
    required String tenantId,
    required String type,
    required double amount,
    required String reason,
    required DateTime effectiveDate,
  }) async {
    final response = await _http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/billing/adjustments'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'tenantId': tenantId,
        'adjustmentType': type,
        'amount': amount,
        'currency': 'ZAR',
        'reason': reason,
        'status': 'APPROVED',
        'effectiveDate': _date(effectiveDate),
      }),
    );
    _ensureSuccess(response.statusCode, response.body);
    return BillingAdjustment.fromJson(_map(response.body));
  }

  Future<List<BillingTaxRate>> taxRates() async {
    final response = await _http.get(Uri.parse('${AppConfig.apiBaseUrl}/billing/tax-rates'));
    _ensureSuccess(response.statusCode, response.body);
    return _list(response.body).map(BillingTaxRate.fromJson).toList();
  }

  Future<BillingTaxRate> saveTaxRate(BillingTaxRate rate, {bool create = false}) async {
    final uri = create
        ? Uri.parse('${AppConfig.apiBaseUrl}/billing/tax-rates')
        : Uri.parse('${AppConfig.apiBaseUrl}/billing/tax-rates/${Uri.encodeComponent(rate.code)}');
    final response = create
        ? await _http.post(uri, headers: _jsonHeaders, body: jsonEncode(rate.toJson()))
        : await _http.put(uri, headers: _jsonHeaders, body: jsonEncode(rate.toJson()));
    _ensureSuccess(response.statusCode, response.body);
    return BillingTaxRate.fromJson(_map(response.body));
  }

  Future<List<BillingAuditLog>> audit({String? tenantId, int limit = 100}) async {
    var uri = Uri.parse('${AppConfig.apiBaseUrl}/billing/audit').replace(queryParameters: {
      'limit': limit.toString(),
      if (tenantId != null && tenantId.isNotEmpty) 'tenant': tenantId,
    });
    final response = await _http.get(uri);
    _ensureSuccess(response.statusCode, response.body);
    return _list(response.body).map(BillingAuditLog.fromJson).toList();
  }

  List<Map<String, dynamic>> _list(String body) => (jsonDecode(body) as List<dynamic>)
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList();

  Map<String, dynamic> _map(String body) => Map<String, dynamic>.from(jsonDecode(body) as Map);

  void _ensureSuccess(int statusCode, String body) {
    if (statusCode >= 200 && statusCode < 300) return;
    String message = body;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) message = decoded['message']?.toString() ?? body;
    } catch (_) {}
    throw AppException(message.isEmpty ? 'Billing request failed ($statusCode)' : message);
  }

  String _date(DateTime value) => '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
