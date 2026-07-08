class ErpHandoff {
  final String tenant;
  final String? tenantHost;
  final String? tenantUrl;
  final String handoffToken;
  final String targetUrl;
  final int? expiresAt;

  ErpHandoff({
    required this.tenant,
    this.tenantHost,
    this.tenantUrl,
    required this.handoffToken,
    required this.targetUrl,
    this.expiresAt,
  });

  factory ErpHandoff.fromJson(Map<String, dynamic> json) {
    return ErpHandoff(
      tenant: (json['tenant'] ?? '').toString(),
      tenantHost: json['tenantHost']?.toString(),
      tenantUrl: json['tenantUrl']?.toString(),
      handoffToken: (json['handoffToken'] ?? '').toString(),
      targetUrl: (json['targetUrl'] ?? '').toString(),
      expiresAt: json['expiresAt'] is int ? json['expiresAt'] as int : int.tryParse(json['expiresAt']?.toString() ?? ''),
    );
  }
}
