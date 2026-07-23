/// Every 30 min from 12:00 AM to 11:30 PM (48 options).
List<String> get timeSlotOptions {
  const ampmList = ['AM', 'PM'];
  const hours = [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
  final list = <String>[];
  for (final ampm in ampmList) {
    for (final h in hours) {
      list.add('$h:00 $ampm');
      list.add('$h:30 $ampm');
    }
  }
  return list;
}

/// Minutes since midnight for "H:MM AM/PM" (e.g. "5:30 PM" -> 17*60+30).
/// 12:00 AM = 0, 11:30 PM = 23*60+30 = 1410.
int? timeToMinutes(String timeStr) {
  final t = timeStr.trim();
  final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false).firstMatch(t);
  if (match == null) return null;
  int h = int.tryParse(match.group(1)!) ?? 0;
  final m = int.tryParse(match.group(2)!) ?? 0;
  final ampm = (match.group(3) ?? '').toUpperCase();
  if (ampm == 'PM' && h != 12) h += 12;
  if (ampm == 'AM' && h == 12) h = 0;
  return h * 60 + m;
}
int? _timeToMinutes(String timeStr) => timeToMinutes(timeStr);

/// For [date], return only "from" time options that are in the future (next 30-min boundary if today).
List<String> allowedFromTimeOptionsForDate(DateTime date) {
  final options = timeSlotOptions;
  final now = DateTime.now();
  final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
  if (!isToday) return options;
  // Next 30-min boundary from now (e.g. 5:07 -> 5:30, 5:30 -> 6:00)
  final currentMins = now.hour * 60 + now.minute;
  final nextBoundaryMins = ((currentMins ~/ 30) + 1) * 30;
  if (nextBoundaryMins >= 24 * 60) return []; // no slots left today
  return options.where((opt) {
    final m = _timeToMinutes(opt);
    return m != null && m >= nextBoundaryMins;
  }).toList();
}

/// When "Till" is 12:00 AM it means end of the same calendar day (midnight).
/// Returns slot end as DateTime; if till is 12:00 AM, returns next day at 00:00.
DateTime? slotEndDateTime(DateTime date, String tillTime) {
  final m = _timeToMinutes(tillTime);
  if (m == null) return null;
  if (m == 0) {
    // 12:00 AM as Till = end of [date], i.e. next day 00:00
    return DateTime(date.year, date.month, date.day + 1, 0, 0);
  }
  return DateTime(date.year, date.month, date.day, m ~/ 60, m % 60);
}

/// True if slot end (date + tillTime) is after now. Treats 12:00 AM as end of that date.
bool isSlotEndInFuture(DateTime date, String tillTime) {
  final slotEnd = slotEndDateTime(date, tillTime);
  return slotEnd != null && slotEnd.isAfter(DateTime.now());
}

/// Valid "Till" options for a given "From" time. Includes 12:00 AM when From is 11:30 PM (last half-hour of day).
List<String> allowedTillOptionsForFrom(String fromTime) {
  final fromMins = _timeToMinutes(fromTime);
  if (fromMins == null) return timeSlotOptions;
  const lastSlotFromMins = 23 * 60 + 30; // 11:30 PM
  if (fromMins == lastSlotFromMins) {
    return ['12:00 AM']; // only valid till for last half-hour
  }
  return timeSlotOptions.where((opt) {
    final m = _timeToMinutes(opt);
    return m != null && m > fromMins;
  }).toList();
}

/// Slot start DateTime from slotDate (YYYY-MM-DD) and timeSlot ("From - Till"). Returns null if invalid.
DateTime? slotStartDateTime(String slotDateStr, String timeSlotStr) {
  if (slotDateStr.isEmpty || timeSlotStr.isEmpty) return null;
  final parts = timeSlotStr.split('-').map((s) => s.trim()).toList();
  final fromStr = parts.isNotEmpty ? parts.first : '';
  final mins = _timeToMinutes(fromStr);
  if (mins == null) return null;
  final dateParts = slotDateStr.split('-');
  if (dateParts.length < 3) return null;
  final y = int.tryParse(dateParts[0]);
  final mo = int.tryParse(dateParts[1]);
  final d = int.tryParse(dateParts[2]);
  if (y == null || mo == null || d == null) return null;
  return DateTime(y, mo, d, mins ~/ 60, mins % 60);
}

/// Human-readable slot start for "available at" message (e.g. "5:00 PM" or "Mar 10 at 5:00 PM").
String formatSlotStartForMessage(DateTime slotStart) {
  final now = DateTime.now();
  final today = now.year == slotStart.year && now.month == slotStart.month && now.day == slotStart.day;
  final h = slotStart.hour;
  final m = slotStart.minute;
  final ampm = h >= 12 ? 'PM' : 'AM';
  final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
  final timeStr = '$h12:${m.toString().padLeft(2, '0')} $ampm';
  if (today) return timeStr;
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${months[slotStart.month - 1]} ${slotStart.day} at $timeStr';
}
