import 'dart:html' as html;

class ExternalWindowHandle {
  final html.WindowBase? window;
  const ExternalWindowHandle(this.window);
}

/// Reserve a browser tab synchronously while still inside the click event.
/// This prevents popup blockers from rejecting the tab after the handoff API
/// request completes.
ExternalWindowHandle reserveExternalWindow() {
  return ExternalWindowHandle(html.window.open('about:blank', '_blank'));
}

Future<bool> navigateExternalWindow(ExternalWindowHandle handle, String url) async {
  if (handle.window != null) {
    handle.window!.location.href = url;
    return true;
  }
  // Popup was blocked. Same-tab navigation remains reliable.
  html.window.location.href = url;
  return true;
}

void closeExternalWindow(ExternalWindowHandle handle) {
  handle.window?.close();
}

Future<bool> openExternalUrl(String url) async {
  final handle = reserveExternalWindow();
  return navigateExternalWindow(handle, url);
}
