class AdminFeature {
  final String code;
  final String name;
  final String description;
  final String category;
  final bool active;
  const AdminFeature({required this.code, required this.name, required this.description, required this.category, required this.active});
  factory AdminFeature.fromJson(Map<String, dynamic> json) => AdminFeature(
    code: (json['code'] ?? '').toString(), name: (json['name'] ?? '').toString(),
    description: (json['description'] ?? '').toString(), category: (json['category'] ?? '').toString(),
    active: json['active'] != false,
  );
}

class AdminRole {
  final String id;
  final String description;
  final bool systemRole;
  final bool protectedRole;
  final bool accessAllFeatures;
  final List<String> featureCodes;
  const AdminRole({required this.id, required this.description, this.systemRole=false, this.protectedRole=false, this.accessAllFeatures=false, this.featureCodes=const []});
  factory AdminRole.fromJson(Map<String,dynamic> json) => AdminRole(
    id:(json['id']??'').toString(), description:(json['description']??'').toString(),
    systemRole:json['systemRole']==true, protectedRole:json['protectedRole']==true,
    accessAllFeatures:json['accessAllFeatures']==true,
    featureCodes:(json['featureCodes'] as List<dynamic>? ?? const []).map((e)=>e.toString()).toList(),
  );
  Map<String,dynamic> toJson()=>{'id':id,'description':description,'systemRole':systemRole,'protectedRole':protectedRole,'accessAllFeatures':accessAllFeatures,'featureCodes':featureCodes};
}

class AdminUser {
  final String id;
  final String username;
  final String email;
  final String cellphone;
  final String status;
  final String accountType;
  final bool testUser;
  final bool protectedUser;
  final bool systemManaged;
  final String platformScope;
  final String environmentScope;
  final bool externalTransactionsBlocked;
  final DateTime? expiresAt;
  final String protectedReason;
  final bool mfaRequired;
  final List<String> roles;
  final List<String> tenantIds;
  const AdminUser({required this.id,required this.username,required this.email,required this.cellphone,required this.status,required this.accountType,required this.testUser,required this.protectedUser,required this.systemManaged,required this.platformScope,required this.environmentScope,required this.externalTransactionsBlocked,this.expiresAt,required this.protectedReason,required this.mfaRequired,this.roles=const [],this.tenantIds=const []});
  factory AdminUser.fromJson(Map<String,dynamic> json)=>AdminUser(
    id:(json['id']??'').toString(),username:(json['username']??'').toString(),email:(json['email']??'').toString(),cellphone:(json['cellphone']??'').toString(),status:(json['status']??'ACTIVE').toString(),accountType:(json['accountType']??'STANDARD').toString(),testUser:json['testUser']==true,protectedUser:json['protectedUser']==true,systemManaged:json['systemManaged']==true,platformScope:(json['platformScope']??'STANDARD').toString(),environmentScope:(json['environmentScope']??'').toString(),externalTransactionsBlocked:json['externalTransactionsBlocked']==true,expiresAt:json['expiresAt']==null?null:DateTime.tryParse(json['expiresAt'].toString()),protectedReason:(json['protectedReason']??'').toString(),mfaRequired:json['mfaRequired']==true,roles:(json['roles'] as List<dynamic>? ?? const []).map((e)=>e.toString()).toList(),tenantIds:(json['tenantIds'] as List<dynamic>? ?? const []).map((e)=>e.toString()).toList());
}

class AdminAccessProfile {
  final AdminUser user;
  final List<String> roles;
  final List<String> featureCodes;
  final List<String> tenantIds;
  final String environment;
  final bool legacyMode;
  final bool allFeatures;
  const AdminAccessProfile({required this.user,required this.roles,required this.featureCodes,required this.tenantIds,required this.environment,required this.legacyMode,required this.allFeatures});
  factory AdminAccessProfile.fromJson(Map<String,dynamic> json)=>AdminAccessProfile(
    user:AdminUser.fromJson((json['user'] as Map<String,dynamic>? ?? const {})), roles:(json['roles'] as List<dynamic>? ?? const []).map((e)=>e.toString()).toList(),featureCodes:(json['featureCodes'] as List<dynamic>? ?? const []).map((e)=>e.toString()).toList(),tenantIds:(json['tenantIds'] as List<dynamic>? ?? const []).map((e)=>e.toString()).toList(),environment:(json['environment']??'').toString(),legacyMode:json['legacyMode']==true,allFeatures:json['allFeatures']==true);
}
