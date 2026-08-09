class Tenant {
  final String id;
  final String name;
  final String host;
  final String? url;
  final String? erpAppUrl;
  final String status;
  final String? subscriptionPlanCode;
  final String? subscriptionStatus;
  final String? primaryIndustryCode;
  final List<String> additionalIndustryCodes;

  Tenant({
    required this.id,
    required this.name,
    required this.host,
    this.url,
    this.erpAppUrl,
    required this.status,
    this.subscriptionPlanCode,
    this.subscriptionStatus,
    this.primaryIndustryCode,
    this.additionalIndustryCodes = const [],
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      host: (json['host'] ?? '').toString(),
      url: json['url']?.toString(),
      erpAppUrl: (json['erpAppUrl'] ?? json['url'])?.toString(),
      status: (json['status'] ?? 'ACTIVE').toString(),
      subscriptionPlanCode: json['subscriptionPlanCode']?.toString(),
      subscriptionStatus: json['subscriptionStatus']?.toString(),
      primaryIndustryCode: json['primaryIndustryCode']?.toString(),
      additionalIndustryCodes: (json['additionalIndustryCodes'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'url': url,
      'erpAppUrl': erpAppUrl ?? url,
      'status': status,
      'subscriptionPlanCode': subscriptionPlanCode,
      'subscriptionStatus': subscriptionStatus,
      'primaryIndustryCode': primaryIndustryCode,
      'additionalIndustryCodes': additionalIndustryCodes,
    };
  }
}

class CreateTenantRequest {
  final String? id;
  final String name;
  final String host;
  final String? url;
  final String? erpAppUrl;
  final String status;
  final String? subscriptionPlanCode;
  final String? subscriptionStatus;
  final String? databaseUrl;
  final String? databaseUsername;
  final String? databasePassword;
  final String primaryIndustryCode;
  final List<String> additionalIndustryCodes;

  CreateTenantRequest({
    this.id,
    required this.name,
    required this.host,
    this.url,
    this.erpAppUrl,
    required this.status,
    this.subscriptionPlanCode,
    this.subscriptionStatus,
    this.databaseUrl,
    this.databaseUsername,
    this.databasePassword,
    this.primaryIndustryCode = 'GENERAL_CUSTOM',
    this.additionalIndustryCodes = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'url': url,
      'erpAppUrl': erpAppUrl ?? url,
      'status': status,
      'subscriptionPlanCode': subscriptionPlanCode,
      'subscriptionStatus': subscriptionStatus,
      'database_url': databaseUrl,
      'database_username': databaseUsername,
      'database_password': databasePassword,
      'primaryIndustryCode': primaryIndustryCode,
      'additionalIndustryCodes': additionalIndustryCodes,
    };
  }
}
