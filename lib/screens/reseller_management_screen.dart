import 'package:flutter/material.dart';

import '../models/reseller.dart';
import '../models/tenant.dart';
import '../services/reseller_service.dart';
import '../services/tenant_service.dart';
import '../utils/app_error.dart';

class ResellerManagementScreen extends StatefulWidget {
  const ResellerManagementScreen({super.key});
  @override
  State<ResellerManagementScreen> createState() => _ResellerManagementScreenState();
}

class _ResellerManagementScreenState extends State<ResellerManagementScreen> {
  final _service = ResellerService();
  late Future<List<ResellerProfile>> _profiles;
  @override
  void initState() { super.initState(); _refresh(); }
  void _refresh() => setState(() => _profiles = _service.profiles());

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Resellers'), actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh'),
        ]),
        body: FutureBuilder<List<ResellerProfile>>(
          future: _profiles,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return _ErrorState(error: snapshot.error, retry: _refresh);
            final profiles = snapshot.data ?? const [];
            if (profiles.isEmpty) return const Center(child: Text('No reseller profiles have been configured.'));
            return ListView.builder(
              padding: const EdgeInsets.all(20), itemCount: profiles.length,
              itemBuilder: (context, index) {
                final reseller = profiles[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(child: Text(reseller.tenantName.isEmpty ? 'R' : reseller.tenantName[0].toUpperCase())),
                    title: Text(reseller.brandingName?.isNotEmpty == true ? reseller.brandingName! : reseller.tenantName),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('${reseller.assignedTenantCount} assigned tenants • ${_label(reseller.status)} • ${reseller.slaResponseHours}h SLA'),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ResellerDetailScreen(profile: reseller),
                    )).then((_) => _refresh()),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createProfile, icon: const Icon(Icons.add_business_rounded), label: const Text('Configure reseller'),
        ),
      );

  Future<void> _createProfile() async {
    final tenants = await TenantService().getTenants();
    if (!mounted) return;
    final candidates = tenants.where((tenant) => tenant.tenantType == 'RESELLER').toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final result = await showDialog<ResellerProfile>(context: context, builder: (_) => _ResellerProfileDialog(tenants: candidates));
    if (result == null) return;
    try { await _service.saveProfile(result); _refresh(); }
    catch (e) { if (mounted) _error(context, e); }
  }
}

class ResellerDetailScreen extends StatefulWidget {
  final ResellerProfile profile;
  const ResellerDetailScreen({super.key, required this.profile});
  @override
  State<ResellerDetailScreen> createState() => _ResellerDetailScreenState();
}

