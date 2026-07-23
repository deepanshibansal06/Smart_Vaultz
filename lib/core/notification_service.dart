import 'package:flutter/material.dart';
import 'theme.dart';

/// Global notification system. Call [init] from [MaterialApp] with [scaffoldMessengerKey],
/// then use [show] / [showSuccess] / [showError] from anywhere.
/// Uses app-styled floating toasts (dark theme, accent icons).
class AppNotification {
  static GlobalKey<ScaffoldMessengerState>? _messengerKey;

  static void init(GlobalKey<ScaffoldMessengerState> key) {
    _messengerKey = key;
  }

  static void show(
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final state = _messengerKey?.currentState;
    if (state == null) return;
    state.clearSnackBars();
    state.showSnackBar(
      SnackBar(
        content: _StyledNotificationContent(message: message, isError: isError),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        padding: EdgeInsets.zero,
      ),
    );
  }

  static void showSuccess(String message) {
    show(message, isError: false);
  }

  static void showError(String message) {
    show(message, isError: true);
  }
}

class _StyledNotificationContent extends StatelessWidget {
  const _StyledNotificationContent({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B263B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError
              ? Colors.red.shade400.withValues(alpha: 0.6)
              : AppTheme.primaryAccent.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isError
                  ? Colors.red.shade400.withValues(alpha: 0.2)
                  : Colors.green.shade400.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              size: 24,
              color: isError ? Colors.red.shade300 : Colors.green.shade300,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.surfaceLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
