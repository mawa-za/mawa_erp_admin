class ExternalWindowHandle {
  const ExternalWindowHandle();
}

ExternalWindowHandle reserveExternalWindow() => const ExternalWindowHandle();

Future<bool> navigateExternalWindow(ExternalWindowHandle handle, String url) async => false;

void closeExternalWindow(ExternalWindowHandle handle) {}

Future<bool> openExternalUrl(String url) async => false;