class _ResellerDetailScreenState extends State<ResellerDetailScreen> {
  final _service = ResellerService();
  late Future<List<ResellerTenantAssignment>> _assignments;
  late Future<List<ResellerEmployeeAccess>> _employeeAccess;
  @override
  void initState() { super.initState(); _refresh(); }
  void _refresh() => setState(() {
    _assignments = _service.assignments(widget.profile.tenantId);
    _employeeAccess = _service.employeeAccess(widget.profile.tenantId);
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.profile.tenantName), actions: [
          IconButton(onPressed: _editProfile, icon: const Icon(Icons.edit_rounded), tooltip: 'Edit reseller'),
        ]),
        body: Column(children: [
          _summary(),
          Expanded(child: DefaultTabController(length: 2, child: Column(children: [
            const TabBar(tabs: [Tab(icon: Icon(Icons.business_rounded), text: 'Client tenants'), Tab(icon: Icon(Icons.badge_outlined), text: 'Employee access')]),
            Expanded(child: TabBarView(children: [_clientList(), _employeeList()])),
          ]))),
        ]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _assignTenant, icon: const Icon(Icons.link_rounded), label: const Text('Assign tenant'),
        ),
      );

  Widget _clientList() => FutureBuilder<List<ResellerTenantAssignment>>(
    future: _assignments, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return _ErrorState(error: snapshot.error, retry: _refresh);
      final assignments = snapshot.data ?? const [];
      if (assignments.isEmpty) return const Center(child: Text('No client tenants are assigned to this reseller.'));
      return ListView.builder(padding: const EdgeInsets.all(20), itemCount: assignments.length, itemBuilder: (context, index) {
        final item = assignments[index];
        return Card(child: ListTile(leading: const Icon(Icons.business_rounded), title: Text(item.clientTenantName),
          subtitle: Text('${item.clientTenantHost ?? ''}\n${_label(item.supportLevel)} • ${_label(item.billingResponsibility)}'),
          isThreeLine: true, trailing: Chip(label: Text(_label(item.status)))));
      });
    });

  Widget _employeeList() => FutureBuilder<List<ResellerEmployeeAccess>>(
    future: _employeeAccess, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return _ErrorState(error: snapshot.error, retry: _refresh);
      final access = snapshot.data ?? const [];
      return Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 4), child: Row(children: [
          const Expanded(child: Text('Grant each reseller employee access only to the client tenants they support.')),
          FilledButton.icon(onPressed: _grantEmployeeAccess, icon: const Icon(Icons.person_add_alt_1), label: const Text('Grant access')),
        ])),
        Expanded(child: access.isEmpty ? const Center(child: Text('No employee access has been configured.'))
          : ListView.builder(padding: const EdgeInsets.all(20), itemCount: access.length, itemBuilder: (context, index) {
            final item = access[index];
            return Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.support_agent_rounded)),
              title: Text(item.employeeDisplayName?.isNotEmpty == true ? item.employeeDisplayName! : item.employeeUsername),
              subtitle: Text('${item.employeeUsername}\n${item.clientTenantName} • ${_label(item.accessLevel)}'), isThreeLine: true,
              trailing: Chip(label: Text(_label(item.status))), onTap: () => _grantEmployeeAccess(existing: item)));
          })),
      ]);
    });

  Widget _summary() => Padding(
        padding: const EdgeInsets.all(20),
        child: Card(child: Padding(
          padding: const EdgeInsets.all(18),
          child: Wrap(spacing: 28, runSpacing: 12, children: [
            _fact(Icons.support_agent_rounded, widget.profile.supportEmail ?? 'No support email'),
            _fact(Icons.schedule_rounded, '${widget.profile.slaResponseHours} hour response SLA'),
            _fact(Icons.receipt_long_rounded, widget.profile.mayInvoiceClients ? 'May invoice clients' : 'MAWA-controlled invoicing'),
            _fact(Icons.add_business_rounded, widget.profile.mayProvisionTenants ? 'May provision tenants' : 'No tenant provisioning'),
          ]),
        )),
      );
  Widget _fact(IconData icon, String value) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(value)]);

  Future<void> _editProfile() async {
    final result = await showDialog<ResellerProfile>(context: context, builder: (_) => _ResellerProfileDialog(profile: widget.profile));
    if (result == null) return;
    try { await _service.saveProfile(result); if (mounted) Navigator.pop(context); }
    catch (e) { if (mounted) _error(context, e); }
  }

  Future<void> _assignTenant() async {
    final tenants = await TenantService().getTenants();
    if (!mounted) return;
    final candidates = tenants.where((tenant) => tenant.id != widget.profile.tenantId && tenant.tenantType != 'PLATFORM_OPERATOR').toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final result = await showDialog<ResellerTenantAssignment>(context: context,
      builder: (_) => _AssignmentDialog(resellerTenantId: widget.profile.tenantId, tenants: candidates));
    if (result == null) return;
    try { await _service.assign(result); _refresh(); }
    catch (e) { if (mounted) _error(context, e); }
  }

  Future<void> _grantEmployeeAccess({ResellerEmployeeAccess? existing}) async {
    final assignments = await _assignments;
    if (!mounted) return;
    if (assignments.where((item) => item.status == 'ACTIVE').isEmpty) {
      _error(context, AppException('Assign an active client tenant before granting employee access.'));
      return;
    }
    final result = await showDialog<ResellerEmployeeAccess>(context: context, builder: (_) => _EmployeeAccessDialog(
      resellerTenantId: widget.profile.tenantId, assignments: assignments, existing: existing));
    if (result == null) return;
    try { await _service.saveEmployeeAccess(result); _refresh(); }
    catch (e) { if (mounted) _error(context, e); }
  }
}

