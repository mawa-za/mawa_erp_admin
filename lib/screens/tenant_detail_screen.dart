import 'dart:async';
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
  int _selectedSection = 0;
  final TextEditingController _propertySearchController = TextEditingController();
  final TextEditingController _activitySearchController = TextEditingController();
  String _activityCategory = 'ALL';

  static const List<_TenantSection> _sections = [
    _TenantSection('Overview', Icons.dashboard_outlined),
    _TenantSection('Subscription & Modules', Icons.extension_outlined),
    _TenantSection('Integration', Icons.hub_outlined),
    _TenantSection('Data & Security', Icons.admin_panel_settings_outlined),
    _TenantSection('Activity', Icons.history_outlined),
  ];

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
  void dispose() {
    _propertySearchController.dispose();
    _activitySearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      appBar: AppBar(
        title: Text(_tenant.name),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshAll),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wide) _buildNavigationRail(),
          Expanded(
            child: Column(
              children: [
                if (!wide) _buildCompactNavigation(),
                Expanded(child: _buildSelectedSection()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail() {
    return Container(
      width: 248,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              'Tenant Configuration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(_sections.length, (index) {
            final section = _sections[index];
            final selected = _selectedSection == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                selected: selected,
                selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Icon(section.icon),
                title: Text(section.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                onTap: () => setState(() => _selectedSection = index),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCompactNavigation() {
    return Container(
      height: 58,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _sections.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final section = _sections[index];
          return ChoiceChip(
            avatar: Icon(section.icon, size: 18),
            label: Text(section.label),
            selected: _selectedSection == index,
            showCheckmark: false,
            onSelected: (_) => setState(() => _selectedSection = index),
          );
        },
      ),
    );
  }

  Widget _buildSelectedSection() {
    switch (_selectedSection) {
      case 1:
        return _buildSectionScroll([
          _buildSubscriptionCard(),
          _buildModuleManagementCard(),
        ]);
      case 2:
        return _buildSectionScroll([
          _buildErpIntegrationCard(),
          _buildSecretManagerCard(),
        ]);
      case 3:
        return _buildSectionScroll([
          _buildDataMaintenanceCard(),
          _buildPropertiesCard(),
        ]);
      case 4:
        return _buildSectionScroll([_buildActivityCard()]);
      default:
        return _buildSectionScroll([
          _buildInfoCard(),
          _buildErpIntegrationCard(),
        ]);
    }
  }

  Widget _buildSectionScroll(List<Widget> children) {
    return RefreshIndicator(
      onRefresh: () async => _refreshAll(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: children.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) => index == children.length
            ? const SizedBox(height: 24)
            : children[index],
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


  Widget _buildDataMaintenanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_sync_outlined, color: Colors.deepOrange.shade700),
                const SizedBox(width: 8),
                const Expanded(child: Text('Data Maintenance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _refreshAll),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Run controlled, once-off tenant maintenance operations. Recurring scheduled-job configuration is managed by the platform and is intentionally hidden here.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
            const Divider(height: 24),
            FutureBuilder<List<TenantSchedule>>(
              future: _schedulesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Failed to load maintenance operations: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                }
                final manualJobs = (snapshot.data ?? [])
                    .where((schedule) => schedule.manualOnly || schedule.jobCode == 'ATTACHMENT_GCS_MIGRATION')
                    .toList();
                if (manualJobs.isEmpty) {
                  return const Text('No once-off maintenance operations are available.');
                }
                return Column(children: manualJobs.map(_buildScheduleTile).toList());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTile(TenantSchedule schedule) {
    final intervalController = TextEditingController(
      text: schedule.intervalMinutes.toString(),
    );
    final manual = schedule.manualOnly;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        color: manual
            ? Colors.blue.shade50
            : (schedule.enabled ? Colors.green.shade50 : Colors.grey.shade50),
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            schedule.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (manual) ...[
                          const SizedBox(width: 8),
                          const Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text('ONCE-OFF'),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      schedule.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              if (!manual)
                Switch(
                  value: schedule.enabled,
                  onChanged: (value) =>
                      _saveSchedule(schedule.copyWith(enabled: value)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (manual)
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => _runScheduleNow(schedule),
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: const Text('Run once'),
                ),
                Text(
                  'Requires MAWA_ATTACHMENT_BUCKET and GCS write permission.',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 180,
                  child: TextFormField(
                    controller: intervalController,
                    decoration: const InputDecoration(
                      labelText: 'Interval minutes',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _saveSchedule(
                    schedule.copyWith(
                      intervalMinutes: int.tryParse(intervalController.text) ??
                          schedule.intervalMinutes,
                    ),
                  ),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _runScheduleNow(schedule),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Run now'),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(
                'Last: ${schedule.lastRunAt ?? 'Never'}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              if (!manual)
                Text(
                  'Next: ${schedule.nextRunAt ?? 'Stopped'}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              if ((schedule.lastRunResult ?? '').isNotEmpty)
                Text(
                  'Result: ${schedule.lastRunResult}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
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
            const SizedBox(height: 8),
            TextField(
              controller: _propertySearchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search properties, values or secret references',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<TenantProperty>>(
              future: _propertiesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(padding: EdgeInsets.only(top: 20), child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return Text('Error loading properties: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                }
                final query = _propertySearchController.text.trim().toLowerCase();
                final properties = (snapshot.data ?? []).where((property) {
                  if (query.isEmpty) return true;
                  return property.property.toLowerCase().contains(query) ||
                      property.displayValue.toLowerCase().contains(query);
                }).toList()
                  ..sort((a, b) => a.property.compareTo(b.property));
                if (properties.isEmpty) {
                  return Text(query.isEmpty ? 'No properties configured for this tenant.' : 'No matching properties.');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${properties.length} properties', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 430,
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: ListView.separated(
                          itemCount: properties.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) => _buildPropertyTile(properties[index]),
                        ),
                      ),
                    ),
                  ],
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _activitySearchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search activity',
                      prefixIcon: Icon(Icons.search_rounded),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    value: _activityCategory,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Category', isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('All categories')),
                      DropdownMenuItem(value: 'TENANT', child: Text('Tenant')),
                      DropdownMenuItem(value: 'MODULE', child: Text('Module')),
                      DropdownMenuItem(value: 'PROPERTY', child: Text('Property')),
                      DropdownMenuItem(value: 'SUBSCRIPTION', child: Text('Subscription')),
                      DropdownMenuItem(value: 'SCHEDULE', child: Text('Maintenance')),
                    ],
                    onChanged: (value) => setState(() => _activityCategory = value ?? 'ALL'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<TenantActivityLog>>(
              future: _activityFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Failed to load activity: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                }
                final query = _activitySearchController.text.trim().toLowerCase();
                final items = (snapshot.data ?? []).where((item) {
                  final categoryMatches = _activityCategory == 'ALL' || item.category.toUpperCase().contains(_activityCategory);
                  final searchMatches = query.isEmpty ||
                      item.message.toLowerCase().contains(query) ||
                      item.action.toLowerCase().contains(query) ||
                      item.actor.toLowerCase().contains(query);
                  return categoryMatches && searchMatches;
                }).toList()
                  ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
                if (items.isEmpty) {
                  return const Text('No matching tenant activity.');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Showing ${items.length} events, latest first', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 500,
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                              leading: const Icon(Icons.event_note_rounded, size: 20),
                              title: Text(item.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                              subtitle: Text('${item.category} • ${item.action} • ${item.actor} • ${item.createdAt ?? ''}'),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
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
    if (schedule.manualOnly) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Run attachment migration?'),
          content: const Text(
            'This will move legacy attachment bytes from the tenant database '
            'to Google Cloud Storage and clear the database file column only '
            'after each upload succeeds. The operation is idempotent and may '
            'take several minutes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Run once'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    if (schedule.jobCode == 'ATTACHMENT_GCS_MIGRATION') {
      await _runAttachmentMigration(schedule);
      return;
    }

    try {
      final result = await _tenantService.runTenantScheduleNow(
        _tenant.id,
        schedule.jobCode,
      );
      if (!mounted) return;
      _refreshAll();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.lastRunResult?.isNotEmpty == true
                ? result.lastRunResult!
                : 'Job completed',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Run failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _runAttachmentMigration(TenantSchedule schedule) async {
    final progress = ValueNotifier<String>('Preparing attachment migration...');
    var dialogOpen = true;

    final dialogFuture = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Migrating attachments'),
        content: SizedBox(
          width: 420,
          child: ValueListenableBuilder<String>(
            valueListenable: progress,
            builder: (context, message, child) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
                Text(message),
                const SizedBox(height: 8),
                const Text(
                  'Keep this window open. The migration runs in bounded, '
                  'restart-safe batches.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    unawaited(dialogFuture);
    await Future<void>.delayed(Duration.zero);

    String? cursor;
    int totalAttempted = 0;
    int totalMigrated = 0;
    int totalFailed = 0;
    int remaining = 0;
    List<String> failures = const [];
    var scanComplete = false;
    var migrationCompleted = false;

    try {
      for (var batchNumber = 1; batchNumber <= 1000; batchNumber++) {
        progress.value =
            'Processing batch $batchNumber... '
            '$totalMigrated attachment(s) migrated so far.';

        final result = await _tenantService.runTenantScheduleNow(
          _tenant.id,
          schedule.jobCode,
          afterId: cursor,
          limit: 25,
        );

        totalAttempted += result.migrationAttempted;
        totalMigrated += result.migrationMigrated;
        totalFailed += result.migrationFailed;
        remaining = result.migrationRemaining;
        failures = result.migrationFailures;
        scanComplete = result.migrationScanComplete;
        migrationCompleted = result.migrationCompleted;

        progress.value =
            '$totalMigrated attachment(s) migrated; '
            '$remaining legacy attachment(s) remaining; '
            '$totalFailed failed.';

        if (migrationCompleted || scanComplete) {
          break;
        }

        final nextCursor = result.migrationNextCursor?.trim();
        if (nextCursor == null ||
            nextCursor.isEmpty ||
            nextCursor == cursor) {
          throw Exception(
            'Migration did not return a valid continuation cursor.',
          );
        }
        cursor = nextCursor;
      }

      if (!migrationCompleted && !scanComplete) {
        throw Exception(
          'Migration stopped after the safety limit of 1000 batches. '
          'Run it again to continue.',
        );
      }

      if (dialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }
      await dialogFuture;
      if (!mounted) return;

      _refreshAll();
      final summary = StringBuffer()
        ..write('$totalMigrated attachment(s) migrated')
        ..write('; $remaining legacy attachment(s) remaining')
        ..write('; $totalFailed failed')
        ..write('; $totalAttempted attempted');
      if (failures.isNotEmpty) {
        summary.write('. First failure: ${failures.first}');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(summary.toString()),
          backgroundColor:
              remaining == 0 && totalFailed == 0 ? null : Colors.orange,
          duration: const Duration(seconds: 12),
        ),
      );
    } catch (e) {
      if (dialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }
      await dialogFuture;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attachment migration failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 12),
        ),
      );
    } finally {
      progress.dispose();
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
    final reservedWindow = reserveExternalWindow();
    try {
      final handoff = await _tenantService.openTenantErp(_tenant.id);
      if (handoff.targetUrl.trim().isEmpty) {
        throw Exception('The backend did not return an ERP handoff URL.');
      }
      final launched = await navigateExternalWindow(reservedWindow, handoff.targetUrl);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open ERP URL: ${handoff.targetUrl}')));
      }
    } catch (e) {
      closeExternalWindow(reservedWindow);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open ERP failed: $e'), backgroundColor: Colors.red));
    }
  }
}

class _TenantSection {
  final String label;
  final IconData icon;

  const _TenantSection(this.label, this.icon);
}
