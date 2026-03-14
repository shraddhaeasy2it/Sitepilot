class LeaveType {
  final int id;
  final String title;
  final String days;
  final int used;
  final int isDisable;
  final int? workspace;
  final int? siteId;
  final String? createdAt;
  final String? updatedAt;

  LeaveType({
    required this.id,
    required this.title,
    required this.days,
    this.used = 0,
    this.isDisable = 0,
    this.workspace,
    this.siteId,
    this.createdAt,
    this.updatedAt,
  });

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      days: json['days'].toString(),
      used: json['used'] is int ? json['used'] : int.tryParse(json['used'].toString()) ?? 0,
      isDisable: json['is_disable'] is int ? json['is_disable'] : int.tryParse(json['is_disable'].toString()) ?? 0,
      workspace: json['workspace'] != null ? (json['workspace'] is int ? json['workspace'] : int.tryParse(json['workspace'].toString())) : null,
      siteId: json['site_id'] != null ? (json['site_id'] is int ? json['site_id'] : int.tryParse(json['site_id'].toString())) : null,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'days': days,
      'used': used,
      'is_disable': isDisable,
      'workspace': workspace,
      'site_id': siteId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
