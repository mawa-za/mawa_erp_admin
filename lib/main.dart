import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/tenant_list_screen.dart';
import 'screens/subscription_plans_screen.dart';
import 'screens/billing_modules_screen.dart';
import 'screens/billing_management_screen.dart';
import 'screens/access_management_screen.dart';
import 'screens/industry_profiles_screen.dart';
import 'services/auth_service.dart';
import 'services/tenant_service.dart';
import 'services/access_management_service.dart';
import 'models/access_management.dart';
import 'models/platform_management.dart';
import 'config.dart';
import 'theme/admin_theme.dart';

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
      theme: AdminTheme.light,
      builder: (context, child) => ColoredBox(
        color: AdminDesign.page,
        child: SizedBox.expand(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MyHomePage(title: 'mawa Admin'),
        '/tenant': (context) => const TenantListScreen(),
        '/subscriptions': (context) => const SubscriptionPlansScreen(),
        '/billing-modules': (context) => const BillingModulesScreen(),
        '/billing': (context) => const BillingManagementScreen(),
        '/access': (context) => const AccessManagementScreen(),
        '/industries': (context) => const IndustryProfilesScreen(),
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminAccessProfile>(
      future: AccessManagementService().getProfile(),
      builder: (context, accessSnapshot) {
        if (accessSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (accessSnapshot.hasError || !accessSnapshot.hasData) {
          return Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          color: AdminDesign.red,
                          size: 42,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Unable to load access profile',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${accessSnapshot.error ?? 'No profile returned'}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AdminDesign.muted,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final profile = accessSnapshot.data!;
        bool can(String feature) =>
            profile.allFeatures || profile.featureCodes.contains(feature);
        final width = MediaQuery.sizeOf(context).width;
        final showSidebar = width >= 1040;
        final modules = <_AdminModule>[
          if (can('TENANT_MANAGEMENT'))
            const _AdminModule(
              title: 'Tenant management',
              description:
                  'Provision, configure and maintain MAWA tenant environments.',
              icon: Icons.business_rounded,
              colour: AdminDesign.red,
              route: '/tenant',
            ),
          if (can('INDUSTRY_PROFILE_MANAGEMENT'))
            const _AdminModule(
              title: 'Industry profiles',
              description:
                  'Define industry experiences, terminology and workcenter grouping defaults.',
              icon: Icons.domain_add_rounded,
              colour: Color(0xFF2563EB),
              route: '/industries',
            ),
          if (can('BILLING_MANAGEMENT'))
            const _AdminModule(
              title: 'Billing & subscriptions',
              description:
                  'Manage plans, tenant subscriptions, invoices and billing activity.',
              icon: Icons.account_balance_wallet_rounded,
              colour: Color(0xFF8B5CF6),
              route: '/billing',
            )
          else if (can('TENANT_SUBSCRIPTIONS'))
            const _AdminModule(
              title: 'Subscriptions',
              description:
                  'Maintain legacy subscription plans and tenant assignments.',
              icon: Icons.workspace_premium_rounded,
              colour: Color(0xFF8B5CF6),
              route: '/subscriptions',
            ),
          if (can('USER_MANAGEMENT') ||
              can('ROLE_MAINTENANCE') ||
              can('AUDIT_LOGS'))
            const _AdminModule(
              title: 'Security & access',
              description:
                  'Manage administrators, roles, feature access and audit history.',
              icon: Icons.security_rounded,
              colour: AdminDesign.warning,
              route: '/access',
            ),
        ];

        return Scaffold(
          backgroundColor: AdminDesign.page,
          body: Row(
            children: [
              if (showSidebar) _buildSidebar(context, modules),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(context, profile, showLogo: !showSidebar),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          width < 700 ? 16 : 28,
                          24,
                          width < 700 ? 16 : 28,
                          32,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildWelcomeHeader(context, profile),
                              const SizedBox(height: 20),
                              _buildProfileBanner(context, profile),
                              if (can('TENANT_MANAGEMENT')) ...[
                                const SizedBox(height: 20),
                                _buildDashboardMetrics(context),
                              ],
                              const SizedBox(height: 28),
                              Text(
                                'Administration workcenters',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Open a workcenter to manage the assigned platform responsibilities.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AdminDesign.muted),
                              ),
                              const SizedBox(height: 16),
                              if (modules.isEmpty)
                                const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(28),
                                    child: Row(
                                      children: [
                                        Icon(Icons.lock_outline_rounded),
                                        SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            'No Admin Console features are assigned to your current roles.',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    return GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 360,
                                        mainAxisExtent: 224,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                      ),
                                      itemCount: modules.length,
                                      itemBuilder: (context, index) =>
                                          _buildModuleCard(
                                        context,
                                        modules[index],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    List<_AdminModule> modules,
  ) {
    return Container(
      width: 224,
      decoration: const BoxDecoration(
        color: AdminDesign.surface,
        border: Border(right: BorderSide(color: AdminDesign.border)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              child: Image.asset(
                'assets/branding/mawa_logo.png',
                height: 38,
                alignment: Alignment.centerLeft,
              ),
            ),
            const Divider(),
            const SizedBox(height: 12),
            _sidebarItem(
              context,
              icon: Icons.home_rounded,
              label: 'Dashboard',
              selected: true,
              onTap: () {},
            ),
            ...modules.map(
              (module) => _sidebarItem(
                context,
                icon: module.icon,
                label: module.title,
                onTap: () => Navigator.pushNamed(context, module.route),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                'v1.0.7+8 • ${AppConfig.environment.name}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AdminDesign.muted,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
              child: OutlinedButton.icon(
                onPressed: () => _signOut(context),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign out'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebarItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? AdminDesign.redSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? AdminDesign.red : AdminDesign.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? AdminDesign.navy : AdminDesign.muted,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    AdminAccessProfile profile, {
    required bool showLogo,
  }) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: AdminDesign.surface,
        border: Border(bottom: BorderSide(color: AdminDesign.border)),
      ),
      child: Row(
        children: [
          if (showLogo) ...[
            Image.asset('assets/branding/mawa_logo.png', height: 34),
            const SizedBox(width: 16),
          ],
          Text('Admin Console', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AdminDesign.redSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              profile.environment.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AdminDesign.redDark,
                  ),
            ),
          ),
          const SizedBox(width: 14),
          CircleAvatar(
            radius: 18,
            backgroundColor: AdminDesign.redSoft,
            child: Text(
              profile.user.username.isEmpty
                  ? 'A'
                  : profile.user.username[0].toUpperCase(),
              style: const TextStyle(
                color: AdminDesign.redDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (MediaQuery.sizeOf(context).width >= 720)
            Text(
              profile.user.username,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(
    BuildContext context,
    AdminAccessProfile profile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, ${profile.user.username}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 7),
        Text(
          'Manage the MAWA platform features assigned through Admin Role Maintenance.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AdminDesign.muted,
              ),
        ),
      ],
    );
  }

  Widget _buildProfileBanner(
    BuildContext context,
    AdminAccessProfile profile,
  ) {
    final accent = profile.user.testUser
        ? AdminDesign.warning
        : profile.user.protectedUser
            ? AdminDesign.red
            : AdminDesign.info;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(
            profile.user.protectedUser
                ? Icons.shield_rounded
                : Icons.person_rounded,
            color: accent,
          ),
          Text(
            profile.user.username,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          ...profile.roles.map((role) => Chip(label: Text(role))),
          if (profile.user.testUser) const Chip(label: Text('TEST USER')),
          if (profile.allFeatures) const Chip(label: Text('ALL FEATURES')),
        ],
      ),
    );
  }

  Widget _buildDashboardMetrics(BuildContext context) {
    return FutureBuilder<AdminDashboardSummary>(
      future: TenantService().getDashboardSummary(),
      builder: (context, snapshot) {
        final summary = snapshot.data;
        final metrics = [
          _Metric(
            'Total tenants',
            summary?.totalTenants.toString() ?? '—',
            Icons.business_rounded,
            AdminDesign.red,
          ),
          _Metric(
            'Active tenants',
            summary?.activeTenants.toString() ?? '—',
            Icons.check_circle_rounded,
            AdminDesign.success,
          ),
          _Metric(
            'Suspended',
            summary?.suspendedTenants.toString() ?? '—',
            Icons.pause_circle_rounded,
            AdminDesign.warning,
          ),
          _Metric(
            'Subscriptions',
            summary?.activeSubscriptions.toString() ?? '—',
            Icons.workspace_premium_rounded,
            const Color(0xFF8B5CF6),
          ),
        ];
        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 980
                ? 4
                : constraints.maxWidth >= 520
                    ? 2
                    : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: columns == 1 ? 3.1 : 1.75,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: metrics.length,
              itemBuilder: (context, index) =>
                  _buildMetricCard(context, metrics[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCard(BuildContext context, _Metric metric) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AdminDesign.muted,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    metric.value,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: metric.colour.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(metric.icon, color: metric.colour, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, _AdminModule module) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, module.route),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: module.colour.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(module.icon, color: module.colour, size: 25),
                  ),
                  const Spacer(),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.arrow_outward_rounded,
                      size: 16,
                      color: AdminDesign.muted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(module.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 7),
              Text(
                module.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AdminDesign.muted,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Open  →',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AdminDesign.red,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: AdminDesign.red),
        title: const Text('Sign out of MAWA Admin?'),
        content: const Text(
          'You will need to sign in again to manage MAWA tenants and platform settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AuthService().logout();
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}

class _AdminModule {
  final String title;
  final String description;
  final IconData icon;
  final Color colour;
  final String route;

  const _AdminModule({
    required this.title,
    required this.description,
    required this.icon,
    required this.colour,
    required this.route,
  });
}

class _Metric {
  final String label;
  final String value;
  final IconData icon;
  final Color colour;

  const _Metric(this.label, this.value, this.icon, this.colour);
}
