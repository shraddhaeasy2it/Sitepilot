import 'package:ecoteam_app/models/dashboard/site_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AttendanceScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;

  const AttendanceScreen({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late String _selectedSiteId;
  final List<Map<String, dynamic>> _attendanceData = [];
  final DateTime _selectedDate = DateTime.now();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedSiteId = widget.selectedSiteId ?? '';
    _loadAttendanceData();
  }

  @override
  void didUpdateWidget(AttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSiteId != oldWidget.selectedSiteId) {
      _selectedSiteId = widget.selectedSiteId ?? '';
      _loadAttendanceData();
    }
  }

  void _loadAttendanceData() {
    _attendanceData.clear();
    _attendanceData.addAll([
      {
        'id': '1',
        'workerName': 'John Smith',
        'workerId': 'WS001',
        'siteId': 'site1',
        'site': 'Site A',
        'date': DateTime.now(),
        'timeIn': '08:00 AM',
        'timeOut': '05:00 PM',
        'status': 'Present',
        'hours': 9.0,
        'overtime': 1.0,
        'image': null,
      },
      {
        'id': '2',
        'workerName': 'Maria Garcia',
        'workerId': 'WS002',
        'siteId': 'site2',
        'site': 'Site B',
        'date': DateTime.now(),
        'timeIn': '07:45 AM',
        'timeOut': '05:15 PM',
        'status': 'Present',
        'hours': 9.5,
        'overtime': 1.5,
        'image': null,
      },
      {
        'id': '3',
        'workerName': 'Robert Johnson',
        'workerId': 'WS003',
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
        'id': '4',
        'workerName': 'Sarah Williams',
        'workerId': 'WS004',
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
    ]);
    setState(() {});
  }

  List<Map<String, dynamic>> get filteredAttendanceData {
    return _attendanceData.where((record) {
      final matchesSite = _selectedSiteId.isEmpty || record['siteId'] == _selectedSiteId;
      final matchesDate = record['date'].year == _selectedDate.year &&
          record['date'].month == _selectedDate.month &&
          record['date'].day == _selectedDate.day;
      return matchesSite && matchesDate;
    }).toList();
  }

  Future<void> _captureImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          // Update the original data list, not the filtered one
          final originalIndex = _attendanceData.indexWhere((item) => item['id'] == filteredAttendanceData[index]['id']);
          if (originalIndex != -1) {
            _attendanceData[originalIndex]['image'] = File(image.path);
            if (_attendanceData[originalIndex]['status'] == 'Absent') {
              _attendanceData[originalIndex]['status'] = 'Present';
            }
            if (_attendanceData[originalIndex]['timeIn'].isEmpty) {
              _attendanceData[originalIndex]['timeIn'] = TimeOfDay.now().format(context);
            }
            _attendanceData[originalIndex]['date'] = DateTime.now();
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickImageFromGallery(int index) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          // Update the original data list, not the filtered one
          final originalIndex = _attendanceData.indexWhere((item) => item['id'] == filteredAttendanceData[index]['id']);
          if (originalIndex != -1) {
            _attendanceData[originalIndex]['image'] = File(image.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: ${e.toString()}')),
      );
    }
  }

  void _editAttendance(int index) {
    // Find the original index in the main list
    final originalIndex = _attendanceData.indexWhere((item) => item['id'] == filteredAttendanceData[index]['id']);
    if (originalIndex == -1) return;
    
    final record = _attendanceData[originalIndex];
    final timeInController = TextEditingController(text: record['timeIn']);
    final timeOutController = TextEditingController(text: record['timeOut']);
    String selectedStatus = record['status'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Attendance - ${record['workerName']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: timeInController,
                decoration: InputDecoration(
                  labelText: 'Time In',
                  prefixIcon: Icon(Icons.access_time, color: Colors.indigo[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                readOnly: true,
                onTap: () => _selectTime(context, true, timeInController, originalIndex),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: timeOutController,
                decoration: InputDecoration(
                  labelText: 'Time Out',
                  prefixIcon: Icon(Icons.access_time, color: Colors.indigo[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                readOnly: true,
                onTap: () => _selectTime(context, false, timeOutController, originalIndex),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.info_outline, color: Colors.indigo[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: ['Present', 'Absent', 'Late'].map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              _saveAttendanceChanges(
                originalIndex,
                timeInController.text,
                timeOutController.text,
                selectedStatus,
              );
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isTimeIn, 
      TextEditingController controller, int index) async {
    final initialTime = TimeOfDay.now();
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.indigo[400]!,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      final formattedTime = pickedTime.format(context);
      controller.text = formattedTime;
      
      if (isTimeIn) {
        setState(() {
          _attendanceData[index]['timeIn'] = formattedTime;
        });
      } else {
        setState(() {
          _attendanceData[index]['timeOut'] = formattedTime;
        });
      }

      if (_attendanceData[index]['timeIn'].isNotEmpty && 
          _attendanceData[index]['timeOut'].isNotEmpty) {
        _calculateWorkingHours(index);
      }
    }
  }

  void _calculateWorkingHours(int index) {
    setState(() {
      _attendanceData[index]['hours'] = 8.0;
      _attendanceData[index]['overtime'] = 1.0;
    });
  }

  void _saveAttendanceChanges(
    int index, 
    String timeIn, 
    String timeOut, 
    String status,
  ) {
    setState(() {
      _attendanceData[index]['timeIn'] = timeIn;
      _attendanceData[index]['timeOut'] = timeOut;
      _attendanceData[index]['status'] = status;
      
      if (timeIn.isNotEmpty && timeOut.isNotEmpty) {
        _calculateWorkingHours(index);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attendance updated successfully'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 90,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 30,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Track daily attendance records',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(25),
            ),
            gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF6f88e2),
                    Color(0xFF5a73d1),
                    Color(0xFF4a63c0),
                  ],
                ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSiteSelector(),
          _buildDateDisplay(),
          _buildSummaryCards(),
          Expanded(
            child: _buildAttendanceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSiteSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedSiteId.isNotEmpty ? _selectedSiteId : null,
        decoration: InputDecoration(
          labelText: 'Select Site',
          labelStyle: TextStyle(color: Colors.grey[600]),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.location_on, color: Colors.indigo[400]),
        ),
        dropdownColor: Colors.white,
        items: [
          const DropdownMenuItem<String>(
            value: '',
            child: Text('All Sites', style: TextStyle(color: Colors.black87)),
          ),
          ...widget.sites.map((site) {
            return DropdownMenuItem<String>(
              value: site.id,
              child: Text(site.name, style: const TextStyle(color: Colors.black87)),
            );
          }),
        ],
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedSiteId = newValue;
            });
            widget.onSiteChanged(newValue);
          }
        },
      ),
    );
  }

  Widget _buildDateDisplay() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Colors.indigo[400], size: 20),
          const SizedBox(width: 8),
          Text(
            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const Spacer(),
          Text(
            'Today',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final presentCount = filteredAttendanceData.where((r) => r['status'] == 'Present').length;
    final absentCount = filteredAttendanceData.where((r) => r['status'] == 'Absent').length;
    final lateCount = filteredAttendanceData.where((r) => r['status'] == 'Late').length;
    final totalHours = filteredAttendanceData.fold<double>(
        0, (sum, record) => sum + (record['hours'] is int ? (record['hours'] as int).toDouble() : record['hours'] as double));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildSummaryCard(
            title: 'Present',
            value: presentCount.toString(),
            color: Colors.green[600]!,
            icon: Icons.check_circle,
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            title: 'Absent',
            value: absentCount.toString(),
            color: Colors.red[600]!,
            icon: Icons.cancel,
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            title: 'Late',
            value: lateCount.toString(),
            color: Colors.orange[600]!,
            icon: Icons.schedule,
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            title: 'Hours',
            value: '${totalHours.toStringAsFixed(1)}h',
            color: Colors.blue[600]!,
            icon: Icons.access_time,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    if (filteredAttendanceData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_alt_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No attendance records',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a different site or date',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredAttendanceData.length,
      itemBuilder: (context, index) {
        final record = filteredAttendanceData[index];
        return _buildAttendanceCard(record, index);
      },
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record, int index) {
    final statusColor = _getStatusColor(record['status']);
    final hasImage = record['image'] != null;

    return Card(
      
      color: const Color.fromARGB(209, 255, 255, 255),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          
          children: [
            Row(
              children: [
                // Image/Status Indicator
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: statusColor.withOpacity(0.1),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: hasImage
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                record['image'] as File,
                                fit: BoxFit.cover,
                                width: 60,
                                height: 60,
                              ),
                            )
                          : Icon(
                              _getStatusIcon(record['status']),
                              color: statusColor,
                              size: 30,
                            ),
                    ),
                    if (record['status'] != 'Absent')
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () => _captureImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.indigo[400],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Worker Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record['workerName'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${record['workerId']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Site: ${record['site']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Status and Hours
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        record['status'],
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${record['hours']}h',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (record['overtime'] > 0)
                      Text(
                        '+${record['overtime']}h OT',
                        style: TextStyle(
                          color: Colors.orange[600],
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'In: ${record['timeIn'].isEmpty ? '--:--' : record['timeIn']}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Out: ${record['timeOut'].isEmpty ? '--:--' : record['timeOut']}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, size: 18, color: Colors.indigo[400]),
                  onPressed: () => _editAttendance(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return Colors.green;
      case 'Absent':
        return Colors.red;
      case 'Late':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Present':
        return Icons.check_circle;
      case 'Absent':
        return Icons.cancel;
      case 'Late':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }
}