class AdminDashboardSummary {
  final int totalTenants;
  final int activeTenants;
  final int inactiveTenants;
  final int suspendedTenants;
  final int activeSubscriptions;
  final int trialSubscriptions;
  final int subscriptionPlans;

  AdminDashboardSummary({
    required this.totalTenants,
    required this.activeTenants,
    required this.inactiveTenants,
    required this.suspendedTenants,
    required this.activeSubscriptions,
    required this.trialSubscriptions,
    required this.subscriptionPlans,
  });

  factory AdminDashboardSummary.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) => value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
    return AdminDashboardSummary(
      totalTenants: asInt(json['totalTenants']),
      activeTenants: asInt(json['activeTenants']),
      inactiveTenants: asInt(json['inactiveTenants']),
      suspendedTenants: asInt(json['suspendedTenants']),
      activeSubscriptions: asInt(json['activeSubscriptions']),
      trialSubscriptions: asInt(json['trialSubscriptions']),
      subscriptionPlans: asInt(json['subscriptionPlans']),
    );
  }
}

class SubscriptionPlan {
  final String code;
  final String name;
  final String? description;
  final String status;
  final String currency;
  final int? monthlyPriceCents;
  final int? annualPriceCents;
  final int? maxUsers;
  final int? maxBranches;
  final int? maxDevices;
  final int? displayOrder;
  final String? createdAt;
  final String? updatedAt;

