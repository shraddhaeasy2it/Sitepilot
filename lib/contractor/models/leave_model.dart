
import 'package:ecoteam_app/contractor/models/leave_type_model.dart';

class Leave {
  final int id;
  final int employeeId;
  final int userId;
  final int leaveTypeId;
  final LeaveType? leaveType;
  final String appliedOn;
  final String startDate;
  final String endDate;
  final String totalLeaveDays;
  final String leaveReason;
  final String? remark;
  final String status;
  final int workspace;
  final int createdBy;

  Leave({
    required this.id,
    required this.employeeId,
    required this.userId,
    required this.leaveTypeId,
    this.leaveType,
    required this.appliedOn,
    required this.startDate,
    required this.endDate,
    required this.totalLeaveDays,
    required this.leaveReason,
    this.remark,
    required this.status,
    required this.workspace,
    required this.createdBy,
  });

  factory Leave.fromJson(Map<String, dynamic> json) {
    return Leave(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      employeeId: json['employee_id'] is int ? json['employee_id'] : int.tryParse(json['employee_id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      leaveTypeId: json['leave_type_id'] is int ? json['leave_type_id'] : int.tryParse(json['leave_type_id'].toString()) ?? 0,
      // leave_type could be an object or null
      leaveType: json['leave_type'] != null && json['leave_type'] is Map<String, dynamic>
          ? LeaveType.fromJson(json['leave_type'])
          : null,
      appliedOn: json['applied_on'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      totalLeaveDays: json['total_leave_days'].toString(),
      leaveReason: json['leave_reason'] ?? '',
      remark: json['remark'],
      status: json['status'] ?? 'Pending',
      workspace: json['workspace'] is int ? json['workspace'] : int.tryParse(json['workspace'].toString()) ?? 0,
      createdBy: json['created_by'] is int ? json['created_by'] : int.tryParse(json['created_by'].toString()) ?? 0,
    );
  }
}
