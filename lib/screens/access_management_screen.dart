import 'package:flutter/material.dart';

import '../models/access_management.dart';
import '../models/tenant.dart';
import '../services/access_management_service.dart';
import '../services/tenant_service.dart';

class AccessManagementScreen extends StatefulWidget {
  const AccessManagementScreen({super.key});

  @override
  State<AccessManagementScreen> createState() =>
      _AccessManagementScreenState();
}

class _AccessManagementScreenState extends State<AccessManagementScreen>
    with SingleTickerProviderStateMixin {
  final AccessManagementService _service = AccessManagementService();
  final TenantService _tenantService = TenantService();

  late final TabController _tabs;
  bool _loading = true;
  String? _error;
  List<AdminUser> _users = [];
  List<AdminRole> _roles = [];
  List<AdminFeature> _features = [];
  List<Tenant> _tenants = [];
  List<Map<String, dynamic>> _audit = [];
  AdminAccessProfile? _profile;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await _service.getProfile();
      bool can(String feature) =>
          profile.allFeatures || profile.featureCodes.contains(feature);

      final users = can('USER_MANAGEMENT')
          ? await _service.getUsers()
          : <AdminUser>[];
      final roles = can('ROLE_MAINTENANCE') || can('USER_MANAGEMENT')
          ? await _service.getRoles()
          : <AdminRole>[];
      final features = can('ROLE_MAINTENANCE')
          ? await _service.getFeatures()
          : <AdminFeature>[];
      final tenants = can('USER_MANAGEMENT')
          ? await _tenantService.getTenants()
          : <Tenant>[];
      final audit = can('AUDIT_LOGS')
          ? await _service.getAudit()
          : <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _users = users;
        _roles = roles;
        _features = features;
        _tenants = tenants;
        _audit = audit;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  bool _can(String feature) =>
      _profile?.allFeatures == true ||
      (_profile?.featureCodes.contains(feature) ?? false);

  @override
  Widget build(BuildContext context) {
    final canAddUser = _tabs.index == 0 && _can('USER_MANAGEMENT');
    final canAddRole = _tabs.index == 1 && _can('ROLE_MAINTENANCE');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Management'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Users', icon: Icon(Icons.people_alt_rounded)),
            Tab(text: 'Roles', icon: Icon(Icons.admin_panel_settings_rounded)),
            Tab(text: 'Audit', icon: Icon(Icons.history_rounded)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: _loading || (!canAddUser && !canAddRole)
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                if (canAddUser) {
                  _editUser();
                } else {
                  _editRole();
                }
              },
              icon: const Icon(Icons.add),
              label: Text(canAddUser ? 'USER' : 'ROLE'),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : Column(
                  children: [
                    if (_profile != null) _profileBanner(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _userList(),
                          _roleList(),
                          _auditList(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!),
          const SizedBox(height: 12),
          FilledButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _profileBanner() {
    final profile = _profile!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: profile.legacyMode
          ? Colors.orange.shade50
          : Colors.blue.shade50,
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '${profile.user.username} • ${profile.roles.join(', ')}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Chip(label: Text(profile.environment.toUpperCase())),
          if (profile.legacyMode)
            const Chip(label: Text('LEGACY ACCESS MODE')),
          if (profile.allFeatures)
            const Chip(
              avatar: Icon(Icons.shield, size: 16),
              label: Text('ALL FEATURES'),
            ),
        ],
      ),
    );
  }

  Widget _userList() {
    if (!_can('USER_MANAGEMENT')) return _denied('User Management');

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(
                user.testUser
                    ? Icons.science_rounded
                    : user.protectedUser
                        ? Icons.shield_rounded
                        : Icons.person_rounded,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    user.username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (user.protectedUser)
                  _badge('PROTECTED', Colors.green),
                if (user.testUser) _badge('TEST', Colors.orange),
              ],
            ),
            subtitle: Text(
              '${user.email}\n'
              '${user.accountType} • ${user.platformScope} • '
              '${user.roles.join(', ')}',
            ),
            isThreeLine: true,
            onTap: () => _editUser(user),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _editUser(user);
                if (value == 'delete') _deleteUser(user);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  enabled: !user.protectedUser && !user.systemManaged,
                  child: const Text('Delete'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _roleList() {
    if (!_can('ROLE_MAINTENANCE')) return _denied('Role Maintenance');

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _roles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final role = _roles[index];
        return Card(
          child: ListTile(
            leading: Icon(
              role.accessAllFeatures
                  ? Icons.all_inclusive_rounded
                  : Icons.security_rounded,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    role.id,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (role.protectedRole)
                  _badge('PROTECTED', Colors.green),
                if (role.accessAllFeatures) _badge('ALL', Colors.purple),
              ],
            ),
            subtitle: Text(
              '${role.description}\n'
              '${role.accessAllFeatures ? 'Automatically includes future features' : '${role.featureCodes.length} assigned features'}',
            ),
            isThreeLine: true,
            onTap: () => _editRole(role),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: role.protectedRole || role.systemRole
                  ? null
                  : () => _deleteRole(role),
            ),
          ),
        );
      },
    );
  }

  Widget _auditList() {
    if (!_can('AUDIT_LOGS')) return _denied('Audit Logs');

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _audit.length,
      itemBuilder: (context, index) {
        final entry = _audit[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.history),
            title: Text((entry['action'] ?? '').toString()),
            subtitle: Text(
              '${entry['username'] ?? ''} • ${entry['targetType'] ?? ''} '
              '${entry['targetId'] ?? ''}\n${entry['reason'] ?? ''}',
            ),
            trailing: Text(
              (entry['createdAt'] ?? '')
                  .toString()
                  .replaceFirst('T', ' ')
                  .split('.')
                  .first,
            ),
          ),
        );
      },
    );
  }

  Widget _denied(String feature) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 48),
              const SizedBox(height: 12),
              Text(
                '$feature is not assigned to your current '
                'Admin Console roles.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Future<void> _editUser([AdminUser? existing]) async {
    final usernameController =
        TextEditingController(text: existing?.username ?? '');
    final passwordController = TextEditingController();
    final emailController = TextEditingController(text: existing?.email ?? '');
    final cellphoneController =
        TextEditingController(text: existing?.cellphone ?? '');
    final environmentController =
        TextEditingController(text: existing?.environmentScope ?? '');
    final reasonController =
        TextEditingController(text: existing?.protectedReason ?? '');
    final expiryController = TextEditingController(
      text: existing?.expiresAt?.toIso8601String().split('T').first ?? '',
    );

    String accountType = existing?.accountType ?? 'STANDARD';
    String platformScope = existing?.platformScope ?? 'STANDARD';
    String status = existing?.status ?? 'ACTIVE';
    bool testUser = existing?.testUser ?? false;
    bool externalTransactionsBlocked =
        existing?.externalTransactionsBlocked ?? false;
    bool mfaRequired = existing?.mfaRequired ?? false;
    final selectedRoles = <String>{...?existing?.roles};
    final selectedTenants = <String>{...?existing?.tenantIds};

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text(
            existing == null ? 'Create user' : 'Edit ${existing.username}',
          ),
          content: SizedBox(
            width: 720,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameController,
                    enabled: existing == null,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  const SizedBox(height: 8),
                  if (existing == null)
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Initial password (optional)',
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: cellphoneController,
                    decoration: const InputDecoration(labelText: 'Cellphone'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: accountType,
                          decoration: const InputDecoration(
                            labelText: 'Account type',
                          ),
                          items: const [
                            'STANDARD',
                            'QA_TESTER',
                            'AUTOMATION_TEST',
                            'DEMO_USER',
                            'SUPPORT_VERIFICATION',
                          ]
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setLocalState(() => accountType = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: platformScope,
                          decoration: const InputDecoration(
                            labelText: 'Platform scope (derived from role)',
                          ),
                          items: const ['STANDARD', 'PLATFORM_ALL']
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: status,
                          decoration:
                              const InputDecoration(labelText: 'Status'),
                          items: const ['ACTIVE', 'LOCKED']
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setLocalState(() => status = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    value: testUser,
                    onChanged: (value) => setLocalState(() {
                      testUser = value;
                      if (value) {
                        if (environmentController.text.isEmpty) {
                          environmentController.text = 'DEV,ALPHA,BETA';
                        }
                        externalTransactionsBlocked = true;
                      }
                    }),
                    title: const Text('Testing user'),
                  ),
                  SwitchListTile(
                    value: selectedRoles.contains('PLATFORM_OWNER'),
                    onChanged: null,
                    title: const Text('Protected — cannot be deleted'),
                    subtitle: const Text(
                      'Derived exclusively from the PLATFORM_OWNER role.',
                    ),
                  ),
                  SwitchListTile(
                    value: externalTransactionsBlocked,
                    onChanged: (value) => setLocalState(
                      () => externalTransactionsBlocked = value,
                    ),
                    title: const Text('Block external transactions'),
                  ),
                  SwitchListTile(
                    value: mfaRequired,
                    onChanged: (value) =>
                        setLocalState(() => mfaRequired = value),
                    title: const Text('MFA required'),
                    subtitle: const Text(
                      'Requires an MFA provider to be configured separately.',
                    ),
                  ),
                  TextField(
                    controller: environmentController,
                    decoration: const InputDecoration(
                      labelText: 'Environment scope',
                      helperText: 'Example: DEV,ALPHA,BETA',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: expiryController,
                    decoration: const InputDecoration(
                      labelText: 'Expiry date',
                      helperText:
                          'YYYY-MM-DD; required for temporary support users',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Protection/access reason',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Roles',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _roles
                        .map(
                          (role) => FilterChip(
                            label: Text(role.id),
                            selected: selectedRoles.contains(role.id),
                            onSelected: (selected) => setLocalState(() {
                              if (selected) {
                                selectedRoles.add(role.id);
                              } else {
                                selectedRoles.remove(role.id);
                              }
                              platformScope = selectedRoles
                                      .contains('PLATFORM_OWNER')
                                  ? 'PLATFORM_ALL'
                                  : 'STANDARD';
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Allowed tenants',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _tenants
                        .map(
                          (tenant) => FilterChip(
                            label: Text(tenant.name),
                            selected: selectedTenants.contains(tenant.id),
                            onSelected: platformScope == 'PLATFORM_ALL'
                                ? null
                                : (selected) => setLocalState(() {
                                      if (selected) {
                                        selectedTenants.add(tenant.id);
                                      } else {
                                        selectedTenants.remove(tenant.id);
                                      }
                                    }),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    try {
      final body = <String, dynamic>{
        'username': usernameController.text.trim(),
        'password': passwordController.text.isEmpty
            ? null
            : passwordController.text,
        'email': emailController.text.trim(),
        'cellphone': cellphoneController.text.trim(),
        'userType': 'ADMIN',
        'status': status,
        'accountType': accountType,
        'testUser': testUser,
        'protectedUser': selectedRoles.contains('PLATFORM_OWNER'),
        // Backend derives PLATFORM_ALL exclusively from PLATFORM_OWNER.
        'platformScope': platformScope,
        'environmentScope': environmentController.text.trim(),
        'externalTransactionsBlocked': externalTransactionsBlocked,
        'expiresAt': expiryController.text.trim().isEmpty
            ? null
            : '${expiryController.text.trim()}T23:59:59',
        'protectedReason': reasonController.text.trim(),
        'mfaRequired': mfaRequired,
        'roles': selectedRoles.toList(),
        'tenantIds': selectedTenants.toList(),
      };

      if (existing == null) {
        await _service.createUser(body);
      } else {
        await _service.updateUser(existing.id, body);
      }
      await _load();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _editRole([AdminRole? existing]) async {
    final idController = TextEditingController(text: existing?.id ?? '');
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');
    bool accessAll = existing?.accessAllFeatures ?? false;
    final selectedFeatures = <String>{...?existing?.featureCodes};

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text(
            existing == null ? 'Create role' : 'Edit ${existing.id}',
          ),
          content: SizedBox(
            width: 700,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: idController,
                    enabled: existing == null,
                    decoration: const InputDecoration(labelText: 'Role ID'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  SwitchListTile(
                    value: accessAll,
                    onChanged: null,
                    title: const Text(
                      'Access to all current and future features',
                    ),
                    subtitle: const Text(
                      'Reserved for the protected PLATFORM_OWNER role.',
                    ),
                  ),
                  if (!accessAll) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Features',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _features
                          .map(
                            (feature) => FilterChip(
                              label: Text(feature.name),
                              selected:
                                  selectedFeatures.contains(feature.code),
                              onSelected: (selected) => setLocalState(() {
                                if (selected) {
                                  selectedFeatures.add(feature.code);
                                } else {
                                  selectedFeatures.remove(feature.code);
                                }
                              }),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    try {
      await _service.saveRole(
        AdminRole(
          id: idController.text.trim().toUpperCase(),
          description: descriptionController.text.trim(),
          systemRole: existing?.systemRole ?? false,
          protectedRole: existing?.protectedRole ?? false,
          accessAllFeatures: accessAll,
          featureCodes: selectedFeatures.toList(),
        ),
        create: existing == null,
      );
      await _load();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _deleteUser(AdminUser user) async {
    if (!await _confirm('Delete ${user.username}?')) return;
    try {
      await _service.deleteUser(user.id);
      await _load();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _deleteRole(AdminRole role) async {
    if (!await _confirm('Delete role ${role.id}?')) return;
    try {
      await _service.deleteRole(role.id);
      await _load();
    } catch (error) {
      _showError(error);
    }
  }

  Future<bool> _confirm(String text) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Confirm'),
            content: Text(text),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        backgroundColor: Colors.red,
      ),
    );
  }
}
