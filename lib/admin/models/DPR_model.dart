import 'package:intl/intl.dart';

class DPRModel {
  int? id;
  String date;
  double machineStartReading;
  double machineEndReading;
  int numberOfOperators;
  String workDetails;
  double dieselConsumption;
  String maintenanceNotes;
  String machineryAdvances;
  int status;
  int siteId;
  int workspaceId;
  int createdBy;
  String? createdAt;
  String? updatedAt;

  DPRModel({
    this.id,
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
    this.createdAt,
    this.updatedAt,
  });

  factory DPRModel.fromJson(Map<String, dynamic> json) {
    return DPRModel(
      id: json['id'],
      date: json['date'] ?? DateTime.now().toIso8601String(),
      machineStartReading: json['machine_start_reading'] is int
          ? (json['machine_start_reading'] as int).toDouble()
          : (json['machine_start_reading'] ?? 0.0),
      machineEndReading: json['machine_end_reading'] is int
          ? (json['machine_end_reading'] as int).toDouble()
          : (json['machine_end_reading'] ?? 0.0),
      numberOfOperators: json['number_of_operators'] ?? 0,
      workDetails: json['work_details'] ?? '',
      dieselConsumption: json['diesel_consumption'] is String
          ? double.tryParse(json['diesel_consumption']) ?? 0.0
          : (json['diesel_consumption'] ?? 0.0).toDouble(),
      maintenanceNotes: json['maintenance_notes'] ?? '',
      machineryAdvances: json['machinery_advances'] ?? '',
      status: json['status'] ?? 0,
      siteId: json['site_id'] ?? 0,
      workspaceId: json['workspace_id'] ?? 0,
      createdBy: json['created_by'] ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
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
    };
  }

  double get machineHours {
    return machineEndReading - machineStartReading;
  }

  String get formattedDate {
    try {
      final date = DateTime.parse(this.date);
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

  factory DPRCreateResponse.fromJson(Map<String, dynamic> json) {
    return DPRCreateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: DPRModel.fromJson(json['data']),
    );
  }
}