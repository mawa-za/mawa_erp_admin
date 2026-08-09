class BillingDashboardSummary {
  final int activeModules;
  final int activePlans;
  final int activeSubscriptions;
  final int trialSubscriptions;
  final int openInvoices;
  final double openInvoiceAmount;
  final int storageBytes;
  final int usageEvents;

  const BillingDashboardSummary({
    required this.activeModules,
    required this.activePlans,
    required this.activeSubscriptions,
    required this.trialSubscriptions,
    required this.openInvoices,
    required this.openInvoiceAmount,
    required this.storageBytes,
    required this.usageEvents,
  });

  factory BillingDashboardSummary.fromJson(Map<String, dynamic> json) => BillingDashboardSummary(
        activeModules: _asInt(json['activeModules']),
        activePlans: _asInt(json['activePlans']),
        activeSubscriptions: _asInt(json['activeSubscriptions']),
        trialSubscriptions: _asInt(json['trialSubscriptions']),
        openInvoices: _asInt(json['openInvoices']),
        openInvoiceAmount: _asDouble(json['openInvoiceAmount']),
        storageBytes: _asInt(json['storageBytes']),
        usageEvents: _asInt(json['usageEvents']),
      );
}

class BillingModule {
  final String code;
  final String name;
  final String? description;
  final bool active;

  const BillingModule({required this.code, required this.name, this.description, required this.active});

  factory BillingModule.fromJson(Map<String, dynamic> json) => BillingModule(
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        active: _asBool(json['active'], fallback: true),
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'description': description,
        'active': active,
      };
}

class BillingPlanModule {
  final int? id;
  final String moduleCode;
  final String? moduleName;
  final double monthlyAmount;
  final double annualAmount;
  final String? meterCode;
  final double includedQuantity;
  final double unitAmount;
  final bool active;

  const BillingPlanModule({
    this.id,
    required this.moduleCode,
    this.moduleName,
    required this.monthlyAmount,
    required this.annualAmount,
    this.meterCode,
    required this.includedQuantity,
    required this.unitAmount,
    required this.active,
  });

  factory BillingPlanModule.fromJson(Map<String, dynamic> json) => BillingPlanModule(
        id: _asNullableInt(json['id']),
        moduleCode: json['moduleCode']?.toString() ?? '',
        moduleName: json['moduleName']?.toString(),
        monthlyAmount: _asDouble(json['monthlyAmount']),
        annualAmount: _asDouble(json['annualAmount']),
        meterCode: json['meterCode']?.toString(),
        includedQuantity: _asDouble(json['includedQuantity']),
        unitAmount: _asDouble(json['unitAmount']),
        active: _asBool(json['active'], fallback: true),
      );

  Map<String, dynamic> toJson() => {
        'moduleCode': moduleCode,
        'monthlyAmount': monthlyAmount,
        'annualAmount': annualAmount,
        'meterCode': meterCode?.trim().isEmpty == true ? null : meterCode,
        'includedQuantity': includedQuantity,
        'unitAmount': unitAmount,
        'active': active,
      };
}

class BillingPlan {
  final int? id;
  final String code;
  final String name;
  final String? description;
  final String currency;
  final double baseMonthlyAmount;
  final double annualBaseAmount;
  final String status;
  final String taxCode;
  final int? maxUsers;
  final int? maxBranches;
  final int? maxDevices;
  final int displayOrder;
  final List<BillingPlanModule> modules;

  const BillingPlan({
    this.id,
    required this.code,
    required this.name,
    this.description,
    required this.currency,
    required this.baseMonthlyAmount,
    required this.annualBaseAmount,
    required this.status,
    required this.taxCode,
    this.maxUsers,
    this.maxBranches,
    this.maxDevices,
    this.displayOrder = 0,
    required this.modules,
  });

