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
  late Future<Map<String, String>> _propertiesFuture;

  @override
  void initState() {
    super.initState();
    _refreshProperties();
  }

  void _refreshProperties() {
    setState(() {
      _propertiesFuture = _tenantService.getTenantProperties(widget.tenant.id);
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('System Properties', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _showAddPropertyDialog,
                    tooltip: 'Add Property',
                  ),
                ],
              ),
              const Divider(),
              FutureBuilder<Map<String, String>>(
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
                      child: Text('Error loading properties: ${snapshot.error}', 
                        style: const TextStyle(color: Colors.red)),
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
                    itemBuilder: (context, index) {
                      final key = properties.keys.elementAt(index);
                      final value = properties[key] ?? '';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(key, 
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 14,
                            fontFamily: 'monospace'
                          )
                        ),
                        subtitle: Text(value, 
                          style: const TextStyle(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: value));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Copied $key to clipboard')),
                            );
                          },
                          tooltip: 'Copy Value',
                        ),
                      );
                    },
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
            _buildDetailRow('Status', widget.tenant.status, 
              color: widget.tenant.status == 'ACTIVE' ? Colors.green : Colors.red),
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
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey))
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color))
          ),
        ],
      ),
    );
  }

  void _showAddPropertyDialog() {
    final propertyController = TextEditingController();
    final valueController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Tenant Property'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: propertyController, 
                  decoration: const InputDecoration(
                    labelText: 'Property Name',
                    hintText: 'e.g. XERO-CLIENT-ID',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: valueController, 
                  decoration: const InputDecoration(
                    labelText: 'Value',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context), 
                child: const Text('Cancel')
              ),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  if (propertyController.text.isNotEmpty && valueController.text.isNotEmpty) {
                    setDialogState(() => isSaving = true);
                    try {
                      await _tenantService.addTenantProperty(TenantPropertyRequest(
                        tenant: widget.tenant.id,
                        property: propertyController.text.trim(),
                        value: valueController.text.trim(),
                      ));
                      if (mounted) {
                        Navigator.pop(context);
                        _refreshProperties();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Property added successfully')),
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
                  }
                },
                child: isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Add'),
              ),
            ],
          );
        }
      ),
    );
  }
}
