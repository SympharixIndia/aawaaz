import '../category.dart';
import '../query.dart';

/// Shared JSON parsing helpers for backend DTOs (enum names + timestamps).
class ApiParse {
  static Urgency urgency(String? value) => switch (value) {
        'HIGH' => Urgency.high,
        'LOW' => Urgency.low,
        _ => Urgency.normal,
      };

  static String urgencyToApi(Urgency u) => switch (u) {
        Urgency.high => 'HIGH',
        Urgency.normal => 'NORMAL',
        Urgency.low => 'LOW',
      };

  static QueryStatus status(String? value) => switch (value) {
        'IN_PROGRESS' => QueryStatus.inProgress,
        'RESOLVED' => QueryStatus.resolved,
        _ => QueryStatus.open,
      };

  static String statusToApi(QueryStatus s) => switch (s) {
        QueryStatus.open => 'OPEN',
        QueryStatus.inProgress => 'IN_PROGRESS',
        QueryStatus.resolved => 'RESOLVED',
      };

  /// Backend serializes Instant as an ISO-8601 string; tolerate epoch too.
  static DateTime? dateTime(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch((value * 1000).round(), isUtc: true);
    }
    return DateTime.tryParse(value.toString());
  }
}
