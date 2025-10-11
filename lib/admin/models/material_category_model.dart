// models/material_category_model.dart
class MaterialCategory {
  final String id;
  final String name;
  final int isActive;
  final dynamic siteId;
  final int createdBy;
  final int workingNoId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaterialCategory({
    required this.id,
    required this.name,
    required this.isActive,
    this.siteId,
    required this.createdBy,
    required this.workingNoId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MaterialCategory.fromJson(Map<String, dynamic> json) {
    return MaterialCategory(
      id: json['id']?.toString() ?? '0',
      name: json['name']?.toString() ?? '',
      isActive: json['is_active'] is int ? json['is_active'] : (json['is_active'] is String ? int.tryParse(json['is_active']) ?? 1 : 1),
      siteId: json['site_id'],
      createdBy: json['created_by'] is int ? json['created_by'] : (json['created_by'] is String ? int.tryParse(json['created_by']) ?? 1 : 1),
      workingNoId: json['working_no_id'] is int ? json['working_no_id'] : (json['working_no_id'] is String ? int.tryParse(json['working_no_id']) ?? 1 : 1),
      status: json['status']?.toString() ?? '0',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()).toLocal() : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'].toString()).toLocal() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_active': isActive,
      'site_id': siteId,
      'created_by': createdBy,
      'working_no_id': workingNoId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MaterialCategory copyWith({
    String? id,
    String? name,
    int? isActive,
    dynamic siteId,
    int? createdBy,
    int? workingNoId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaterialCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      siteId: siteId ?? this.siteId,
      createdBy: createdBy ?? this.createdBy,
      workingNoId: workingNoId ?? this.workingNoId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}