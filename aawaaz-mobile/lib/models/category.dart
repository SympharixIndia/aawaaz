/// A request category. Managers can adjust [priority]; higher sorts first.
class Category {
  final String key;
  final String label;
  int priority;
  final bool isSafetyCritical;

  Category({
    required this.key,
    required this.label,
    required this.priority,
    this.isSafetyCritical = false,
  });
}

/// How urgent a query is. Safety-critical categories seed [Urgency.high].
enum Urgency { high, normal, low }

/// Default categories seeded at startup. Safety and health rank highest.
List<Category> defaultCategories() => [
  Category(key: 'safety', label: 'Safety', priority: 100, isSafetyCritical: true),
  Category(key: 'health', label: 'Health', priority: 90, isSafetyCritical: true),
  Category(key: 'early_exit', label: 'Early exit', priority: 60),
  Category(key: 'leave', label: 'Leave', priority: 50),
  Category(key: 'advance', label: 'Salary advance', priority: 40),
  Category(key: 'other', label: 'Other', priority: 10),
];
