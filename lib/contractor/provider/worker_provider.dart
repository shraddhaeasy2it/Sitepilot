import 'package:flutter/material.dart';

class WorkerProvider with ChangeNotifier {
  // Worker data
  final List<Map<String, dynamic>> _workers = [
    {
      'id': '1',
      'name': 'Maria Garcia',
      'role': 'Supervisor',
      'siteId': 'site2',
      'site': 'Site B',
      'status': 'Present',
      'avatar': 'MG',
      'timeIn': '07:45 AM',
      'late': true,
      'phone': '+1 555-234-5678',
      'email': 'maria.garcia@example.com',
    },
    {
      'id': '2',
      'name': 'Robert Johnson',
      'role': 'Carpenter',
      'siteId': 'site1',
      'site': 'Site A',
      'status': 'Late',
      'avatar': 'RJ',
      'timeIn': '08:35 AM',
      'late': true,
      'phone': '+1 555-345-6789',
      'email': 'robert.johnson@example.com',
    },
    {
      'id': '3',
      'name': 'Sarah Williams',
      'role': 'Electrician',
      'siteId': 'site3',
      'site': 'Site C',
      'status': 'Absent',
      'avatar': 'SW',
      'timeIn': '',
      'late': false,
      'phone': '+1 555-456-7890',
      'email': 'sarah.williams@example.com',
    },
  ];

  // Attendance data
  final List<Map<String, dynamic>> _attendanceData = [
    {
      'id': '1',
      'workerId': '1',
      'workerName': 'Maria Garcia',
      'siteId': 'site2',
      'site': 'Site B',
      'date': DateTime.now(),
      'timeIn': '07:45 AM',
      'timeOut': '05:00 PM',
      'status': 'Present',
      'hours': 9.0,
      'overtime': 1.0,
      'image': null,
    },
    {
      'id': '2',
      'workerId': '2',
      'workerName': 'Robert Johnson',
      'siteId': 'site1',
      'site': 'Site A',
      'date': DateTime.now(),
      'timeIn': '08:35 AM',
      'timeOut': '05:00 PM',
      'status': 'Late',
      'hours': 8.5,
      'overtime': 0.5,
      'image': null,
    },
    {
      'id': '3',
      'workerId': '3',
      'workerName': 'Sarah Williams',
      'siteId': 'site3',
      'site': 'Site C',
      'date': DateTime.now(),
      'timeIn': '',
      'timeOut': '',
      'status': 'Absent',
      'hours': 0.0,
      'overtime': 0.0,
      'image': null,
    },
  ];

  // Getters
  List<Map<String, dynamic>> get workers => _workers;
  List<Map<String, dynamic>> get attendanceData => _attendanceData;

  // Update worker
  void updateWorker(Map<String, dynamic> updatedWorker) {
    final index = _workers.indexWhere((w) => w['id'] == updatedWorker['id']);
    if (index != -1) {
      _workers[index] = updatedWorker;
      
      // Update corresponding attendance record
      final attendanceIndex = _attendanceData.indexWhere(
        (a) => a['workerId'] == updatedWorker['id'],
      );
      if (attendanceIndex != -1) {
        _attendanceData[attendanceIndex]['workerName'] = updatedWorker['name'];
        _attendanceData[attendanceIndex]['siteId'] = updatedWorker['siteId'];
        _attendanceData[attendanceIndex]['site'] = updatedWorker['site'];
        _attendanceData[attendanceIndex]['status'] = updatedWorker['status'];
      }
      
      notifyListeners();
    }
  }

  // Add new worker
  void addWorker(Map<String, dynamic> newWorker) {
    _workers.add(newWorker);
    
    // Generate a unique ID for the attendance record
    final attendanceId = (_attendanceData.isNotEmpty) 
        ? (int.parse(_attendanceData.last['id']) + 1).toString() 
        : '1';
    
    // Add corresponding attendance record
    _attendanceData.add({
      'id': attendanceId,
      'workerId': newWorker['id'],
      'workerName': newWorker['name'],
      'siteId': newWorker['siteId'],
      'site': newWorker['site'],
      'date': DateTime.now(),
      'timeIn': newWorker['status'] == 'Present' ? '08:00 AM' : '',
      'timeOut': newWorker['status'] == 'Present' ? '05:00 PM' : '',
      'status': newWorker['status'],
      'hours': newWorker['status'] == 'Present' ? 9.0 : 0.0,
      'overtime': newWorker['status'] == 'Present' ? 1.0 : 0.0,
      'image': null,
    });
    
    notifyListeners();
  }

  // Update attendance record
  void updateAttendanceRecord(Map<String, dynamic> updatedRecord) {
    final index = _attendanceData.indexWhere((a) => a['id'] == updatedRecord['id']);
    if (index != -1) {
      _attendanceData[index] = updatedRecord;
      notifyListeners();
    }
  }

  // Update attendance image
  void updateAttendanceImage(String recordId, dynamic image) {
    final index = _attendanceData.indexWhere((a) => a['id'] == recordId);
    if (index != -1) {
      _attendanceData[index]['image'] = image;
      notifyListeners();
    }
  }

  // Get attendance for a specific worker
  List<Map<String, dynamic>> getAttendanceForWorker(String workerId) {
    return _attendanceData.where((record) => record['workerId'] == workerId).toList();
  }
}