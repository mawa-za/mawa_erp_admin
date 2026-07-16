import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/tenant_list_screen.dart';
import 'screens/subscription_plans_screen.dart';
import 'screens/access_management_screen.dart';
import 'services/auth_service.dart';
import 'services/tenant_service.dart';
import 'services/access_management_service.dart';
import 'models/access_management.dart';
import 'models/platform_management.dart';
import 'config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Log the current environment loaded from environment variables
  debugPrint('Running in ${AppConfig.environment.name} mode');

  final authService = AuthService();
  final isLoggedIn = await authService.isLoggedIn();
  if (isLoggedIn) authService.startKeepAlive();

  runApp(MyApp(initialRoute: isLoggedIn ? '/home' : '/login'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mawa Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          primary: const Color(0xFF1E88E5),
          secondary: const Color(0xFF26C6DA),
          surface: const Color(0xFFF8FAFC),
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          color: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: GoogleFonts.inter(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1),
          ),
          labelStyle: const TextStyle(color: Color(0xFF64748B)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MyHomePage(title: 'mawa Admin'),
        '/tenant': (context) => const TenantListScreen(),
        '/subscriptions': (context) => const SubscriptionPlansScreen(),
        '/access': (context) => const AccessManagementScreen(),
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tenantService = TenantService();
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(title),
            const SizedBox(width: 8),
            Text(
              'v1.0.4+5 (${AppConfig.environment.name})',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.logout_rounded, color: Colors.red.shade700),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Sign out?'),
                    content: const Text('You will need to sign in again to manage MAWA tenants.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('CANCEL'),
                      ),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('SIGN OUT'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;
                await AuthService().logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<AdminAccessProfile>(
        future: AccessManagementService().getProfile(),
        builder: (context, accessSnapshot) {
          if (accessSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (accessSnapshot.hasError || !accessSnapshot.hasData) {
            return Center(
              child: Text('Unable to load access profile: ${accessSnapshot.error ?? 'No profile returned'}'),
            );
          }
          final profile = accessSnapshot.data!;
          bool can(String feature) => profile.allFeatures || profile.featureCodes.contains(feature);
          final menuCards = <Widget>[
            if (can('TENANT_MANAGEMENT'))
              _buildMenuCard(
                context,
                title: 'Tenants',
                subtitle: 'Manage instances',
                icon: Icons.business_rounded,
                color: const Color(0xFF1E88E5),
                onTap: () => Navigator.pushNamed(context, '/tenant'),
              ),
            if (can('TENANT_SUBSCRIPTIONS'))
              _buildMenuCard(
                context,
                title: 'Subscriptions',
                subtitle: 'Plans and packages',
                icon: Icons.workspace_premium_rounded,
                color: Colors.purple,
                onTap: () => Navigator.pushNamed(context, '/subscriptions'),
              ),
            if (can('USER_MANAGEMENT') || can('ROLE_MAINTENANCE') || can('AUDIT_LOGS'))
              _buildMenuCard(
                context,
                title: 'Security',
                subtitle: 'Users, roles and audit',
                icon: Icons.security_rounded,
                color: Colors.orange,
                onTap: () => Navigator.pushNamed(context, '/access'),
              ),
          ];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: profile.user.testUser ? Colors.orange.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: profile.user.testUser ? Colors.orange.shade200 : Colors.blue.shade200),
                  ),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(profile.user.protectedUser ? Icons.shield_rounded : Icons.person_rounded),
                      Text(profile.user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ...profile.roles.map((role) => Chip(label: Text(role))),
                      if (profile.user.testUser) const Chip(label: Text('TEST USER')),
                      if (profile.allFeatures) const Chip(label: Text('ALL FEATURES')),
                      Chip(label: Text(profile.environment.toUpperCase())),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Welcome Back, ${profile.user.username}', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Manage only the platform features assigned through Admin Role Maintenance.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
                if (can('TENANT_MANAGEMENT')) ...[
                  const SizedBox(height: 24),
                  FutureBuilder<AdminDashboardSummary>(
                    future: tenantService.getDashboardSummary(),
                    builder: (context, snapshot) {
                      final summary = snapshot.data;
                      return Wrap(spacing: 12, runSpacing: 12, children: [
                        _buildSummaryChip('Tenants', summary?.totalTenants.toString() ?? '...', Icons.business_rounded),
                        _buildSummaryChip('Active', summary?.activeTenants.toString() ?? '...', Icons.check_circle_rounded),
                        _buildSummaryChip('Suspended', summary?.suspendedTenants.toString() ?? '...', Icons.pause_circle_rounded),
                        _buildSummaryChip('Subscriptions', summary?.activeSubscriptions.toString() ?? '...', Icons.workspace_premium_rounded),
                      ]);
                    },
                  ),
                ],
                const SizedBox(height: 32),
                if (menuCards.isEmpty)
                  const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('No Admin Console features are assigned to your current roles.')))
                else
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.5,
                    children: menuCards,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryChip(String label, String value, IconData icon) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1E88E5)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
