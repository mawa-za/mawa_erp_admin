import 'package:flutter_test/flutter_test.dart';
import 'package:mawa_erp_admin/config.dart';

void main() {
  test('maps the platform operator tenant host for every environment', () {
    expect(
      AppConfig.platformOperatorTenantHostFor(Environment.dev),
      'web.dev.app.mawa.co.za',
    );
    expect(
      AppConfig.platformOperatorTenantHostFor(Environment.alpha),
      'web.alpha.app.mawa.co.za',
    );
    expect(
      AppConfig.platformOperatorTenantHostFor(Environment.beta),
      'web.beta.app.mawa.co.za',
    );
    expect(
      AppConfig.platformOperatorTenantHostFor(Environment.prod),
      'web.app.mawa.co.za',
    );
  });
}
