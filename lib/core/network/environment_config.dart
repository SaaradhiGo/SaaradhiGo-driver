import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentConfig {
  static Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }

  static String get apiBaseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'https://dev.api.saaradhigo.in/';
  }

  static String get wsBaseUrl {
    return dotenv.env['WS_BASE_URL'] ?? 'ws://dev.api.saaradhigo.in/';
  }
}
