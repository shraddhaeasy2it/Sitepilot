class HolidayModel {
  final int id;
  final String title;
  final String startDate;
  final String endDate;
  final String description;
  final dynamic createdBy;
  final dynamic workspace;
  final dynamic siteId;

  HolidayModel({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.description,
    this.createdBy,
    this.workspace,
    this.siteId,
  });

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    return HolidayModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['occasion'] ?? json['title'] ?? '', // Handle "occasion" or "title"
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      description: json['description'] ?? json['note'] ?? json['desc'] ?? '',
      createdBy: json['created_by'],
      workspace: json['workspace'],
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
      'created_by': createdBy,
      'workspace': workspace,
      'site_id': siteId,
    };
  }
}
