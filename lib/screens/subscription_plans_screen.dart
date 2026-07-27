import 'package:flutter/material.dart';
import '../models/platform_management.dart';
import '../services/tenant_service.dart';
import 'package:mawa_erp_admin/utils/app_error.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  final TenantService _tenantService = TenantService();
  late Future<List<SubscriptionPlan>> _plansFuture;
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _plansFuture = _tenantService.getSubscriptionPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _refresh),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<SubscriptionPlan>>(
        future: _plansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(friendlyErrorMessage('Failed to load plans: ${snapshot.error}')));
          }
          final allPlans = List<SubscriptionPlan>.from(snapshot.data ?? const [])
            ..sort((a, b) {
              final aDate = DateTime.tryParse(a.createdAt ?? '');
              final bDate = DateTime.tryParse(b.createdAt ?? '');
              final dateCompare = (bDate?.millisecondsSinceEpoch ?? 0)
                  .compareTo(aDate?.millisecondsSinceEpoch ?? 0);
              if (dateCompare != 0) return dateCompare;
              return b.code.compareTo(a.code);
            });
          if (allPlans.isEmpty) {
            return const Center(child: Text('No subscription plans configured.'));
          }
          final statuses = allPlans
              .map((plan) => plan.status.toUpperCase())
              .toSet()
              .toList()
            ..sort();
          final plans = _selectedStatus == 'ALL'
              ? allPlans
              : allPlans
                  .where((plan) => plan.status.toUpperCase() == _selectedStatus)
                  .toList();
          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: ['ALL', ...statuses].map((status) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(status == 'ALL' ? 'All statuses' : status),
                        selected: _selectedStatus == status,
                        onSelected: (_) => setState(() => _selectedStatus = status),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: plans.isEmpty
                    ? const Center(child: Text('No plans match this status.'))
                    : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: plans.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _buildPlanCard(plans[index]),
                    ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPlanDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Plan'),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isActive = plan.status == 'ACTIVE';
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          child: Text(plan.code.isNotEmpty ? plan.code.substring(0, 1) : '?'),
        ),
        title: Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text([
            plan.code,
            plan.description ?? '',
            'Users: ${plan.maxUsers?.toString() ?? 'Unlimited'}',
            'Branches: ${plan.maxBranches?.toString() ?? 'Unlimited'}',
            'Devices: ${plan.maxDevices?.toString() ?? 'Unlimited'}',
          ].where((text) => text.isNotEmpty).join(' • ')),
        ),
        trailing: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(
              label: Text(plan.status),
              backgroundColor: isActive ? Colors.green.shade50 : Colors.grey.shade200,
              labelStyle: TextStyle(color: isActive ? Colors.green.shade700 : Colors.grey.shade700),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => _showPlanDialog(plan: plan),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlanDialog({SubscriptionPlan? plan}) {
    final codeController = TextEditingController(text: plan?.code ?? '');
    final nameController = TextEditingController(text: plan?.name ?? '');
    final descriptionController = TextEditingController(text: plan?.description ?? '');
    final maxUsersController = TextEditingController(text: plan?.maxUsers?.toString() ?? '');
    final maxBranchesController = TextEditingController(text: plan?.maxBranches?.toString() ?? '');
    final maxDevicesController = TextEditingController(text: plan?.maxDevices?.toString() ?? '');
    final displayOrderController = TextEditingController(text: plan?.displayOrder?.toString() ?? '');
    String status = plan?.status ?? 'ACTIVE';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(plan == null ? 'New Subscription Plan' : 'Edit Subscription Plan'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeController,
                      enabled: plan == null,
                      decoration: const InputDecoration(labelText: 'Code', hintText: 'STANDARD'),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                    const SizedBox(height: 12),
                    TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: ['ACTIVE', 'INACTIVE'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                      onChanged: isSaving ? null : (value) => setDialogState(() => status = value ?? 'ACTIVE'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: maxUsersController, decoration: const InputDecoration(labelText: 'Max Users'), keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: maxBranchesController, decoration: const InputDecoration(labelText: 'Max Branches'), keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: maxDevicesController, decoration: const InputDecoration(labelText: 'Max Devices'), keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: displayOrderController, decoration: const InputDecoration(labelText: 'Display Order'), keyboardType: TextInputType.number)),
                      ],
                    ),
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
                        if (codeController.text.trim().isEmpty || nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code and name are required')));
                          return;
                        }
                        setDialogState(() => isSaving = true);
                        try {
                          await _tenantService.saveSubscriptionPlan(
                            SubscriptionPlan(
                              code: codeController.text.trim().toUpperCase(),
                              name: nameController.text.trim(),
                              description: descriptionController.text.trim(),
                              status: status,
                              currency: 'ZAR',
                              maxUsers: int.tryParse(maxUsersController.text.trim()),
                              maxBranches: int.tryParse(maxBranchesController.text.trim()),
                              maxDevices: int.tryParse(maxDevicesController.text.trim()),
                              displayOrder: int.tryParse(displayOrderController.text.trim()),
                            ),
                          );
                          if (!mounted) return;
                          Navigator.pop(context);
                          _refresh();
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage('Save failed: $e')), backgroundColor: Colors.red));
                          setDialogState(() => isSaving = false);
                        }
                      },
                child: isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
