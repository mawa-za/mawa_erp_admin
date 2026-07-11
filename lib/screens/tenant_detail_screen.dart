import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/external_url_opener.dart';
import '../models/tenant.dart';
import '../services/tenant_service.dart';
import '../models/tenant_property.dart';
import '../models/platform_management.dart';

class TenantDetailScreen extends StatefulWidget {
  final Tenant tenant;

  const TenantDetailScreen({super.key, required this.tenant});

  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  final TenantService _tenantService = TenantService();
  late Tenant _tenant;
  late Future<List<TenantProperty>> _propertiesFuture;
  late Future<List<TenantModule>> _modulesFuture;
  late Future<TenantSubscription?> _subscriptionFuture;
  late Future<List<TenantActivityLog>> _activityFuture;
  late Future<List<TenantSchedule>> _schedulesFuture;
  late Future<List<SubscriptionPlan>> _plansFuture;

  @override
  void initState() {
    super.initState();
    _tenant = widget.tenant;
    _refreshAll();
  }

  void _refreshAll() {
    setState(() {
      _propertiesFuture = _tenantService.getTenantPropertyDetails(_tenant.id);
      _modulesFuture = _tenantService.getTenantModules(_tenant.id);
      _subscriptionFuture = _tenantService.getTenantSubscription(_tenant.id);
      _activityFuture = _tenantService.getTenantActivity(_tenant.id);
      _schedulesFuture = _tenantService.getTenantSchedules(_tenant.id);
      _plansFuture = _tenantService.getSubscriptionPlans();
    });
  }

