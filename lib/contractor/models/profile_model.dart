class Profile {
  final String name;
  final String email;
  final String mobile;
  final String type;
  final String avatarUrl;
  final String? department;
  final String? position;

  Profile({
    required this.name,
    required this.email,
    required this.mobile,
    required this.type,
    required this.avatarUrl,
    this.department,
    this.position,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      type: json['type'] ?? '',
      avatarUrl: json['avatar_url'] ?? json['avatar'] ?? '',
      department: json['department'] ?? '',
      position: json['position'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'mobile': mobile,
      'type': type,
      'avatar_url': avatarUrl,
      'department': department,
      'position': position,
    };
  }
}