class _ResellerProfileDialog extends StatefulWidget {
  final List<Tenant> tenants;
  final ResellerProfile? profile;
  const _ResellerProfileDialog({this.tenants = const [], this.profile});
  @override State<_ResellerProfileDialog> createState() => _ResellerProfileDialogState();
}
class _ResellerProfileDialogState extends State<_ResellerProfileDialog> {
  final _form = GlobalKey<FormState>(); late String? _tenantId; late String _status;
  late final TextEditingController _email, _phone, _hours, _sla, _branding;
  late bool _provision, _invoice;
  @override void initState() { super.initState(); final p = widget.profile; _tenantId = p?.tenantId; _status = p?.status ?? 'ACTIVE';
    _email = TextEditingController(text: p?.supportEmail); _phone = TextEditingController(text: p?.supportPhone);
    _hours = TextEditingController(text: p?.supportHours); _sla = TextEditingController(text: '${p?.slaResponseHours ?? 8}');
    _branding = TextEditingController(text: p?.brandingName); _provision = p?.mayProvisionTenants ?? false; _invoice = p?.mayInvoiceClients ?? true; }
  @override Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.profile == null ? 'Configure reseller' : 'Edit reseller'),
    content: SizedBox(width: 520, child: Form(key: _form, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      if (widget.profile == null) DropdownButtonFormField<String>(value: _tenantId, decoration: const InputDecoration(labelText: 'Reseller tenant'),
        items: widget.tenants.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
        onChanged: (v) => setState(() => _tenantId = v), validator: (v) => v == null ? 'Select a reseller tenant' : null),
      if (widget.profile == null) const SizedBox(height: 12),
      TextFormField(controller: _branding, decoration: const InputDecoration(labelText: 'Support brand name')),
      const SizedBox(height: 12), TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Support email')),
      const SizedBox(height: 12), TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Support phone')),
      const SizedBox(height: 12), TextFormField(controller: _hours, decoration: const InputDecoration(labelText: 'Support hours')),
      const SizedBox(height: 12), TextFormField(controller: _sla, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Response SLA (hours)'), validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1 ? 'Enter a positive number' : null),
      const SizedBox(height: 12), DropdownButtonFormField<String>(value: _status, decoration: const InputDecoration(labelText: 'Status'),
        items: const ['ACTIVE','SUSPENDED','TERMINATED'].map((v) => DropdownMenuItem(value: v, child: Text(_label(v)))).toList(), onChanged: (v) => setState(() => _status = v!)),
      SwitchListTile(value: _provision, onChanged: (v) => setState(() => _provision = v), title: const Text('May provision tenants'), contentPadding: EdgeInsets.zero),
      SwitchListTile(value: _invoice, onChanged: (v) => setState(() => _invoice = v), title: const Text('May invoice clients'), contentPadding: EdgeInsets.zero),
    ])))),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: _save, child: const Text('Save'))],
  );
  void _save() { if (!_form.currentState!.validate()) return; Navigator.pop(context, ResellerProfile(
    id: widget.profile?.id, tenantId: _tenantId!, tenantName: widget.profile?.tenantName ?? '', status: _status,
    supportEmail: _email.text.trim(), supportPhone: _phone.text.trim(), supportHours: _hours.text.trim(),
    slaResponseHours: int.parse(_sla.text), mayProvisionTenants: _provision, mayInvoiceClients: _invoice, brandingName: _branding.text.trim())); }
}

class _AssignmentDialog extends StatefulWidget {
  final String resellerTenantId; final List<Tenant> tenants;
  const _AssignmentDialog({required this.resellerTenantId, required this.tenants});
  @override State<_AssignmentDialog> createState() => _AssignmentDialogState();
}
class _AssignmentDialogState extends State<_AssignmentDialog> {
  final _form = GlobalKey<FormState>(); String? _client; String _support = 'FIRST_LINE'; String _billing = 'MAWA_TO_TENANT'; bool _primary = true;
  @override Widget build(BuildContext context) => AlertDialog(title: const Text('Assign client tenant'), content: SizedBox(width: 500, child: Form(key: _form, child: Column(mainAxisSize: MainAxisSize.min, children: [
    DropdownButtonFormField<String>(value: _client, decoration: const InputDecoration(labelText: 'Client tenant'),
      items: widget.tenants.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(), onChanged: (v) => setState(() => _client = v), validator: (v) => v == null ? 'Select a tenant' : null),
    const SizedBox(height: 12), DropdownButtonFormField<String>(value: _support, decoration: const InputDecoration(labelText: 'Support level'),
      items: const ['FIRST_LINE','FIRST_AND_SECOND_LINE','COMMERCIAL_ONLY'].map((v) => DropdownMenuItem(value: v, child: Text(_label(v)))).toList(), onChanged: (v) => setState(() => _support = v!)),
    const SizedBox(height: 12), DropdownButtonFormField<String>(value: _billing, decoration: const InputDecoration(labelText: 'Billing responsibility'),
      items: const ['MAWA_TO_TENANT','MAWA_TO_RESELLER','RESELLER_TO_CLIENT','SHARED'].map((v) => DropdownMenuItem(value: v, child: Text(_label(v)))).toList(), onChanged: (v) => setState(() => _billing = v!)),
    SwitchListTile(value: _primary, onChanged: (v) => setState(() => _primary = v), title: const Text('Primary reseller'), contentPadding: EdgeInsets.zero),
  ]))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: _save, child: const Text('Assign'))]);
  void _save() { if (!_form.currentState!.validate()) return; Navigator.pop(context, ResellerTenantAssignment(
    resellerTenantId: widget.resellerTenantId, clientTenantId: _client!, supportLevel: _support,
    billingResponsibility: _billing, primaryReseller: _primary)); }
}

class _EmployeeAccessDialog extends StatefulWidget {
  final String resellerTenantId;
  final List<ResellerTenantAssignment> assignments;
  final ResellerEmployeeAccess? existing;
  const _EmployeeAccessDialog({required this.resellerTenantId, required this.assignments, this.existing});
  @override State<_EmployeeAccessDialog> createState() => _EmployeeAccessDialogState();
}

