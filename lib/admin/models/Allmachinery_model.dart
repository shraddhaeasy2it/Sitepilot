import 'dart:convert';

class Site {
  final int id;
  final String name;
  final int workspace;
  final String status;
  final String? image;
  final String description;

  Site({
    required this.id,
    required this.name,
    required this.workspace,
    required this.status,
    this.image,
    required this.description,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      workspace: json['workspace'] ?? 0,
      status: json['status'] ?? '',
      image: json['image'],
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'workspace': workspace,
      'status': status,
      'image': image,
      'description': description,
    };
  }
}

class TransferData {
  final String transferType;
  final Map<String, String>? machinerase;
  final Map<String, dynamic>? tools;
  final Map<String, dynamic>? employee3;
  final Map<String, String> toSiteId;
  final Map<String, String> fromSiteId;
  final Map<String, dynamic>? users;
  final String? machineryId;
  final List<int>? fromSiteIdList;

  TransferData({
    required this.transferType,
    this.machinerase,
    this.tools,
    this.employee3,
    required this.toSiteId,
    required this.fromSiteId,
    this.users,
    this.machineryId,
    this.fromSiteIdList,
  });

  factory TransferData.fromJson(Map<String, dynamic> json) {
    return TransferData(
      transferType: json['transfer_type'] ?? '',
      machinerase: json['machinerase'] != null 
          ? Map<String, String>.from(json['machinerase']) 
          : null,
      tools: json['tools'],
      employee3: json['employee3'],
      toSiteId: Map<String, String>.from(json['to_site_id'] ?? {}),
      fromSiteId: Map<String, String>.from(json['from_site_id'] ?? {}),
      users: json['users'],
      machineryId: json['machineryId'],
      fromSiteIdList: json['fromSiteId'] != null 
          ? List<int>.from(json['fromSiteId']) 
          : null,
    );
  }
}

class TransferResponse {
  final String status;
  final TransferData data;

  TransferResponse({
    required this.status,
    required this.data,
  });

  factory TransferResponse.fromJson(Map<String, dynamic> json) {
    return TransferResponse(
      status: json['status'] ?? '',
      data: TransferData.fromJson(json['data'] ?? {}),
    );
  }
}

class CreateTransferRequest {
  final String transferType;
  final int machineryId;
  final String transferDate;
  final int fromSiteId;
  final int toSiteId;
  final int createdBy;

  CreateTransferRequest({
    required this.transferType,
    required this.machineryId,
    required this.transferDate,
    required this.fromSiteId,
    required this.toSiteId,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'transfer_type': transferType,
      'machinery_id': machineryId,
      'transfer_date': transferDate,
      'from_site_id': fromSiteId,
      'to_site_id': toSiteId,
      'created_by': createdBy,
    };
  }
}

class CreateTransferResponse {
  final String status;
  final String message;
  final TransferRecord data;

  CreateTransferResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory CreateTransferResponse.fromJson(Map<String, dynamic> json) {
    return CreateTransferResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: TransferRecord.fromJson(json['data'] ?? {}),
    );
  }
}

class TransferRecord {
  final int id;
  final String transferType;
  final int machineryId;
  final String transferDate;
  final int fromSiteId;
  final int toSiteId;
  final int createdBy;
  final int workspaceId;
  final String updatedAt;
  final String createdAt;

  TransferRecord({
    required this.id,
    required this.transferType,
    required this.machineryId,
    required this.transferDate,
    required this.fromSiteId,
    required this.toSiteId,
    required this.createdBy,
    required this.workspaceId,
    required this.updatedAt,
    required this.createdAt,
  });

  factory TransferRecord.fromJson(Map<String, dynamic> json) {
    return TransferRecord(
      id: json['id'] ?? 0,
      transferType: json['transfer_type'] ?? '',
      machineryId: json['machinery_id'] ?? 0,
      transferDate: json['transfer_date'] ?? '',
      fromSiteId: json['from_site_id'] ?? 0,
      toSiteId: json['to_site_id'] ?? 0,
      createdBy: json['created_by'] ?? 0,
      workspaceId: json['workspace_id'] ?? 0,
      updatedAt: json['updated_at'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

// Existing AllMachinery class remains the same
class AllMachinery {
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

  AllMachinery({
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

  factory AllMachinery.fromJson(Map<String, dynamic> json) {
    return AllMachinery(
      id: int.tryParse(json['id']?.toString() ?? '0'),
      name: json['name'] ?? '',
      categoryId: int.tryParse(json['category_id']?.toString() ?? '0') ?? 0,
      modelNumber: json['model_number'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      purchaseDate: json['purchase_date'] ?? '',
      capacity: json['capacity'] ?? '',
      maintenanceSchedule: json['maintenance_schedule'] ?? '',
      remarks: json['remarks'],
      description: json['description'],
      vehicleNumber: json['vehicle_number'] ?? '',
      ownedBy: json['owned_by'] ?? '',
      supplierId: int.tryParse(json['supplier_id']?.toString() ?? ''),
      operationalStatus: json['operational_status'] ?? '',
      siteId: int.tryParse(json['site_id']?.toString() ?? '0') ?? 0,
      createdBy: int.tryParse(json['created_by']?.toString() ?? '0') ?? 0,
      workspaceId: int.tryParse(json['workspace_id']?.toString() ?? '0') ?? 0,
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
}

class MachineryResponse {
  final int status;
  final List<AllMachinery> data;

  MachineryResponse({
    required this.status,
    required this.data,
  });

  factory MachineryResponse.fromJson(Map<String, dynamic> json) {
    return MachineryResponse(
      status: json['status'] ?? 0,
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => AllMachinery.fromJson(item))
          .toList() ?? [],
    );
  }
}