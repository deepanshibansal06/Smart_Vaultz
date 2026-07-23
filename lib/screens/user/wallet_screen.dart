import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/error_utils.dart';
import '../../core/theme.dart';
import '../../core/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _amountController = TextEditingController();
  bool _adding = false;
  bool _showSuccess = false;
  double _lastAddedAmount = 0;
  bool _mpinSet = false;

  @override
  void initState() {
    super.initState();
    _loadMpinStatus();
  }

  Future<void> _loadMpinStatus() async {
    final auth = context.read<AuthProvider>();
    // After logout/login we have no local PIN; refresh profile so mpinSet from DB is used (don't ask to set again)
    final localSet = await auth.hasMpinSet();
    if (auth.token != null && !localSet) {
      try {
        await auth.refreshProfile();
      } catch (_) {}
    }
    if (!mounted) return;
    final fromDb = auth.mpinSet;
    if (mounted) setState(() => _mpinSet = localSet || fromDb);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _openSetMpinDialog() async {
    final auth = context.read<AuthProvider>();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SetMpinDialog(isChange: _mpinSet),
    );
    if (ok == true && mounted) await _loadMpinStatus();
  }

  Future<void> _addMoney() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      AppNotification.showError('Enter a valid amount');
      return;
    }
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() => _adding = true);
    try {
      final newBalance = await UserService.addWalletMoney(token, amount);
      if (!mounted) return;
      setState(() {
        _lastAddedAmount = amount;
        _adding = false;
        _showSuccess = true;
        _amountController.clear();
      });
      context.read<AuthProvider>().setWalletBalance(newBalance);
      await Future.delayed(const Duration(milliseconds: 2200));
      if (mounted) setState(() => _showSuccess = false);
    } catch (e) {
      if (mounted) {
        setState(() => _adding = false);
        AppNotification.showError(userFacingErrorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        title: const Text('Wallet'),
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1B263B), Color(0xFF0D1B2A)],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    _BalanceCard(balance: auth.walletBalance),
                    const SizedBox(height: 32),
                    _AddMoneyCard(
                      amountController: _amountController,
                      adding: _adding,
                      onAddMoney: _addMoney,
                    ),
                    const SizedBox(height: 24),
                    _SetMpinCard(
                      mpinSet: _mpinSet,
                      onTap: _openSetMpinDialog,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          if (_showSuccess) _PaymentSuccessOverlay(amount: _lastAddedAmount),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final double balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryAccent.withValues(alpha: 0.5),
            AppTheme.primaryAccent.withValues(alpha: 0.25),
            const Color(0xFF0D1B2A),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryAccent.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Available balance',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                balance.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddMoneyCard extends StatelessWidget {
  const _AddMoneyCard({
    required this.amountController,
    required this.adding,
    required this.onAddMoney,
  });

  final TextEditingController amountController;
  final bool adding;
  final VoidCallback onAddMoney;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryAccent, size: 24),
              const SizedBox(width: 10),
              Text(
                'Add money',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.surfaceLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enter amount to add to your wallet',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(
                color: AppTheme.textMuted.withValues(alpha: 0.6),
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 18, right: 12),
                child: Text(
                  '₹',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryAccent,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppTheme.primaryAccent, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: adding ? null : onAddMoney,
            icon: adding
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.add_rounded, size: 24),
            label: Text(adding ? 'Adding…' : 'Add money'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSuccessOverlay extends StatefulWidget {
  const _PaymentSuccessOverlay({required this.amount});

  final double amount;

  @override
  State<_PaymentSuccessOverlay> createState() => _PaymentSuccessOverlayState();
}

class _PaymentSuccessOverlayState extends State<_PaymentSuccessOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
            decoration: BoxDecoration(
              color: const Color(0xFF1B263B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 72,
                    color: Colors.green.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Payment successful',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.surfaceLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${widget.amount.toStringAsFixed(0)} added to wallet',
                  style: TextStyle(fontSize: 16, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetMpinCard extends StatelessWidget {
  const _SetMpinCard({required this.mpinSet, required this.onTap});

  final bool mpinSet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.lock_rounded,
                  color: AppTheme.surfaceLight,
                  size: 28,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mpinSet ? 'Change payment MPIN' : 'Set payment MPIN',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mpinSet
                          ? 'Use this MPIN when paying with wallet'
                          : 'Set a 4-digit MPIN to pay using wallet',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetMpinDialog extends StatefulWidget {
  const _SetMpinDialog({required this.isChange});

  final bool isChange;

  @override
  State<_SetMpinDialog> createState() => _SetMpinDialogState();
}

class _SetMpinDialogState extends State<_SetMpinDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePin = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();
    if (pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
      AppNotification.showError('Enter a 4-digit MPIN');
      return;
    }
    if (confirm != pin) {
      AppNotification.showError('MPIN and confirm MPIN do not match');
      return;
    }
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) {
      if (mounted) {
        setState(() => _saving = false);
        AppNotification.showError('Please sign in again');
      }
      return;
    }
    try {
      await UserService.setMpin(token, pin);
      await auth.refreshProfile();
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.of(context).pop(true);
      AppNotification.showSuccess(widget.isChange ? 'MPIN updated' : 'MPIN set for payments');
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppNotification.showError(userFacingErrorMessage(e));
      }
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
                Text(
                  widget.isChange ? 'Change MPIN' : 'Set MPIN',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.surfaceLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Enter 4-digit MPIN for wallet payments',
              style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _pinController,
              obscureText: _obscurePin,
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
                    _obscurePin ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: AppTheme.textMuted,
                  ),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
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
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              keyboardType: TextInputType.number,
              maxLength: 4,
              style: const TextStyle(
                fontSize: 22,
                letterSpacing: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: 'Confirm MPIN',
                counterText: '',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: AppTheme.textMuted,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
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
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                    child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save'),
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
