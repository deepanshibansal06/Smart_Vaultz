import 'package:flutter/material.dart';
import '../models/vault_model.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/user/user_dashboard.dart';
import '../screens/user/vault_list_screen.dart';
import '../screens/user/booking_screen.dart';
import '../screens/user/profile_screen.dart';
import '../screens/user/contact_screen.dart';
import '../screens/user/user_home_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/create_vault_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/': (_) => const SplashScreen(),
    '/login': (_) => const LoginScreen(),
    '/signup': (_) => const SignupScreen(),
    '/forgotPassword': (_) => const ForgotPasswordScreen(),
    '/userDashboard': (_) => const UserDashboard(),
    '/userHome': (_) => const UserHomeScreen(),
    '/vaultList': (_) => const VaultListScreen(),
    '/booking': (ctx) {
      final v = ModalRoute.of(ctx)?.settings.arguments as VaultModel?;
      return BookingScreen(vault: v);
    },
    '/profile': (_) => const ProfileScreen(),
    '/contact': (_) => const ContactScreen(),
    '/adminDashboard': (_) => const AdminDashboard(),
    '/createVault': (ctx) {
      final v = ModalRoute.of(ctx)?.settings.arguments as VaultModel?;
      return CreateVaultScreen(editVault: v);
    },
  };
}