  factory BillingPlan.fromJson(Map<String, dynamic> json) => BillingPlan(
        id: _asNullableInt(json['id']),
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        currency: json['currency']?.toString() ?? 'ZAR',
        baseMonthlyAmount: _asDouble(json['baseMonthlyAmount']),
        annualBaseAmount: _asDouble(json['annualBaseAmount']),
        status: json['status']?.toString() ?? 'ACTIVE',
        taxCode: json['taxCode']?.toString() ?? 'ZA_VAT',
        maxUsers: _asNullableInt(json['maxUsers']),
        maxBranches: _asNullableInt(json['maxBranches']),
        maxDevices: _asNullableInt(json['maxDevices']),
        displayOrder: _asInt(json['displayOrder']),
        modules: (json['modules'] as List<dynamic>? ?? const [])
            .map((item) => BillingPlanModule.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'description': description,
        'currency': currency,
        'baseMonthlyAmount': baseMonthlyAmount,
        'annualBaseAmount': annualBaseAmount,
        'status': status,
        'taxCode': taxCode,
        'maxUsers': maxUsers,
        'maxBranches': maxBranches,
        'maxDevices': maxDevices,
        'displayOrder': displayOrder,
        'modules': modules.map((item) => item.toJson()).toList(),
      };
}

class BillingSubscription {
  final int? id;
  final String tenantId;
  final int? planId;
  final String planCode;
  final String? planName;
  final String status;
  final String? startDate;
  final String? trialEndDate;
  final String? currentPeriodStart;
  final String? currentPeriodEnd;
  final String billingCycle;
  final String currency;
  final double? amountOverride;
  final String? nextBillingDate;
  final String? endDate;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  const BillingSubscription({
    this.id,
    required this.tenantId,
    this.planId,
    required this.planCode,
    this.planName,
    required this.status,
    this.startDate,
    this.trialEndDate,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    required this.billingCycle,
    required this.currency,
    this.amountOverride,
    this.nextBillingDate,
    this.endDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory BillingSubscription.fromJson(Map<String, dynamic> json) => BillingSubscription(
        id: _asNullableInt(json['id']),
        tenantId: json['tenantId']?.toString() ?? '',
        planId: _asNullableInt(json['planId']),
        planCode: json['planCode']?.toString() ?? '',
        planName: json['planName']?.toString(),
        status: json['status']?.toString() ?? 'ACTIVE',
        startDate: json['startDate']?.toString(),
        trialEndDate: json['trialEndDate']?.toString(),
        currentPeriodStart: json['currentPeriodStart']?.toString(),
        currentPeriodEnd: json['currentPeriodEnd']?.toString(),
        billingCycle: json['billingCycle']?.toString() ?? 'MONTHLY',
        currency: json['currency']?.toString() ?? 'ZAR',
        amountOverride: _asNullableDouble(json['amountOverride']),
        nextBillingDate: json['nextBillingDate']?.toString(),
        endDate: json['endDate']?.toString(),
        notes: json['notes']?.toString(),
        createdAt: json['createdAt']?.toString(),
        updatedAt: json['updatedAt']?.toString(),
      );
}

class TenantEntitlement {
  final int? id;
  final String tenantId;
  final String moduleCode;
  final String? moduleName;
  final bool enabled;
  final String? effectiveFrom;
  final String? effectiveTo;

  const TenantEntitlement({
    this.id,
    required this.tenantId,
    required this.moduleCode,
    this.moduleName,
    required this.enabled,
    this.effectiveFrom,
    this.effectiveTo,
  });

  factory TenantEntitlement.fromJson(Map<String, dynamic> json) => TenantEntitlement(
        id: _asNullableInt(json['id']),
        tenantId: json['tenantId']?.toString() ?? '',
        moduleCode: json['moduleCode']?.toString() ?? '',
        moduleName: json['moduleName']?.toString(),
        enabled: _asBool(json['enabled']),
        effectiveFrom: json['effectiveFrom']?.toString(),
        effectiveTo: json['effectiveTo']?.toString(),
      );
}

class BillingUsageSummary {
  final String meterCode;
  final double quantity;

  const BillingUsageSummary({required this.meterCode, required this.quantity});

  factory BillingUsageSummary.fromJson(Map<String, dynamic> json) => BillingUsageSummary(
        meterCode: json['meterCode']?.toString() ?? '',
        quantity: _asDouble(json['quantity']),
      );
}

class BillingStorageSummary {
  final String tenantId;
  final int bytes;
  final double gigabytes;
  final int objectCount;

  const BillingStorageSummary({required this.tenantId, required this.bytes, required this.gigabytes, required this.objectCount});

  factory BillingStorageSummary.fromJson(Map<String, dynamic> json) => BillingStorageSummary(
        tenantId: json['tenantId']?.toString() ?? '',
        bytes: _asInt(json['bytes']),
        gigabytes: _asDouble(json['gigabytes']),
        objectCount: _asInt(json['objectCount']),
      );
}

class BillingInvoiceLine {
  final int? id;
  final String lineType;
  final String? referenceCode;
  final String description;
  final double quantity;
  final double unitAmount;
  final double netAmount;
  final double taxRate;
  final double taxAmount;
  final double totalAmount;

  const BillingInvoiceLine({
    this.id,
    required this.lineType,
    this.referenceCode,
    required this.description,
    required this.quantity,
    required this.unitAmount,
    required this.netAmount,
    required this.taxRate,
    required this.taxAmount,
    required this.totalAmount,
  });

  factory BillingInvoiceLine.fromJson(Map<String, dynamic> json) => BillingInvoiceLine(
        id: _asNullableInt(json['id']),
        lineType: json['lineType']?.toString() ?? '',
        referenceCode: json['referenceCode']?.toString(),
        description: json['description']?.toString() ?? '',
        quantity: _asDouble(json['quantity']),
        unitAmount: _asDouble(json['unitAmount']),
        netAmount: _asDouble(json['netAmount']),
        taxRate: _asDouble(json['taxRate']),
        taxAmount: _asDouble(json['taxAmount']),
        totalAmount: _asDouble(json['totalAmount']),
      );
}

class BillingInvoice {
  final int id;
  final String invoiceNumber;
  final String tenantId;
  final String periodStart;
  final String periodEnd;
  final String? dueDate;
  final String currency;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final String status;
  final String taxCode;
  final String? createdAt;
  final String? issuedAt;
  final String? paidAt;
  final String? createdBy;
  final List<BillingInvoiceLine> lines;

  const BillingInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.tenantId,
    required this.periodStart,
    required this.periodEnd,
    this.dueDate,
    required this.currency,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.status,
    required this.taxCode,
    this.createdAt,
    this.issuedAt,
    this.paidAt,
    this.createdBy,
    required this.lines,
  });