  SubscriptionPlan({
    required this.code,
    required this.name,
    this.description,
    required this.status,
    required this.currency,
    this.monthlyPriceCents,
    this.annualPriceCents,
    this.maxUsers,
    this.maxBranches,
    this.maxDevices,
    this.displayOrder,
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    int? asNullableInt(dynamic value) => value == null ? null : int.tryParse(value.toString());
    return SubscriptionPlan(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'ACTIVE',
      currency: json['currency'] ?? 'ZAR',
      monthlyPriceCents: asNullableInt(json['monthlyPriceCents']),
      annualPriceCents: asNullableInt(json['annualPriceCents']),
      maxUsers: asNullableInt(json['maxUsers']),
      maxBranches: asNullableInt(json['maxBranches']),
      maxDevices: asNullableInt(json['maxDevices']),
      displayOrder: asNullableInt(json['displayOrder']),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'description': description,
        'status': status,
        'currency': currency,
        'monthlyPriceCents': monthlyPriceCents,
        'annualPriceCents': annualPriceCents,
        'maxUsers': maxUsers,
        'maxBranches': maxBranches,
        'maxDevices': maxDevices,
        'displayOrder': displayOrder,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}

class TenantSubscription {
  final String? id;
  final String? tenantId;
  final String planCode;
  final String? planName;
  final String status;
  final String billingCycle;
  final String currency;
  final int? amountCents;
  final String? startDate;
  final String? trialEndsAt;
  final String? nextBillingDate;
  final String? endDate;
  final String? notes;

  TenantSubscription({
    this.id,
    this.tenantId,
    required this.planCode,
    this.planName,
    required this.status,
    required this.billingCycle,
    required this.currency,
    this.amountCents,
    this.startDate,
    this.trialEndsAt,
    this.nextBillingDate,
    this.endDate,
    this.notes,
  });

  factory TenantSubscription.fromJson(Map<String, dynamic> json) {
    int? asNullableInt(dynamic value) => value == null ? null : int.tryParse(value.toString());
    return TenantSubscription(
      id: json['id'],
      tenantId: json['tenantId'],
      planCode: json['planCode'] ?? '',
      planName: json['planName'],
      status: json['status'] ?? 'ACTIVE',
      billingCycle: json['billingCycle'] ?? 'MONTHLY',
      currency: json['currency'] ?? 'ZAR',
      amountCents: asNullableInt(json['amountCents']),
      startDate: json['startDate'],
      trialEndsAt: json['trialEndsAt'],
      nextBillingDate: json['nextBillingDate'],
      endDate: json['endDate'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'planCode': planCode,
        'status': status,
        'billingCycle': billingCycle,
        'currency': currency,
        'amountCents': amountCents,
        'startDate': startDate,
        'trialEndsAt': trialEndsAt,
        'nextBillingDate': nextBillingDate,
        'endDate': endDate,
        'notes': notes,
      };
}

class TenantModule {
  final String code;
  final String name;
  final bool enabled;
  final String? description;

  TenantModule({
    required this.code,
    required this.name,
    required this.enabled,
    this.description,
  });

  factory TenantModule.fromJson(Map<String, dynamic> json) => TenantModule(
        code: json['code'] ?? '',
        name: json['name'] ?? json['code'] ?? '',
        enabled: json['enabled'] == true || json['enabled']?.toString() == 'true',
        description: json['description'],
      );
}

class TenantActivityLog {
  final String id;
  final String? tenantId;
  final String category;
  final String action;
  final String message;
  final String actor;
  final String? details;
  final String? createdAt;

  TenantActivityLog({
    required this.id,
    this.tenantId,
    required this.category,
    required this.action,
    required this.message,
    required this.actor,
    this.details,
    this.createdAt,
  });

  factory TenantActivityLog.fromJson(Map<String, dynamic> json) => TenantActivityLog(
        id: json['id'] ?? '',
        tenantId: json['tenantId'],
        category: json['category'] ?? '',
        action: json['action'] ?? '',
        message: json['message'] ?? '',
        actor: json['actor'] ?? '',
        details: json['details'],
        createdAt: json['createdAt'],
      );
}


class TenantSchedule {
  final String jobCode;
  final String name;
  final String description;
  final bool enabled;
  final int intervalMinutes;
  final String? lastRunAt;
  final String? nextRunAt;
  final bool manualOnly;
  final String? lastRunResult;
  final int migrationAttempted;
  final int migrationMigrated;
  final int migrationFailed;
  final int migrationRemaining;
  final bool migrationCompleted;
  final bool migrationScanComplete;
  final String? migrationNextCursor;
  final List<String> migrationFailures;

  TenantSchedule({
    required this.jobCode,
    required this.name,
    required this.description,
    required this.enabled,
    required this.intervalMinutes,
    this.lastRunAt,
    this.nextRunAt,
    this.manualOnly = false,
    this.lastRunResult,
    this.migrationAttempted = 0,
    this.migrationMigrated = 0,
    this.migrationFailed = 0,
    this.migrationRemaining = 0,
    this.migrationCompleted = false,
    this.migrationScanComplete = false,
    this.migrationNextCursor,
    this.migrationFailures = const [],
  });

  factory TenantSchedule.fromJson(Map<String, dynamic> json) => TenantSchedule(
        jobCode: json['jobCode'] ?? '',
        name: json['name'] ?? json['jobCode'] ?? '',
        description: json['description'] ?? '',
        enabled: json['enabled'] == true || json['enabled']?.toString() == 'true',
        intervalMinutes: int.tryParse('${json['intervalMinutes'] ?? 5}') ?? 5,
        lastRunAt: json['lastRunAt'],
        nextRunAt: json['nextRunAt'],
        manualOnly: json['manualOnly'] == true || json['manualOnly']?.toString() == 'true',
        lastRunResult: json['lastRunResult']?.toString(),
        migrationAttempted: int.tryParse('${json['migrationAttempted'] ?? 0}') ?? 0,
        migrationMigrated: int.tryParse('${json['migrationMigrated'] ?? 0}') ?? 0,
        migrationFailed: int.tryParse('${json['migrationFailed'] ?? 0}') ?? 0,
        migrationRemaining: int.tryParse('${json['migrationRemaining'] ?? 0}') ?? 0,
        migrationCompleted: json['migrationCompleted'] == true || json['migrationCompleted']?.toString() == 'true',
        migrationScanComplete: json['migrationScanComplete'] == true || json['migrationScanComplete']?.toString() == 'true',
        migrationNextCursor: json['migrationNextCursor']?.toString(),
        migrationFailures: (json['migrationFailures'] as List<dynamic>?)
                ?.map((item) => item.toString())
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'jobCode': jobCode,
        'name': name,
        'description': description,
        'enabled': enabled,
        'intervalMinutes': intervalMinutes,
        'lastRunAt': lastRunAt,
        'nextRunAt': nextRunAt,
        'manualOnly': manualOnly,
        'lastRunResult': lastRunResult,
        'migrationAttempted': migrationAttempted,
        'migrationMigrated': migrationMigrated,
        'migrationFailed': migrationFailed,
        'migrationRemaining': migrationRemaining,
        'migrationCompleted': migrationCompleted,
        'migrationScanComplete': migrationScanComplete,
        'migrationNextCursor': migrationNextCursor,
        'migrationFailures': migrationFailures,
      };

  TenantSchedule copyWith({bool? enabled, int? intervalMinutes}) => TenantSchedule(
        jobCode: jobCode,
        name: name,
        description: description,
        enabled: enabled ?? this.enabled,
        intervalMinutes: intervalMinutes ?? this.intervalMinutes,
        lastRunAt: lastRunAt,
        nextRunAt: nextRunAt,
        manualOnly: manualOnly,
        lastRunResult: lastRunResult,
        migrationAttempted: migrationAttempted,
        migrationMigrated: migrationMigrated,
        migrationFailed: migrationFailed,
        migrationRemaining: migrationRemaining,
        migrationCompleted: migrationCompleted,
        migrationScanComplete: migrationScanComplete,
        migrationNextCursor: migrationNextCursor,
        migrationFailures: migrationFailures,
      );
}
