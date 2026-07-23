import 'package:flutter/material.dart';
import '../../core/error_utils.dart';
import '../../core/theme.dart';
import '../../core/notification_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/app_error_dialog.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  bool _resendCooldown = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_emailController.text.trim().isEmpty) {
      AppNotification.showError('Enter your email');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await AuthService.sendOtp(_emailController.text.trim(), 'forgot');
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

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.resetPassword(
        _emailController.text.trim(),
        _otpController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        AppNotification.showSuccess('Password reset. You can sign in now.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showAppError(context, message: userFacingErrorMessage(e), title: 'Reset failed');
      }
    }
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.pop(context),
                      color: AppTheme.surfaceLight,
                    ),
                    const Text(
                      'Forgot password',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        // Step 1: Email
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                                      color: AppTheme.primaryAccent.withValues(alpha: 0.4),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '1',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.surfaceLight,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Enter your email',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.surfaceLight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'We’ll send a 6-digit OTP to this address.',
                                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                readOnly: _otpSent,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: TextStyle(color: AppTheme.textMuted),
                                  prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMuted),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.08),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Enter email';
                                  if (!v.contains('@')) return 'Enter a valid email';
                                  return null;
                                },
                              ),
                              if (!_otpSent) ...[
                                const SizedBox(height: 24),
                                CustomButton(
                                  text: _loading ? 'Sending…' : 'Send OTP',
                                  onTap: _loading ? () {} : _sendOtp,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (_otpSent) ...[
                          const SizedBox(height: 28),
                          // Step 2: OTP + New password
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                                        color: AppTheme.primaryAccent.withValues(alpha: 0.4),
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
                                      'OTP & new password',
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
                                  'Check your inbox (and spam). Enter the code and choose a new password.',
                                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'OTP',
                                    hintText: '6-digit code',
                                    labelStyle: TextStyle(color: AppTheme.textMuted),
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
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'New password',
                                    labelStyle: TextStyle(color: AppTheme.textMuted),
                                    prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textMuted),
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.08),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.length < 6) return 'At least 6 characters';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: TextButton(
                                    onPressed: _resendCooldown || _loading ? null : _sendOtp,
                                    child: Text(
                                      _resendCooldown ? 'Resend OTP (wait 60s)' : 'Resend OTP',
                                      style: TextStyle(color: AppTheme.primaryAccent, fontSize: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                CustomButton(
                                  text: _loading ? 'Resetting…' : 'Reset password',
                                  onTap: _loading ? () {} : _reset,
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
