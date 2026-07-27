import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawa_erp_admin/theme/admin_theme.dart';

void main() {
  testWidgets('Admin Console uses the shared MAWA visual language',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AdminTheme.light,
        home: const Scaffold(body: Text('Admin Console')),
      ),
    );

    final BuildContext context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).scaffoldBackgroundColor, AdminDesign.page);
    expect(Theme.of(context).colorScheme.primary, AdminDesign.red);
    expect(find.text('Admin Console'), findsOneWidget);
  });
}