  factory BillingInvoice.fromJson(Map<String, dynamic> json) => BillingInvoice(
        id: _asInt(json['id']),
        invoiceNumber: json['invoiceNumber']?.toString() ?? '',
        tenantId: json['tenantId']?.toString() ?? '',
        periodStart: json['periodStart']?.toString() ?? '',
        periodEnd: json['periodEnd']?.toString() ?? '',
        dueDate: json['dueDate']?.toString(),
        currency: json['currency']?.toString() ?? 'ZAR',
        subtotal: _asDouble(json['subtotal']),
        taxAmount: _asDouble(json['taxAmount']),
        totalAmount: _asDouble(json['totalAmount']),
        status: json['status']?.toString() ?? '',
        taxCode: json['taxCode']?.toString() ?? '',
        createdAt: json['createdAt']?.toString(),
        issuedAt: json['issuedAt']?.toString(),
        paidAt: json['paidAt']?.toString(),
        createdBy: json['createdBy']?.toString(),
        lines: (json['lines'] as List<dynamic>? ?? const [])
            .map((item) => BillingInvoiceLine.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
}

class BillingAdjustment {
  final int id;
  final String tenantId;
  final String adjustmentType;
  final double amount;
  final String currency;
  final String reason;
  final String status;
  final String effectiveDate;
  final int? invoiceId;
  final String? createdAt;
  final String? createdBy;

  const BillingAdjustment({
    required this.id,
    required this.tenantId,
    required this.adjustmentType,
    required this.amount,
    required this.currency,
    required this.reason,
    required this.status,
    required this.effectiveDate,
    this.invoiceId,
    this.createdAt,
    this.createdBy,
  });

  factory BillingAdjustment.fromJson(Map<String, dynamic> json) => BillingAdjustment(
        id: _asInt(json['id']),
        tenantId: json['tenantId']?.toString() ?? '',
        adjustmentType: json['adjustmentType']?.toString() ?? '',
        amount: _asDouble(json['amount']),
        currency: json['currency']?.toString() ?? 'ZAR',
        reason: json['reason']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        effectiveDate: json['effectiveDate']?.toString() ?? '',
        invoiceId: _asNullableInt(json['invoiceId']),
        createdAt: json['createdAt']?.toString(),
        createdBy: json['createdBy']?.toString(),
      );
}

class BillingTaxRate {
  final String code;
  final String name;
  final double ratePercent;
  final bool active;
  final String effectiveFrom;
  final String? effectiveTo;

  const BillingTaxRate({
    required this.code,
    required this.name,
    required this.ratePercent,
    required this.active,
    required this.effectiveFrom,
    this.effectiveTo,
  });

  factory BillingTaxRate.fromJson(Map<String, dynamic> json) => BillingTaxRate(
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        ratePercent: _asDouble(json['ratePercent']),
        active: _asBool(json['active'], fallback: true),
        effectiveFrom: json['effectiveFrom']?.toString() ?? '',
        effectiveTo: json['effectiveTo']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'ratePercent': ratePercent,
        'active': active,
        'effectiveFrom': effectiveFrom,
        'effectiveTo': effectiveTo,
      };
}

class BillingAuditLog {
  final int id;
  final String? tenantId;
  final String entityType;
  final String? entityId;
  final String action;
  final String actor;
  final String? detailsJson;
  final String? createdAt;

  const BillingAuditLog({
    required this.id,
    this.tenantId,
    required this.entityType,
    this.entityId,
    required this.action,
    required this.actor,
    this.detailsJson,
    this.createdAt,
  });

  factory BillingAuditLog.fromJson(Map<String, dynamic> json) => BillingAuditLog(
        id: _asInt(json['id']),
        tenantId: json['tenantId']?.toString(),
        entityType: json['entityType']?.toString() ?? '',
        entityId: json['entityId']?.toString(),
        action: json['action']?.toString() ?? '',
        actor: json['actor']?.toString() ?? '',
        detailsJson: json['detailsJson']?.toString(),
        createdAt: json['createdAt']?.toString(),
      );
}

class TenantBillingSummary {
  final String tenantId;
  final BillingSubscription? subscription;
  final List<TenantEntitlement> entitlements;
  final BillingStorageSummary storage;
  final List<BillingUsageSummary> currentPeriodUsage;
  final double outstandingAmount;
  final int invoiceCount;
  final int openInvoiceCount;

  const TenantBillingSummary({
    required this.tenantId,
    this.subscription,
    required this.entitlements,
    required this.storage,
    required this.currentPeriodUsage,
    required this.outstandingAmount,
    required this.invoiceCount,
    required this.openInvoiceCount,
  });

  factory TenantBillingSummary.fromJson(Map<String, dynamic> json) {
    final subscription = json['subscription'];
    final storage = json['storage'];
    return TenantBillingSummary(
      tenantId: json['tenantId']?.toString() ?? '',
      subscription: subscription is Map
          ? BillingSubscription.fromJson(Map<String, dynamic>.from(subscription))
          : null,
      entitlements: (json['entitlements'] as List<dynamic>? ?? const [])
          .map((item) => TenantEntitlement.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      storage: BillingStorageSummary.fromJson(
        storage is Map ? Map<String, dynamic>.from(storage) : const {},
      ),
      currentPeriodUsage: (json['currentPeriodUsage'] as List<dynamic>? ?? const [])
          .map((item) => BillingUsageSummary.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      outstandingAmount: _asDouble(json['outstandingAmount']),
      invoiceCount: _asInt(json['invoiceCount']),
      openInvoiceCount: _asInt(json['openInvoiceCount']),
    );
  }
}

int _asInt(dynamic value) => value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
int? _asNullableInt(dynamic value) => value == null ? null : int.tryParse(value.toString());
double _asDouble(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
double? _asNullableDouble(dynamic value) => value == null ? null : _asDouble(value);
bool _asBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  return value.toString().toLowerCase() == 'true' || value.toString() == '1';
}
