import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/error_utils.dart';
import '../../core/theme.dart';
import '../../core/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/sign_out_dialog.dart';
import '../../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _locationController;
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController = TextEditingController(text: auth.name ?? '');
    _phoneController = TextEditingController(text: auth.phone ?? '');
    _addressController = TextEditingController(text: auth.address ?? '');
    _locationController = TextEditingController(text: auth.location ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().refreshProfile();
      if (mounted) {
        final auth = context.read<AuthProvider>();
        _nameController.text = auth.name ?? '';
        _phoneController.text = auth.phone ?? '';
        _addressController.text = auth.address ?? '';
        _locationController.text = auth.location ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() => _saving = true);
    try {
      await UserService.updateProfile(
        token,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        location: _locationController.text.trim(),
      );
      await context.read<AuthProvider>().refreshProfile();
      if (mounted) AppNotification.showSuccess('Profile updated');
    } catch (e) {
      if (mounted) AppNotification.showError(userFacingErrorMessage(e));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

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
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.white70))
              : Column(
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
                          const Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
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
                            children: [
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryAccent.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 64,
                                  color: AppTheme.surfaceLight,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                auth.email ?? '—',
                                style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 28),
                              _buildField(
                                controller: _nameController,
                                label: 'Name (max 3 words)',
                                icon: Icons.badge_outlined,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Enter name';
                                  final words = v.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
                                  if (words > 3) return 'Name must be at most 3 words';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildField(
                                controller: _phoneController,
                                label: 'Contact number',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return null;
                                  final digits = v.replaceAll(RegExp(r'\D'), '');
                                  if (digits.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) return null;
                                  if (digits.length == 12 && digits.startsWith('91') && RegExp(r'^91[6-9]\d{9}$').hasMatch(digits)) return null;
                                  return 'Enter a valid 10-digit mobile number';
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildField(
                                controller: _addressController,
                                label: 'Address (max 7 words)',
                                icon: Icons.home_outlined,
                                maxLines: 2,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return null;
                                  final words = v.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
                                  if (words > 7) return 'Address must be at most 7 words';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildField(
                                controller: _locationController,
                                label: 'Location (max 2 words)',
                                icon: Icons.location_on_outlined,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return null;
                                  final words = v.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
                                  if (words > 2) return 'Location must be at most 2 words';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _saving ? null : _save,
                                  icon: _saving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.save_rounded),
                                  label: Text(_saving ? 'Saving…' : 'Update profile'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.primaryAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final confirm = await showSignOutDialog(
                                      context,
                                      message: 'Are you sure you want to sign out?',
                                    );
                                    if (confirm == true && context.mounted) {
                                      await context.read<AuthProvider>().logout();
                                      if (context.mounted) {
                                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.logout_rounded),
                                  label: const Text('Log out'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red.shade300,
                                    side: BorderSide(color: Colors.red.shade300),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.textMuted),
        prefixIcon: Icon(icon, color: AppTheme.primaryAccent, size: 22),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white24),
        ),
      ),
    );
  }
}
