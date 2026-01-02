// models/transfer_models.dart

import 'dart:convert';

class TransferData {
  final String transferType;
  final Map<String, dynamic>? machineries;
  final Map<String, dynamic>? tools;
  final Map<String, dynamic>? employees;
  final Map<String, String> toSiteId;
  final Map<String, String> fromSiteId;
  final Map<String, dynamic>? users;

  TransferData({
    required this.transferType,
    this.machineries,
    this.tools,
    this.employees,
    required this.toSiteId,
    required this.fromSiteId,
    this.users,
  });

  factory TransferData.fromJson(Map<String, dynamic> json) {
    return TransferData(
      transferType: json['transfer_type'] ?? '',
      machineries: json['machineries'] != null 
          ? Map<String, dynamic>.from(json['machineries']) 
          : null,
      tools: json['tools'] != null 
          ? Map<String, dynamic>.from(json['tools']) 
          : null,
      employees: json['employees'] != null 
          ? Map<String, dynamic>.from(json['employees']) 
          : null,
      toSiteId: Map<String, String>.from(json['to_site_id'] ?? {}),
      fromSiteId: Map<String, String>.from(json['from_site_id'] ?? {}),
      users: json['users'] != null 
          ? Map<String, dynamic>.from(json['users']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transfer_type': transferType,
      'machineries': machineries,
      'tools': tools,
      'employees': employees,
      'to_site_id': toSiteId,
      'from_site_id': fromSiteId,
      'users': users,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.toJson(),
    };
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
  final Map<String, dynamic> data;

  CreateTransferResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory CreateTransferResponse.fromJson(Map<String, dynamic> json) {
    return CreateTransferResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transfer_type': transferType,
      'machinery_id': machineryId,
      'transfer_date': transferDate,
      'from_site_id': fromSiteId,
      'to_site_id': toSiteId,
      'created_by': createdBy,
      'workspace_id': workspaceId,
      'updated_at': updatedAt,
      'created_at': createdAt,
    };
  }
}