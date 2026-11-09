import 'package:flutter/material.dart';
import '../services/platform_microsoft365_service.dart';
import '../config.dart';
import '../theme/admin_theme.dart';

/// This workcenter configures MAWA's central Microsoft application, never a customer-owned mailbox.
class PlatformMicrosoft365Screen extends StatefulWidget {
  const PlatformMicrosoft365Screen({super.key});
  @override
  State<PlatformMicrosoft365Screen> createState() => _PlatformMicrosoft365ScreenState();
}

class _PlatformMicrosoft365ScreenState extends State<PlatformMicrosoft365Screen> {
  final _service = PlatformMicrosoft365Service();
  final _formKey = GlobalKey<FormState>();
  final _clientId = TextEditingController();
  final _redirectUri = TextEditingController();
  final _clientSecret = TextEditingController();
  Microsoft365PlatformConfig? _config;
  bool _loading = true;
  bool _saving = false;
  bool _showSecret = false;
  String? _error;

  String get _suggestedRedirectUri {
    switch (AppConfig.environment) {
      case Environment.hotfix:
        return 'https://hotfix.api.app.mawa.co.za/v2/bank-transactions/microsoft/callback';
      case Environment.prod:
        return 'https://api.app.mawa.co.za/v2/bank-transactions/microsoft/callback';
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _redirectUri.text = _suggestedRedirectUri;
    _refresh();
  }
  @override
  void dispose() { _clientId.dispose(); _redirectUri.dispose(); _clientSecret.dispose(); super.dispose(); }

  Future<void> _refresh() async {
    setState(() { _loading = true; _error = null; });
    try {
      final config = await _service.get();
      if (!mounted) return;
      setState(() {
        _config = config;
        _clientId.text = config.clientId;
        _redirectUri.text = config.redirectUri.isEmpty
            ? _suggestedRedirectUri : config.redirectUri;
        _clientSecret.clear(); // NEVER retrieve or render the stored secret.
      });
    } catch (error) { if (mounted) setState(() => _error = '$error'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      final saved = await _service.save(clientId: _clientId.text, redirectUri: _redirectUri.text,
          clientSecret: _clientSecret.text.isEmpty ? null : _clientSecret.text);
      if (!mounted) return;
      setState(() { _config = saved; _clientSecret.clear(); _showSecret = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Microsoft 365 credentials saved securely to Google Secret Manager.')));
    } catch (error) { if (mounted) setState(() => _error = '$error'); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Microsoft 365 Platform Integration'), actions: [
      IconButton(onPressed: _loading || _saving ? null : _refresh,
          tooltip: 'Refresh configuration', icon: const Icon(Icons.refresh_rounded))
    ]),
    body: _loading ? const Center(child: CircularProgressIndicator()) :
      SingleChildScrollView(padding: const EdgeInsets.all(24), child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('MAWA-owned Microsoft Entra application', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              const Text('Configure this once for all MAWA customers in this environment. Each customer connects its own Microsoft organization and grants mailbox-scoped access in its ERP tenant. Do not enter any customer mailbox credentials here.'),
              const SizedBox(height: 10),
              Text('Environment: ${(_config?.environment.isNotEmpty == true ? _config!.environment : AppConfig.environment.name).toUpperCase()}',
                style: const TextStyle(color: AdminDesign.muted)),
              const SizedBox(height: 8),
              Text(_config?.configured == true ? 'Credentials stored in Secret Manager' : 'Credentials not configured',
                style: TextStyle(color: _config?.configured == true ? Colors.green : AdminDesign.warning)),
            ]))),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(24), child: Form(
            key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextFormField(controller: _clientId, decoration: const InputDecoration(
                  labelText: 'Application (client) ID', border: OutlineInputBorder()),
                validator: (value) => (value == null || !RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(value.trim()))
                    ? 'Enter the Application (client) ID from Microsoft Entra' : null),
              const SizedBox(height: 18),
              TextFormField(controller: _redirectUri, decoration: const InputDecoration(
                  labelText: 'Web redirect URI', border: OutlineInputBorder()),
                validator: (value) => value == null || !value.trim().startsWith('https://') ||
                  !value.trim().endsWith('/v2/bank-transactions/microsoft/callback')
                    ? 'Enter the registered MAWA HTTPS callback URL' : null),
              if (_suggestedRedirectUri.isNotEmpty) ...[
                Align(alignment: Alignment.centerRight, child: TextButton.icon(
                  onPressed: _saving ? null : () {
                    setState(() => _redirectUri.text = _suggestedRedirectUri);
                    _formKey.currentState?.validate();
                  },
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('Use registered callback URL'),
                )),
              ],
              const SizedBox(height: 18),
              TextFormField(controller: _clientSecret, obscureText: !_showSecret,
                enableSuggestions: false, autocorrect: false,
                decoration: InputDecoration(
                  labelText: _config?.clientSecretConfigured == true
                    ? 'Client Secret Value (leave blank to keep existing)' : 'Client Secret Value',
                  border: const OutlineInputBorder(),
                  helperText: _config?.clientSecretConfigured == true
                    ? 'Existing secret remains masked and is never returned to the browser.'
                    : 'Paste the Value from Microsoft Entra Certificates & secrets, not its Secret ID.',
                  suffixIcon: IconButton(onPressed: () => setState(() => _showSecret = !_showSecret),
                    icon: Icon(_showSecret ? Icons.visibility_off : Icons.visibility)),
                ),
                validator: (value) => (_config?.clientSecretConfigured != true && (value?.isEmpty ?? true))
                  ? 'A client secret is required for initial setup' : null),
              const SizedBox(height: 20),
              if (_error != null) ...[
                SelectableText(_error!, style: const TextStyle(color: AdminDesign.red)),
                Align(alignment: Alignment.centerLeft, child: TextButton.icon(
                  onPressed: _loading || _saving ? null : _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry loading configuration'),
                )),
                const SizedBox(height: 12),
              ],
              Align(alignment: Alignment.centerRight, child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Saving...' : 'Save securely'),
              )),
            ])))),
          const SizedBox(height: 12),
          const Text('Only MAWA Platform Owners can view or rotate central credentials. Saving creates a new Secret Manager version and records an administrator audit event.',
            style: TextStyle(color: AdminDesign.muted)),
        ]),
      ))),
  );
}
