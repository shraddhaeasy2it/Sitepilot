class AnnouncementModel {
  final int id;
  final String title;
  final String startDate;
  final String endDate;
  final String description;
  final dynamic workspaceId;
  final dynamic siteId;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.description,
    this.workspaceId,
    this.siteId,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      description: json['description'] ?? '',
      workspaceId: json['workspace'],
      siteId: json['site_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'start_date': startDate,
      'end_date': endDate,
      'description': description,
      'workspace': workspaceId,
      'site_id': siteId,
    };
  }
}
