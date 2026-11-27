import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/query.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Date-only key for grouping queries (ignores time).
DateTime dateKey(DateTime d) => DateTime(d.year, d.month, d.day);

/// "Today" / "Yesterday" / "27 Nov 2026" for a date-group header.
String dateGroupLabel(DateTime d) {
  final today = dateKey(DateTime.now());
  final k = dateKey(d);
  final diff = today.difference(k).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return '${k.day} ${_months[k.month - 1]} ${k.year}';
}

String timeLabel(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
}

String urgencyLabel(Urgency u) => switch (u) {
      Urgency.high => 'High',
      Urgency.normal => 'Normal',
      Urgency.low => 'Low',
    };

Color urgencyColor(Urgency u, ColorScheme scheme) => switch (u) {
      Urgency.high => scheme.error,
      Urgency.normal => scheme.primary,
      Urgency.low => scheme.outline,
    };

String statusLabel(QueryStatus s) => switch (s) {
      QueryStatus.open => 'Open',
      QueryStatus.inProgress => 'In progress',
      QueryStatus.resolved => 'Resolved',
    };

/// Icon for a category key, so the UI reads at a glance for low-literacy users.
IconData categoryIcon(String key) => switch (key) {
      'safety' => Icons.warning_amber_rounded,
      'health' => Icons.healing,
      'early_exit' => Icons.logout,
      'leave' => Icons.event_busy,
      'advance' => Icons.currency_rupee,
      _ => Icons.help_outline,
    };
