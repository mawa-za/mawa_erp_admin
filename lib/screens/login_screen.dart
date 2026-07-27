import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/admin_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await _authService.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() {
        _errorMessage = 'Invalid username or password. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showBrandPanel = width >= 980;

    return Scaffold(
      backgroundColor: AdminDesign.page,
      body: Row(
        children: [
          if (showBrandPanel)
            Expanded(
              flex: 5,
              child: Container(
                height: double.infinity,
                padding: const EdgeInsets.all(56),
                decoration: const BoxDecoration(
                  color: AdminDesign.navy,
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/branding/mawa_logo.png',
                        height: 48,
                        color: Colors.white,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                      const Spacer(),
                      Text(
                        'Platform administration,\nmade clear and secure.',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontSize: 38,
                              height: 1.16,
                            ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Manage tenants, billing, subscriptions and access from one professional console.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFFCBD5E1),
                              height: 1.6,
                            ),
                      ),
                      const SizedBox(height: 34),
                      const _FeatureLine(
                        icon: Icons.shield_outlined,
                        text: 'Protected platform administration',
                      ),
                      const SizedBox(height: 14),
                      const _FeatureLine(
                        icon: Icons.business_outlined,
                        text: 'Centralised tenant management',
                      ),
                      const SizedBox(height: 14),
                      const _FeatureLine(
                        icon: Icons.receipt_long_outlined,
                        text: 'Billing and subscription oversight',
                      ),
                      const Spacer(),
                      const Text(
                        'Trusted technology for communities that matter.',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            flex: showBrandPanel ? 4 : 1,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(34),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!showBrandPanel) ...[
                              Image.asset(
                                'assets/branding/mawa_logo.png',
                                height: 52,
                              ),
                              const SizedBox(height: 24),
                            ],
                            Text(
                              'Welcome back',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in to the MAWA Admin Console.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AdminDesign.muted,
                                  ),
                            ),
                            const SizedBox(height: 28),
                            TextFormField(
                              controller: _usernameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: (value) => value == null || value.trim().isEmpty
                                  ? 'Please enter your username'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              onFieldSubmitted: (_) => _isLoading ? null : _handleLogin(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Please enter your password'
                                  : null,
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AdminDesign.redSoft,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AdminDesign.red.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: AdminDesign.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: AdminDesign.redDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Sign in'),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'MAWA Admin Console • v1.0.6+7',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AdminDesign.muted,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _FeatureLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: Colors.white, size: 19),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFFE2E8F0),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
