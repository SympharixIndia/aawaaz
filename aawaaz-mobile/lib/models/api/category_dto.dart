/// Mirrors the backend `CategoryResponse`.
class CategoryDto {
  final String categoryKey;
  final String label;
  final int priority;
  final bool safetyCritical;

  CategoryDto({
    required this.categoryKey,
    required this.label,
    required this.priority,
    required this.safetyCritical,
  });

  factory CategoryDto.fromJson(Map<String, dynamic> j) => CategoryDto(
        categoryKey: j['categoryKey'] as String,
        label: j['label'] as String,
        priority: (j['priority'] as num).toInt(),
        safetyCritical: j['safetyCritical'] as bool,
      );
}
