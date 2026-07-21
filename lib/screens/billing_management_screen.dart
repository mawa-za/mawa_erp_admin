import 'package:flutter/material.dart';

import '../models/billing.dart';
import '../models/tenant.dart';
import '../services/billing_service.dart';
import '../services/tenant_service.dart';

class BillingManagementScreen extends StatefulWidget {
  const BillingManagementScreen({super.key});

  @override
  State<BillingManagementScreen> createState() => _BillingManagementScreenState();
}

class _BillingManagementScreenState extends State<BillingManagementScreen> {
  final BillingService _billing = BillingService();
  final TenantService _tenantsService = TenantService();

  late Future<BillingDashboardSummary> _dashboardFuture;
  late Future<List<BillingModule>> _modulesFuture;
  late Future<List<BillingPlan>> _plansFuture;
  late Future<List<Tenant>> _tenantsFuture;
  late Future<List<BillingInvoice>> _invoicesFuture;
  late Future<List<BillingAdjustment>> _adjustmentsFuture;
  late Future<List<BillingTaxRate>> _taxRatesFuture;
  late Future<List<BillingAuditLog>> _auditFuture;
  Future<TenantBillingSummary>? _tenantSummaryFuture;

  List<Tenant> _tenants = const [];
  String? _selectedTenantId;
  bool _migratingLegacy = false;

  @override
  void initState() {
    super.initState();
    _reloadAll();
  }

  void _reloadAll() {
    _dashboardFuture = _billing.dashboard();
    _modulesFuture = _billing.modules();
    _plansFuture = _billing.plans();
    _tenantsFuture = _tenantsService.getTenants();
    _invoicesFuture = _billing.invoices(tenantId: _selectedTenantId);
    _adjustmentsFuture = _billing.adjustments(tenantId: _selectedTenantId);
    _taxRatesFuture = _billing.taxRates();
    _auditFuture = _billing.audit(tenantId: _selectedTenantId);
    if (_selectedTenantId != null) {
      _tenantSummaryFuture = _billing.tenantSummary(_selectedTenantId!);
    }
    _tenantsFuture.then((items) {
      if (!mounted) return;
      setState(() {
        _tenants = items;
        if (_selectedTenantId == null && items.isNotEmpty) {
          _selectedTenantId = items.first.id;
          _tenantSummaryFuture = _billing.tenantSummary(_selectedTenantId!);
          _invoicesFuture = _billing.invoices(tenantId: _selectedTenantId);
          _adjustmentsFuture = _billing.adjustments(tenantId: _selectedTenantId);
          _auditFuture = _billing.audit(tenantId: _selectedTenantId);
        }
      });
    });
  }

  void _selectTenant(String? tenantId) {
    if (tenantId == null || tenantId.isEmpty) return;
    setState(() {
      _selectedTenantId = tenantId;
      _tenantSummaryFuture = _billing.tenantSummary(tenantId);
      _invoicesFuture = _billing.invoices(tenantId: tenantId);
      _adjustmentsFuture = _billing.adjustments(tenantId: tenantId);
      _auditFuture = _billing.audit(tenantId: tenantId);
    });
  }

