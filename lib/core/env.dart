import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'env_defaults.dart';

class Env {
  static String get baseUrl {
    final url = dotenv.env['BASE_URL']?.trim();
    if (url != null && url.isNotEmpty) return url;
    return EnvDefaults.baseUrl;
  }
}