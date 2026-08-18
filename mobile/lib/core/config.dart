import 'dart:io';

class AppConfig {
  AppConfig._();

  static const String _envBaseUrl = String.fromEnvironment('ZYNORA_API_BASE_URL', defaultValue: '');
  static const String _envSocketUrl = String.fromEnvironment('ZYNORA_SOCKET_URL', defaultValue: '');
  static const String _appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'production');
  // Single production backend. Legacy hosting is intentionally not used.
  static const String _productionBaseUrl = 'https://zornor.onrender.com';

  static String _normalize(String value) => value.trim().replaceFirst(RegExp(r'/+$'), '');

  static String apiBaseUrl() {
    if (_envBaseUrl.trim().isNotEmpty) return _normalize(_envBaseUrl);
    if (_appEnv == 'production') return _productionBaseUrl;
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  static String socketBaseUrl() {
    if (_envSocketUrl.trim().isNotEmpty) return _normalize(_envSocketUrl);
    return apiBaseUrl();
  }

  static const Duration httpClientTimeout = Duration(seconds: 12);
  static const Duration socketConnectTimeout = Duration(seconds: 12);
}
