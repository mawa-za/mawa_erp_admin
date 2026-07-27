import 'dart:convert';
import '../config.dart';
import '../models/access_management.dart';
import 'authenticated_http_client.dart';
import 'package:mawa_erp_admin/utils/app_error.dart';

class AccessManagementService {
  final AuthenticatedHttpClient _client=AuthenticatedHttpClient();
  Map<String,String> get _headers=>const {'Content-Type':'application/json','Accept':'application/json'};
  Future<dynamic> _decode(Future<dynamic> request) async { final response=await request; if(response.statusCode>=200&&response.statusCode<300){return response.body.isEmpty?null:jsonDecode(response.body);} throw AppException(response.body.isNotEmpty?response.body:'Access management request failed'); }
  Future<AdminAccessProfile> getProfile() async=>AdminAccessProfile.fromJson((await _decode(_client.get(Uri.parse('${AppConfig.apiBaseUrl}/v2/access/profile'),headers:_headers))) as Map<String,dynamic>);
  Future<List<AdminUser>> getUsers() async{final d=await _decode(_client.get(Uri.parse('${AppConfig.apiBaseUrl}/v2/access/users'),headers:_headers)) as List<dynamic>; return d.map((e)=>AdminUser.fromJson(e as Map<String,dynamic>)).toList();}
  Future<List<AdminRole>> getRoles() async{final d=await _decode(_client.get(Uri.parse('${AppConfig.apiBaseUrl}/v2/access/roles'),headers:_headers)) as List<dynamic>; return d.map((e)=>AdminRole.fromJson(e as Map<String,dynamic>)).toList();}
  Future<List<AdminFeature>> getFeatures() async{final d=await _decode(_client.get(Uri.parse('${AppConfig.apiBaseUrl}/v2/access/features'),headers:_headers)) as List<dynamic>; return d.map((e)=>AdminFeature.fromJson(e as Map<String,dynamic>)).toList();}
  Future<void> createUser(Map<String,dynamic> body) async{await _decode(_client.post(Uri.parse('${AppConfig.apiBaseUrl}/v2/access/users'),headers:_headers,body:jsonEncode(body)));}
  Future<void> updateUser(String id,Map<String,dynamic> body) async{await _decode(_client.put(Uri.parse('${AppConfig.apiBaseUrl}/v2/access/users/$id'),headers:_headers,body:jsonEncode(body)));}
  Future<void> deleteUser(String id) async{await _decode(_client.delete(Uri.parse('${AppConfig.apiBaseUrl}/v2/access/users/$id'),headers:_headers));}
  Future<void> saveRole(AdminRole role,{bool create=false}) async{final uri=create?Uri.parse('${AppConfig.apiBaseUrl}/v2/access/roles'):Uri.parse('${AppConfig.apiBaseUrl}/v2/access/roles/${role.id}'); await _decode(create?_client.post(uri,headers:_headers,body:jsonEncode(role.toJson())):_client.put(uri,headers:_headers,body:jsonEncode(role.toJson())));}
  Future<void> deleteRole(String id) async{await _decode(_client.delete(Uri.parse('${AppConfig.apiBaseUrl}/v2/access/roles/$id'),headers:_headers));}
  Future<List<Map<String,dynamic>>> getAudit() async{final d=await _decode(_client.get(Uri.parse('${AppConfig.apiBaseUrl}/v2/access/audit'),headers:_headers)) as List<dynamic>; return d.map((e)=>Map<String,dynamic>.from(e as Map)).toList();}
}
