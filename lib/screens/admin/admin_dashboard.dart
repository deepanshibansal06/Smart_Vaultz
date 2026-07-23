import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/error_utils.dart';
import '../../core/theme.dart';
import '../../models/vault_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vault_provider.dart';
import '../../services/admin_service.dart';
import '../../core/notification_service.dart';
import '../../services/vault_service.dart';
import '../../widgets/sign_out_dialog.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, int>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final stats = await AdminService.getDashboardStats(token);
      final vaults = await VaultService.getVaults(token);
      if (mounted) {
        context.read<VaultProvider>().vaults = vaults;
        context.read<VaultProvider>().notifyListeners();
        setState(() { _stats = stats; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = userFacingErrorMessage(e); _loading = false; });
    }
  }

  Future<void> _deleteVault(VaultModel vault) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete vault'),
        content: Text('Delete "${vault.location}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      await VaultService.deleteVault(token, vault.id);
      context.read<VaultProvider>().deleteVault(vault.id);
      if (mounted) {
        AppNotification.showSuccess('Vault deleted');
        _load();
      }
    } catch (e) {
      if (mounted) AppNotification.showError(userFacingErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaults = context.watch<VaultProvider>().vaults;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        title: const Text('Super Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              final confirm = await showSignOutDialog(
                context,
                message: 'Sign out of admin account?',
              );
              if (confirm == true && context.mounted) {
                await context.read<AuthProvider>().logout();
                if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
              }
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B2A), Color(0xFF1B263B)],
          ),
        ),
        child: _loading && _stats == null
            ? const Center(child: CircularProgressIndicator(color: Colors.white70))
            : RefreshIndicator(
                onRefresh: _load,
                color: AppTheme.primaryAccent,
                backgroundColor: Colors.white24,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + MediaQuery.paddingOf(context).bottom),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.sizeOf(context).height -
                          (MediaQuery.paddingOf(context).top + kToolbarHeight + MediaQuery.paddingOf(context).bottom),
                    ),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Dashboard',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppTheme.surfaceLight),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vaults, bookings & users',
                        style: TextStyle(fontSize: 14, color: AppTheme.textMuted.withValues(alpha: 0.95)),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.lock_rounded,
                              label: 'Vaults',
                              value: _stats?['totalVaults'] ?? 0,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.book_rounded,
                              label: 'Booked',
                              value: _stats?['totalBookings'] ?? 0,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.people_rounded,
                              label: 'Users',
                              value: _stats?['totalUsers'] ?? 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/createVault').then((_) => _load()),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Create Vault'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'All vaults',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.surfaceLight),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 400,
                        child: vaults.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.lock_open_rounded, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.6)),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No vaults yet. Create one above.',
                                      style: TextStyle(color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 8),
                                itemCount: vaults.length,
                                itemBuilder: (_, index) {
                                  final v = vaults[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _VaultTile(
                                      vault: v,
                                      onEdit: () => Navigator.pushNamed(context, '/createVault', arguments: v).then((_) => _load()),
                                      onDelete: () => _deleteVault(v),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryAccent, size: 28),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

class _VaultTile extends StatelessWidget {
  const _VaultTile({
    required this.vault,
    required this.onEdit,
    required this.onDelete,
  });

  final VaultModel vault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isBooked = vault.status == 'booked';
    final dateTimeText = vault.slotDate.isNotEmpty
        ? '${vault.slotDate} • ${vault.timeSlot}'
        : vault.timeSlot;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_rounded, color: AppTheme.surfaceLight, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vault.lockerNo.isNotEmpty ? 'Locker ${vault.lockerNo}' : 'Locker',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isBooked ? Colors.orange.withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isBooked ? 'Booked' : 'Unbooked',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isBooked ? Colors.orange.shade200 : Colors.green.shade200),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(vault.location, style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                  Text('₹${vault.price} • $dateTimeText', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit, color: AppTheme.surfaceLight),
            IconButton(icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
