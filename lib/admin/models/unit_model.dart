class Unit {
  final int id;
  final String name;
  final String symbol;
  final String? description;
  final bool isActive;
  final int siteId;
  final int workspaceId;
  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Unit({
    required this.id,
    required this.name,
    required this.symbol,
    this.description,
    required this.isActive,
    required this.siteId,
    required this.workspaceId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
      description: json['description'],
      isActive: (int.tryParse((json['is_active'] ?? json['status'])?.toString() ?? '1') ?? 1) == 1,
      siteId: int.tryParse(json['site_id']?.toString() ?? '') ?? 1,
      workspaceId: int.tryParse(json['workspace_id']?.toString() ?? '0') ?? 1,
      createdBy: int.tryParse(json['created_by']?.toString() ?? '0') ?? 1,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'description': description ?? '',
      'is_active': isActive ? 1 : 0,
      'site_id': siteId,
      'workspace_id': workspaceId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'symbol': symbol,
      'description': description ?? '',
      'is_active': isActive ? 1 : 0,
      'site_id': siteId,
      'workspace_id': workspaceId,
      'created_by': createdBy,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'symbol': symbol,
      'description': description ?? '',
      'is_active': isActive ? 1 : 0,
      'site_id': siteId,
      'workspace_id': workspaceId,
      'created_by': createdBy,
    };
  }

  Unit copyWith({
    int? id,
    String? name,
    String? symbol,
    String? description,
    bool? isActive,
    int? siteId,
    int? workspaceId,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Unit(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      siteId: siteId ?? this.siteId,
      workspaceId: workspaceId ?? this.workspaceId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}