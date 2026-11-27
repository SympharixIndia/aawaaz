import 'category.dart';

/// Lifecycle of a query. V1 moves forward: open -> inProgress -> resolved.
enum QueryStatus { open, inProgress, resolved }

/// A request spoken by a worker and filed into the in-memory store.
class Query {
  final String id;
  final int ticketNo; // short number spoken back to the worker
  final String workerId;
  final DateTime createdAt;
  final String transcript; // raw spoken text
  final String languageCode;

  String categoryKey; // key into the category list
  Urgency urgency;
  QueryStatus status;

  String? managerComment; // played back to the worker in My Status
  DateTime? commentedAt;

  Query({
    required this.id,
    required this.ticketNo,
    required this.workerId,
    required this.createdAt,
    required this.transcript,
    required this.languageCode,
    required this.categoryKey,
    this.urgency = Urgency.normal,
    this.status = QueryStatus.open,
    this.managerComment,
    this.commentedAt,
  });
}