  void _refreshDashboard() => setState(() => _dashboardFuture = _billing.dashboard());
  void _refreshModules() => setState(() => _modulesFuture = _billing.modules());
  void _refreshPlans() => setState(() => _plansFuture = _billing.plans());
  void _refreshInvoices() => setState(() => _invoicesFuture = _billing.invoices(tenantId: _selectedTenantId));
  void _refreshAdjustments() => setState(() => _adjustmentsFuture = _billing.adjustments(tenantId: _selectedTenantId));
  void _refreshTaxRates() => setState(() => _taxRatesFuture = _billing.taxRates());
  void _refreshAudit() => setState(() => _auditFuture = _billing.audit(tenantId: _selectedTenantId));
  void _refreshTenant() {
    if (_selectedTenantId == null) return;
    setState(() => _tenantSummaryFuture = _billing.tenantSummary(_selectedTenantId!));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Billing Management'),
          actions: [
            IconButton(
              tooltip: 'Refresh billing data',
              onPressed: () => setState(_reloadAll),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
              Tab(icon: Icon(Icons.extension_outlined), text: 'Modules'),
              Tab(icon: Icon(Icons.workspace_premium_outlined), text: 'Plans'),
              Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Invoices'),
              Tab(icon: Icon(Icons.tune_outlined), text: 'Adjustments'),
              Tab(icon: Icon(Icons.percent_rounded), text: 'Tax'),
              Tab(icon: Icon(Icons.history_rounded), text: 'Audit'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverview(),
            _buildModules(),
            _buildPlans(),
            _buildInvoices(),
            _buildAdjustments(),
            _buildTaxRates(),
            _buildAudit(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview() {
    return RefreshIndicator(
      onRefresh: () async {
        _refreshDashboard();
        _refreshTenant();
        await Future.wait([_dashboardFuture, if (_tenantSummaryFuture != null) _tenantSummaryFuture!]);
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _legacyImportCard(),
          const SizedBox(height: 16),
          FutureBuilder<BillingDashboardSummary>(
            future: _dashboardFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
              if (snapshot.hasError) return _errorCard('Unable to load billing dashboard', snapshot.error, _refreshDashboard);
              final summary = snapshot.data!;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _metricCard('Active Plans', '${summary.activePlans}', Icons.workspace_premium_outlined),
                  _metricCard('Subscriptions', '${summary.activeSubscriptions}', Icons.groups_outlined),
                  _metricCard('Trials', '${summary.trialSubscriptions}', Icons.hourglass_bottom_rounded),
                  _metricCard('Open Invoices', '${summary.openInvoices}', Icons.receipt_long_outlined),
                  _metricCard('Outstanding', _money(summary.openInvoiceAmount), Icons.account_balance_wallet_outlined),
                  _metricCard('Storage', _storage(summary.storageBytes), Icons.cloud_outlined),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _tenantSelector(),
          const SizedBox(height: 16),
          if (_tenantSummaryFuture != null)
            FutureBuilder<TenantBillingSummary>(
              future: _tenantSummaryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
                if (snapshot.hasError) return _errorCard('Unable to load tenant billing', snapshot.error, _refreshTenant);
                return _tenantSummary(snapshot.data!);
              },
            ),
        ],
      ),
    );
  }

  Widget _legacyImportCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.move_up_rounded),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Legacy Billing Transition', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Import existing Admin Console plans, latest tenant subscriptions, and module settings into the central billing service. The import is safe to repeat.'),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _migratingLegacy ? null : _migrateLegacyBilling,
              icon: _migratingLegacy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.system_update_alt_rounded),
              label: Text(_migratingLegacy ? 'Importing' : 'Import Legacy Data'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _migrateLegacyBilling() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import legacy billing data?'),
        content: const Text('Existing plans and tenant billing settings will be copied into the central billing service. Current module pricing in central billing will be preserved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Import')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _migratingLegacy = true);
    try {
      final result = await _billing.migrateLegacyBilling();
      if (!mounted) return;
      setState(() {
        _migratingLegacy = false;
        _reloadAll();
      });
      final failures = (result['failures'] as List?)?.length ?? 0;
      final message = '${result['plansMigrated'] ?? 0} plans, ${result['subscriptionsMigrated'] ?? 0} subscriptions, and ${result['entitlementsMigrated'] ?? 0} entitlements imported${failures == 0 ? '.' : ' with $failures issue(s).'}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      setState(() => _migratingLegacy = false);
      _showError(error);
    }
  }

