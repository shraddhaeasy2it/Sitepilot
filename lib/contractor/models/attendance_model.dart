class AttendanceHistoryResponse {
  final int status;
  final List<AttendanceData> data;

  AttendanceHistoryResponse({
    required this.status,
    required this.data,
  });

  factory AttendanceHistoryResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryResponse(
      status: _parseInt(json['status']),
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => AttendanceData.fromJson(e))
              .toList() ??
          [],
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class AttendanceData {
  final String totalTime;
  final String date;
  final List<HistoryItem> history;

  AttendanceData({
    required this.totalTime,
    required this.date,
    required this.history,
  });

  factory AttendanceData.fromJson(Map<String, dynamic> json) {
    return AttendanceData(
      totalTime: json['total_time']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      history: (json['history'] as List<dynamic>?)
              ?.map((e) => HistoryItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class HistoryItem {
  final int id;
  final String status;
  final String clockIn;
  final String clockOut;
  final String total;
  final int employeeId;
  final String employeeName;
  final int siteId;
  final String siteName;

  HistoryItem({
    required this.id,
    required this.status,
    required this.clockIn,
    required this.clockOut,
    required this.total,
    required this.employeeId,
    required this.employeeName,
    required this.siteId,
    required this.siteName,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: AttendanceHistoryResponse._parseInt(json['id']),
      status: (json['status'] ?? '').toString(),
      clockIn: (json['clock_in'] ?? '').toString(),
      clockOut: (json['clock_out'] ?? '').toString(),
      total: (json['total'] ?? '').toString(),
      employeeId: AttendanceHistoryResponse._parseInt(json['employee_id']),
      employeeName: (json['employee_name'] ?? json['name'] ?? '').toString(),
      siteId: AttendanceHistoryResponse._parseInt(json['site_id']),
      siteName: (json['site_name'] ?? json['site'] ?? '').toString(),
    );
  }
}

class DropdownEmployee {
  final int id;
  final String name;

  DropdownEmployee({
    required this.id,
    required this.name,
  });

  factory DropdownEmployee.fromJson(Map<String, dynamic> json) {
    return DropdownEmployee(
      id: AttendanceHistoryResponse._parseInt(json['id']),
      name: json['name'] ?? '',
    );
  }
}
