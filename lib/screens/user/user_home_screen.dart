import 'package:flutter/material.dart';
import 'user_dashboard.dart';
import 'vault_list_screen.dart';
import 'wallet_screen.dart';
import 'contact_screen.dart';
import '../../core/theme.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;
  final ValueNotifier<int> _dashboardRefreshTrigger = ValueNotifier(0);
  final ValueNotifier<int> _vaultListRefreshTrigger = ValueNotifier(0);

  @override
  void dispose() {
    _dashboardRefreshTrigger.dispose();
    _vaultListRefreshTrigger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          UserDashboard(
            onNavigateToBook: () => setState(() => _currentIndex = 1),
            refreshTrigger: _dashboardRefreshTrigger,
          ),
          VaultListScreen(showBackButton: false, refreshTrigger: _vaultListRefreshTrigger),
          const WalletScreen(showBackButton: false),
          const ContactScreen(showBackButton: false),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  selected: _currentIndex == 0,
                  onTap: () {
                    if (_currentIndex != 0) _dashboardRefreshTrigger.value++;
                    setState(() => _currentIndex = 0);
                  },
                ),
                _NavItem(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Book',
                  selected: _currentIndex == 1,
                  onTap: () {
                    if (_currentIndex != 1) _vaultListRefreshTrigger.value++;
                    setState(() => _currentIndex = 1);
                  },
                ),
                _NavItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Wallet',
                  selected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.contact_support_rounded,
                  label: 'Contact us',
                  selected: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: selected ? AppTheme.primaryAccent : AppTheme.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppTheme.primaryAccent : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
