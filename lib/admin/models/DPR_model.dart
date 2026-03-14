

import 'package:intl/intl.dart';

class DPRItem {
  int? materialId;
  String? materialName;
  int quantity;
  String unit;
  String remarks;
  double currentStock;

  DPRItem({
    this.materialId,
    this.materialName,
    required this.quantity,
    required this.unit,
    required this.remarks,
    this.currentStock = 0.0,
  });

  factory DPRItem.fromJson(Map<String, dynamic> json) {
    return DPRItem(
      materialId: json['material_id'] is String
          ? int.tryParse(json['material_id'])
          : json['material_id'],
      materialName: json['material'] != null ? json['material']['name'] : null,
      quantity: json['quantity'] is String
          ? double.tryParse(json['quantity'])?.toInt() ?? 0
          : (json['quantity'] ?? 0).toInt(),
      unit: json['material'] != null && json['material']['unit'] != null
          ? json['material']['unit']['name'] ?? json['unit'] ?? ''
          : json['unit'] ?? '',
      remarks: json['remarks'] ?? '',
      currentStock: json['material'] != null && json['material']['current_stock'] != null
          ? (json['material']['current_stock'] as num).toDouble()
          : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material_id': materialId,
      'quantity': quantity,
      'unit': unit,
      'remarks': remarks,
    };
  }
}

class DPRModel {
  int? id;
  int machineryId;
  String date;
  double machineStartReading;
  double machineEndReading;
  int numberOfOperators;
  String workDetails;
  double dieselConsumption;
  String maintenanceNotes;
  String machineryAdvances;
  int status;
  int? siteId;
  int? workspaceId;
  String? machineryName;
  int? createdBy;
  int? ownedById;
  String? referenceFileUrl;
  String? createdAt;
  String? updatedAt;
  List<DPRItem> items;
  String consumptionType;

  DPRModel({
    this.id,
    required this.machineryId,
    this.machineryName,
    required this.date,
    required this.machineStartReading,
    required this.machineEndReading,
    required this.numberOfOperators,
    required this.workDetails,
    required this.dieselConsumption,
    required this.maintenanceNotes,
    required this.machineryAdvances,
    required this.status,
    required this.siteId,
    required this.workspaceId,
    required this.createdBy,
    this.ownedById,
    this.referenceFileUrl,
    this.createdAt,
    this.updatedAt,
    List<DPRItem>? items,
    this.consumptionType = 'fuel',
  }) : items = items ?? [];

  factory DPRModel.fromJson(Map<String, dynamic> json) {
    int _parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return DPRModel(
      id: _parseInt(json['id']),
      machineryId: _parseInt(json['machinery_id']),
      machineryName: json['machinery'] != null ? json['machinery']['name'] : (json['machinery_name'] ?? 'Unknown'),
      date: json['date'] ?? DateTime.now().toIso8601String(),
      machineStartReading: json['machine_start_reading'] is int
          ? (json['machine_start_reading'] as int).toDouble()
          : (double.tryParse(json['machine_start_reading']?.toString() ?? '0') ?? 0.0),
      machineEndReading: json['machine_end_reading'] is int
          ? (json['machine_end_reading'] as int).toDouble()
          : (double.tryParse(json['machine_end_reading']?.toString() ?? '0') ?? 0.0),
      numberOfOperators: _parseInt(json['number_of_operators']),
      workDetails: json['work_details'] ?? '',
      dieselConsumption: json['diesel_consumption'] is String
          ? double.tryParse(json['diesel_consumption']) ?? 0.0
          : (json['diesel_consumption'] ?? 0.0).toDouble(),
      maintenanceNotes: json['maintenance_notes'] ?? '',
      machineryAdvances: json['machinery_advances'] ?? '',
      status: _parseInt(json['status']),
      siteId: _parseInt(json['site_id']),
      workspaceId: _parseInt(json['workspace_id']),
      createdBy: _parseInt(json['created_by']),
      ownedById: _parseInt(json['owned_by']),
      referenceFileUrl: json['reference_file'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      consumptionType: json['consumption_type'] ?? 'fuel',
      items: (json['consumption_master'] != null && json['consumption_master']['details'] != null)
          ? (json['consumption_master']['details'] as List)
              .map((i) => DPRItem.fromJson(i))
              .toList()
          : (json['items'] != null)
              ? (json['items'] as List).map((i) => DPRItem.fromJson(i)).toList()
              : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'machinery_id': machineryId,
      'date': date,
      'machine_start_reading': machineStartReading,
      'machine_end_reading': machineEndReading,
      'number_of_operators': numberOfOperators,
      'work_details': workDetails,
      'diesel_consumption': dieselConsumption,
      'maintenance_notes': maintenanceNotes,
      'machinery_advances': machineryAdvances,
      'status': status,
      'site_id': siteId,
      'workspace_id': workspaceId,
      'created_by': createdBy,
      'owned_by': ownedById,
      'consumption_type': consumptionType,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  double get machineHours {
    return machineEndReading - machineStartReading;
  }

  String get formattedDate {
    try {
      final date = DateTime.parse(this.date).toLocal();
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return date;
    }
  }
}

class DPRResponse {
  bool success;
  String message;
  List<DPRModel> data;

  DPRResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory DPRResponse.fromJson(Map<String, dynamic> json) {
    return DPRResponse(
      success: json['success'],
      message: json['message'] ?? '',
      data: (json['data'] as List)
          .map((item) => DPRModel.fromJson(item))
          .toList(),
    );
  }
}

class DPRCreateResponse {
  bool success;
  String message;
  DPRModel data;

  DPRCreateResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory DPRCreateResponse.fromJson(Map<String, dynamic> json, {List<DPRItem>? localItems}) {
    Map<String, dynamic> dataJson = json['data'] ?? {};
    
    // The POST response provides details inside 'consumption']['data']['details']
    if (json['consumption'] != null && json['consumption']['data'] != null && json['consumption']['data']['details'] != null) {
      List<dynamic> details = json['consumption']['data']['details'];
      
      // Inject local material names back into the payload since the POST API strips them
      if (localItems != null && localItems.isNotEmpty) {
         for (int i = 0; i < details.length; i++) {
            if (i < localItems.length && localItems[i].materialName != null) {
               details[i]['material'] = {
                 'name': localItems[i].materialName
               };
            }
         }
      }

      dataJson['consumption_master'] = {
        'details': details,
      };
    }

    return DPRCreateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: DPRModel.fromJson(dataJson),
    );
  }
}

