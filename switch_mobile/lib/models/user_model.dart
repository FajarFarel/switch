class UserModel {
  final int id;
  final String username;
  final String email;
  final bool? isActive;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.isActive,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isActive: json['is_active'] != null ? (json['is_active'] == 1 || json['is_active'] == true) : null,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }
}
