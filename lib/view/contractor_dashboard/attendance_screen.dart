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
  final TextEditingController _searchController = TextEditingController();
  List<Site> _filteredSites = [];

  @override
  void initState() {
    super.initState();
    _selectedSiteId = widget.selectedSiteId ?? '';
    _filteredSites = widget.sites;
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
      final matchesSite =
          _selectedSiteId.isEmpty || record['siteId'] == _selectedSiteId;
      final matchesDate =
          record['date'].year == _selectedDate.year &&
          record['date'].month == _selectedDate.month &&
          record['date'].day == _selectedDate.day;
      return matchesSite && matchesDate;
    }).toList();
  }

  void _filterSites(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSites = widget.sites;
      } else {
        _filteredSites = widget.sites
            .where(
              (site) => site.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  void _showSiteSelectionBottomSheet() {
    _searchController.clear();
    _filteredSites = widget.sites;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Site',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[700],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search sites...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.indigo[400]),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[500]),
                              onPressed: () {
                                _searchController.clear();
                                _filterSites('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                    onChanged: (value) {
                      _filterSites(value);
                    },
                  ),
                ),
                SizedBox(height: 5),

                // Sites List
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredSites
                        .length, // Removed +1 for "All Sites" option
                    itemBuilder: (context, index) {
                      final site =
                          _filteredSites[index]; // Directly use index without subtracting
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.indigo[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: Colors.indigo[400],
                          ),
                        ),
                        title: Text(
                          site.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        trailing: _selectedSiteId == site.id
                            ? Icon(
                                Icons.check_circle,
                                color: Colors.indigo[400],
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedSiteId = site.id;
                          });
                          widget.onSiteChanged(site.id);
                          _loadAttendanceData();
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _captureImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          final originalIndex = _attendanceData.indexWhere(
            (item) => item['id'] == filteredAttendanceData[index]['id'],
          );
          if (originalIndex != -1) {
            _attendanceData[originalIndex]['image'] = File(image.path);
            if (_attendanceData[originalIndex]['status'] == 'Absent') {
              _attendanceData[originalIndex]['status'] = 'Present';
            }
            if (_attendanceData[originalIndex]['timeIn'].isEmpty) {
              _attendanceData[originalIndex]['timeIn'] = TimeOfDay.now().format(
                context,
              );
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
          final originalIndex = _attendanceData.indexWhere(
            (item) => item['id'] == filteredAttendanceData[index]['id'],
          );
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
    final originalIndex = _attendanceData.indexWhere(
      (item) => item['id'] == filteredAttendanceData[index]['id'],
    );
    if (originalIndex == -1) return;

    final record = _attendanceData[originalIndex];
    final timeInController = TextEditingController(text: record['timeIn']);
    final timeOutController = TextEditingController(text: record['timeOut']);
    String selectedStatus = record['status'];

    _showEditBottomSheet(
      context,
      record: record,
      timeInController: timeInController,
      timeOutController: timeOutController,
      selectedStatus: selectedStatus,
      onStatusChanged: (value) {
        setState(() {
          selectedStatus = value!;
        });
      },
      onSave: () {
        _saveAttendanceChanges(
          originalIndex,
          timeInController.text,
          timeOutController.text,
          selectedStatus,
        );
        Navigator.pop(context);
      },
    );
  }

  void _showEditBottomSheet(
    BuildContext context, {
    required Map<String, dynamic> record,
    required TextEditingController timeInController,
    required TextEditingController timeOutController,
    required String selectedStatus,
    required Function(String?) onStatusChanged,
    required VoidCallback onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Attendance',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[700],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              record['workerName'],
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            SizedBox(height: 24),

            // Time In Field
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextFormField(
                controller: timeInController,
                decoration: InputDecoration(
                  labelText: 'Time In',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(
                    Icons.access_time,
                    color: Colors.indigo[400],
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                ),
                readOnly: true,
                onTap: () => _selectTime(
                  context,
                  true,
                  timeInController,
                  _attendanceData.indexOf(record),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Time Out Field
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextFormField(
                controller: timeOutController,
                decoration: InputDecoration(
                  labelText: 'Time Out',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(
                    Icons.access_time,
                    color: Colors.indigo[400],
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                ),
                readOnly: true,
                onTap: () => _selectTime(
                  context,
                  false,
                  timeOutController,
                  _attendanceData.indexOf(record),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Status Field
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Status',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(
                    Icons.info_outline,
                    color: Colors.indigo[400],
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                ),
                items: ['Present', 'Absent', 'Late'].map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: onStatusChanged,
              ),
            ),
            SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[400],
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    bool isTimeIn,
    TextEditingController controller,
    int index,
  ) async {
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
      SnackBar(
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
    // Get the selected site name for display in the app bar
    String selectedSiteName = 'All Sites';
    if (_selectedSiteId.isNotEmpty) {
      final selectedSite = widget.sites
          .where((site) => site.id == _selectedSiteId)
          .firstOrNull;
      if (selectedSite != null) {
        selectedSiteName = selectedSite.name;
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 80,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _showSiteSelectionBottomSheet,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedSiteName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 22,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            const Text(
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
              colors: [Color(0xFF4a63c0), Color(0xFF3a53b0), Color(0xFF2a43a0)],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildDateDisplay(),
          _buildSummaryCards(),
          Expanded(child: _buildAttendanceList()),
        ],
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
    final presentCount = filteredAttendanceData
        .where((r) => r['status'] == 'Present')
        .length;
    final absentCount = filteredAttendanceData
        .where((r) => r['status'] == 'Absent')
        .length;
    final lateCount = filteredAttendanceData
        .where((r) => r['status'] == 'Late')
        .length;
    final totalHours = filteredAttendanceData.fold<double>(
      0,
      (sum, record) =>
          sum +
          (record['hours'] is int
              ? (record['hours'] as int).toDouble()
              : record['hours'] as double),
    );
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
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a different site or date',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        'Site: ${record['site']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Status and Hours
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Out: ${record['timeOut'].isEmpty ? '--:--' : record['timeOut']}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
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
