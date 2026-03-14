class EventModel {
  final int id;
  final String title;
  final String startDate;
  final String endDate;
  final String color;
  final String description;
  final dynamic createdBy;
  final dynamic workspace;
  final dynamic siteId;

  EventModel({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.color,
    required this.description,
    this.createdBy,
    this.workspace,
    this.siteId,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      color: json['color'] ?? '',
      description: json['description'] ?? '',
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
      'color': color,
      'description': description,
      'created_by': createdBy,
      'workspace': workspace,
      'site_id': siteId,
    };
  }
}
