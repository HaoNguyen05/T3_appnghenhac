class UserProfile {
  final String id;
  final String? email;
  final String? name;
  final String? avatarUrl; // URL của avatar người dùng
  final List<String>? favoriteSongs; // lưu danh sách id bài hát yêu thích
  final String? userRole;
  final DateTime? createdAt;

  UserProfile({
    required this.id,
    this.email,
    this.name,
    this.avatarUrl,
    this.favoriteSongs,
    this.userRole,
    this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> m) {
    return UserProfile(
      id: m['id'].toString(),
      email: m['email']?.toString(),
      name: m['name']?.toString(),
      avatarUrl: m['avatar_url']?.toString(),
      favoriteSongs: m['favorite_songs'] != null
          ? List<String>.from(m['favorite_songs'])
          : null,
      userRole: m['user_role']?.toString(),
      createdAt:
          m['created_at'] != null ? DateTime.parse(m['created_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'favorite_songs': favoriteSongs,
      'user_role': userRole,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
