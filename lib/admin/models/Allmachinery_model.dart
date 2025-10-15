class Machinery {
  final int? id;
  final String name;
  final int categoryId;
  final String modelNumber;
  final String manufacturer;
  final String purchaseDate;
  final String capacity;
  final String maintenanceSchedule;
  final String? remarks;
  final String? description;
  final String vehicleNumber;
  final String ownedBy;
  final int? supplierId;
  final String operationalStatus;
  final int siteId;
  final int createdBy;
  final int workspaceId;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  Machinery({
    this.id,
    required this.name,
    required this.categoryId,
    required this.modelNumber,
    required this.manufacturer,
    required this.purchaseDate,
    required this.capacity,
    required this.maintenanceSchedule,
    this.remarks,
    this.description,
    required this.vehicleNumber,
    required this.ownedBy,
    this.supplierId,
    required this.operationalStatus,
    required this.siteId,
    required this.createdBy,
    required this.workspaceId,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Machinery.fromJson(Map<String, dynamic> json) {
    return Machinery(
      id: json['id'],
      name: json['name'] ?? '',
      categoryId: json['category_id'] ?? 0,
      modelNumber: json['model_number'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      purchaseDate: json['purchase_date'] ?? '',
      capacity: json['capacity'] ?? '',
      maintenanceSchedule: json['maintenance_schedule'] ?? '',
      remarks: json['remarks'],
      description: json['description'],
      vehicleNumber: json['vehicle_number'] ?? '',
      ownedBy: json['owned_by'] ?? '',
      supplierId: json['supplier_id'],
      operationalStatus: json['operational_status'] ?? '',
      siteId: json['site_id'] ?? 0,
      createdBy: json['created_by'] ?? 0,
      workspaceId: json['workspace_id'] ?? 0,
      status: json['status']?.toString() ?? '0',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category_id': categoryId,
      'model_number': modelNumber,
      'manufacturer': manufacturer,
      'purchase_date': purchaseDate,
      'capacity': capacity,
      'maintenance_schedule': maintenanceSchedule,
      'remarks': remarks,
      'description': description,
      'vehicle_number': vehicleNumber,
      'owned_by': ownedBy,
      'supplier_id': supplierId,
      'operational_status': operationalStatus,
      'site_id': siteId,
      'created_by': createdBy,
      'workspace_id': workspaceId,
      'status': status,
    };
  }

  Machinery copyWith({
    int? id,
    String? name,
    int? categoryId,
    String? modelNumber,
    String? manufacturer,
    String? purchaseDate,
    String? capacity,
    String? maintenanceSchedule,
    String? remarks,
    String? description,
    String? vehicleNumber,
    String? ownedBy,
    int? supplierId,
    String? operationalStatus,
    int? siteId,
    int? createdBy,
    int? workspaceId,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return Machinery(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      modelNumber: modelNumber ?? this.modelNumber,
      manufacturer: manufacturer ?? this.manufacturer,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      capacity: capacity ?? this.capacity,
      maintenanceSchedule: maintenanceSchedule ?? this.maintenanceSchedule,
      remarks: remarks ?? this.remarks,
      description: description ?? this.description,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      ownedBy: ownedBy ?? this.ownedBy,
      supplierId: supplierId ?? this.supplierId,
      operationalStatus: operationalStatus ?? this.operationalStatus,
      siteId: siteId ?? this.siteId,
      createdBy: createdBy ?? this.createdBy,
      workspaceId: workspaceId ?? this.workspaceId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class MachineryResponse {
  final int status;
  final List<Machinery> data;

  MachineryResponse({
    required this.status,
    required this.data,
  });

  factory MachineryResponse.fromJson(Map<String, dynamic> json) {
    return MachineryResponse(
      status: json['status'] ?? 0,
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => Machinery.fromJson(item))
          .toList() ?? [],
    );
  }
}