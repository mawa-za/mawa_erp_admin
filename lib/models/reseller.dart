class ResellerProfile {
  final String? id;
  final String tenantId;
  final String tenantName;
  final String status;
  final String? supportEmail;
  final String? supportPhone;
  final String? supportHours;
  final int slaResponseHours;
  final bool mayProvisionTenants;
  final bool mayInvoiceClients;
  final String? brandingName;
  final String? agreementStartDate;
  final String? agreementEndDate;
  final int assignedTenantCount;

  const ResellerProfile({
    this.id,
    required this.tenantId,
    this.tenantName = '',
    this.status = 'ACTIVE',
    this.supportEmail,
    this.supportPhone,
    this.supportHours,
    this.slaResponseHours = 8,
    this.mayProvisionTenants = false,
    this.mayInvoiceClients = true,
    this.brandingName,
    this.agreementStartDate,
    this.agreementEndDate,
    this.assignedTenantCount = 0,
  });

  factory ResellerProfile.fromJson(Map<String, dynamic> json) => ResellerProfile(
        id: json['id']?.toString(),
        tenantId: (json['tenantId'] ?? '').toString(),
        tenantName: (json['tenantName'] ?? '').toString(),
        status: (json['status'] ?? 'ACTIVE').toString(),
        supportEmail: json['supportEmail']?.toString(),
        supportPhone: json['supportPhone']?.toString(),
        supportHours: json['supportHours']?.toString(),
        slaResponseHours: (json['slaResponseHours'] as num?)?.toInt() ?? 8,
        mayProvisionTenants: json['mayProvisionTenants'] == true,
        mayInvoiceClients: json['mayInvoiceClients'] != false,
        brandingName: json['brandingName']?.toString(),
        agreementStartDate: json['agreementStartDate']?.toString(),
        agreementEndDate: json['agreementEndDate']?.toString(),
        assignedTenantCount: (json['assignedTenantCount'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'tenantId': tenantId,
        'status': status,
        'supportEmail': supportEmail,
        'supportPhone': supportPhone,
        'supportHours': supportHours,
        'slaResponseHours': slaResponseHours,
        'mayProvisionTenants': mayProvisionTenants,
        'mayInvoiceClients': mayInvoiceClients,
        'brandingName': brandingName,
        'agreementStartDate': agreementStartDate,
        'agreementEndDate': agreementEndDate,
      };
}

class ResellerTenantAssignment {
  final String? id;
  final String resellerTenantId;
  final String clientTenantId;
  final String clientTenantName;
  final String? clientTenantHost;
  final String relationshipType;
  final String supportLevel;
  final String billingResponsibility;
  final bool primaryReseller;
  final String status;
  final String? validFrom;
  final String? validTo;

  const ResellerTenantAssignment({
    this.id,
    required this.resellerTenantId,
    required this.clientTenantId,
    this.clientTenantName = '',
    this.clientTenantHost,
    this.relationshipType = 'PRIMARY_RESELLER',
    this.supportLevel = 'FIRST_LINE',
    this.billingResponsibility = 'MAWA_TO_TENANT',
    this.primaryReseller = true,
    this.status = 'ACTIVE',
    this.validFrom,
    this.validTo,
  });

  factory ResellerTenantAssignment.fromJson(Map<String, dynamic> json) => ResellerTenantAssignment(
        id: json['id']?.toString(),
        resellerTenantId: (json['resellerTenantId'] ?? '').toString(),
        clientTenantId: (json['clientTenantId'] ?? '').toString(),
        clientTenantName: (json['clientTenantName'] ?? '').toString(),
        clientTenantHost: json['clientTenantHost']?.toString(),
        relationshipType: (json['relationshipType'] ?? 'PRIMARY_RESELLER').toString(),
        supportLevel: (json['supportLevel'] ?? 'FIRST_LINE').toString(),
        billingResponsibility: (json['billingResponsibility'] ?? 'MAWA_TO_TENANT').toString(),
        primaryReseller: json['primaryReseller'] != false,
        status: (json['status'] ?? 'ACTIVE').toString(),
        validFrom: json['validFrom']?.toString(),
        validTo: json['validTo']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'clientTenantId': clientTenantId,
        'relationshipType': relationshipType,
        'supportLevel': supportLevel,
        'billingResponsibility': billingResponsibility,
        'primaryReseller': primaryReseller,
        'status': status,
        'validFrom': validFrom,
        'validTo': validTo,
      };
}

class ResellerEmployeeAccess {
  final String? id;
  final String resellerTenantId;
  final String clientTenantId;
  final String clientTenantName;
  final String employeeUsername;
  final String? employeeDisplayName;
  final String accessLevel;
  final bool mayRequestElevatedAccess;
  final String status;
  final String? validFrom;
  final String? validTo;

  const ResellerEmployeeAccess({
    this.id, required this.resellerTenantId, required this.clientTenantId,
    this.clientTenantName = '', required this.employeeUsername, this.employeeDisplayName,
    this.accessLevel = 'READ_ONLY', this.mayRequestElevatedAccess = false,
    this.status = 'ACTIVE', this.validFrom, this.validTo,
  });

  factory ResellerEmployeeAccess.fromJson(Map<String, dynamic> json) => ResellerEmployeeAccess(
    id: json['id']?.toString(), resellerTenantId: (json['resellerTenantId'] ?? '').toString(),
    clientTenantId: (json['clientTenantId'] ?? '').toString(),
    clientTenantName: (json['clientTenantName'] ?? '').toString(),
    employeeUsername: (json['employeeUsername'] ?? '').toString(),
    employeeDisplayName: json['employeeDisplayName']?.toString(),
    accessLevel: (json['accessLevel'] ?? 'READ_ONLY').toString(),
    mayRequestElevatedAccess: json['mayRequestElevatedAccess'] == true,
    status: (json['status'] ?? 'ACTIVE').toString(), validFrom: json['validFrom']?.toString(),
    validTo: json['validTo']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'clientTenantId': clientTenantId, 'employeeUsername': employeeUsername,
    'employeeDisplayName': employeeDisplayName, 'accessLevel': accessLevel,
    'mayRequestElevatedAccess': mayRequestElevatedAccess, 'status': status,
    'validFrom': validFrom, 'validTo': validTo,
  };
}
