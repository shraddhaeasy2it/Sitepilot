import 'dart:io';

class AdminUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String imageUrl;
  final File? imageFile; // For picked images

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.imageUrl,
    this.imageFile,
  });

  // Factory constructor for creating from JSON
  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'imageUrl': imageUrl,
    };
  }

  // Get display image (file if available, otherwise URL)
  String? get displayImage => imageFile?.path ?? (imageUrl.isNotEmpty ? imageUrl : null);
}