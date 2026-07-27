class IndustryWorkcenter {
  final String id;
  final String displayLabel;
  final String description;
  final int displayOrder;
  final bool active;

  const IndustryWorkcenter({
    required this.id,
    required this.displayLabel,
    required this.description,
    required this.displayOrder,
    required this.active,
  });

  factory IndustryWorkcenter.fromJson(Map<String, dynamic> json) => IndustryWorkcenter(
        id: (json['id'] ?? '').toString(),
        displayLabel: (json['displayLabel'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        displayOrder: _asInt(json['displayOrder']),
        active: json['active'] != false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayLabel': displayLabel,
        'description': description,
        'displayOrder': displayOrder,
        'active': active,
      };
}

class IndustryGroup {
  final String code;
  final String title;
  final String description;
  final String sectionCode;
  final String iconKey;
  final int displayOrder;
  final bool active;
  final List<IndustryWorkcenter> workcenters;

  const IndustryGroup({
    required this.code,
    required this.title,
    required this.description,
    required this.sectionCode,
    required this.iconKey,
    required this.displayOrder,
    required this.active,
    required this.workcenters,
  });

  factory IndustryGroup.fromJson(Map<String, dynamic> json) => IndustryGroup(
        code: (json['code'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        sectionCode: (json['sectionCode'] ?? 'YOUR_BUSINESS').toString(),
        iconKey: (json['iconKey'] ?? '').toString(),
        displayOrder: _asInt(json['displayOrder']),
        active: json['active'] != false,
        workcenters: (json['workcenters'] as List<dynamic>? ?? const [])
            .map((item) => IndustryWorkcenter.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'title': title,
        'description': description,
        'sectionCode': sectionCode,
        'iconKey': iconKey,
        'displayOrder': displayOrder,
        'active': active,
        'workcenters': workcenters.map((item) => item.toJson()).toList(),
      };
}

class IndustryProfile {
  final String code;
  final String name;
  final String description;
  final String status;
  final String iconKey;
  final int displayOrder;
  final List<IndustryGroup> groups;

  const IndustryProfile({
    required this.code,
    required this.name,
    required this.description,
    required this.status,
    required this.iconKey,
    required this.displayOrder,
    required this.groups,
  });

  factory IndustryProfile.fromJson(Map<String, dynamic> json) => IndustryProfile(
        code: (json['code'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        status: (json['status'] ?? 'ACTIVE').toString(),
        iconKey: (json['iconKey'] ?? '').toString(),
        displayOrder: _asInt(json['displayOrder']),
        groups: (json['groups'] as List<dynamic>? ?? const [])
            .map((item) => IndustryGroup.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'description': description,
        'status': status,
        'iconKey': iconKey,
        'displayOrder': displayOrder,
        'groups': groups.map((group) => group.toJson()).toList(),
      };
}

class TenantExperienceSection {
  final String code;
  final String title;
  final String description;
  final int displayOrder;
  final List<IndustryGroup> groups;

  const TenantExperienceSection({
    required this.code,
    required this.title,
    required this.description,
    required this.displayOrder,
    required this.groups,
  });

  factory TenantExperienceSection.fromJson(Map<String, dynamic> json) => TenantExperienceSection(
        code: (json['code'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        displayOrder: _asInt(json['displayOrder']),
        groups: (json['groups'] as List<dynamic>? ?? const [])
            .map((item) => IndustryGroup.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
}

class TenantExperience {
  final String tenantId;
  final String primaryIndustryCode;
  final String primaryIndustryName;
  final List<IndustryProfile> additionalIndustries;
  final List<TenantExperienceSection> sections;

  const TenantExperience({
    required this.tenantId,
    required this.primaryIndustryCode,
    required this.primaryIndustryName,
    required this.additionalIndustries,
    required this.sections,
  });

  factory TenantExperience.fromJson(Map<String, dynamic> json) => TenantExperience(
        tenantId: (json['tenantId'] ?? '').toString(),
        primaryIndustryCode: (json['primaryIndustryCode'] ?? 'GENERAL_CUSTOM').toString(),
        primaryIndustryName: (json['primaryIndustryName'] ?? 'General / Custom').toString(),
        additionalIndustries: (json['additionalIndustries'] as List<dynamic>? ?? const [])
            .map((item) => IndustryProfile.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        sections: (json['sections'] as List<dynamic>? ?? const [])
            .map((item) => TenantExperienceSection.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
}

class TenantIndustryProfile {
  final String tenantId;
  final IndustryProfile primaryIndustry;
  final List<IndustryProfile> additionalIndustries;
  final TenantExperience experience;

  const TenantIndustryProfile({
    required this.tenantId,
    required this.primaryIndustry,
    required this.additionalIndustries,
    required this.experience,
  });

  factory TenantIndustryProfile.fromJson(Map<String, dynamic> json) => TenantIndustryProfile(
        tenantId: (json['tenantId'] ?? '').toString(),
        primaryIndustry: IndustryProfile.fromJson(
          Map<String, dynamic>.from(json['primaryIndustry'] as Map? ?? const {}),
        ),
        additionalIndustries: (json['additionalIndustries'] as List<dynamic>? ?? const [])
            .map((item) => IndustryProfile.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        experience: TenantExperience.fromJson(
          Map<String, dynamic>.from(json['experience'] as Map? ?? const {}),
        ),
      );
}

int _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
