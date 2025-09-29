import 'dart:io';
import 'package:ecoteam_app/services/report_services.dart';
import 'package:ecoteam_app/view/auth/login_selector.dart';
import 'package:ecoteam_app/view/contractor_dashboard/notification.dart';
import 'package:ecoteam_app/view/contractor_dashboard/profilepage.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ecoteam_app/models/site_model.dart';
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
  
  // New state variables for search and filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All';
  final List<String> _statusOptions = ['All', 'Present', 'Absent', 'Late'];

  @override
  void initState() {
    super.initState();
    _selectedSiteId = widget.selectedSiteId ?? '';
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
              child: Column(
                children: [
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Select Site',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQueryForSites = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search sites...',
                      prefixIcon: Icon(Icons.search, size: 20.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
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
                            style: TextStyle(
                              fontWeight: FontWeight.w600, 
                              fontSize: 16.sp
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedSiteId = site.id;
                            });
                            widget.onSiteChanged(site.id);
                            Navigator.pop(context);
                          },
                          trailing: _selectedSiteId == site.id
                              ? Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF4a63c0),
                                  size: 24.sp,
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
        final workerProvider = Provider.of<WorkerProvider>(
          context,
          listen: false,
        );
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.h),
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
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4a63c0),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.grey[600], size: 24.sp),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  record['workerName'],
                  style: TextStyle(fontSize: 18.sp, color: Colors.grey[700]),
                ),
                SizedBox(height: 24.h),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: timeInController,
                    decoration: InputDecoration(
                      labelText: 'Time In',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 16.h,
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
                        icon: Icon(Icons.access_time, 
                                  color: Color(0xFF4a63c0), 
                                  size: 20.sp),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: timeOutController,
                    decoration: InputDecoration(
                      labelText: 'Time Out',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 16.h,
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
                        icon: Icon(Icons.access_time, 
                                  color: Color(0xFF4a63c0), 
                                  size: 20.sp),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: DropdownButtonFormField<String>(
                      value: selectedStatus,
                      items: ['Present', 'Absent', 'Late']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status, style: TextStyle(fontSize: 16.sp)),
                            ),
                          )
                          .toList(),
                      onChanged: onStatusChanged,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4a63c0),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    child: Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
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

  void _showWorkerProfile(Map<String, dynamic> record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.symmetric(vertical: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            // Profile content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile image
                    Container(
                      width: 100.w,
                      height: 100.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getStatusColor(record['status']),
                          width: 2.w,
                        ),
                      ),
                      child: record['image'] != null
                          ? ClipOval(
                              child: Image.file(
                                record['image'] as File,
                                fit: BoxFit.cover,
                                width: 96.w,
                                height: 96.h,
                              ),
                            )
                          : Center(
                              child: Text(
                                record['workerName'].toString().substring(0, 1) +
                                    (record['workerName'].toString().contains(' ')
                                        ? record['workerName'].toString().split(' ')[1][0]
                                        : ''),
                                style: TextStyle(
                                  color: Color.fromARGB(255, 87, 87, 87),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 36.sp,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                    ),
                    SizedBox(height: 16.h),
                    // Name and status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          record['workerName'],
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        ],
                    ),
                         SizedBox(width: 20),
                        Row(
                          children: [
                            _buildStatusIndicator(record['status']),
                          ]
                          
                        ),
                       
                        
                      
                    SizedBox(height: 8.h),
                    // ID
                    Text(
                      'ID: ${record['workerId']}',
                      style: TextStyle(
                        fontSize: 17.sp,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    // Divider
                    
                    // Details grid
                    _buildProfileDetailRow(
                      'Site',
                      record['site'],
                      Icons.location_on_rounded,
                    ),
                    SizedBox(height: 12.h),
                    _buildProfileDetailRow(
                      'Status',
                      record['status'],
                      _getStatusIcon(record['status']),
                      iconColor: _getStatusColor(record['status']),
                    ),
                    SizedBox(height: 12.h),
                    _buildProfileDetailRow(
                      'Time In',
                      record['timeIn'].isNotEmpty
                          ? record['timeIn']
                          : 'Not recorded',
                      Icons.access_time_rounded,
                    ),
                    SizedBox(height: 12.h),
                    _buildProfileDetailRow(
                      'Time Out',
                      record['timeOut'].isNotEmpty
                          ? record['timeOut']
                          : 'Not recorded',
                      Icons.access_time_rounded,
                    ),
                    SizedBox(height: 12.h),
                    _buildProfileDetailRow(
                      'Hours Worked',
                      '${record['hours']}h',
                      Icons.schedule,
                    ),
                    if (record['overtime'] > 0) ...[
                      SizedBox(height: 12.h),
                      _buildProfileDetailRow(
                        'Overtime',
                        '+${record['overtime']}h',
                        Icons.update,
                        iconColor: const Color(0xFFe79315),
                      ),
                    ],
                    SizedBox(height: 24.h),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _captureImage(record['id']);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Color(0xFF4a63c0), width: 1.w),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  color: Color(0xFF4a63c0),
                                  size: 20.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Capture Photo',
                                  style: TextStyle(
                                    color: Color(0xFF4a63c0),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _editAttendance(record);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 56, 59, 68),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit, color: Colors.white, size: 20.sp),
                                SizedBox(width: 8.w),
                                Text(
                                  'Edit Details',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetailRow(
    String title,
    String value,
    IconData icon, {
    Color? iconColor,
  }) {
    return Row(
      children: [
        Container(
          width: 40.w,
          height: 40.h,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, 
                     color: iconColor ?? const Color(0xFF4a63c0), 
                     size: 20.sp),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Present':
        return Icons.check_circle;
      case 'Absent':
        return Icons.cancel;
      case 'Late':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.download, size: 24.sp),
            onPressed: _showExportOptions,
            tooltip: 'Export Report',
          ),
        ],
        iconTheme: IconThemeData(color: Colors.white, size: 24.sp),
        toolbarHeight: 80.h,
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
                      fontSize: 22.sp,
                    ),
                  ),
                  if (widget.sites.isNotEmpty) SizedBox(width: 8.w),
                  if (widget.sites.isNotEmpty)
                    Icon(Icons.keyboard_arrow_down, 
                          color: Colors.white, 
                          size: 24.sp),
                ],
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Track daily attendance',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w400,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
        flexibleSpace: ClipRRect(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25.r)),
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
            // Site filter
            final matchesSite =
                _selectedSiteId.isEmpty || record['siteId'] == _selectedSiteId;
            // Date filter
            final matchesDate =
                record['date'].year == _selectedDate.year &&
                record['date'].month == _selectedDate.month &&
                record['date'].day == _selectedDate.day;
            // Status filter
            final matchesStatus =
                _statusFilter == 'All' || record['status'] == _statusFilter;
            // Search filter
            final matchesSearch =
                _searchQuery.isEmpty ||
                record['workerName'].toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                record['workerId'].toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
            return matchesSite && matchesDate && matchesStatus && matchesSearch;
          }).toList();
          
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.all(20.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                     children: [ 
                      Icon(
                        Icons.calendar_month_outlined,
                        color: Color.fromARGB(255, 106, 131, 219),
                        size: 20.sp,
                      ),
                      SizedBox(width: 10.w),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                     ]
                    ),
                    
                    Text("Todays date", 
                          style: TextStyle(
                            color: const Color.fromARGB(255, 143, 143, 143),
                            fontSize: 14.sp
                          )),
                  ],
                ),
              ),
              // Search and Filter Row
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    // Search field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name or ID...',
                          hintStyle: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 16.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Color(0xFF667EEA),
                            size: 20.sp,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12.h),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, size: 20.sp),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    // Filter chips
                    SizedBox(
                      height: 36.h,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          SizedBox(width: 4.w),
                          _buildFilterChip('All'),
                          _buildFilterChip('Present'),
                          _buildFilterChip('Absent'),
                          _buildFilterChip('Late'),
                          SizedBox(width: 4.w),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(height: 16.h),
              Expanded(
                child: attendanceData.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 60.sp,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              _searchQuery.isNotEmpty || _statusFilter != 'All'
                                  ? 'No matching records found'
                                  : 'No attendance records',
                              style: TextStyle(
                                fontSize: 18.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Try changing your search or filters',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemCount: attendanceData.length,
                        itemBuilder: (context, index) {
                          final record = attendanceData[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: AnimatedContainer(
                              duration: Duration(
                                milliseconds: 300 + (index * 50),
                              ),
                              curve: Curves.easeOutCubic,
                              child: _buildAttendanceCard(
                                record,
                                workerProvider,
                              ),
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

  Widget _buildAttendanceCard(
    Map<String, dynamic> record,
    WorkerProvider workerProvider,
  ) {
    return Container(
      height: 130.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: Colors.white,
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showWorkerProfile(record),
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.h),
            child: Row(
              children: [
                // Avatar Section with Camera
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _showWorkerProfile(record),
                      child: Container(
                        width: 65.w,
                        height: 65.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getStatusColor(record['status']),
                            width: 1.5.w,
                          ),
                        ),
                        child: record['image'] != null
                            ? ClipOval(
                                child: Image.file(
                                  record['image'] as File,
                                  fit: BoxFit.cover,
                                  width: 46.w,
                                  height: 46.h,
                                ),
                              )
                            : Center(
                                child: Text(
                                  record['workerName'].toString().substring(0, 1) +
                                      (record['workerName'].toString().contains(' ')
                                          ? record['workerName']
                                                .toString()
                                                .split(' ')[1][0]
                                          : ''),
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 87, 87, 87),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18.sp,
                                    letterSpacing: -0.5,
                                  ),
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
                            padding: EdgeInsets.all(2.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _getStatusColor(record['status']),
                                width: 1.5.w,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: _getStatusColor(record['status']),
                              size: 14.sp,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 16.w),
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
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 5.w),
                          _buildStatusIndicator(record['status']),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'ID: ${record['workerId']}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14.sp,
                            color: const Color(0xFF94A3B8),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              record['site'],
                              style: TextStyle(
                                fontSize: 13.sp,
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
                SizedBox(width: 16.w),
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
                            size: 14.sp,
                            color: const Color.fromARGB(255, 107, 118, 133),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '${record['timeIn']} - ${record['timeOut']}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14.sp,
                              color: const Color(0xFF94A3B8),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Not checked in',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 8.h),
                    // Hours Info
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${record['hours']}h',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (record['overtime'] > 0) ...[
                          SizedBox(width: 4.w),
                          Text(
                            '+${record['overtime']}h',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFFe79315),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 8.h),
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

  // Add this method to your _AttendanceScreenState class
  void _showExportOptions() {
    _showPdfFilterBottomSheet();
  }

  void _showPdfFilterBottomSheet() {
    String selectedPresence = 'All';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4a63c0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.filter_list,
                        color: Color(0xFF4a63c0),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Filter PDF Report',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Presence Filter
                const Text('Presence Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: DropdownButton<String>(
                    value: selectedPresence,
                    hint: const Text('All Status'),
                    isExpanded: true,
                    underline: Container(),
                    items: ['All', 'Present', 'Absent', 'Late']
                        .map((status) => DropdownMenuItem<String>(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedPresence = value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _exportPDF(presenceFilter: selectedPresence);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4a63c0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Download PDF',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  Future<void> _exportPDF({
    String? presenceFilter,
  }) async {
    try {
      final workerProvider = Provider.of<WorkerProvider>(
        context,
        listen: false,
      );
      // Filter attendance data
      final attendanceData = workerProvider.attendanceData.where((record) {
        final matchesSite =
            _selectedSiteId.isEmpty || record['siteId'] == _selectedSiteId;

        // Use current selected date
        final matchesDate = record['date'].year == _selectedDate.year &&
            record['date'].month == _selectedDate.month &&
            record['date'].day == _selectedDate.day;

        // Presence filter
        final matchesPresence = presenceFilter == null ||
            presenceFilter == 'All' ||
            record['status'] == presenceFilter;

        return matchesSite && matchesDate && matchesPresence;
      }).toList();
      
      if (attendanceData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No attendance data to export')),
        );
        return;
      }
      
      // Get site name
      String siteName = 'All Sites';
      if (_selectedSiteId.isNotEmpty) {
        final site = widget.sites.firstWhere(
          (site) => site.id == _selectedSiteId,
          orElse: () => Site(id: '', name: 'Unknown Site', address: ''),
        );
        siteName = site.name;
      }
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );
      
      final path = await ReportService.generateAttendancePDF(
        attendanceData,
        siteName,
        null,
        null,
      );
      
      // Close loading indicator
      Navigator.of(context).pop();
      
      await ReportService.openFile(path);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF exported successfully!')),
      );
    } catch (e) {
      // Close loading indicator if still open
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting PDF: ${e.toString()}')),
      );
      print('PDF Export Error: $e');
    }
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
        borderRadius: BorderRadius.circular(8.r),
        child: Icon(icon, size: 20.sp, color: color),
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: _getStatusColor(status),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 5.w),
        Text(
          status,
          style: TextStyle(
            color: _getStatusColor(status),
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = _statusFilter == filter;
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4a63c0) : Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4a63c0)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18.r),
            onTap: () {
              setState(() {
                _statusFilter = filter;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
        ),
      ),
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