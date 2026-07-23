import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../../widgets/custom_button.dart';
import '../../core/error_utils.dart';
import '../../widgets/app_error_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await AuthService.login(email.text.trim(), password.text);
      await context.read<AuthProvider>().login(
            res['token']!,
            res['role']!,
            name: res['name'] as String?,
            email: res['email'] as String?,
          );
      if (!mounted) return;
      if (res["role"] == "superadmin") {
        Navigator.pushReplacementNamed(context, "/adminDashboard");
      } else {
        await context.read<AuthProvider>().refreshProfile();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, "/userHome");
      }
    } catch (e) {
      if (!mounted) return;
      await showAppError(context, message: userFacingErrorMessage(e), title: 'Sign in failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1B2A),
              Color(0xFF1B263B),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: 56,
                      color: AppTheme.surfaceLight.withValues(alpha: 0.9),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.surfaceLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to SmartVaultz',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter email';
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: password,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: AppTheme.textMuted,
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter password';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            text: _loading ? 'Signing in…' : 'Login',
                            onTap: _loading ? () {} : _login,
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _loading ? null : () => Navigator.pushNamed(context, "/forgotPassword"),
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => Navigator.pushNamed(context, "/signup"),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 14,
                                ),
                                children: [
                                  const TextSpan(text: "Don't have an account? "),
                                  TextSpan(
                                    text: 'Create account',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
