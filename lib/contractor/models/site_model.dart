class Site {
  final String id;
  final String name;
  final String companyId;
  final String status;
  final String startDate;
  final String endDate;
  final double budget;
  final double progress;
  final String? description;
  final String? image;
  final String? latitude;
  final String? longitude;
  final String? address;

  Site({
    required this.id,
    required this.name,
    required this.companyId,
    this.status = 'Planning',
    this.startDate = '',
    this.endDate = '',
    this.budget = 0.0,
    this.progress = 0.0,
    this.description,
    this.image,
    this.latitude,
    this.longitude,
    this.address,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id'].toString(),
      name: json['name'] ?? 'Unnamed Project',
      companyId: json['workspace'].toString(),
      status: json['status'] ?? 'Planning',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      budget: double.tryParse(json['budget']?.toString() ?? '0.0') ?? 0.0,
      progress: double.tryParse(json['progress']?.toString() ?? '0.0') ?? 0.0,
      description: json['description'],
      image: json['image'],
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description ?? name,
      'workspace': companyId,
      'status': status,
      'start_date': startDate,
      'end_date': endDate,
      'budget': budget,
      'progress': progress.toString(),
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }

  Site copyWith({
    String? id,
    String? name,
    String? companyId,
    String? status,
    String? startDate,
    String? endDate,
    double? budget,
    double? progress,
    String? description,
    String? image,
    String? latitude,
    String? longitude,
    String? address,
  }) {
    return Site(
      id: id ?? this.id,
      name: name ?? this.name,
      companyId: companyId ?? this.companyId,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      progress: progress ?? this.progress,
      description: description ?? this.description,
      image: image ?? this.image,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
    );
  }
}