class MaterialCategory {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaterialCategory({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MaterialCategory.fromJson(Map<String, dynamic> json) {
    return MaterialCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  MaterialCategory copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaterialCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}