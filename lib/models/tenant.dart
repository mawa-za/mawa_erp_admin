class Tenant {
  final String id;
  final String name;
  final String host;
  final String? url;
  final String? erpAppUrl;
  final String status;
  final String? subscriptionPlanCode;
  final String? subscriptionStatus;

  Tenant({
    required this.id,
    required this.name,
    required this.host,
    this.url,
    this.erpAppUrl,
    required this.status,
    this.subscriptionPlanCode,
    this.subscriptionStatus,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'],
      name: json['name'],
      host: json['host'],
      url: json['url'],
      erpAppUrl: json['erpAppUrl'] ?? json['url'],
      status: json['status'],
      subscriptionPlanCode: json['subscriptionPlanCode'],
      subscriptionStatus: json['subscriptionStatus'],
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
    };
  }
}
