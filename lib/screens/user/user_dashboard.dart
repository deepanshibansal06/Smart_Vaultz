import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/error_utils.dart';
import '../../core/theme.dart';
import '../../core/notification_service.dart';
import '../../core/time_slots.dart' show slotStartDateTime, formatSlotStartForMessage;
import '../../widgets/sign_out_dialog.dart';
import '../../models/vault_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key, this.onNavigateToBook, this.refreshTrigger});

  final VoidCallback? onNavigateToBook;
  /// When this notifier fires (e.g. when user switches to Dashboard tab), bookings are refetched
  /// so entries unbooked by admin disappear from the list.
  final ValueNotifier<int>? refreshTrigger;

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  List<BookingItem> _bookings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.refreshTrigger?.addListener(_onRefreshTriggered);
    _load();
  }

  @override
  void didUpdateWidget(covariant UserDashboard oldWidget) {
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
    if (mounted) _load();
  }

  void _updateBookingLockStatus(String bookingId, String lockStatus) {
    setState(() {
      _bookings = _bookings
          .map((b) => b.id == bookingId
              ? BookingItem(id: b.id, lockStatus: lockStatus, vault: b.vault)
              : b)
          .toList();
    });
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final list = await BookingService.getMyBookings(token);
      if (mounted) setState(() { _bookings = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = userFacingErrorMessage(e); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        leading: Consumer<AuthProvider>(
          builder: (_, auth, __) {
            final name = auth.name?.trim() ?? '';
            final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
            return IconButton(
              onPressed: () => Navigator.pushNamed(context, '/profile'),
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              final confirm = await showSignOutDialog(context, message: 'Sign out?');
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
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white70))
            : RefreshIndicator(
                onRefresh: _load,
                color: AppTheme.primaryAccent,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'My lockers',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.surfaceLight),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Use the Book tab below to browse and book a locker.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ],
                      const SizedBox(height: 20),
                      if (_bookings.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.lock_open_rounded, size: 56, color: AppTheme.textMuted.withValues(alpha: 0.7)),
                              const SizedBox(height: 16),
                              Text(
                                'No booked lockers',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.surfaceLight),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Use the Book tab in the bottom navigation to browse and book a locker.',
                                style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        ..._bookings.map((b) => _BookedLockerCard(
                        booking: b,
                        onOpen: () => _updateBookingLockStatus(b.id, 'open'),
                        onClose: () => _updateBookingLockStatus(b.id, 'closed'),
                      )),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _BookedLockerCard extends StatelessWidget {
  const _BookedLockerCard({required this.booking, required this.onOpen, required this.onClose});

  final BookingItem booking;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final v = booking.vault;
    final dateTimeText = v.slotDate.isNotEmpty
        ? '${v.slotDate} • ${v.timeSlot}'
        : v.timeSlot;
    final slotStart = slotStartDateTime(v.slotDate, v.timeSlot);
    final now = DateTime.now();
    final isBeforeSlotStart = slotStart != null && now.isBefore(slotStart);
    final availableAtText = slotStart != null ? formatSlotStartForMessage(slotStart) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                      Text(
                        v.lockerNo.isNotEmpty ? 'Locker ${v.lockerNo}' : 'Locker',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(v.location, style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                      Text(dateTimeText, style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Builder(
              builder: (context) {
                final isOpen = booking.lockStatus == 'open';
                void onOpenTap() async {
                  if (isBeforeSlotStart && availableAtText != null) {
                    AppNotification.show('Locker will be available at $availableAtText', isError: false);
                    return;
                  }
                  final token = context.read<AuthProvider>().token;
                  if (token == null) return;
                  try {
                    final result = await BookingService.openVault(token, booking.id);
                    if (context.mounted) {
                      onOpen();
                      if (result.hasHardware) {
                        AppNotification.showSuccess('Locker opened');
                      } else {
                        AppNotification.show('No locker is attached for this vault yet.');
                      }
                    }
                  } catch (e) {
                    if (context.mounted) AppNotification.showError(userFacingErrorMessage(e));
                  }
                }
                void onCloseTap() async {
                  if (isBeforeSlotStart && availableAtText != null) {
                    AppNotification.show('Locker will be available at $availableAtText', isError: false);
                    return;
                  }
                  final token = context.read<AuthProvider>().token;
                  if (token == null) return;
                  try {
                    final result = await BookingService.closeVault(token, booking.id);
                    if (context.mounted) {
                      onClose();
                      if (result.hasHardware) {
                        AppNotification.showSuccess('Locker closed');
                      } else {
                        AppNotification.show('No locker is attached for this vault yet.');
                      }
                    }
                  } catch (e) {
                    if (context.mounted) AppNotification.showError(userFacingErrorMessage(e));
                  }
                }
                return Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onOpenTap,
                        icon: const Icon(Icons.lock_open_rounded, size: 18),
                        label: const Text('Open'),
                        style: FilledButton.styleFrom(
                          backgroundColor: isOpen ? Colors.green.shade600 : Colors.green.shade600.withValues(alpha: 0.35),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onCloseTap,
                        icon: const Icon(Icons.lock_rounded, size: 18),
                        label: const Text('Close'),
                        style: FilledButton.styleFrom(
                          backgroundColor: isOpen ? Colors.orange.shade600.withValues(alpha: 0.35) : Colors.orange.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
