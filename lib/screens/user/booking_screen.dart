import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../core/error_utils.dart';
import '../../core/theme.dart';
import '../../core/notification_service.dart';
import '../../models/vault_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../services/user_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, this.vault});

  final VaultModel? vault;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool _loading = false;
  bool _success = false;

  static bool _isValidUpiId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    return RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+$').hasMatch(trimmed);
  }

  Future<void> _confirmBook(String paymentMethod) async {
    if (widget.vault == null) return;
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() => _loading = true);
    try {
      await BookingService.createBooking(token, widget.vault!.id, paymentMethod: paymentMethod);
      if (mounted) {
        await context.read<AuthProvider>().refreshProfile();
        if (!mounted) return;
        setState(() { _loading = false; _success = true; });
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/userHome', (r) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        AppNotification.showError(userFacingErrorMessage(e));
      }
    }
  }

  Future<void> _payWithWallet() async {
    final auth = context.read<AuthProvider>();
    if (auth.token != null) {
      try {
        await auth.refreshProfile();
      } catch (_) {}
    }
    if (!mounted) return;
    if (!auth.mpinSet) {
      AppNotification.showError('Set MPIN in Wallet first to pay with wallet');
      return;
    }
    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _VerifyMpinDialog(
        onVerified: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
      ),
    );
    if (verified == true && mounted) _confirmBook('wallet');
  }

  Future<void> _payWithUpi() async {
    final v = widget.vault!;
    final auth = context.read<AuthProvider>();
    final savedUpi = await auth.getUpiId();
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UpiPaySheet(
        amount: v.price,
        initialUpiId: savedUpi ?? '',
        isValidUpi: _isValidUpiId,
        onSaveUpi: (id) => auth.setUpiId(id),
      ),
    );
    if (result != null && result['pay'] == true && mounted) _confirmBook('upi');
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vault;
    if (v == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking')),
        body: const Center(child: Text('No locker selected')),
      );
    }
    final dateTimeText = v.slotDate.isNotEmpty ? '${v.slotDate} • ${v.timeSlot}' : v.timeSlot;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B263B), Color(0xFF0D1B2A)],
          ),
        ),
        child: _success
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.network(
                        "https://assets10.lottiefiles.com/packages/lf20_jbrw3hcz.json",
                        height: 150,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Booking confirmed',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppTheme.surfaceLight),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Locker ${v.lockerNo} is now in your dashboard.',
                        style: TextStyle(fontSize: 14, color: AppTheme.textMuted.withValues(alpha: 0.95)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () => Navigator.pop(context),
                            color: AppTheme.surfaceLight,
                          ),
                          Text(
                            'Pay & book',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.surfaceLight),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              'Amount to pay',
                              style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                            ),
                            Text(
                              '₹${v.price.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryAccent.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.lock_rounded, color: AppTheme.surfaceLight, size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          v.lockerNo.isNotEmpty ? 'Locker ${v.lockerNo}' : 'Locker',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          v.location,
                                          style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                                        ),
                                        Text(dateTimeText, style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                            Text(
                              'Choose payment method',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.surfaceLight),
                            ),
                            const SizedBox(height: 16),
                            Consumer<AuthProvider>(
                              builder: (_, auth, __) {
                                final canUseWallet = auth.walletBalance >= v.price;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (canUseWallet) ...[
                                      _PaymentCard(
                                        icon: Icons.account_balance_wallet_rounded,
                                        title: 'Wallet',
                                        subtitle: 'Balance: ₹${auth.walletBalance.toStringAsFixed(0)}',
                                        amount: v.price,
                                        onTap: _loading ? null : _payWithWallet,
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    _PaymentCard(
                                      icon: Icons.phone_android_rounded,
                                      title: 'UPI',
                                      subtitle: 'GPay, PhonePe, Paytm & more',
                                      amount: v.price,
                                      onTap: _loading ? null : _payWithUpi,
                                    ),
                                    if (!canUseWallet && auth.walletBalance > 0) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        'Add ₹${(v.price - auth.walletBalance).toStringAsFixed(0)} more to use wallet',
                                        style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                    if (_loading)
                      Container(
                        padding: const EdgeInsets.all(20),
                        color: Colors.black26,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Text('Processing…', style: TextStyle(color: AppTheme.surfaceLight)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double amount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppTheme.primaryAccent, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primaryAccent),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerifyMpinDialog extends StatefulWidget {
  const _VerifyMpinDialog({required this.onVerified, required this.onCancel});

  final VoidCallback onVerified;
  final VoidCallback onCancel;

  @override
  State<_VerifyMpinDialog> createState() => _VerifyMpinDialogState();
}

class _VerifyMpinDialogState extends State<_VerifyMpinDialog> {
  final _pinController = TextEditingController();
  bool _obscure = true;
  bool _verifying = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final pin = _pinController.text.trim();
    if (pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() => _error = 'Enter 4-digit MPIN');
      return;
    }
    setState(() { _error = null; _verifying = true; });
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) {
      if (mounted) setState(() { _verifying = false; _error = 'Please sign in again'; });
      return;
    }
    try {
      final ok = await UserService.verifyMpin(token, pin);
      if (!mounted) return;
      setState(() => _verifying = false);
      if (ok) {
        widget.onVerified();
      } else {
        setState(() => _error = 'Wrong MPIN');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = 'Wrong MPIN';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1B263B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.lock_rounded, color: AppTheme.primaryAccent, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Enter MPIN',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.surfaceLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Confirm MPIN to pay with wallet',
              style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _pinController,
              obscureText: _obscure,
              keyboardType: TextInputType.number,
              maxLength: 4,
              style: const TextStyle(
                fontSize: 22,
                letterSpacing: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: 'MPIN',
                counterText: '',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: AppTheme.textMuted,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.primaryAccent, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _verifying ? null : widget.onCancel,
                    child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _verifying ? null : _verify,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _verifying
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Verify'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UpiPaySheet extends StatefulWidget {
  const _UpiPaySheet({
    required this.amount,
    required this.initialUpiId,
    required this.isValidUpi,
    required this.onSaveUpi,
  });

  final double amount;
  final String initialUpiId;
  final bool Function(String) isValidUpi;
  final void Function(String) onSaveUpi;

  @override
  State<_UpiPaySheet> createState() => _UpiPaySheetState();
}

class _UpiPaySheetState extends State<_UpiPaySheet> {
  late TextEditingController _upiController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _upiController = TextEditingController(text: widget.initialUpiId);
  }

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }

  void _pay() {
    final upi = _upiController.text.trim();
    if (!widget.isValidUpi(upi)) {
      setState(() => _error = 'Enter valid UPI ID (e.g. name@bank)');
      return;
    }
    setState(() => _error = null);
    widget.onSaveUpi(upi);
    Navigator.of(context).pop({'pay': true, 'upiId': upi});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1B263B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Pay with UPI',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.surfaceLight),
            ),
            const SizedBox(height: 8),
            Text('Amount to pay', style: TextStyle(fontSize: 14, color: AppTheme.textMuted)),
            Text(
              '₹${widget.amount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _upiController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              style: const TextStyle(fontSize: 16, color: Colors.white),
              decoration: InputDecoration(
                labelText: 'UPI ID',
                hintText: 'name@bank or name@upi',
                hintStyle: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.8)),
                errorText: _error,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.primaryAccent, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _pay,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Pay ₹${widget.amount.toStringAsFixed(0)} (Demo)'),
            ),
            const SizedBox(height: 8),
            Text(
              'Demo payment – no real UPI transaction',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
          ],
        ),
      ),
    );
  }
}
