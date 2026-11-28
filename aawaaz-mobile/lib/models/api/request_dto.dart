import '../category.dart';
import '../query.dart';
import 'api_parse.dart';

/// Mirrors the backend `RequestResponse`. The `id` is the ticket number.
class RequestDto {
  final int id;
  final int workerId;
  final String? workerName;
  final String originalText;
  final String originalLanguage;
  final String? translatedText;
  final String? translatedLanguage;
  final String categoryKey;
  final Urgency urgency;
  final QueryStatus status;
  final String? managerComment;
  final String? managerCommentLanguage;
  final String? managerCommentTranslated;
  final String? managerCommentTranslatedLanguage;
  final DateTime? commentedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RequestDto({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.originalText,
    required this.originalLanguage,
    required this.translatedText,
    required this.translatedLanguage,
    required this.categoryKey,
    required this.urgency,
    required this.status,
    required this.managerComment,
    required this.managerCommentLanguage,
    required this.managerCommentTranslated,
    required this.managerCommentTranslatedLanguage,
    required this.commentedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// The manager's reply in the worker's language (falls back to the original).
  String? get workerReply =>
      (managerCommentTranslated != null && managerCommentTranslated!.trim().isNotEmpty)
          ? managerCommentTranslated
          : managerComment;

  factory RequestDto.fromJson(Map<String, dynamic> j) => RequestDto(
        id: (j['id'] as num).toInt(),
        workerId: (j['workerId'] as num).toInt(),
        workerName: j['workerName'] as String?,
        originalText: j['originalText'] as String,
        originalLanguage: j['originalLanguage'] as String,
        translatedText: j['translatedText'] as String?,
        translatedLanguage: j['translatedLanguage'] as String?,
        categoryKey: j['categoryKey'] as String,
        urgency: ApiParse.urgency(j['urgency'] as String?),
        status: ApiParse.status(j['status'] as String?),
        managerComment: j['managerComment'] as String?,
        managerCommentLanguage: j['managerCommentLanguage'] as String?,
        managerCommentTranslated: j['managerCommentTranslated'] as String?,
        managerCommentTranslatedLanguage: j['managerCommentTranslatedLanguage'] as String?,
        commentedAt: ApiParse.dateTime(j['commentedAt']),
        createdAt: ApiParse.dateTime(j['createdAt']),
        updatedAt: ApiParse.dateTime(j['updatedAt']),
      );
}
