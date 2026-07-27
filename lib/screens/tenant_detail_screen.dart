import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/external_url_opener.dart';
import '../models/tenant.dart';
import '../services/tenant_service.dart';
import '../models/tenant_property.dart';
import '../models/platform_management.dart';
import '../models/industry_profile.dart';

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
  late Future<Map<String, dynamic>> _printingFuture;
  late Future<TenantIndustryProfile> _industryProfileFuture;
  late Future<List<IndustryProfile>> _industryCatalogueFuture;
  int _selectedSection = 0;
  final TextEditingController _propertySearchController = TextEditingController();
  final TextEditingController _activitySearchController = TextEditingController();
  String _activityCategory = 'ALL';

  static const List<_TenantSection> _sections = [
    _TenantSection('Overview', Icons.dashboard_outlined),
    _TenantSection('Industry & Experience', Icons.domain_outlined),
    _TenantSection('Subscription & Modules', Icons.extension_outlined),
    _TenantSection('Integration', Icons.hub_outlined),
    _TenantSection('Data & Security', Icons.admin_panel_settings_outlined),
    _TenantSection('Activity', Icons.history_outlined),
    _TenantSection('POS Printing', Icons.point_of_sale_outlined),
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
      _printingFuture = _tenantService.getTenantPosPrinting(_tenant.id);
      _industryProfileFuture = _tenantService.getTenantIndustryProfile(_tenant.id);
      _industryCatalogueFuture = _tenantService.getIndustryProfiles();
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
        return _buildSectionScroll([_buildIndustryExperienceCard()]);
      case 2:
        return _buildSectionScroll([
          _buildSubscriptionCard(),
          _buildModuleManagementCard(),
        ]);
      case 3:
        return _buildSectionScroll([
          _buildErpIntegrationCard(),
          _buildSecretManagerCard(),
        ]);
      case 4:
        return _buildSectionScroll([
          _buildDataMaintenanceCard(),
          _buildPropertiesCard(),
        ]);
      case 5:
        return _buildSectionScroll([_buildActivityCard()]);
      case 6:
        return _buildSectionScroll([_buildPosPrintingCard()]);
      default:
        return _buildSectionScroll([
          _buildInfoCard(),
          _buildIndustryExperienceCard(compact: true),
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

  Widget _buildIndustryExperienceCard({bool compact = false}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<TenantIndustryProfile>(
          future: _industryProfileFuture,
          builder: (context, snapshot) {
            final header = Row(
              children: [
                Icon(Icons.domain_rounded, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Industry & Tenant Experience',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: snapshot.hasData ? () => _showIndustryProfileDialog(snapshot.data!) : null,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Configure'),
                ),
              ],
            );
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [header, const Divider(), const LinearProgressIndicator()]);
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  const Divider(),
                  Text('Failed to load industry profile: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                ],
              );
            }
            final profile = snapshot.data!;
            final experience = profile.experience;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const Divider(),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildMiniMetric('Primary industry', profile.primaryIndustry.name),
                    _buildMiniMetric(
                      'Additional industries',
                      profile.additionalIndustries.isEmpty
                          ? 'None'
                          : profile.additionalIndustries.map((item) => item.name).join(', '),
                    ),
                    _buildMiniMetric(
                      'Homepage groups',
                      experience.sections.fold<int>(0, (total, section) => total + section.groups.length).toString(),
                    ),
                  ],
                ),
                if (!compact) ...[
                  const SizedBox(height: 18),
                  Text('ERP homepage preview', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Only workcenters assigned to each user role will be shown. Industry profiles control presentation, terminology and grouping; they do not delete business data.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  ...experience.sections.map((section) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(section.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (section.description.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(section.description, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: section.groups
                                  .map((group) => Chip(
                                        avatar: const Icon(Icons.apps_rounded, size: 16),
                                        label: Text('${group.title} (${group.workcenters.length})'),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showIndustryProfileDialog(TenantIndustryProfile current) async {
    late final List<IndustryProfile> allProfiles;
    try {
      allProfiles = await _industryCatalogueFuture;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Industry profiles could not be loaded: $error'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!mounted) return;
    final assignedCodes = <String>{
      current.primaryIndustry.code,
      ...current.additionalIndustries.map((item) => item.code),
    };
    final catalogue = allProfiles
        .where((item) => item.status.toUpperCase() == 'ACTIVE' || assignedCodes.contains(item.code))
        .toList();
    if (catalogue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No industry profiles are available.')),
      );
      return;
    }
    var primaryCode = catalogue.any((item) => item.code == current.primaryIndustry.code)
        ? current.primaryIndustry.code
        : catalogue.first.code;
    final additionalCodes = current.additionalIndustries.map((item) => item.code).toSet();
    var saving = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final availableAdditional = catalogue.where((item) => item.code != primaryCode).toList();
          return AlertDialog(
            title: const Text('Configure Tenant Industries'),
            content: SizedBox(
              width: 720,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'The primary industry controls the tenant’s default terminology and highest-priority workcenters. Additional industries merge their relevant workcenters into the same experience.',
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      value: primaryCode,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Primary industry'),
                      items: catalogue
                          .map((item) => DropdownMenuItem(value: item.code, child: Text(item.name)))
                          .toList(),
                      onChanged: saving
                          ? null
                          : (value) => setDialogState(() {
                                primaryCode = value ?? primaryCode;
                                additionalCodes.remove(primaryCode);
                              }),
                    ),
                    const SizedBox(height: 18),
                    Text('Additional industries', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableAdditional
                          .map((item) => FilterChip(
                                label: Text(item.name),
                                selected: additionalCodes.contains(item.code),
                                onSelected: saving
                                    ? null
                                    : (selected) => setDialogState(() {
                                          if (selected) {
                                            additionalCodes.add(item.code);
                                          } else {
                                            additionalCodes.remove(item.code);
                                          }
                                        }),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
              FilledButton.icon(
                onPressed: saving
                    ? null
                    : () async {
                        setDialogState(() => saving = true);
                        try {
                          await _tenantService.saveTenantIndustryProfile(
                            _tenant.id,
                            primaryIndustryCode: primaryCode,
                            additionalIndustryCodes: additionalCodes.toList(),
                          );
                          if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                        } catch (error) {
                          setDialogState(() => saving = false);
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text('Industry profile could not be saved: $error'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                icon: saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_rounded),
                label: const Text('Save Industries'),
              ),
            ],
          );
        },
      ),
    );
    if (saved == true && mounted) {
      _refreshAll();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tenant industry experience updated. ERP users will see it after configuration refresh.')),
      );
    }
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


  Widget _buildPosPrintingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.point_of_sale_outlined, color: Colors.deepOrange.shade700),
                const SizedBox(width: 8),
                const Expanded(child: Text('POS Print Agents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                OutlinedButton.icon(onPressed: _showCreatePrintAgentCodeDialog, icon: const Icon(Icons.add_link), label: const Text('Setup code')),
                const SizedBox(width: 8),
                IconButton(onPressed: _refreshAll, icon: const Icon(Icons.refresh)),
              ],
            ),
            const Divider(),
            FutureBuilder<Map<String, dynamic>>(
              future: _printingFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
                if (snapshot.hasError) return Text('Failed to load POS printing: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                final data = snapshot.data ?? const {};
                final agents = (data['agents'] as List?) ?? const [];
                final terminals = (data['terminals'] as List?) ?? const [];
                final jobs = (data['jobs'] as List?) ?? const [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(spacing: 12, runSpacing: 8, children: [
                      _buildMiniMetric('Agents', agents.length.toString()),
                      _buildMiniMetric('Online', agents.where((a) => a is Map && a['online'] == true).length.toString()),
                      _buildMiniMetric('Terminals', terminals.length.toString()),
                      _buildMiniMetric('Recent Jobs', jobs.length.toString()),
                      _buildMiniMetric('Failed', jobs.where((j) => j is Map && j['status'] == 'FAILED').length.toString()),
                    ]),
                    const SizedBox(height: 16),
                    if (agents.isEmpty) const Text('No Windows print agents are enrolled for this tenant.'),
                    ...agents.whereType<Map>().map((raw) {
                      final agent = Map<String, dynamic>.from(raw);
                      final printers = (agent['printers'] as List?) ?? const [];
                      return ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        leading: Icon(
                          agent['online'] == true ? Icons.computer : Icons.computer_outlined,
                          color: agent['online'] == true ? Colors.green : Colors.orange,
                        ),
                        title: Text((agent['name'] ?? 'Unnamed agent').toString()),
                        subtitle: Text('${agent['machineName'] ?? ''} • ${agent['location'] ?? ''} • ${printers.length} printer(s)\n${agent['online'] == true ? 'Online' : 'Offline'} • Heartbeat: ${agent['lastHeartbeatAt'] ?? 'never'}'),
                        children: [
                          ...printers.whereType<Map>().map((p) => ListTile(
                            dense: true,
                            leading: Icon(Icons.print_outlined, color: p['status'] == 'ONLINE' ? Colors.green : Colors.grey),
                            title: Text((p['displayName'] ?? p['windowsQueueName'] ?? '').toString()),
                            subtitle: Text('${p['status'] ?? ''} • ${p['windowsQueueName'] ?? ''}'),
                          )),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: agent['status'] == 'ACTIVE' ? () => _revokePrintAgent(agent['id'].toString()) : null,
                              icon: const Icon(Icons.block),
                              label: const Text('Revoke agent'),
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 16),
                    Text('ERP terminals', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    if (terminals.isEmpty) const Text('No ERP browser terminals have registered.'),
                    ...terminals.whereType<Map>().map((raw) {
                      final terminal = Map<String, dynamic>.from(raw);
                      final enabled = terminal['enabled'] != false;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.desktop_windows_outlined, color: enabled ? Colors.green : Colors.grey),
                        title: Text((terminal['displayName'] ?? 'Unnamed terminal').toString()),
                        subtitle: Text("${terminal['location'] ?? ''} • agent ${terminal['agentId'] ?? 'not assigned'}\nprinter ${terminal['defaultReceiptPrinterId'] ?? 'not assigned'}"),
                        isThreeLine: true,
                        trailing: Switch(
                          value: enabled,
                          onChanged: (value) => _setPrintTerminalEnabled(terminal['id'].toString(), value),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    Text('Recent print jobs', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    if (jobs.isEmpty) const Text('No print jobs have been created.'),
                    ...jobs.take(20).whereType<Map>().map((raw) {
                      final job = Map<String, dynamic>.from(raw);
                      final failed = job['status'] == 'FAILED';
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(failed ? Icons.error_outline : Icons.receipt_long_outlined, color: failed ? Colors.red : Colors.blueGrey),
                        title: Text('${job['sourceType'] ?? ''} • ${job['sourceId'] ?? ''}'),
                        subtitle: Text('${job['status'] ?? ''} • attempts ${job['attemptCount'] ?? 0}\n${job['lastError'] ?? job['createdAt'] ?? ''}'),
                        isThreeLine: true,
                        trailing: failed ? IconButton(icon: const Icon(Icons.replay), tooltip: 'Retry', onPressed: () => _retryPrintJob(job['id'].toString())) : null,
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreatePrintAgentCodeDialog() async {
    final name = TextEditingController();
    final location = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Windows agent setup code'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Agent name', hintText: 'Front Desk PC')),
          const SizedBox(height: 12),
          TextField(controller: location, decoration: const InputDecoration(labelText: 'Location')),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create'))],
      ),
    );
    if (confirmed != true) return;
    try {
      final result = await _tenantService.createPosPrintEnrollment(_tenant.id, agentName: name.text, location: location.text);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enrollment code'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Use this one-time code during installation on the Windows POS computer.'),
            const SizedBox(height: 16),
            SelectableText((result['code'] ?? '').toString(), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 4)),
            const SizedBox(height: 8),
            Text('Expires: ${result['expiresAt'] ?? ''}'),
          ]),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
        ),
      );
      _refreshAll();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _revokePrintAgent(String agentId) async {
    try { await _tenantService.revokePosPrintAgent(_tenant.id, agentId); _refreshAll(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red)); }
  }

  Future<void> _setPrintTerminalEnabled(String terminalId, bool enabled) async {
    try {
      await _tenantService.setPosTerminalEnabled(_tenant.id, terminalId, enabled);
      _refreshAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _retryPrintJob(String jobId) async {
    try { await _tenantService.retryPosPrintJob(_tenant.id, jobId); _refreshAll(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red)); }
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
                            primaryIndustryCode: _tenant.primaryIndustryCode,
                            additionalIndustryCodes: _tenant.additionalIndustryCodes,
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
    Timer? secretNameDebounce;
    bool isSaving = false;
    bool storeAsSecret = storeAsSecretDefault;
    bool isLoadingSecretName = false;
    bool dialogOpen = true;
    String generatedSecretName = '';
    int secretNameRequest = 0;

    void refreshGeneratedSecretName(StateSetter setDialogState) {
      secretNameDebounce?.cancel();
      final property = propertyController.text.trim();
      if (!storeAsSecret || property.isEmpty) {
        setDialogState(() {
          generatedSecretName = '';
          isLoadingSecretName = false;
        });
        return;
      }

      final requestId = ++secretNameRequest;
      setDialogState(() => isLoadingSecretName = true);
      secretNameDebounce = Timer(const Duration(milliseconds: 300), () async {
        try {
          final name = await _tenantService.getGeneratedTenantSecretName(_tenant.id, property);
          if (!dialogOpen || requestId != secretNameRequest) return;
          setDialogState(() {
            generatedSecretName = name;
            isLoadingSecretName = false;
          });
        } catch (_) {
          if (!dialogOpen || requestId != secretNameRequest) return;
          setDialogState(() {
            generatedSecretName = '';
            isLoadingSecretName = false;
          });
        }
      });
    }

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
                    onChanged: isSaving
                        ? null
                        : (value) {
                            setDialogState(() => storeAsSecret = value);
                            refreshGeneratedSecretName(setDialogState);
                          },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: propertyController,
                    decoration: const InputDecoration(labelText: 'Property Name', hintText: 'e.g. XERO-SECRET-KEY'),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => refreshGeneratedSecretName(setDialogState),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: valueController,
                    decoration: InputDecoration(labelText: storeAsSecret ? 'Secret Value' : 'Value'),
                    obscureText: storeAsSecret,
                    maxLines: storeAsSecret ? 1 : 3,
                    minLines: 1,
                  ),
                  if (storeAsSecret) ...[
                    const SizedBox(height: 16),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Generated GCP Secret Name',
                        helperText: 'Generated from the environment, tenant host and property. This name cannot be changed.',
                        border: OutlineInputBorder(),
                      ),
                      child: isLoadingSecretName
                          ? const LinearProgressIndicator()
                          : SelectableText(
                              generatedSecretName.isEmpty ? 'Enter a property name to generate the secret name' : generatedSecretName,
                            ),
                    ),
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
                          ),
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          _refreshAll();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(storeAsSecret ? 'Secret saved and property reference added' : 'Property added successfully')));
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                        if (dialogOpen) setDialogState(() => isSaving = false);
                      }
                    },
              child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(storeAsSecret ? 'Save Secret' : 'Add'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      dialogOpen = false;
      secretNameDebounce?.cancel();
      propertyController.dispose();
      valueController.dispose();
    });
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
      for (var batchNumber = 1; batchNumber <= 100000; batchNumber++) {
        progress.value =
            'Processing batch $batchNumber... '
            '$totalMigrated attachment(s) migrated so far.';

        TenantSchedule? result;
        Object? lastError;
        for (var attempt = 1; attempt <= 3; attempt++) {
          try {
            final batchLimit = attempt == 1 ? 5 : (attempt == 2 ? 2 : 1);
            result = await _tenantService.runTenantScheduleNow(
              _tenant.id,
              schedule.jobCode,
              afterId: cursor,
              limit: batchLimit,
            );
            lastError = null;
            break;
          } catch (error) {
            lastError = error;
            progress.value =
                'Batch $batchNumber attempt $attempt failed. Retrying with a smaller '
                'restart-safe batch...';
            if (attempt < 3) {
              await Future<void>.delayed(Duration(seconds: attempt * 2));
            }
          }
        }
        if (lastError != null) throw lastError;
        final batchResult = result;
        if (batchResult == null) {
          throw Exception('Attachment migration batch returned no result.');
        }

        totalAttempted += batchResult.migrationAttempted;
        totalMigrated += batchResult.migrationMigrated;
        totalFailed += batchResult.migrationFailed;
        remaining = batchResult.migrationRemaining;
        failures = batchResult.migrationFailures;
        scanComplete = batchResult.migrationScanComplete;
        migrationCompleted = batchResult.migrationCompleted;

        progress.value =
            '$totalMigrated attachment(s) migrated; '
            '$remaining legacy attachment(s) remaining; '
            '$totalFailed failed.';

        if (migrationCompleted || scanComplete) {
          break;
        }

        final nextCursor = batchResult.migrationNextCursor?.trim();
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
          'Migration stopped after the safety limit of 100000 batches. '
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
    final accessReasonController = TextEditingController();
    final ticketController = TextEditingController();
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Open tenant ERP'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This creates a short-lived, fully audited platform administration session for this tenant.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: accessReasonController,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Access reason',
                  hintText: 'Describe the support, configuration, or verification work',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ticketController,
                decoration: const InputDecoration(
                  labelText: 'Ticket/reference (optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (accessReasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Access reason is required.')),
                );
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Open ERP'),
          ),
        ],
      ),
    );
    if (approved != true) return;

    final reservedWindow = reserveExternalWindow();
    try {
      final handoff = await _tenantService.openTenantErp(
        _tenant.id,
        accessReason: accessReasonController.text.trim(),
        ticketReference: ticketController.text.trim().isEmpty
            ? null
            : ticketController.text.trim(),
      );
      if (handoff.targetUrl.trim().isEmpty) {
        throw Exception('The backend did not return an ERP handoff URL.');
      }
      final launched = await navigateExternalWindow(reservedWindow, handoff.targetUrl);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open ERP URL: ${handoff.targetUrl}')),
        );
      }
    } catch (e) {
      closeExternalWindow(reservedWindow);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Open ERP failed: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

class _TenantSection {
  final String label;
  final IconData icon;

  const _TenantSection(this.label, this.icon);
}
