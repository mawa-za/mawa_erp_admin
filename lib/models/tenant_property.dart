class TenantPropertyRequest {
  final String tenant;
  final String property;
  final String value;

  TenantPropertyRequest({
    required this.tenant,
    required this.property,
    required this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'tenant': tenant,
      'property': property,
      'value': value,
    };
  }
}
