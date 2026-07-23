import 'dart:io';

import 'env.dart';

/// Resolves base URL for mobile/desktop. On Android emulator, replaces
/// localhost with 10.0.2.2 so the app can reach the host machine.
String resolveBaseUrl(String baseUrl) {
  if (Platform.isAndroid &&
      (baseUrl.contains('localhost') || baseUrl.contains('127.0.0.1'))) {
    return baseUrl
        .replaceFirst(RegExp(r'localhost|127\.0\.0\.1'), '10.0.2.2');
  }
  return baseUrl;
}
