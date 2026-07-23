import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/routes.dart';
import 'core/theme.dart';
import 'core/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/vault_provider.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    try {
      await dotenv.load(fileName: "assets/.env");
    } catch (_) {
      // .env missing; Env.baseUrl will use EnvDefaults.baseUrl (localhost)
    }
  }
  AppNotification.init(scaffoldMessengerKey);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VaultProvider()),
      ],
      child: const SmartVaultApp(),
    ),
  );
}

class SmartVaultApp extends StatelessWidget {
  const SmartVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'SmartVaultz',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: AppRoutes.routes,
    );
  }
}