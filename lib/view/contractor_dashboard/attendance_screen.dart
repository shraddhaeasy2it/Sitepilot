import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ecoteam_app/models/dashboard/site_model.dart';
import 'package:ecoteam_app/provider/worker_provider.dart';

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
  DateTime _selectedDate = DateTime.now();
  final ImagePicker _picker = ImagePicker();
  String? _searchQueryForSites;

  @override
  void initState() {
    super.initState();
    _selectedSiteId = widget.selectedSiteId ?? '';
  }

  @override
  void didUpdateWidget(AttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSiteId != oldWidget.selectedSiteId) {
      setState(() {
        _selectedSiteId = widget.selectedSiteId ?? '';
      });
    }
  }

  void _showSiteSelectorBottomSheet() {
    setState(() {
      _searchQueryForSites = '';
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Site',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQueryForSites = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search sites...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: widget.sites.length,
                      itemBuilder: (context, index) {
                        final site = widget.sites[index];
                        if (_searchQueryForSites != null &&
                            _searchQueryForSites!.isNotEmpty &&
                            !site.name.toLowerCase().contains(
                                  _searchQueryForSites!.toLowerCase(),
                                )) {
                          return const SizedBox.shrink();
                        }
                        return ListTile(
                          title: Text(
                            site.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedSiteId = site.id;
                            });
                            widget.onSiteChanged(site.id);
                            Navigator.pop(context);
                          },
                          trailing: _selectedSiteId == site.id
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF4a63c0),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _captureImage(String recordId) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
        workerProvider.updateAttendanceImage(recordId, File(image.path));
        
        // Update status if needed
        final record = workerProvider.attendanceData.firstWhere(
          (r) => r['id'] == recordId,
        );
        if (record['status'] == 'Absent') {
          final updatedRecord = Map<String, dynamic>.from(record);
          updatedRecord['status'] = 'Present';
          updatedRecord['timeIn'] = TimeOfDay.now().format(context);
          updatedRecord['date'] = DateTime.now();
          workerProvider.updateAttendanceRecord(updatedRecord);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickImageFromGallery(String recordId) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
        workerProvider.updateAttendanceImage(recordId, File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: ${e.toString()}')),
      );
    }
  }

  void _editAttendance(Map<String, dynamic> record) {
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
          record['id'],
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
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                        color: Color(0xFF4a63c0),
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
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: timeInController,
                    decoration: InputDecoration(
                      labelText: 'Time In',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            timeInController.text = time.format(context);
                          }
                        },
                        icon: Icon(Icons.access_time, color: Color(0xFF4a63c0)),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: timeOutController,
                    decoration: InputDecoration(
                      labelText: 'Time Out',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            timeOutController.text = time.format(context);
                          }
                        },
                        icon: Icon(Icons.access_time, color: Color(0xFF4a63c0)),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonFormField<String>(
                      value: selectedStatus,
                      items: ['Present', 'Absent', 'Late']
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ))
                          .toList(),
                      onChanged: onStatusChanged,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4a63c0),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveAttendanceChanges(
    String recordId,
    String timeIn,
    String timeOut,
    String status,
  ) {
    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    final record = workerProvider.attendanceData.firstWhere(
      (r) => r['id'] == recordId,
    );
    
    final updatedRecord = Map<String, dynamic>.from(record);
    updatedRecord['timeIn'] = timeIn;
    updatedRecord['timeOut'] = timeOut;
    updatedRecord['status'] = status;
    
    if (timeIn.isNotEmpty && timeOut.isNotEmpty) {
      final inTime = _parseTime(timeIn);
      final outTime = _parseTime(timeOut);
      final hours = outTime.difference(inTime).inHours.toDouble();
      updatedRecord['hours'] = hours >= 8 ? hours : 0.0;
      updatedRecord['overtime'] = hours > 8 ? hours - 8 : 0.0;
    } else {
      updatedRecord['hours'] = 0.0;
      updatedRecord['overtime'] = 0.0;
    }
    
    workerProvider.updateAttendanceRecord(updatedRecord);
    
    final worker = workerProvider.workers.firstWhere(
      (w) => w['id'] == record['workerId'],
      orElse: () => {},
    );
    if (worker.isNotEmpty) {
      final updatedWorker = Map<String, dynamic>.from(worker);
      updatedWorker['status'] = status;
      updatedWorker['timeIn'] = timeIn;
      updatedWorker['late'] = status == 'Late';
      workerProvider.updateWorker(updatedWorker);
    }
  }

  DateTime _parseTime(String timeString) {
    final now = DateTime.now();
    final parts = timeString.split(' ');
    final timeParts = parts[0].split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final isPM = parts[1].toUpperCase() == 'PM';
    
    return DateTime(
      now.year,
      now.month,
      now.day,
      isPM && hour != 12 ? hour + 12 : hour,
      minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        toolbarHeight: 80,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: widget.sites.isEmpty ? null : _showSiteSelectorBottomSheet,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.sites.isEmpty
                        ? 'No Sites'
                        : (_selectedSiteId.isEmpty
                            ? 'All Sites'
                            : widget.sites
                                .firstWhere(
                                  (site) => site.id == _selectedSiteId,
                                  orElse: () => Site(
                                    id: '',
                                    name: 'Unknown Site',
                                    address: '',
                                  ),
                                )
                                .name),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 22,
                    ),
                  ),
                  if (widget.sites.isNotEmpty) SizedBox(width: 8),
                  if (widget.sites.isNotEmpty)
                    Icon(Icons.keyboard_arrow_down, color: Colors.white),
                ],
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Track daily attendance',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
          ],
        ),
        flexibleSpace: ClipRRect(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(25),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4a63c0),
                  Color(0xFF3a53b0),
                  Color(0xFF2a43a0),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Consumer<WorkerProvider>(
        builder: (context, workerProvider, child) {
          // Filter attendance data using the provider instance
          final attendanceData = workerProvider.attendanceData.where((record) {
            final matchesSite = _selectedSiteId.isEmpty || 
                record['siteId'] == _selectedSiteId;
            final matchesDate = record['date'].year == _selectedDate.year &&
                record['date'].month == _selectedDate.month &&
                record['date'].day == _selectedDate.day;
            return matchesSite && matchesDate;
          }).toList();
          
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2023),
                          lastDate: DateTime.now(),
                        );
                        if (selected != null) {
                          setState(() {
                            _selectedDate = selected;
                          });
                        }
                      },
                      icon: Icon(Icons.calendar_today, color: Color(0xFF4a63c0)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Total',
                        value: attendanceData.length.toString(),
                        icon: Icons.people_outline,
                        color: Color(0xFF4a63c0),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Present',
                        value: attendanceData
                            .where((r) => r['status'] == 'Present')
                            .length
                            .toString(),
                        icon: Icons.check_circle_outline,
                        color: Color(0xFF0aa137),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Absent',
                        value: attendanceData
                            .where((r) => r['status'] == 'Absent')
                            .length
                            .toString(),
                        icon: Icons.cancel_outlined,
                        color: Color(0xFFe94b1b),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Late',
                        value: attendanceData
                            .where((r) => r['status'] == 'Late')
                            .length
                            .toString(),
                        icon: Icons.schedule_outlined,
                        color: Color(0xFFe79315),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: attendanceData.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 60, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              'No attendance records',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try changing the date or site filter',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: attendanceData.length,
                        itemBuilder: (context, index) {
                          final record = attendanceData[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300 + (index * 50)),
                              curve: Curves.easeOutCubic,
                              child: _buildAttendanceCard(record, workerProvider),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record, WorkerProvider workerProvider) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editAttendance(record),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar Section with Camera
                Stack(
                  children: [
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getStatusColor(record['status']),
                          width: 1.5,
                        ),
                      ),
                      child: record['image'] != null
                          ? ClipOval(
                              child: Image.file(
                                record['image'] as File,
                                fit: BoxFit.cover,
                                width: 46,
                                height: 46,
                              ),
                            )
                          : Center(
                              child: Text(
                                record['workerName'].toString().substring(0, 1) + 
                                    (record['workerName'].toString().contains(' ') 
                                        ? record['workerName'].toString().split(' ')[1][0] 
                                        : ''),
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 87, 87, 87),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                    ),
                    
                    if (record['status'] != 'Absent')
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () => _captureImage(record['id']),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _getStatusColor(record['status']),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: _getStatusColor(record['status']),
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Info Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              record['workerName'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 5),
                          _buildStatusIndicator(record['status']),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${record['workerId']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              record['site'],
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Right Section - Time & Actions
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Time Info
                    if (record['timeIn'].isNotEmpty) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: const Color.fromARGB(255, 107, 118, 133),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${record['timeIn']} - ${record['timeOut']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Not checked in',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Hours Info
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${record['hours']}h',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (record['overtime'] > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '+${record['overtime']}h',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFFe79315),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Action Button - Only Edit
                    _buildActionButton(
                      icon: Icons.edit_outlined,
                      onPressed: () => _editAttendance(record),
                      color: const Color(0xFF4a63c0),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    return Row(
      
      mainAxisSize: MainAxisSize.min,
      children: [
        
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _getStatusColor(status),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          status,
          style: TextStyle(
            color: _getStatusColor(status),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return const Color(0xFF0aa137);
      case 'Absent':
        return const Color(0xFFe94b1b);
      case 'Late':
        return const Color(0xFFe79315);
      default:
        return const Color(0xFF64748B);
    }
  }
}