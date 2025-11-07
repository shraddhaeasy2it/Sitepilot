// models/mapower_model.dart
class ManpowerType {
  final int id;
  final String name;
  final int status;
  final int siteId;
  final int createdBy;
  final int workspaceId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ManpowerType({
    required this.id,
    required this.name,
    required this.status,
    required this.siteId,
    required this.createdBy,
    required this.workspaceId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ManpowerType.fromJson(Map<String, dynamic> json) {
    return ManpowerType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      status: json['status'] ?? 0,
      siteId: json['site_id'] ?? 0,
      createdBy: json['created_by'] ?? 0,
      workspaceId: json['workspace_id'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'site_id': siteId,
      'workspace_id': workspaceId,
      'created_by': createdBy,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'site_id': siteId,
      'workspace_id': workspaceId,
      'created_by': createdBy,
    };
  }

  ManpowerType copyWith({
    String? name,
    int? siteId,
    int? workspaceId,
    int? createdBy,
  }) {
    return ManpowerType(
      id: id,
      name: name ?? this.name,
      status: status,
      siteId: siteId ?? this.siteId,
      createdBy: createdBy ?? this.createdBy,
      workspaceId: workspaceId ?? this.workspaceId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}