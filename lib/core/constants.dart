import 'env.dart';

class AppConstants {
  /// Same value as in .env BASE_URL (or fallback when unset). Use this for display or config.
  static String get baseUrl => Env.baseUrl;
}