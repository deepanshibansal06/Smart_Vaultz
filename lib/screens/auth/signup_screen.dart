import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../core/theme.dart';
import '../../core/error_utils.dart';
import '../../core/notification_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/app_error_dialog.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final otpController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  bool _otpSent = false;
  bool _resendCooldown = false;

  Future<void> _sendOtp() async {
    if (name.text.trim().isEmpty || email.text.trim().isEmpty || password.text.isEmpty) {
      AppNotification.showError('Fill name, email and password first');
      return;
    }
    if (!email.text.contains('@')) {
      AppNotification.showError('Enter a valid email');
      return;
    }
    if (password.text.length < 6) {
      AppNotification.showError('Password at least 6 characters');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await AuthService.sendOtp(email.text.trim(), 'signup');
      if (mounted) {
        setState(() { _otpSent = true; _loading = false; _resendCooldown = true; });
        final msg = result['checkSpamNotice'] != null
            ? '${result['message']} Check your spam folder if you don\'t see it.'
            : (result['message'] ?? 'OTP sent to your email');
        AppNotification.showSuccess(msg);
        Future.delayed(const Duration(seconds: 60), () {
          if (mounted) setState(() => _resendCooldown = false);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showAppError(context, message: userFacingErrorMessage(e), title: 'Send OTP failed');
      }
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_otpSent && (otpController.text.trim().length != 6)) {
      AppNotification.showError('Enter 6-digit OTP');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.signup(
        name.text.trim(),
        email.text.trim(),
        password.text,
        otp: _otpSent ? otpController.text.trim() : null,
      );
      if (!mounted) return;
      AppNotification.showSuccess('Account created. You can sign in now.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      await showAppError(context, message: userFacingErrorMessage(e), title: 'Create account failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    otpController.dispose();
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
            colors: [Color(0xFF0D1B2A), Color(0xFF1B263B)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add_rounded,
                      size: 52,
                      color: AppTheme.surfaceLight.withValues(alpha: 0.9),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Create account',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.surfaceLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Join SmartVaultz',
                      style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 32),
                    // Step 1: Name, email, password
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
                            controller: name,
                            textCapitalization: TextCapitalization.words,
                            readOnly: _otpSent,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter name';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            readOnly: _otpSent,
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
                            readOnly: _otpSent,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: _otpSent
                                  ? null
                                  : IconButton(
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
                              if (v.length < 6) return 'Password at least 6 characters';
                              return null;
                            },
                          ),
                          if (!_otpSent) ...[
                            const SizedBox(height: 28),
                            CustomButton(
                              text: _loading ? 'Sending…' : 'Send OTP',
                              onTap: _loading ? () {} : _sendOtp,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Step 2: OTP (separate card when OTP sent)
                    if (_otpSent) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryAccent.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '2',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.surfaceLight,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Verify with OTP',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.surfaceLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'We sent a 6-digit code to your email. Check spam if you don’t see it.',
                              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: otpController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                              decoration: InputDecoration(
                                labelText: 'OTP',
                                hintText: '6-digit code',
                                labelStyle: TextStyle(color: AppTheme.textMuted),
                                hintStyle: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.7)),
                                prefixIcon: Icon(Icons.pin_rounded, color: AppTheme.textMuted),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.08),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().length != 6) return 'Enter 6-digit OTP';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                onPressed: _resendCooldown || _loading ? null : _sendOtp,
                                child: Text(
                                  _resendCooldown ? 'Resend OTP (wait 60s)' : 'Resend OTP',
                                  style: TextStyle(color: AppTheme.primaryAccent, fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            CustomButton(
                              text: _loading ? 'Creating account…' : 'Create account',
                              onTap: _loading ? () {} : _signup,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _loading ? null : () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                          children: [
                            const TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Sign in',
                              style: TextStyle(
                                color: AppTheme.primaryAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
