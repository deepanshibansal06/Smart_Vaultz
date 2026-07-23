import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/error_utils.dart';
import '../../core/theme.dart';
import '../../core/time_slots.dart' show timeSlotOptions, allowedFromTimeOptionsForDate, allowedTillOptionsForFrom, isSlotEndInFuture;
import '../../models/vault_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vault_provider.dart';
import '../../services/vault_service.dart';
import '../../core/notification_service.dart';
import '../../widgets/custom_button.dart';

class CreateVaultScreen extends StatefulWidget {
  const CreateVaultScreen({super.key, this.editVault});

  final VaultModel? editVault;

  @override
  State<CreateVaultScreen> createState() => _CreateVaultScreenState();
}

class _CreateVaultScreenState extends State<CreateVaultScreen> {
  final _formKey = GlobalKey<FormState>();
  final lockerNo = TextEditingController();
  final location = TextEditingController();
  final price = TextEditingController();
  final timeOptions = timeSlotOptions;
  String? timeFrom;
  String? timeTill;
  DateTime? slotDate;
  List<String> _allowedFromOptions = timeSlotOptions;
  String _status = 'available'; // used in edit mode: 'available' | 'booked'
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editVault != null) {
      lockerNo.text = widget.editVault!.lockerNo;
      location.text = widget.editVault!.location;
      price.text = widget.editVault!.price.toString();
      if (widget.editVault!.slotDate.isNotEmpty) {
        final d = DateTime.tryParse(widget.editVault!.slotDate);
        if (d != null) slotDate = d;
      }
      if (widget.editVault!.status == 'booked' || widget.editVault!.status == 'available') {
        _status = widget.editVault!.status;
      }
      final parts = widget.editVault!.timeSlot.split(' - ');
      if (parts.length >= 2) {
        timeFrom = parts[0].trim();
        timeTill = parts[1].trim();
        if (!timeOptions.contains(timeFrom)) timeFrom = timeOptions.first;
        if (!timeOptions.contains(timeTill)) timeTill = timeOptions.last;
      }
    }
    if (slotDate == null) slotDate = DateTime.now();
    final isEdit = widget.editVault != null;
    _allowedFromOptions = isEdit ? timeOptions : allowedFromTimeOptionsForDate(slotDate!);
    if (timeFrom == null || !_allowedFromOptions.contains(timeFrom)) {
      timeFrom = _allowedFromOptions.isNotEmpty ? _allowedFromOptions.first : null;
    }
    if (timeTill == null) {
      final allowedTill = allowedTillOptionsForFrom(timeFrom ?? timeOptions.first);
      timeTill = allowedTill.isNotEmpty ? allowedTill.first : timeOptions.last;
    } else {
      final allowedTill = allowedTillOptionsForFrom(timeFrom ?? timeOptions.first);
      if (!allowedTill.contains(timeTill)) timeTill = allowedTill.isNotEmpty ? allowedTill.first : timeOptions.last;
    }
  }

  @override
  void dispose() {
    lockerNo.dispose();
    location.dispose();
    price.dispose();
    super.dispose();
  }

  void _onSlotDateChanged(DateTime? d) {
    if (d == null) return;
    setState(() {
      slotDate = d;
      _allowedFromOptions = allowedFromTimeOptionsForDate(d);
      if (timeFrom == null || !_allowedFromOptions.contains(timeFrom)) {
        timeFrom = _allowedFromOptions.isNotEmpty ? _allowedFromOptions.first : null;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (slotDate == null) {
      AppNotification.showError('Select date');
      return;
    }
    final from = timeFrom ?? (_allowedFromOptions.isNotEmpty ? _allowedFromOptions.first : timeOptions.first);
    final allowedTill = allowedTillOptionsForFrom(from);
    final till = () {
      final t = timeTill ?? timeOptions.last;
      return allowedTill.contains(t) ? t : (allowedTill.isNotEmpty ? allowedTill.first : timeOptions.last);
    }();
    final isEdit = widget.editVault != null;
    if (!isEdit && _allowedFromOptions.isEmpty) {
      AppNotification.showError('No slots left for this date. Choose another day.');
      return;
    }
    if (!isEdit && !isSlotEndInFuture(slotDate!, till)) {
      AppNotification.showError('Slot end time has passed. Choose an upcoming time.');
      return;
    }
    final timeSlot = '$from - $till';
    final slotDateStr = '${slotDate!.year}-${slotDate!.month.toString().padLeft(2, '0')}-${slotDate!.day.toString().padLeft(2, '0')}';
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      if (mounted) AppNotification.showError('Please sign in again');
      return;
    }
    setState(() => _loading = true);
    try {
      if (widget.editVault != null) {
        await VaultService.updateVault(
          token,
          widget.editVault!.id,
          lockerNo: lockerNo.text.trim(),
          location: location.text.trim(),
          price: double.tryParse(price.text) ?? 0,
          slotDate: slotDateStr,
          timeSlot: timeSlot,
          status: _status,
        );
        context.read<VaultProvider>().updateVault(
          VaultModel(
            id: widget.editVault!.id,
            lockerNo: lockerNo.text.trim(),
            location: location.text.trim(),
            price: double.tryParse(price.text) ?? 0,
            slotDate: slotDateStr,
            timeSlot: timeSlot,
            status: _status,
          ),
        );
        if (mounted) {
          AppNotification.showSuccess('Vault updated');
          Navigator.pop(context);
        }
      } else {
        final vault = await VaultService.createVault(
          token,
          lockerNo.text.trim(),
          location.text.trim(),
          double.tryParse(price.text) ?? 0,
          slotDateStr,
          timeSlot,
        );
        context.read<VaultProvider>().addVault(vault);
        if (mounted) {
          AppNotification.showSuccess('Vault created');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(userFacingErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editVault != null;
    final allowedTill = allowedTillOptionsForFrom(timeFrom ?? timeOptions.first);
    final tillValue = timeTill != null && allowedTill.contains(timeTill)
        ? timeTill
        : (allowedTill.isNotEmpty ? allowedTill.first : null);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Vault' : 'Create Vault'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isEdit ? 'Update vault details' : 'Add a new vault',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppTheme.surfaceLight),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6))],
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: lockerNo,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Locker No',
                            hintText: 'e.g. L001 (for IoT locker)',
                            prefixIcon: Icon(Icons.tag_rounded),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Enter locker no';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: location,
                          decoration: const InputDecoration(
                            labelText: 'Location (max 2 words)',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Enter location';
                            final words = v.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
                            if (words > 2) return 'Location must be at most 2 words';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: slotDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                            );
                            if (d != null) _onSlotDateChanged(d);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              prefixIcon: Icon(Icons.calendar_today_rounded),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              slotDate != null
                                  ? '${slotDate!.day}/${slotDate!.month}/${slotDate!.year}'
                                  : 'Select date',
                              style: TextStyle(color: slotDate != null ? Colors.black87 : Colors.black45),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: price,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Price (₹)',
                            prefixIcon: Icon(Icons.currency_rupee),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Enter price';
                            if (double.tryParse(v) == null) return 'Enter a valid number';
                            return null;
                          },
                        ),
                        if (isEdit) ...[
                          const SizedBox(height: 16),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Status', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _status,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.lock_rounded),
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'available', child: Text('Unbooked')),
                              DropdownMenuItem(value: 'booked', child: Text('Booked')),
                            ],
                            onChanged: (v) => setState(() { if (v != null) _status = v; }),
                          ),
                        ],
                        const SizedBox(height: 20),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Time slot (From)', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _allowedFromOptions.contains(timeFrom) ? timeFrom : (_allowedFromOptions.isNotEmpty ? _allowedFromOptions.first : null),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.schedule_rounded),
                            border: const OutlineInputBorder(),
                            hintText: _allowedFromOptions.isEmpty ? 'No upcoming slots this day' : null,
                          ),
                          items: _allowedFromOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: _allowedFromOptions.isEmpty ? null : (v) {
                            if (v == null) return;
                            setState(() {
                              timeFrom = v;
                              final allowedTill = allowedTillOptionsForFrom(v);
                              if (timeTill == null || !allowedTill.contains(timeTill)) {
                                timeTill = allowedTill.isNotEmpty ? allowedTill.first : timeOptions.last;
                              }
                            });
                          },
                          validator: (v) => v == null || v.isEmpty ? 'Select from time' : null,
                        ),
                        const SizedBox(height: 16),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Time slot (Till)', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: tillValue,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.schedule_rounded),
                            border: OutlineInputBorder(),
                          ),
                          items: allowedTill.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => setState(() => timeTill = v),
                          validator: (v) => v == null ? 'Select till time' : null,
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: _loading ? (isEdit ? 'Updating…' : 'Creating…') : (isEdit ? 'Update Vault' : 'Create Vault'),
                          onTap: _loading ? () {} : _submit,
                        ),
                      ],
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