  void _refreshProperties() {
    setState(() {
      _propertiesFuture = _tenantService.getTenantPropertyDetails(_tenant.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tenant.name),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshAll),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshAll(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 16),
              _buildSubscriptionCard(),
              const SizedBox(height: 16),
              _buildModuleManagementCard(),
              const SizedBox(height: 16),
              _buildErpIntegrationCard(),
              const SizedBox(height: 16),
              _buildSchedulingCard(),
              const SizedBox(height: 16),
              _buildSecretManagerCard(),
              const SizedBox(height: 16),
              _buildPropertiesCard(),
              const SizedBox(height: 16),
              _buildActivityCard(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 8),
                const Expanded(child: Text('Tenant Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                OutlinedButton.icon(onPressed: _showEditTenantDialog, icon: const Icon(Icons.edit_rounded, size: 18), label: const Text('Edit')),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (status) => _updateStatus(status),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'ACTIVE', child: Text('Mark Active')),
                    PopupMenuItem(value: 'INACTIVE', child: Text('Mark Inactive')),
                    PopupMenuItem(value: 'SUSPENDED', child: Text('Suspend')),
                  ],
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.more_vert_rounded),
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildDetailRow('ID', _tenant.id),
            _buildDetailRow('Name', _tenant.name),
            _buildDetailRow('Host', _tenant.host),
            _buildDetailRow('ERP URL', _tenant.erpAppUrl ?? _tenant.url ?? '-'),
            _buildDetailRow('Status', _tenant.status, color: _statusColor(_tenant.status)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium_rounded, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                const Expanded(child: Text('Subscription', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                OutlinedButton.icon(onPressed: _showSubscriptionDialog, icon: const Icon(Icons.edit_rounded, size: 18), label: const Text('Assign Plan')),
              ],
            ),
            const Divider(),
            FutureBuilder<TenantSubscription?>(
              future: _subscriptionFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Failed to load subscription: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                }
                final subscription = snapshot.data;
                if (subscription == null) {
                  return const Text('No subscription assigned yet.');
                }
                return Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildMiniMetric('Plan', subscription.planName ?? subscription.planCode),
                    _buildMiniMetric('Status', subscription.status),
                    _buildMiniMetric('Cycle', subscription.billingCycle),
                    _buildMiniMetric('Next Billing', subscription.nextBillingDate ?? '-'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleManagementCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.extension_rounded, color: Colors.indigo.shade700),
                const SizedBox(width: 8),
                const Expanded(child: Text('Modules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                OutlinedButton.icon(onPressed: _syncTenantModules, icon: const Icon(Icons.sync_rounded, size: 18), label: const Text('Sync Modules')),
              ],
            ),
            const Divider(),
            FutureBuilder<List<TenantModule>>(
              future: _modulesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Failed to load modules: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                }
                final modules = snapshot.data ?? [];
                if (modules.isEmpty) {
                  return const Text('No modules configured.');
                }
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: modules.map(_buildModuleSwitch).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleSwitch(TenantModule module) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: module.enabled ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: module.enabled ? Colors.green.shade100 : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(module.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(module.code, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: module.enabled,
            onChanged: (value) async {
              try {
                await _tenantService.setTenantModule(_tenant.id, module.code, value);
                setState(() {
                  _modulesFuture = _tenantService.getTenantModules(_tenant.id);
                  _propertiesFuture = _tenantService.getTenantPropertyDetails(_tenant.id);
                  _activityFuture = _tenantService.getTenantActivity(_tenant.id);
      _schedulesFuture = _tenantService.getTenantSchedules(_tenant.id);
                });
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Module update failed: $e'), backgroundColor: Colors.red));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErpIntegrationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.deepPurple.shade50, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.hub_rounded, color: Colors.deepPurple.shade700),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ERP Integration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text('Sync configuration with mawa-bes or open tenant ERP through a short-lived support handoff.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(onPressed: _syncErpConfiguration, icon: const Icon(Icons.sync_rounded, size: 18), label: const Text('Sync ERP')),
                ElevatedButton.icon(onPressed: _openTenantErp, icon: const Icon(Icons.open_in_new_rounded, size: 18), label: const Text('Open ERP')),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSchedulingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule_rounded, color: Colors.deepOrange.shade700),
                const SizedBox(width: 8),
                const Expanded(child: Text('Tenant Schedules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _refreshAll),
              ],
            ),
            const Divider(),
            FutureBuilder<List<TenantSchedule>>(
              future: _schedulesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Failed to load schedules: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                }
                final schedules = snapshot.data ?? [];
                if (schedules.isEmpty) {
                  return const Text('No scheduled jobs configured for this tenant.');
                }
                return Column(children: schedules.map(_buildScheduleTile).toList());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTile(TenantSchedule schedule) {
    final intervalController = TextEditingController(text: schedule.intervalMinutes.toString());
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        color: schedule.enabled ? Colors.green.shade50 : Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(schedule.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(schedule.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  ],
                ),
              ),
              if (!schedule.manualOnly)
                Switch(
                  value: schedule.enabled,
                  onChanged: (value) => _saveSchedule(schedule.copyWith(enabled: value)),
                )
              else
                const Chip(label: Text('Once off')),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (!schedule.manualOnly) ...[
                SizedBox(
                  width: 180,
                  child: TextFormField(
                    controller: intervalController,
                    decoration: const InputDecoration(labelText: 'Interval minutes', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _saveSchedule(schedule.copyWith(intervalMinutes: int.tryParse(intervalController.text) ?? schedule.intervalMinutes)),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save'),
                ),
              ],
              OutlinedButton.icon(
                onPressed: () => _runScheduleNow(schedule),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(schedule.manualOnly ? 'Run once' : 'Run now'),
              ),
              Text('Last: ${schedule.lastRunAt ?? 'Never'}', style: TextStyle(color: Colors.grey.shade700)),
              if (!schedule.manualOnly) Text('Next: ${schedule.nextRunAt ?? 'Stopped'}', style: TextStyle(color: Colors.grey.shade700)),
              if (schedule.lastRunResult != null && schedule.lastRunResult!.isNotEmpty)
                Text('Result: ${schedule.lastRunResult}', style: TextStyle(color: Colors.grey.shade700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecretManagerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.key_rounded, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Google Secret Manager', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text('Sensitive tenant values are saved to GCP and stored here as secret references only.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            ElevatedButton.icon(onPressed: () => _showAddPropertyDialog(storeAsSecretDefault: true), icon: const Icon(Icons.enhanced_encryption_rounded, size: 18), label: const Text('Add Secret')),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertiesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('System Properties', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _showAddPropertyDialog, tooltip: 'Add Property'),
              ],
            ),
            const Divider(),
            FutureBuilder<List<TenantProperty>>(
              future: _propertiesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(padding: EdgeInsets.only(top: 20), child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return Text('Error loading properties: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                }
                final properties = snapshot.data ?? [];
                if (properties.isEmpty) {
                  return const Text('No properties configured for this tenant.');
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: properties.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) => _buildPropertyTile(properties[index]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history_rounded, size: 20),
                SizedBox(width: 8),
                Text('Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            FutureBuilder<List<TenantActivityLog>>(
              future: _activityFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Failed to load activity: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Text('No tenant activity recorded yet.');
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_note_rounded, size: 20),
                      title: Text(item.message),
                      subtitle: Text('${item.category} • ${item.action} • ${item.actor} • ${item.createdAt ?? ''}'),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPropertyTile(TenantProperty property) {
    final canCopy = property.value != null && property.value!.isNotEmpty;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(property.property, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'monospace')),
          if (property.secretReference) _buildTag('Secret Manager', Icons.verified_user_rounded, Colors.green),
          if (property.sensitive && !property.secretReference) _buildTag('Sensitive', Icons.visibility_off_rounded, Colors.orange),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(property.displayValue, style: const TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.copy, size: 20),
        onPressed: canCopy
            ? () {
                Clipboard.setData(ClipboardData(text: property.value!));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied ${property.property} to clipboard')));
              }
            : null,
        tooltip: canCopy ? 'Copy Value' : 'Raw sensitive value hidden',
      ),
    );
  }

  Widget _buildTag(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey))),
          Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color))),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'SUSPENDED':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  void _showEditTenantDialog() {
    final nameController = TextEditingController(text: _tenant.name);
    final hostController = TextEditingController(text: _tenant.host);
    final urlController = TextEditingController(text: _tenant.erpAppUrl ?? _tenant.url ?? '');
    String status = _tenant.status;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Tenant'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 12),
                TextField(controller: hostController, decoration: const InputDecoration(labelText: 'Host')),
                const SizedBox(height: 12),
                TextField(controller: urlController, decoration: const InputDecoration(labelText: 'Tenant ERP App URL')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: ['ACTIVE', 'INACTIVE', 'SUSPENDED'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                  onChanged: isSaving ? null : (value) => setDialogState(() => status = value ?? 'ACTIVE'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      try {
                        final updated = await _tenantService.updateTenant(
                          _tenant.id,
                          Tenant(
                            id: _tenant.id,
                            name: nameController.text.trim(),
                            host: hostController.text.trim(),
                            url: urlController.text.trim(),
                            erpAppUrl: urlController.text.trim(),
                            status: status,
                          ),
                        );
                        if (!mounted) return;
                        setState(() => _tenant = updated);
                        Navigator.pop(context);
                        _refreshAll();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red));
                        setDialogState(() => isSaving = false);
                      }
                    },
              child: isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(String status) async {
    try {
      final updated = await _tenantService.updateTenantStatus(_tenant.id, status);
      if (!mounted) return;
      setState(() => _tenant = updated);
      _refreshAll();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tenant marked $status')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status update failed: $e'), backgroundColor: Colors.red));
    }
  }

  void _showSubscriptionDialog() async {
    final plans = await _plansFuture;
    final current = await _subscriptionFuture;
    String? selectedPlan = current?.planCode ?? (plans.isNotEmpty ? plans.first.code : null);
    if (selectedPlan != null && !plans.any((plan) => plan.code == selectedPlan)) {
      selectedPlan = plans.isNotEmpty ? plans.first.code : null;
    }
    String status = current?.status ?? 'TRIAL';
    String billingCycle = current?.billingCycle ?? 'MONTHLY';
    final nextBillingController = TextEditingController(text: current?.nextBillingDate ?? '');
    final notesController = TextEditingController(text: current?.notes ?? '');
    bool isSaving = false;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Assign Subscription'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedPlan,
                  decoration: const InputDecoration(labelText: 'Plan'),
                  items: plans.map((plan) => DropdownMenuItem(value: plan.code, child: Text('${plan.name} (${plan.code})'))).toList(),
                  onChanged: isSaving ? null : (value) => setDialogState(() => selectedPlan = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Subscription Status'),
                  items: ['TRIAL', 'ACTIVE', 'PAST_DUE', 'SUSPENDED', 'CANCELLED'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                  onChanged: isSaving ? null : (value) => setDialogState(() => status = value ?? 'ACTIVE'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: billingCycle,
                  decoration: const InputDecoration(labelText: 'Billing Cycle'),
                  items: ['MONTHLY', 'ANNUAL', 'ONCE_OFF'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                  onChanged: isSaving ? null : (value) => setDialogState(() => billingCycle = value ?? 'MONTHLY'),
                ),
                const SizedBox(height: 12),
                TextField(controller: nextBillingController, decoration: const InputDecoration(labelText: 'Next Billing Date', hintText: 'YYYY-MM-DD')),
                const SizedBox(height: 12),
                TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (selectedPlan == null || selectedPlan!.isEmpty) return;
                      setDialogState(() => isSaving = true);
                      try {
                        await _tenantService.saveTenantSubscription(
                          _tenant.id,
                          TenantSubscription(
                            id: current?.id,
                            planCode: selectedPlan!,
                            status: status,
                            billingCycle: billingCycle,
                            currency: 'ZAR',
                            nextBillingDate: nextBillingController.text.trim().isEmpty ? null : nextBillingController.text.trim(),
                            notes: notesController.text.trim(),
                          ),
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                        _refreshAll();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Subscription update failed: $e'), backgroundColor: Colors.red));
                        setDialogState(() => isSaving = false);
                      }
                    },
              child: isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPropertyDialog({bool storeAsSecretDefault = false}) {
    final propertyController = TextEditingController();
    final valueController = TextEditingController();
    final secretNameController = TextEditingController();
    bool isSaving = false;
    bool storeAsSecret = storeAsSecretDefault;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(storeAsSecret ? 'Add Secret Property' : 'Add Tenant Property'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Store value in Google Secret Manager'),
                    subtitle: const Text('Only the generated secret reference is stored against the tenant.'),
                    value: storeAsSecret,
                    onChanged: isSaving ? null : (value) => setDialogState(() => storeAsSecret = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: propertyController, decoration: const InputDecoration(labelText: 'Property Name', hintText: 'e.g. XERO-SECRET-KEY'), textCapitalization: TextCapitalization.characters),
                  const SizedBox(height: 16),
                  TextField(controller: valueController, decoration: InputDecoration(labelText: storeAsSecret ? 'Secret Value' : 'Value'), obscureText: storeAsSecret, maxLines: storeAsSecret ? 1 : 3, minLines: 1),
                  if (storeAsSecret) ...[
                    const SizedBox(height: 16),
                    TextField(controller: secretNameController, decoration: const InputDecoration(labelText: 'Secret Name (Optional)', hintText: 'Leave blank to auto-generate')),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final propertyName = propertyController.text.trim();
                      final rawValue = valueController.text;
                      final propertyValue = storeAsSecret ? rawValue : rawValue.trim();
                      if (propertyName.isEmpty || propertyValue.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Property name and value are required')));
                        return;
                      }
                      setDialogState(() => isSaving = true);
                      try {
                        await _tenantService.addTenantProperty(
                          TenantPropertyRequest(
                            tenant: _tenant.id,
                            property: propertyName,
                            value: propertyValue,
                            storeAsSecret: storeAsSecret,
                            secretName: secretNameController.text.trim().isEmpty ? null : secretNameController.text.trim(),
                          ),
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          _refreshAll();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(storeAsSecret ? 'Secret saved and property reference added' : 'Property added successfully')));
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                        setDialogState(() => isSaving = false);
                      }
                    },
              child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(storeAsSecret ? 'Save Secret' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _saveSchedule(TenantSchedule schedule) async {
    try {
      await _tenantService.saveTenantSchedule(_tenant.id, schedule);
      if (!mounted) return;
      _refreshAll();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedule updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Schedule update failed: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _runScheduleNow(TenantSchedule schedule) async {
    try {
      await _tenantService.runTenantScheduleNow(_tenant.id, schedule.jobCode);
      if (!mounted) return;
      _refreshAll();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(schedule.manualOnly ? 'Once-off migration completed' : 'Scheduled job triggered')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Run failed: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _syncErpConfiguration() async {
    try {
      await _tenantService.syncTenantErp(_tenant.id);
      if (!mounted) return;
      _refreshAll();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ERP configuration sync requested')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ERP sync failed: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _syncTenantModules() async {
    try {
      await _tenantService.syncTenantModules(_tenant.id);
      if (!mounted) return;
      _refreshAll();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ERP module sync requested')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Module sync failed: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _openTenantErp() async {
    try {
      final handoff = await _tenantService.openTenantErp(_tenant.id);
      final launched = await openExternalUrl(handoff.targetUrl);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open ERP URL: ${handoff.targetUrl}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open ERP failed: $e'), backgroundColor: Colors.red));
    }
  }
}
