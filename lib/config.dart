import 'package:flutter/foundation.dart';

enum Environment { dev, alpha, beta, prod }

class AppConfig {
  static Environment get environment {
    // 1. Check for environment variable (e.g., flutter run --dart-define=ENVIRONMENT=prod)
    // Supports both 'ENVIRONMENT' and 'env' (as used in Dockerfile)
    const env = String.fromEnvironment('ENVIRONMENT', defaultValue: '');
    const envAlt = String.fromEnvironment('env', defaultValue: '');
    final envString = env.isNotEmpty ? env : envAlt;

    if (envString.isNotEmpty) {
      switch (envString.toLowerCase()) {
        case 'dev': return Environment.dev;
        case 'alpha': return Environment.alpha;
        case 'beta': return Environment.beta;
        case 'prod': return Environment.prod;
      }
    }

    // 2. Web Host detection as fallback
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1' || host.contains('dev.admin.app.mawa.co.za')) {
        return Environment.dev;
      }
      if (host.contains('alpha.admin.app.mawa.co.za')) {
        return Environment.alpha;
      }
      if (host.contains('beta.admin.app.mawa.co.za')) {
        return Environment.beta;
      }
      if (host.contains('admin.app.mawa.co.za')) {
        return Environment.prod;
      }
    }
    
    // 3. Fallback based on build mode
    if (kReleaseMode) {
      return Environment.prod;
    }
    return Environment.dev;
  }

  static String get apiBaseUrl {
    // Allow overriding via --dart-define=API_BASE_URL=...
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;

    switch (environment) {
      case Environment.dev:
        return 'https://dev.admin.api.app.mawa.co.za';
      case Environment.alpha:
        return 'https://alpha.admin.api.app.mawa.co.za';
      case Environment.beta:
        return 'https://beta.admin.api.app.mawa.co.za';
      case Environment.prod:
        return 'https://admin.api.app.mawa.co.za';
    }
  }

  static String get tenantUrl {
    // Allow overriding via --dart-define=TENANT_URL=...
    const fromEnv = String.fromEnvironment('TENANT_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;

    switch (environment) {
      case Environment.dev:
        return 'https://dev.admin.app.mawa.co.za';
      case Environment.alpha:
        return 'https://alpha.admin.app.mawa.co.za';
      case Environment.beta:
        return 'https://beta.admin.app.mawa.co.za';
      case Environment.prod:
        return 'https://admin.app.mawa.co.za';
    }
  }
}
