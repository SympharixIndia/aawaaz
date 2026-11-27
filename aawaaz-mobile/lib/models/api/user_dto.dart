/// Mirrors the backend `UserResponse` (no password hash is ever returned).
class UserDto {
  final int id;
  final String username;
  final String name;
  final String userType; // "MANAGER" | "WORKER"
  final String? profession;
  final String languageCode;

  UserDto({
    required this.id,
    required this.username,
    required this.name,
    required this.userType,
    required this.profession,
    required this.languageCode,
  });

  bool get isManager => userType == 'MANAGER';

  factory UserDto.fromJson(Map<String, dynamic> j) => UserDto(
        id: (j['id'] as num).toInt(),
        username: j['username'] as String,
        name: j['name'] as String,
        userType: j['userType'] as String,
        profession: j['profession'] as String?,
        languageCode: j['languageCode'] as String,
      );
}
