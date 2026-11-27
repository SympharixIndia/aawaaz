/// Lifecycle of a request: open -> inProgress -> resolved.
/// (Mirrors the backend `RequestStatus`; parsed from JSON via `ApiParse`.)
enum QueryStatus { open, inProgress, resolved }
