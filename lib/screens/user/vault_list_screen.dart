import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vault_provider.dart';
import '../../services/vault_service.dart';
import '../../widgets/vault_card.dart';
import '../../core/theme.dart';
import '../../core/notification_service.dart';

class VaultListScreen extends StatefulWidget {
  const VaultListScreen({super.key, this.showBackButton = true, this.refreshTrigger});

  final bool showBackButton;
  /// When this fires (e.g. when user switches to Book tab), vault list is refetched
  /// so lockers that admin set to available appear.
  final ValueNotifier<int>? refreshTrigger;

  @override
  State<VaultListScreen> createState() => _VaultListScreenState();
}

class _VaultListScreenState extends State<VaultListScreen> {
  @override
  void initState() {
    super.initState();
    widget.refreshTrigger?.addListener(_onRefreshTriggered);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadVaults());
  }

  @override
  void didUpdateWidget(covariant VaultListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      oldWidget.refreshTrigger?.removeListener(_onRefreshTriggered);
      widget.refreshTrigger?.addListener(_onRefreshTriggered);
    }
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onRefreshTriggered);
    super.dispose();
  }

  void _onRefreshTriggered() {
    if (mounted) _loadVaults();
  }

  Future<void> _loadVaults() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final list = await VaultService.getVaults(token, availableOnly: true);
      if (mounted) {
        context.read<VaultProvider>().vaults = list;
        context.read<VaultProvider>().notifyListeners();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VaultProvider>();
    final vaults = provider.displayVaults;
    final isDummy = provider.vaults.isEmpty && vaults.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        title: const Text('Book a locker'),
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1B263B),
              Color(0xFF0D1B2A),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isDummy)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Text(
                  'Demo lockers — tap to book',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted.withValues(alpha: 0.95),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadVaults,
                color: AppTheme.primaryAccent,
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: vaults.length,
                  itemBuilder: (_, index) {
                    final vault = vaults[index];
                    final isDummyLocker = vault.id.startsWith('dummy');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: VaultCard(
                        vault: vault,
                        onTap: () {
                          if (isDummyLocker) {
                            AppNotification.showError(
                              'It\'s a demo locker. Booking can be done only on real locker.',
                            );
                            return;
                          }
                          Navigator.pushNamed(context, "/booking", arguments: vault);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