class _EmployeeAccessDialogState extends State<_EmployeeAccessDialog> {
  final _form = GlobalKey<FormState>();
  late String? _clientId;
  late String _accessLevel;
  late String _status;
  late bool _mayElevate;
  late final TextEditingController _username, _displayName, _validFrom, _validTo;
  @override void initState() {
    super.initState(); final current = widget.existing;
    _clientId = current?.clientTenantId; _accessLevel = current?.accessLevel ?? 'READ_ONLY';
    _status = current?.status ?? 'ACTIVE'; _mayElevate = current?.mayRequestElevatedAccess ?? false;
    _username = TextEditingController(text: current?.employeeUsername);
    _displayName = TextEditingController(text: current?.employeeDisplayName);
    _validFrom = TextEditingController(text: current?.validFrom ?? DateTime.now().toIso8601String().substring(0, 10));
    _validTo = TextEditingController(text: current?.validTo);
  }
  @override Widget build(BuildContext context) {
    final clients = widget.assignments.where((item) => item.status == 'ACTIVE').toList()
      ..sort((a, b) => a.clientTenantName.compareTo(b.clientTenantName));
    return AlertDialog(title: Text(widget.existing == null ? 'Grant employee access' : 'Edit employee access'),
      content: SizedBox(width: 540, child: Form(key: _form, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(value: _clientId, decoration: const InputDecoration(labelText: 'Client tenant'),
          items: clients.map((item) => DropdownMenuItem(value: item.clientTenantId, child: Text(item.clientTenantName))).toList(),
          onChanged: widget.existing == null ? (value) => setState(() => _clientId = value) : null,
          validator: (value) => value == null ? 'Select a client tenant' : null),
        const SizedBox(height: 12), TextFormField(controller: _username, enabled: widget.existing == null,
          decoration: const InputDecoration(labelText: 'Employee username', helperText: 'Use the exact MAWA sign-in username.'),
          validator: (value) => value == null || value.trim().isEmpty ? 'Employee username is required' : null),
        const SizedBox(height: 12), TextFormField(controller: _displayName, decoration: const InputDecoration(labelText: 'Display name')),
        const SizedBox(height: 12), DropdownButtonFormField<String>(value: _accessLevel, decoration: const InputDecoration(labelText: 'Access level'),
          items: const ['READ_ONLY', 'SUPPORT_OPERATOR'].map((value) => DropdownMenuItem(value: value, child: Text(_label(value)))).toList(),
          onChanged: (value) => setState(() => _accessLevel = value!)),
        SwitchListTile(value: _mayElevate, contentPadding: EdgeInsets.zero, title: const Text('May request support-operator access'),
          onChanged: (value) => setState(() => _mayElevate = value)),
        Row(children: [Expanded(child: TextFormField(controller: _validFrom, decoration: const InputDecoration(labelText: 'Valid from (YYYY-MM-DD)'),
          validator: _dateValidator)), const SizedBox(width: 12), Expanded(child: TextFormField(controller: _validTo,
          decoration: const InputDecoration(labelText: 'Valid to (optional)'), validator: _optionalDateValidator))]),
        const SizedBox(height: 12), DropdownButtonFormField<String>(value: _status, decoration: const InputDecoration(labelText: 'Status'),
          items: const ['ACTIVE', 'SUSPENDED', 'ENDED'].map((value) => DropdownMenuItem(value: value, child: Text(_label(value)))).toList(),
          onChanged: (value) => setState(() => _status = value!)),
      ])))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save access'))]);
  }
  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, ResellerEmployeeAccess(id: widget.existing?.id, resellerTenantId: widget.resellerTenantId,
      clientTenantId: _clientId!, clientTenantName: widget.existing?.clientTenantName ?? '',
      employeeUsername: _username.text.trim(), employeeDisplayName: _displayName.text.trim(),
      accessLevel: _accessLevel, mayRequestElevatedAccess: _mayElevate, status: _status,
      validFrom: _validFrom.text.trim(), validTo: _validTo.text.trim().isEmpty ? null : _validTo.text.trim()));
  }
}

String? _dateValidator(String? value) {
  if (value == null || value.trim().isEmpty) return 'Date is required';
  return DateTime.tryParse(value.trim()) == null ? 'Use YYYY-MM-DD' : null;
}
String? _optionalDateValidator(String? value) => value == null || value.trim().isEmpty ? null : _dateValidator(value);

class _ErrorState extends StatelessWidget { final Object? error; final VoidCallback retry; const _ErrorState({required this.error, required this.retry});
  @override Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(friendlyErrorMessage(error)), const SizedBox(height: 12), FilledButton(onPressed: retry, child: const Text('Retry'))])); }
void _error(BuildContext context, Object error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error)), backgroundColor: Colors.red.shade700));
String _label(String value) => value.toLowerCase().split('_').map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}').join(' ');
