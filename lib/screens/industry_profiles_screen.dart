import 'package:flutter/material.dart';

import '../models/industry_profile.dart';
import '../services/tenant_service.dart';
import '../theme/admin_theme.dart';
import 'package:mawa_erp_admin/utils/app_error.dart';

class IndustryProfilesScreen extends StatefulWidget {
  const IndustryProfilesScreen({super.key});

  @override
  State<IndustryProfilesScreen> createState() => _IndustryProfilesScreenState();
}

class _IndustryProfilesScreenState extends State<IndustryProfilesScreen> {
  final TenantService _service = TenantService();
  late Future<List<IndustryProfile>> _future;
  bool _activeOnly = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() => _future = _service.getIndustryProfiles(activeOnly: _activeOnly));
  }

  Future<void> _openEditor([IndustryProfile? profile]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => IndustryProfileEditorScreen(profile: profile),
      ),
    );
    if (saved == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Industry Profiles'),
        actions: [
          FilterChip(
            label: const Text('Active only'),
            selected: _activeOnly,
            onSelected: (value) {
              _activeOnly = value;
              _refresh();
            },
          ),
          const SizedBox(width: 8),
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded)),
          const SizedBox(width: 12),
        ],
      ),
      body: FutureBuilder<List<IndustryProfile>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(error: snapshot.error, onRetry: _refresh);
          }
          final profiles = snapshot.data ?? const <IndustryProfile>[];
          if (profiles.isEmpty) {
            return const Center(
              child: Text('No industry profiles are configured.'),
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1280
                  ? 4
                  : constraints.maxWidth >= 900
                      ? 3
                      : constraints.maxWidth >= 580
                          ? 2
                          : 1;
              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisExtent: 260,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: profiles.length,
                itemBuilder: (context, index) => _ProfileCard(
                  profile: profiles[index],
                  onTap: () => _openEditor(profiles[index]),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Industry Profile'),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final IndustryProfile profile;
  final VoidCallback onTap;

  const _ProfileCard({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = profile.status.toUpperCase() == 'ACTIVE';
    final workcenterCount = profile.groups.fold<int>(
      0,
      (total, group) => total + group.workcenters.length,
    );
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AdminDesign.red.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_iconForKey(profile.iconKey), color: AdminDesign.red),
                  ),
                  const Spacer(),
                  Chip(
                    label: Text(profile.status),
                    backgroundColor: active
                        ? AdminDesign.success.withValues(alpha: 0.1)
                        : AdminDesign.warning.withValues(alpha: 0.1),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(profile.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                profile.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminDesign.muted),
              ),
              const Spacer(),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _CountChip(label: '${profile.groups.length} groups'),
                  _CountChip(label: '$workcenterCount workcenters'),
                ],
              ),
              const SizedBox(height: 12),
              Text('Configure  →', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AdminDesign.red)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  const _CountChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AdminDesign.page,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AdminDesign.border),
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall),
      );
}

class IndustryProfileEditorScreen extends StatefulWidget {
  final IndustryProfile? profile;
  const IndustryProfileEditorScreen({super.key, this.profile});

  @override
  State<IndustryProfileEditorScreen> createState() => _IndustryProfileEditorScreenState();
}

