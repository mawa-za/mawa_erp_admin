class TenantProperty {
  final String tenant;
  final String property;
  final String? value;
  final String displayValue;
  final bool sensitive;
  final bool secretReference;

  TenantProperty({
    required this.tenant,
    required this.property,
    this.value,
    required this.displayValue,
    required this.sensitive,
    required this.secretReference,
  });

  factory TenantProperty.fromJson(Map<String, dynamic> json) {
    return TenantProperty(
      tenant: json['tenant']?.toString() ?? '',
      property: json['property']?.toString() ?? '',
      value: json['value']?.toString(),
      displayValue: json['displayValue']?.toString() ?? json['value']?.toString() ?? '',
      sensitive: json['sensitive'] == true,
      secretReference: json['secretReference'] == true,
    );
  }
}

class TenantPropertyRequest {
  final String tenant;
  final String property;
  final String value;
  final bool storeAsSecret;
  final String? secretName;

  TenantPropertyRequest({
    required this.tenant,
    required this.property,
    required this.value,
    this.storeAsSecret = false,
    this.secretName,
  });

  Map<String, dynamic> toJson() {
    return {
      'tenant': tenant,
      'property': property,
      'value': value,
      'storeAsSecret': storeAsSecret,
      if (secretName != null && secretName!.isNotEmpty) 'secretName': secretName,
    };
  }
}