  Widget _tenantSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Tenant>>(
          future: _tenantsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
            if (snapshot.hasError) return Text('Unable to load tenants: ${snapshot.error}');
            final tenants = snapshot.data ?? const [];
            if (tenants.isEmpty) return const Text('No tenants are configured.');
            return Row(
              children: [
                const Icon(Icons.business_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedTenantId,
                    decoration: const InputDecoration(labelText: 'Tenant'),
                    items: tenants
                        .map((tenant) => DropdownMenuItem(value: tenant.id, child: Text('${tenant.name} (${tenant.id})')))
                        .toList(),
                    onChanged: _selectTenant,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(onPressed: _refreshTenant, tooltip: 'Refresh tenant billing', icon: const Icon(Icons.refresh_rounded)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tenantSummary(TenantBillingSummary summary) {
    final subscription = summary.subscription;
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Subscription', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                    OutlinedButton.icon(
                      onPressed: () => _showSubscriptionDialog(subscription),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: Text(subscription == null ? 'Assign Plan' : 'Edit'),
                    ),
                  ],
                ),
                const Divider(),
                if (subscription == null)
                  const Text('No billing subscription has been assigned to this tenant.')
                else
                  Wrap(
                    spacing: 20,
                    runSpacing: 12,
                    children: [
                      _detail('Plan', subscription.planName ?? subscription.planCode),
                      _detail('Status', subscription.status),
                      _detail('Cycle', subscription.billingCycle),
                      _detail('Next Billing', subscription.nextBillingDate ?? 'Not set'),
                      _detail('Override', subscription.amountOverride == null ? 'Plan pricing' : _money(subscription.amountOverride!)),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _metricCard('Invoices', '${summary.invoiceCount}', Icons.receipt_outlined),
            _metricCard('Open', '${summary.openInvoiceCount}', Icons.pending_actions_outlined),
            _metricCard('Outstanding', _money(summary.outstandingAmount), Icons.account_balance_wallet_outlined),
            _metricCard('Storage', '${summary.storage.gigabytes.toStringAsFixed(3)} GB', Icons.cloud_outlined),
            _metricCard('Stored Objects', '${summary.storage.objectCount}', Icons.attach_file_rounded),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Module Entitlements', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                    OutlinedButton.icon(
                      onPressed: subscription == null ? null : _syncEntitlements,
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: const Text('Sync from Plan'),
                    ),
                  ],
                ),
                const Divider(),
                if (summary.entitlements.isEmpty)
                  const Text('No billing modules are configured.')
                else
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: summary.entitlements.map(_entitlementTile).toList(),
                  ),
              ],
            ),
          ),
        ),
        if (summary.currentPeriodUsage.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Period Usage', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const Divider(),
                  ...summary.currentPeriodUsage.map((usage) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.data_usage_rounded),
                        title: Text(usage.meterCode),
                        trailing: Text(usage.quantity.toStringAsFixed(3), style: const TextStyle(fontWeight: FontWeight.bold)),
                      )),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _entitlementTile(TenantEntitlement entitlement) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: entitlement.enabled ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: entitlement.enabled ? Colors.green.shade200 : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entitlement.moduleName ?? entitlement.moduleCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(entitlement.moduleCode, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Switch(
            value: entitlement.enabled,
            onChanged: (value) => _setEntitlement(entitlement.moduleCode, value),
          ),
        ],
      ),
    );
  }

  Widget _buildModules() {
    return FutureBuilder<List<BillingModule>>(
      future: _modulesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return _errorCard('Unable to load billing modules', snapshot.error, _refreshModules);
        final modules = snapshot.data ?? const [];
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              _refreshModules();
              await _modulesFuture;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: modules.length,
              itemBuilder: (context, index) {
                final module = modules[index];
                return Card(
                  child: ListTile(
                    leading: Icon(module.active ? Icons.check_circle_rounded : Icons.block_rounded,
                        color: module.active ? Colors.green : Colors.grey),
                    title: Text(module.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${module.code}${module.description == null ? '' : ' • ${module.description}'}'),
                    trailing: IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () => _showModuleDialog(module)),
                  ),
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showModuleDialog(null),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Module'),
          ),
        );
      },
    );
  }

  Widget _buildPlans() {
    return FutureBuilder<List<BillingPlan>>(
      future: _plansFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return _errorCard('Unable to load billing plans', snapshot.error, _refreshPlans);
        final plans = snapshot.data ?? const [];
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              _refreshPlans();
              await _plansFuture;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: plans.length,
              itemBuilder: (context, index) => _planCard(plans[index]),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showPlanDialog(null),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Plan'),
          ),
        );
      },
    );
  }

  Widget _planCard(BillingPlan plan) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(plan.code, style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Chip(label: Text(plan.status)),
                IconButton(onPressed: () => _showPlanDialog(plan), icon: const Icon(Icons.edit_rounded)),
              ],
            ),
            if (plan.description?.isNotEmpty == true) Padding(padding: const EdgeInsets.only(top: 8), child: Text(plan.description!)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _detail('Monthly Base', _money(plan.baseMonthlyAmount)),
                _detail('Annual Base', _money(plan.annualBaseAmount)),
                _detail('Tax', plan.taxCode),
                _detail('Users', plan.maxUsers?.toString() ?? 'Unlimited'),
                _detail('Branches', plan.maxBranches?.toString() ?? 'Unlimited'),
                _detail('Devices', plan.maxDevices?.toString() ?? 'Unlimited'),
                _detail('Modules', '${plan.modules.where((item) => item.active).length}'),
              ],
            ),
            if (plan.modules.isNotEmpty) ...[
              const Divider(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: plan.modules.where((item) => item.active).map((item) {
                  final price = item.monthlyAmount == 0 ? '' : ' • ${_money(item.monthlyAmount)}/month';
                  return Chip(label: Text('${item.moduleName ?? item.moduleCode}$price'));
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInvoices() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _compactTenantSelector()),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _selectedTenantId == null ? null : _showGenerateInvoiceDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Generate Invoice'),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<BillingInvoice>>(
            future: _invoicesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return _errorCard('Unable to load invoices', snapshot.error, _refreshInvoices);
              final invoices = snapshot.data ?? const [];
              if (invoices.isEmpty) return const Center(child: Text('No invoices have been generated.'));
              return RefreshIndicator(
                onRefresh: () async {
                  _refreshInvoices();
                  await _invoicesFuture;
                },
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: invoices.length,
                  itemBuilder: (context, index) => _invoiceCard(invoices[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _invoiceCard(BillingInvoice invoice) {
    return Card(
      child: ExpansionTile(
        leading: Icon(_invoiceIcon(invoice.status)),
        title: Text(invoice.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${invoice.periodStart} to ${invoice.periodEnd} • ${invoice.tenantId}'),
        trailing: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(label: Text(invoice.status)),
            Text(_money(invoice.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
            PopupMenuButton<String>(
              tooltip: 'Invoice status',
              onSelected: (status) => _changeInvoiceStatus(invoice, status),
              itemBuilder: (context) => ['DRAFT', 'ISSUED', 'PAID', 'OVERDUE', 'VOID']
                  .map((status) => PopupMenuItem(value: status, child: Text(status)))
                  .toList(),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                ...invoice.lines.map((line) => ListTile(
                      dense: true,
                      title: Text(line.description),
                      subtitle: Text('${line.lineType}${line.referenceCode == null ? '' : ' • ${line.referenceCode}'}'),
                      trailing: Text(_money(line.totalAmount)),
                    )),
                const Divider(),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text('Subtotal ${_money(invoice.subtotal)}  •  Tax ${_money(invoice.taxAmount)}  •  Total ${_money(invoice.totalAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustments() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _compactTenantSelector()),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _selectedTenantId == null ? null : _showAdjustmentDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Credit / Debit'),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<BillingAdjustment>>(
            future: _adjustmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return _errorCard('Unable to load adjustments', snapshot.error, _refreshAdjustments);
              final adjustments = snapshot.data ?? const [];
              if (adjustments.isEmpty) return const Center(child: Text('No billing adjustments have been recorded.'));
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: adjustments.length,
                itemBuilder: (context, index) {
                  final adjustment = adjustments[index];
                  final credit = adjustment.adjustmentType == 'CREDIT';
                  return Card(
                    child: ListTile(
                      leading: Icon(credit ? Icons.remove_circle_outline : Icons.add_circle_outline,
                          color: credit ? Colors.green : Colors.orange),
                      title: Text(adjustment.reason, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${adjustment.tenantId} • ${adjustment.effectiveDate} • ${adjustment.status}'),
                      trailing: Text('${credit ? '-' : '+'}${_money(adjustment.amount)}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: credit ? Colors.green.shade700 : Colors.orange.shade800)),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaxRates() {
    return FutureBuilder<List<BillingTaxRate>>(
      future: _taxRatesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return _errorCard('Unable to load tax rates', snapshot.error, _refreshTaxRates);
        final rates = snapshot.data ?? const [];
        return Scaffold(
          body: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: rates.length,
            itemBuilder: (context, index) {
              final rate = rates[index];
              return Card(
                child: ListTile(
                  leading: Icon(rate.active ? Icons.percent_rounded : Icons.block_rounded),
                  title: Text(rate.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${rate.code} • Effective ${rate.effectiveFrom}${rate.effectiveTo == null ? '' : ' to ${rate.effectiveTo}'}'),
                  trailing: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('${rate.ratePercent.toStringAsFixed(2)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () => _showTaxDialog(rate)),
                    ],
                  ),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showTaxDialog(null),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tax Rate'),
          ),
        );
      },
    );
  }

  Widget _buildAudit() {
    return Column(
      children: [
        Padding(padding: const EdgeInsets.all(16), child: _compactTenantSelector(allowAll: true)),
        Expanded(
          child: FutureBuilder<List<BillingAuditLog>>(
            future: _auditFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return _errorCard('Unable to load billing audit', snapshot.error, _refreshAudit);
              final logs = snapshot.data ?? const [];
              if (logs.isEmpty) return const Center(child: Text('No billing audit entries.'));
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.history_rounded),
                      title: Text(log.action, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${log.entityType}${log.entityId == null ? '' : ' • ${log.entityId}'}${log.tenantId == null ? '' : ' • ${log.tenantId}'}\n${log.createdAt ?? ''} by ${log.actor}'),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _compactTenantSelector({bool allowAll = false}) {
    final items = <DropdownMenuItem<String>>[
      if (allowAll) const DropdownMenuItem(value: '', child: Text('All tenants')),
      ..._tenants.map((tenant) => DropdownMenuItem(value: tenant.id, child: Text(tenant.name))),
    ];
    return DropdownButtonFormField<String>(
      value: allowAll ? (_selectedTenantId ?? '') : _selectedTenantId,
      decoration: const InputDecoration(labelText: 'Tenant'),
      items: items,
      onChanged: (value) {
        if (allowAll && value == '') {
          setState(() {
            _selectedTenantId = null;
            _auditFuture = _billing.audit();
          });
        } else {
          _selectTenant(value);
        }
      },
    );
  }

  Future<void> _showModuleDialog(BillingModule? module) async {
    final code = TextEditingController(text: module?.code ?? '');
    final name = TextEditingController(text: module?.name ?? '');
    final description = TextEditingController(text: module?.description ?? '');
    bool active = module?.active ?? true;
    bool saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(module == null ? 'New Billing Module' : 'Edit Billing Module'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: code, enabled: module == null, decoration: const InputDecoration(labelText: 'Code')),
                const SizedBox(height: 12),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 12),
                TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
                SwitchListTile(contentPadding: EdgeInsets.zero, value: active, onChanged: (value) => setDialogState(() => active = value), title: const Text('Active')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (code.text.trim().isEmpty || name.text.trim().isEmpty) return;
                      setDialogState(() => saving = true);
                      try {
                        await _billing.saveModule(
                          BillingModule(code: code.text.trim().toUpperCase(), name: name.text.trim(), description: description.text.trim(), active: active),
                          create: module == null,
                        );
                        if (!mounted) return;
                        Navigator.pop(dialogContext);
                        _refreshModules();
                        _refreshDashboard();
                      } catch (error) {
                        _showError(error);
                        setDialogState(() => saving = false);
                      }
                    },
              child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPlanDialog(BillingPlan? plan) async {
    List<BillingModule> modules;
    List<BillingTaxRate> taxRates;
    try {
      modules = await _billing.modules();
      taxRates = await _billing.taxRates();
    } catch (error) {
      _showError(error);
      return;
    }
    if (!mounted) return;
    final code = TextEditingController(text: plan?.code ?? '');
    final name = TextEditingController(text: plan?.name ?? '');
    final description = TextEditingController(text: plan?.description ?? '');
    final baseMonthly = TextEditingController(text: plan?.baseMonthlyAmount.toStringAsFixed(2) ?? '0.00');
    final annualBase = TextEditingController(text: plan?.annualBaseAmount.toStringAsFixed(2) ?? '0.00');
    final maxUsers = TextEditingController(text: plan?.maxUsers?.toString() ?? '');
    final maxBranches = TextEditingController(text: plan?.maxBranches?.toString() ?? '');
    final maxDevices = TextEditingController(text: plan?.maxDevices?.toString() ?? '');
    final displayOrder = TextEditingController(text: plan?.displayOrder.toString() ?? '0');
    String status = plan?.status ?? 'ACTIVE';
    String taxCode = plan?.taxCode ?? (taxRates.isEmpty ? 'ZA_VAT' : taxRates.first.code);
    final existing = {for (final item in plan?.modules ?? const <BillingPlanModule>[]) item.moduleCode: item};
    final editors = modules.map((module) => _PlanModuleEditor(module, existing[module.code])).toList();
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(plan == null ? 'New Billing Plan' : 'Edit Billing Plan'),
          content: SizedBox(
            width: 820,
            height: MediaQuery.of(context).size.height * 0.75,
            child: ListView(
              children: [
                Row(children: [
                  Expanded(child: TextField(controller: code, enabled: plan == null, decoration: const InputDecoration(labelText: 'Code'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: name, decoration: const InputDecoration(labelText: 'Name'))),
                ]),
                const SizedBox(height: 12),
                TextField(controller: description, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: baseMonthly, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Base Monthly Amount'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: annualBase, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Annual Base Amount'))),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: maxUsers, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Users', hintText: 'Unlimited'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: maxBranches, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Branches', hintText: 'Unlimited'))),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: maxDevices, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Devices', hintText: 'Unlimited'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: displayOrder, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Display Order'))),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: ['ACTIVE', 'INACTIVE'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                      onChanged: (value) => setDialogState(() => status = value ?? 'ACTIVE'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: taxRates.any((rate) => rate.code == taxCode) ? taxCode : null,
                      decoration: const InputDecoration(labelText: 'Tax Rate'),
                      items: taxRates.map((rate) => DropdownMenuItem(value: rate.code, child: Text('${rate.name} (${rate.ratePercent}%)'))).toList(),
                      onChanged: (value) => setDialogState(() => taxCode = value ?? taxCode),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                const Text('Included Modules and Pricing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...editors.map((editor) => _planModuleEditor(editor, setDialogState)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (code.text.trim().isEmpty || name.text.trim().isEmpty) return;
                      setDialogState(() => saving = true);
                      try {
                        final savedPlan = BillingPlan(
                          code: code.text.trim().toUpperCase(),
                          name: name.text.trim(),
                          description: description.text.trim(),
                          currency: 'ZAR',
                          baseMonthlyAmount: double.tryParse(baseMonthly.text.trim()) ?? 0,
                          annualBaseAmount: double.tryParse(annualBase.text.trim()) ?? 0,
                          status: status,
                          taxCode: taxCode,
                          maxUsers: int.tryParse(maxUsers.text.trim()),
                          maxBranches: int.tryParse(maxBranches.text.trim()),
                          maxDevices: int.tryParse(maxDevices.text.trim()),
                          displayOrder: int.tryParse(displayOrder.text.trim()) ?? 0,
                          modules: editors
                              .where((editor) => editor.enabled)
                              .map((editor) => BillingPlanModule(
                                    moduleCode: editor.module.code,
                                    moduleName: editor.module.name,
                                    monthlyAmount: double.tryParse(editor.monthly.text.trim()) ?? 0,
                                    annualAmount: double.tryParse(editor.annual.text.trim()) ?? 0,
                                    meterCode: editor.meter.text.trim(),
                                    includedQuantity: double.tryParse(editor.included.text.trim()) ?? 0,
                                    unitAmount: double.tryParse(editor.unit.text.trim()) ?? 0,
                                    active: true,
                                  ))
                              .toList(),
                        );
                        await _billing.savePlan(savedPlan, create: plan == null);
                        if (!mounted) return;
                        Navigator.pop(dialogContext);
                        _refreshPlans();
                        _refreshDashboard();
                      } catch (error) {
                        _showError(error);
                        setDialogState(() => saving = false);
                      }
                    },
              child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Plan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planModuleEditor(_PlanModuleEditor editor, StateSetter setDialogState) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: editor.enabled,
              onChanged: (value) => setDialogState(() => editor.enabled = value ?? false),
              title: Text(editor.module.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(editor.module.code),
            ),
            if (editor.enabled) ...[
              Row(children: [
                Expanded(child: TextField(controller: editor.monthly, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly Amount'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: editor.annual, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Annual Amount'))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: editor.meter, decoration: const InputDecoration(labelText: 'Usage Meter (optional)'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: editor.included, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Included Quantity'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: editor.unit, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Unit Amount'))),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showSubscriptionDialog(BillingSubscription? current) async {
    if (_selectedTenantId == null) return;
    List<BillingPlan> plans;
    try {
      plans = await _billing.plans();
    } catch (error) {
      _showError(error);
      return;
    }
    if (!mounted || plans.isEmpty) return;
    String planCode = current?.planCode ?? plans.first.code;
    String status = current?.status ?? 'ACTIVE';
    String cycle = current?.billingCycle ?? 'MONTHLY';
    final amountOverride = TextEditingController(text: current?.amountOverride?.toStringAsFixed(2) ?? '');
    final notes = TextEditingController(text: current?.notes ?? '');
    DateTime startDate = _parseDate(current?.startDate) ?? DateTime.now();
    DateTime? trialEnd = _parseDate(current?.trialEndDate);
    DateTime? nextBilling = _parseDate(current?.nextBillingDate);
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(current == null ? 'Assign Subscription' : 'Edit Subscription'),
          content: SizedBox(
            width: 620,
            child: ListView(
              shrinkWrap: true,
              children: [
                DropdownButtonFormField<String>(
                  value: planCode,
                  decoration: const InputDecoration(labelText: 'Plan'),
                  items: plans.map((plan) => DropdownMenuItem(value: plan.code, child: Text('${plan.name} (${plan.code})'))).toList(),
                  onChanged: (value) => setDialogState(() => planCode = value ?? planCode),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: ['TRIAL', 'ACTIVE', 'SUSPENDED', 'CANCELLED'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                      onChanged: (value) => setDialogState(() => status = value ?? status),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: cycle,
                      decoration: const InputDecoration(labelText: 'Billing Cycle'),
                      items: ['MONTHLY', 'ANNUAL'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                      onChanged: (value) => setDialogState(() => cycle = value ?? cycle),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextField(controller: amountOverride, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount Override (leave blank for plan pricing)')),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
                        if (picked != null) setDialogState(() => startDate = picked);
                      },
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text('Start: ${_date(startDate)}'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(context: context, initialDate: trialEnd ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                        if (picked != null) setDialogState(() => trialEnd = picked);
                      },
                      icon: const Icon(Icons.hourglass_bottom_rounded),
                      label: Text('Trial End: ${trialEnd == null ? 'Not set' : _date(trialEnd!)}'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(context: context, initialDate: nextBilling ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                        if (picked != null) setDialogState(() => nextBilling = picked);
                      },
                      icon: const Icon(Icons.event_repeat_rounded),
                      label: Text('Next Billing: ${nextBilling == null ? 'Not set' : _date(nextBilling!)}'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() => saving = true);
                      try {
                        await _billing.saveSubscription(_selectedTenantId!, {
                          'planCode': planCode,
                          'status': status,
                          'billingCycle': cycle,
                          'currency': 'ZAR',
                          'amountOverride': amountOverride.text.trim().isEmpty ? null : double.tryParse(amountOverride.text.trim()),
                          'startDate': _date(startDate),
                          'trialEndDate': trialEnd == null ? null : _date(trialEnd!),
                          'nextBillingDate': nextBilling == null ? null : _date(nextBilling!),
                          'notes': notes.text.trim(),
                        });
                        if (!mounted) return;
                        Navigator.pop(dialogContext);
                        _refreshTenant();
                        _refreshDashboard();
                      } catch (error) {
                        _showError(error);
                        setDialogState(() => saving = false);
                      }
                    },
              child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showGenerateInvoiceDialog() async {
    DateTime start = DateTime(DateTime.now().year, DateTime.now().month, 1);
    DateTime end = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
    DateTime due = end.add(const Duration(days: 7));
    bool saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Generate Billing Invoice'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dateButton('Period Start', start, (value) => setDialogState(() => start = value)),
                const SizedBox(height: 10),
                _dateButton('Period End', end, (value) => setDialogState(() => end = value)),
                const SizedBox(height: 10),
                _dateButton('Due Date', due, (value) => setDialogState(() => due = value)),
                const SizedBox(height: 12),
                const Text('The invoice will include plan charges, module charges, metered overages, storage and approved adjustments for the selected period.'),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() => saving = true);
                      try {
                        await _billing.generateInvoice(_selectedTenantId!, start, end, due);
                        if (!mounted) return;
                        Navigator.pop(dialogContext);
                        _refreshInvoices();
                        _refreshTenant();
                        _refreshDashboard();
                      } catch (error) {
                        _showError(error);
                        setDialogState(() => saving = false);
                      }
                    },
              child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateButton(String label, DateTime value, ValueChanged<DateTime> onChanged) {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(context: context, initialDate: value, firstDate: DateTime(2020), lastDate: DateTime(2100));
        if (picked != null) onChanged(picked);
      },
      icon: const Icon(Icons.calendar_today_outlined),
      label: SizedBox(width: 420, child: Text('$label: ${_date(value)}')),
    );
  }

  Future<void> _showAdjustmentDialog() async {
    String type = 'CREDIT';
    final amount = TextEditingController();
    final reason = TextEditingController();
    DateTime effectiveDate = DateTime.now();
    bool saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Billing Credit / Debit'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Adjustment Type'),
                  items: ['CREDIT', 'DEBIT'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                  onChanged: (value) => setDialogState(() => type = value ?? type),
                ),
                const SizedBox(height: 12),
                TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount')),
                const SizedBox(height: 12),
                TextField(controller: reason, maxLines: 3, decoration: const InputDecoration(labelText: 'Reason')),
                const SizedBox(height: 12),
                _dateButton('Effective Date', effectiveDate, (value) => setDialogState(() => effectiveDate = value)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final parsedAmount = double.tryParse(amount.text.trim());
                      if (parsedAmount == null || parsedAmount <= 0 || reason.text.trim().isEmpty) return;
                      setDialogState(() => saving = true);
                      try {
                        await _billing.createAdjustment(
                          tenantId: _selectedTenantId!,
                          type: type,
                          amount: parsedAmount,
                          reason: reason.text.trim(),
                          effectiveDate: effectiveDate,
                        );
                        if (!mounted) return;
                        Navigator.pop(dialogContext);
                        _refreshAdjustments();
                        _refreshAudit();
                      } catch (error) {
                        _showError(error);
                        setDialogState(() => saving = false);
                      }
                    },
              child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTaxDialog(BillingTaxRate? rate) async {
    final code = TextEditingController(text: rate?.code ?? '');
    final name = TextEditingController(text: rate?.name ?? '');
    final percentage = TextEditingController(text: rate?.ratePercent.toStringAsFixed(4) ?? '0.0000');
    bool active = rate?.active ?? true;
    DateTime effectiveFrom = _parseDate(rate?.effectiveFrom) ?? DateTime.now();
    bool saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(rate == null ? 'New Tax Rate' : 'Edit Tax Rate'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: code, enabled: rate == null, decoration: const InputDecoration(labelText: 'Code')),
                const SizedBox(height: 12),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 12),
                TextField(controller: percentage, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rate %')),
                const SizedBox(height: 12),
                _dateButton('Effective From', effectiveFrom, (value) => setDialogState(() => effectiveFrom = value)),
                SwitchListTile(contentPadding: EdgeInsets.zero, value: active, onChanged: (value) => setDialogState(() => active = value), title: const Text('Active')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final parsed = double.tryParse(percentage.text.trim());
                      if (code.text.trim().isEmpty || name.text.trim().isEmpty || parsed == null || parsed < 0) return;
                      setDialogState(() => saving = true);
                      try {
                        await _billing.saveTaxRate(
                          BillingTaxRate(
                            code: code.text.trim().toUpperCase(),
                            name: name.text.trim(),
                            ratePercent: parsed,
                            active: active,
                            effectiveFrom: _date(effectiveFrom),
                          ),
                          create: rate == null,
                        );
                        if (!mounted) return;
                        Navigator.pop(dialogContext);
                        _refreshTaxRates();
                      } catch (error) {
                        _showError(error);
                        setDialogState(() => saving = false);
                      }
                    },
              child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setEntitlement(String moduleCode, bool enabled) async {
    if (_selectedTenantId == null) return;
    try {
      await _billing.setEntitlement(_selectedTenantId!, moduleCode, enabled);
      _refreshTenant();
      _refreshAudit();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _syncEntitlements() async {
    if (_selectedTenantId == null) return;
    try {
      await _billing.syncEntitlements(_selectedTenantId!);
      _refreshTenant();
      _refreshAudit();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _changeInvoiceStatus(BillingInvoice invoice, String status) async {
    try {
      await _billing.updateInvoiceStatus(invoice.id, status);
      _refreshInvoices();
      _refreshTenant();
      _refreshDashboard();
      _refreshAudit();
    } catch (error) {
      _showError(error);
    }
  }

  Widget _metricCard(String label, String value, IconData icon) {
    return SizedBox(
      width: 210,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(label, style: TextStyle(color: Colors.grey.shade600)),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _errorCard(String title, Object? error, VoidCallback retry) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 36),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: retry, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
          ]),
        ),
      ),
    );
  }

  IconData _invoiceIcon(String status) {
    switch (status) {
      case 'PAID':
        return Icons.check_circle_outline_rounded;
      case 'OVERDUE':
        return Icons.warning_amber_rounded;
      case 'VOID':
        return Icons.block_rounded;
      case 'ISSUED':
        return Icons.send_outlined;
      default:
        return Icons.edit_note_rounded;
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error'), backgroundColor: Colors.red.shade700));
  }

  String _money(double amount) => 'R ${amount.toStringAsFixed(2)}';
  String _storage(int bytes) {
    if (bytes >= 1073741824) return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
    if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(2)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '$bytes B';
  }

  DateTime? _parseDate(String? value) => value == null || value.isEmpty ? null : DateTime.tryParse(value);
  String _date(DateTime value) => '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class _PlanModuleEditor {
  final BillingModule module;
  bool enabled;
  final TextEditingController monthly;
  final TextEditingController annual;
  final TextEditingController meter;
  final TextEditingController included;
  final TextEditingController unit;

  _PlanModuleEditor(this.module, BillingPlanModule? current)
      : enabled = current?.active ?? false,
        monthly = TextEditingController(text: current?.monthlyAmount.toStringAsFixed(2) ?? '0.00'),
        annual = TextEditingController(text: current?.annualAmount.toStringAsFixed(2) ?? '0.00'),
        meter = TextEditingController(text: current?.meterCode ?? ''),
        included = TextEditingController(text: current?.includedQuantity.toStringAsFixed(3) ?? '0.000'),
        unit = TextEditingController(text: current?.unitAmount.toStringAsFixed(4) ?? '0.0000');
}
