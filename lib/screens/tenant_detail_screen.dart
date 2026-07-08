import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tenant.dart';
import '../services/tenant_service.dart';
import '../models/tenant_property.dart';

class TenantDetailScreen extends StatefulWidget {
  final Tenant tenant;

  const TenantDetailScreen({super.key, required this.tenant});

  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  final TenantService _tenantService = TenantService();
  late Future<List<TenantProperty>> _propertiesFuture;

  @override
  void initState() {
    super.initState();
    _refreshProperties();
  }

  void _refreshProperties() {
    setState(() {
      _propertiesFuture = _tenantService.getTenantPropertyDetails(widget.tenant.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tenant.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProperties,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshProperties(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.key_rounded, color: Colors.blue.shade700),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Google Secret Manager',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Sensitive values can be saved to GCP and stored here as secret references only.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddPropertyDialog(storeAsSecretDefault: true),
                        icon: const Icon(Icons.enhanced_encryption_rounded, size: 18),
                        label: const Text('Add Secret'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'System Properties',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _showAddPropertyDialog,
                    tooltip: 'Add Property',
                  ),
                ],
              ),
              const Divider(),
              FutureBuilder<List<TenantProperty>>(
                future: _propertiesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        'Error loading properties: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text('No properties configured for this tenant.'),
                    );
                  }

                  final properties = snapshot.data!;
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: properties.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) => _buildPropertyTile(properties[index]),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
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
          Text(
            property.property,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'monospace',
            ),
          ),
          if (property.secretReference)
            _buildTag('Secret Manager', Icons.verified_user_rounded, Colors.green),
          if (property.sensitive && !property.secretReference)
            _buildTag('Sensitive', Icons.visibility_off_rounded, Colors.orange),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          property.displayValue,
          style: const TextStyle(fontSize: 13),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.copy, size: 20),
        onPressed: canCopy
            ? () {
                Clipboard.setData(ClipboardData(text: property.value!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Copied ${property.property} to clipboard')),
                );
              }
            : null,
        tooltip: canCopy ? 'Copy Value' : 'Raw sensitive value hidden',
      ),
    );
  }

  Widget _buildTag(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, size: 20),
                SizedBox(width: 8),
                Text('Tenant Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            _buildDetailRow('ID', widget.tenant.id),
            _buildDetailRow('Host', widget.tenant.host),
            _buildDetailRow(
              'Status',
              widget.tenant.status,
              color: widget.tenant.status == 'ACTIVE' ? Colors.green : Colors.red,
            ),
            if (widget.tenant.url != null) _buildDetailRow('URL', widget.tenant.url!),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ),
        ],
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
        builder: (context, setDialogState) {
          return AlertDialog(
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
                    TextField(
                      controller: propertyController,
                      decoration: const InputDecoration(
                        labelText: 'Property Name',
                        hintText: 'e.g. XERO-SECRET-KEY',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: valueController,
                      decoration: InputDecoration(
                        labelText: storeAsSecret ? 'Secret Value' : 'Value',
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: storeAsSecret,
                      maxLines: storeAsSecret ? 1 : 3,
                      minLines: 1,
                    ),
                    if (storeAsSecret) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: secretNameController,
                        decoration: const InputDecoration(
                          labelText: 'Secret Name (Optional)',
                          hintText: 'Leave blank to auto-generate',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final propertyName = propertyController.text.trim();
                        final rawValue = valueController.text;
                        final propertyValue = storeAsSecret ? rawValue : rawValue.trim();
                        if (propertyName.isEmpty || propertyValue.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Property name and value are required')),
                          );
                          return;
                        }
                        setDialogState(() => isSaving = true);
                        try {
                          await _tenantService.addTenantProperty(
                            TenantPropertyRequest(
                              tenant: widget.tenant.id,
                              property: propertyName,
                              value: propertyValue,
                              storeAsSecret: storeAsSecret,
                              secretName: secretNameController.text.trim().isEmpty
                                  ? null
                                  : secretNameController.text.trim(),
                            ),
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            _refreshProperties();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(storeAsSecret
                                    ? 'Secret saved and property reference added'
                                    : 'Property added successfully'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                            );
                          }
                          setDialogState(() => isSaving = false);
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(storeAsSecret ? 'Save Secret' : 'Add'),
              ),
            ],
          );
        },
      ),
    );
  }
}
