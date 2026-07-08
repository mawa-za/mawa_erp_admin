import 'package:flutter/material.dart';
import '../models/tenant.dart';
import '../services/tenant_service.dart';
import 'tenant_detail_screen.dart';

class TenantListScreen extends StatefulWidget {
  const TenantListScreen({super.key});

  @override
  State<TenantListScreen> createState() => _TenantListScreenState();
}

class _TenantListScreenState extends State<TenantListScreen> {
  final TenantService _tenantService = TenantService();
  late Future<List<Tenant>> _tenantsFuture;

  @override
  void initState() {
    super.initState();
    _refreshTenants();
  }

  void _refreshTenants() {
    setState(() {
      _tenantsFuture = _tenantService.getTenants();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshTenants,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Tenant>>(
        future: _tenantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Failed to load tenants', style: theme.textTheme.titleMedium),
                  TextButton(onPressed: _refreshTenants, child: const Text('Try Again')),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_center_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No tenants found', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey)),
                ],
              ),
            );
          }

          final tenants = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tenants.length,
            itemBuilder: (context, index) {
              final tenant = tenants[index];
              final isActive = tenant.status == 'ACTIVE';
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TenantDetailScreen(tenant: tenant),
                      ),
                    ).then((_) => _refreshTenants());
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.business_rounded, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tenant.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [tenant.host, if (tenant.subscriptionPlanCode != null) tenant.subscriptionPlanCode!].join(' • '),
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tenant.status,
                            style: TextStyle(
                              color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTenantDialog,
        label: const Text('New Tenant'),
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showCreateTenantDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateTenantDialog(),
    ).then((success) {
      if (success == true) {
        _refreshTenants();
      }
    });
  }
}

class CreateTenantDialog extends StatefulWidget {
  const CreateTenantDialog({super.key});

  @override
  State<CreateTenantDialog> createState() => _CreateTenantDialogState();
}

class _CreateTenantDialogState extends State<CreateTenantDialog> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _urlController = TextEditingController();
  final _dbUrlController = TextEditingController();
  final _dbUserController = TextEditingController();
  final _dbPassController = TextEditingController();
  String _status = 'ACTIVE';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('Create Tenant'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Basic Information'),
                const SizedBox(height: 16),
                _buildTextField(_idController, 'ID (Optional)', Icons.fingerprint_rounded),
                const SizedBox(height: 12),
                _buildTextField(_nameController, 'Name', Icons.badge_rounded, required: true),
                const SizedBox(height: 12),
                _buildTextField(_hostController, 'Host', Icons.language_rounded, required: true),
                const SizedBox(height: 12),
                _buildTextField(_urlController, 'ERP App URL (Optional)', Icons.link_rounded),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.info_outline_rounded),
                  ),
                  items: ['ACTIVE', 'INACTIVE', 'SUSPENDED']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _status = v!),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Database Configuration'),
                const SizedBox(height: 16),
                _buildTextField(_dbUrlController, 'DB URL', Icons.storage_rounded),
                const SizedBox(height: 12),
                _buildTextField(_dbUserController, 'DB Username', Icons.account_circle_rounded),
                const SizedBox(height: 12),
                _buildTextField(_dbPassController, 'DB Password', Icons.lock_rounded, obscureText: true),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Create Tenant'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, {
    bool required = false,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
      validator: required ? (v) => v?.isEmpty ?? true ? 'This field is required' : null : null,
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final request = CreateTenantRequest(
          id: _idController.text.isEmpty ? null : _idController.text,
          name: _nameController.text,
          host: _hostController.text,
          url: _urlController.text.isEmpty ? null : _urlController.text,
          erpAppUrl: _urlController.text.isEmpty ? null : _urlController.text,
          status: _status,
          databaseUrl: _dbUrlController.text.isEmpty ? null : _dbUrlController.text,
          databaseUsername: _dbUserController.text.isEmpty ? null : _dbUserController.text,
          databasePassword: _dbPassController.text.isEmpty ? null : _dbPassController.text,
        );
        await TenantService().createTenant(request);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