class _IndustryProfileEditorScreenState extends State<IndustryProfileEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TenantService _service = TenantService();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _iconKeyController;
  late final TextEditingController _order;
  late String _status;
  late List<IndustryGroup> _groups;
  bool _saving = false;

  bool get _editing => widget.profile != null;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _code = TextEditingController(text: profile?.code ?? '');
    _name = TextEditingController(text: profile?.name ?? '');
    _description = TextEditingController(text: profile?.description ?? '');
    _iconKeyController = TextEditingController(text: profile?.iconKey ?? 'general');
    _order = TextEditingController(text: (profile?.displayOrder ?? 100).toString());
    _status = profile?.status ?? 'ACTIVE';
    _groups = [...?profile?.groups];
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _description.dispose();
    _iconKeyController.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final profile = IndustryProfile(
        code: _normaliseCode(_code.text),
        name: _name.text.trim(),
        description: _description.text.trim(),
        status: _status,
        iconKey: _iconKeyController.text.trim(),
        displayOrder: int.tryParse(_order.text.trim()) ?? 0,
        groups: _groups,
      );
      await _service.saveIndustryProfile(profile, create: !_editing);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage('Industry profile could not be saved: $error')), backgroundColor: Colors.red),
      );
      setState(() => _saving = false);
    }
  }

  Future<void> _editGroup({IndustryGroup? group, int? index}) async {
    final result = await showDialog<IndustryGroup>(
      context: context,
      builder: (_) => _IndustryGroupDialog(group: group),
    );
    if (result == null) return;
    setState(() {
      if (index == null) {
        _groups.add(result);
      } else {
        _groups[index] = result;
      }
      _groups.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit Industry Profile' : 'New Industry Profile'),
        actions: [
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_rounded),
            label: const Text('Save Profile'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Profile information', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final stacked = constraints.maxWidth < 760;
                        final code = TextFormField(
                          controller: _code,
                          enabled: !_editing,
                          decoration: const InputDecoration(labelText: 'Code', hintText: 'LEGAL_PRACTICE'),
                          textCapitalization: TextCapitalization.characters,
                          validator: (value) => value == null || value.trim().isEmpty ? 'Code is required' : null,
                        );
                        final name = TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(labelText: 'Display name'),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
                        );
                        if (stacked) return Column(children: [code, const SizedBox(height: 12), name]);
                        return Row(children: [Expanded(child: code), const SizedBox(width: 12), Expanded(child: name)]);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _description,
                      decoration: const InputDecoration(labelText: 'Description'),
                      minLines: 2,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final fields = [
                          Expanded(child: TextFormField(controller: _iconKeyController, decoration: const InputDecoration(labelText: 'Icon key'))),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: _order, decoration: const InputDecoration(labelText: 'Display order'), keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _status,
                              decoration: const InputDecoration(labelText: 'Status'),
                              items: const [
                                DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                                DropdownMenuItem(value: 'INACTIVE', child: Text('INACTIVE')),
                              ],
                              onChanged: (value) => setState(() => _status = value ?? 'ACTIVE'),
                            ),
                          ),
                        ];
                        if (constraints.maxWidth < 760) {
                          return Column(
                            children: [
                              TextFormField(controller: _iconKeyController, decoration: const InputDecoration(labelText: 'Icon key')),
                              const SizedBox(height: 12),
                              TextFormField(controller: _order, decoration: const InputDecoration(labelText: 'Display order'), keyboardType: TextInputType.number),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _status,
                                decoration: const InputDecoration(labelText: 'Status'),
                                items: const [
                                  DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                                  DropdownMenuItem(value: 'INACTIVE', child: Text('INACTIVE')),
                                ],
                                onChanged: (value) => setState(() => _status = value ?? 'ACTIVE'),
                              ),
                            ],
                          );
                        }
                        return Row(children: fields);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Homepage groups', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        'Define how this industry presents workcenters under Your Business, Business Services and System Administration.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminDesign.muted),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _editGroup(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Group'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_groups.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(28), child: Text('No workcenter groups have been configured.')))
            else
              ...List.generate(_groups.length, (index) {
                final group = _groups[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: CircleAvatar(child: Icon(_iconForKey(group.iconKey), size: 20)),
                    title: Text(group.title),
                    subtitle: Text('${_sectionTitle(group.sectionCode)} • ${group.workcenters.length} workcenters'),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(onPressed: () => _editGroup(group: group, index: index), icon: const Icon(Icons.edit_outlined)),
                        IconButton(
                          onPressed: () => setState(() => _groups.removeAt(index)),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (group.description.isNotEmpty) Text(group.description),
                            const SizedBox(height: 12),
                            ...group.workcenters.map(
                              (item) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.apps_rounded),
                                title: Text(item.displayLabel.isEmpty ? item.id : item.displayLabel),
                                subtitle: Text('${item.id}${item.description.isEmpty ? '' : ' • ${item.description}'}'),
                                trailing: Text('#${item.displayOrder}'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _IndustryGroupDialog extends StatefulWidget {
  final IndustryGroup? group;
  const _IndustryGroupDialog({this.group});

  @override
  State<_IndustryGroupDialog> createState() => _IndustryGroupDialogState();
}

class _IndustryGroupDialogState extends State<_IndustryGroupDialog> {
  late final TextEditingController _code;
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _iconKey;
  late final TextEditingController _order;
  late String _section;
  late bool _active;
  late List<IndustryWorkcenter> _workcenters;

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    _code = TextEditingController(text: group?.code ?? '');
    _title = TextEditingController(text: group?.title ?? '');
    _description = TextEditingController(text: group?.description ?? '');
    _iconKey = TextEditingController(text: group?.iconKey ?? 'apps');
    _order = TextEditingController(text: (group?.displayOrder ?? 10).toString());
    _section = group?.sectionCode ?? 'YOUR_BUSINESS';
    _active = group?.active ?? true;
    _workcenters = [...?group?.workcenters];
  }

  @override
  void dispose() {
    _code.dispose();
    _title.dispose();
    _description.dispose();
    _iconKey.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _editWorkcenter({IndustryWorkcenter? workcenter, int? index}) async {
    final result = await showDialog<IndustryWorkcenter>(
      context: context,
      builder: (_) => _IndustryWorkcenterDialog(workcenter: workcenter),
    );
    if (result == null) return;
    setState(() {
      if (index == null) {
        _workcenters.add(result);
      } else {
        _workcenters[index] = result;
      }
      _workcenters.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    });
  }

  void _submit() {
    if (_title.text.trim().isEmpty) return;
    Navigator.of(context).pop(
      IndustryGroup(
        code: _normaliseGroupCode(_code.text.isEmpty ? _title.text : _code.text),
        title: _title.text.trim(),
        description: _description.text.trim(),
        sectionCode: _section,
        iconKey: _iconKey.text.trim(),
        displayOrder: int.tryParse(_order.text.trim()) ?? 0,
        active: _active,
        workcenters: _workcenters,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.group == null ? 'Add Workcenter Group' : 'Edit Workcenter Group'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: TextField(controller: _title, decoration: const InputDecoration(labelText: 'Group title'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _code, decoration: const InputDecoration(labelText: 'Group code', hintText: 'legal-practice'))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: _description, decoration: const InputDecoration(labelText: 'Description'), minLines: 2, maxLines: 3),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _section,
                      decoration: const InputDecoration(labelText: 'Homepage section'),
                      items: const [
                        DropdownMenuItem(value: 'YOUR_BUSINESS', child: Text('Your Business')),
                        DropdownMenuItem(value: 'BUSINESS_SERVICES', child: Text('Business Services')),
                        DropdownMenuItem(value: 'SYSTEM_ADMINISTRATION', child: Text('System Administration')),
                      ],
                      onChanged: (value) => setState(() => _section = value ?? 'YOUR_BUSINESS'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _iconKey, decoration: const InputDecoration(labelText: 'Icon key'))),
                  const SizedBox(width: 12),
                  SizedBox(width: 120, child: TextField(controller: _order, decoration: const InputDecoration(labelText: 'Order'), keyboardType: TextInputType.number)),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active group'),
                value: _active,
                onChanged: (value) => setState(() => _active = value),
              ),
              const Divider(height: 28),
              Row(
                children: [
                  Expanded(child: Text('Workcenters', style: Theme.of(context).textTheme.titleMedium)),
                  OutlinedButton.icon(onPressed: () => _editWorkcenter(), icon: const Icon(Icons.add_rounded), label: const Text('Add Workcenter')),
                ],
              ),
              const SizedBox(height: 8),
              if (_workcenters.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Text('No workcenters have been added.'))
              else
                ...List.generate(_workcenters.length, (index) {
                  final item = _workcenters[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.apps_rounded),
                    title: Text(item.displayLabel.isEmpty ? item.id : item.displayLabel),
                    subtitle: Text(item.id),
                    trailing: Wrap(
                      spacing: 2,
                      children: [
                        IconButton(onPressed: () => _editWorkcenter(workcenter: item, index: index), icon: const Icon(Icons.edit_outlined)),
                        IconButton(onPressed: () => setState(() => _workcenters.removeAt(index)), icon: const Icon(Icons.delete_outline_rounded)),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save Group')),
      ],
    );
  }
}

class _IndustryWorkcenterDialog extends StatefulWidget {
  final IndustryWorkcenter? workcenter;
  const _IndustryWorkcenterDialog({this.workcenter});

  @override
  State<_IndustryWorkcenterDialog> createState() => _IndustryWorkcenterDialogState();
}

class _IndustryWorkcenterDialogState extends State<_IndustryWorkcenterDialog> {
  late final TextEditingController _id;
  late final TextEditingController _label;
  late final TextEditingController _description;
  late final TextEditingController _order;
  late bool _active;

  @override
  void initState() {
    super.initState();
    final item = widget.workcenter;
    _id = TextEditingController(text: item?.id ?? '');
    _label = TextEditingController(text: item?.displayLabel ?? '');
    _description = TextEditingController(text: item?.description ?? '');
    _order = TextEditingController(text: (item?.displayOrder ?? 10).toString());
    _active = item?.active ?? true;
  }

  @override
  void dispose() {
    _id.dispose();
    _label.dispose();
    _description.dispose();
    _order.dispose();
    super.dispose();
  }

  void _submit() {
    if (_id.text.trim().isEmpty) return;
    Navigator.of(context).pop(
      IndustryWorkcenter(
        id: _normaliseGroupCode(_id.text),
        displayLabel: _label.text.trim(),
        description: _description.text.trim(),
        displayOrder: int.tryParse(_order.text.trim()) ?? 0,
        active: _active,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.workcenter == null ? 'Add Workcenter' : 'Edit Workcenter'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _id, decoration: const InputDecoration(labelText: 'Workcenter ID', hintText: 'legal-case')),
            const SizedBox(height: 12),
            TextField(controller: _label, decoration: const InputDecoration(labelText: 'Industry-specific label')),
            const SizedBox(height: 12),
            TextField(controller: _description, decoration: const InputDecoration(labelText: 'Card description'), minLines: 2, maxLines: 3),
            const SizedBox(height: 12),
            TextField(controller: _order, decoration: const InputDecoration(labelText: 'Display order'), keyboardType: TextInputType.number),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Active'), value: _active, onChanged: (value) => setState(() => _active = value)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save Workcenter')),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AdminDesign.red),
            const SizedBox(height: 12),
            Text('Industry profiles could not be loaded', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(friendlyErrorMessage('$error'), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
          ],
        ),
      );
}

String _normaliseCode(String value) => value
    .trim()
    .toUpperCase()
    .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '');

String _normaliseGroupCode(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

String _sectionTitle(String code) {
  switch (code) {
    case 'BUSINESS_SERVICES':
      return 'Business Services';
    case 'SYSTEM_ADMINISTRATION':
      return 'System Administration';
    default:
      return 'Your Business';
  }
}

IconData _iconForKey(String key) {
  final value = key.toLowerCase();
  if (value.contains('legal')) return Icons.gavel_rounded;
  if (value.contains('funeral')) return Icons.volunteer_activism_rounded;
  if (value.contains('membership')) return Icons.card_membership_rounded;
  if (value.contains('tombstone')) return Icons.account_balance_rounded;
  if (value.contains('retail') || value.contains('sales')) return Icons.storefront_rounded;
  if (value.contains('warehouse') || value.contains('inventory')) return Icons.warehouse_rounded;
  if (value.contains('manufact')) return Icons.precision_manufacturing_rounded;
  if (value.contains('property')) return Icons.apartment_rounded;
  if (value.contains('health')) return Icons.local_hospital_rounded;
  if (value.contains('community')) return Icons.groups_rounded;
  if (value.contains('construction')) return Icons.construction_rounded;
  if (value.contains('finance')) return Icons.account_balance_wallet_rounded;
  if (value.contains('people')) return Icons.badge_rounded;
  if (value.contains('report')) return Icons.bar_chart_rounded;
  if (value.contains('admin')) return Icons.settings_rounded;
  return Icons.domain_rounded;
}
