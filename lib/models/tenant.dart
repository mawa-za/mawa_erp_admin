class Tenant {
  final String id;
  final String name;
  final String host;
  final String? url;
  final String status;

  Tenant({
    required this.id,
    required this.name,
    required this.host,
    this.url,
    required this.status,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'],
      name: json['name'],
      host: json['host'],
      url: json['url'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'url': url,
      'status': status,
    };
  }
}

class CreateTenantRequest {
  final String? id;
  final String name;
  final String host;
  final String? url;
  final String status;
  final String? databaseUrl;
  final String? databaseUsername;
  final String? databasePassword;

  CreateTenantRequest({
    this.id,
    required this.name,
    required this.host,
    this.url,
    required this.status,
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
      'status': status,
      'database_url': databaseUrl,
      'database_username': databaseUsername,
      'database_password': databasePassword,
    };
  }
}
