/// A registered worker. Identity in V1 is username + numeric PIN (no face/camera).
class Worker {
  final String id;
  final String username;
  final String name; // actual display name
  final String password; // simple numeric PIN, e.g. "1234"
  final String languageCode; // "hi-IN" | "bn-IN" | "en-IN"
  final DateTime registeredAt;

  Worker({
    required this.id,
    required this.username,
    required this.name,
    required this.password,
    required this.languageCode,
    required this.registeredAt,
  });
}
