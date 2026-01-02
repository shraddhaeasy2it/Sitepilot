import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../models/site_model.dart';




// Employee Model
class Employee {
  String id;
  String name;
  String position;
  String employeeId;
  String siteId;
  File? image;
  String status;
  String? timeIn;
  String? timeOut;
  double hours;
  double overtime;
  double latitude;
  double longitude;
  DateTime date;

  Employee({
    required this.id,
    required this.name,
    required this.position,
    required this.employeeId,
    required this.siteId,
    this.image,
    this.status = 'Absent',
    this.timeIn,
    this.timeOut,
    this.hours = 0.0,
    this.overtime = 0.0,
    required this.latitude,
    required this.longitude,
    required this.date,
  });
}

// Provider
class EmployeeProvider extends ChangeNotifier {
  List<Employee> _employees = [];
  List<Site> _sites = [];
  String _selectedSiteId = '';
  LocationData? _currentLocation;
  bool _locationEnabled = false;
  bool _permissionGranted = false;

  List<Employee> get employees => _employees;
  List<Site> get sites => _sites;
  String get selectedSiteId => _selectedSiteId;
  LocationData? get currentLocation => _currentLocation;
  bool get locationEnabled => _locationEnabled;
  bool get permissionGranted => _permissionGranted;

  EmployeeProvider() {
    _initializeData();
    _initializeLocation();
  }

  void _initializeData() {
    // Initialize sites
    _sites = [
      Site(id: '1', name: 'Main Office', companyId: '1'),
      Site(id: '2', name: 'Construction Site A', companyId: '1'),
      Site(id: '3', name: 'Construction Site B', companyId: '1'),
      Site(id: '4', name: 'Warehouse', companyId: '1'),
      Site(id: '3', name: 'Construction Site B', companyId: '1'),
      Site(id: '4', name: 'Warehouse', companyId: '1'),
    ];
    _selectedSiteId = '';

    // Initialize employees
    _employees = [
      Employee(
        id: '1',
        name: 'John Smith',
        position: 'Software Engineer',
        employeeId: 'EMP001',
        siteId: '1',
        status: 'Present',
        timeIn: '09:00 AM',
        timeOut: '06:00 PM',
        hours: 8.0,
        overtime: 1.0,
        latitude: 0.0,
        longitude: 0.0,
        date: DateTime.now(),
      ),
      Employee(
        id: '2',
        name: 'Sarah Johnson',
        position: 'Project Manager',
        employeeId: 'EMP002',
        siteId: '2',
        status: 'Late',
        timeIn: '09:30 AM',
        timeOut: '06:30 PM',
        hours: 8.0,
        overtime: 0.0,
        latitude: 0.0,
        longitude: 0.0,
        date: DateTime.now(),
      ),
      Employee(
        id: '3',
        name: 'Mike Wilson',
        position: 'Designer',
        employeeId: 'EMP003',
        siteId: '1',
        status: 'Absent',
        timeIn: '',
        timeOut: '',
        hours: 0.0,
        overtime: 0.0,
        latitude: 0.0,
        longitude: 0.0,
        date: DateTime.now(),
      ),
      Employee(
        id: '4',
        name: 'Emily Davis',
        position: 'QA Tester',
        employeeId: 'EMP004',
        siteId: '3',
        status: 'Present',
        timeIn: '09:00 AM',
        timeOut: '05:30 PM',
        hours: 8.0,
        overtime: 0.0,
        latitude: 0.0,
        longitude: 0.0,
        date: DateTime.now(),
      ),
      Employee(
        id: '5',
        name: 'Robert Brown',
        position: 'DevOps Engineer',
        employeeId: 'EMP005',
        siteId: '4',
        status: 'Present',
        timeIn: '08:45 AM',
        timeOut: '06:15 PM',
        hours: 8.5,
        overtime: 0.5,
        latitude: 0.0,
        longitude: 0.0,
        date: DateTime.now(),
      ),
    ];
    notifyListeners();
  }

  Future<void> _initializeLocation() async {
    await _checkLocationPermission();
    if (_permissionGranted && _locationEnabled) {
      await _getCurrentLocation();
    }
  }

  Future<void> _checkLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isGranted) {
      _permissionGranted = true;
    } else {
      status = await Permission.location.request();
      _permissionGranted = status.isGranted;
    }

    Location location = Location();
    _locationEnabled = await location.serviceEnabled();
    if (!_locationEnabled) {
      _locationEnabled = await location.requestService();
    }
    
    notifyListeners();
  }

  Future<void> _getCurrentLocation() async {
    if (!_permissionGranted || !_locationEnabled) return;

    try {
      Location location = Location();
      _currentLocation = await location.getLocation();
      notifyListeners();
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void setSelectedSite(String siteId) {
    _selectedSiteId = siteId;
    notifyListeners();
  }

  Future<void> updateEmployeeImage(String id, File image) async {
    final index = _employees.indexWhere((emp) => emp.id == id);
    if (index != -1) {
      _employees[index].image = image;
      
      // Update status and time if marking attendance
      if (_employees[index].status == 'Absent') {
        _employees[index].status = 'Present';
        _employees[index].timeIn = DateFormat('hh:mm a').format(DateTime.now());
        _employees[index].date = DateTime.now();
        
        // Update with current location
        if (_currentLocation != null) {
          _employees[index].latitude = _currentLocation!.latitude!;
          _employees[index].longitude = _currentLocation!.longitude!;
        }
      }
      
      notifyListeners();
    }
  }

  void updateEmployee(Employee updatedEmployee) {
    final index = _employees.indexWhere((emp) => emp.id == updatedEmployee.id);
    if (index != -1) {
      _employees[index] = updatedEmployee;
      notifyListeners();
    }
  }

  void markAttendance(String id, String status) {
    final index = _employees.indexWhere((emp) => emp.id == id);
    if (index != -1) {
      _employees[index].status = status;
      _employees[index].timeIn = DateFormat('hh:mm a').format(DateTime.now());
      _employees[index].date = DateTime.now();
      
      // Update with current location
      if (_currentLocation != null) {
        _employees[index].latitude = _currentLocation!.latitude!;
        _employees[index].longitude = _currentLocation!.longitude!;
      }
      
      notifyListeners();
    }
  }

  Future<void> refreshLocation() async {
    await _checkLocationPermission();
    if (_permissionGranted && _locationEnabled) {
      await _getCurrentLocation();
    }
  }

  // Get employees filtered by selected site
  List<Employee> getFilteredEmployees() {
    if (_selectedSiteId.isEmpty) return _employees;
    return _employees.where((emp) => emp.siteId == _selectedSiteId).toList();
  }

  // Set sites from parent
  void setSites(List<Site> sites) {
    _sites = sites;
    if (_selectedSiteId.isEmpty && _sites.isNotEmpty) {
      // _selectedSiteId = _sites.first.id; // Don't force select, let parent handle
    }
    notifyListeners();
  }
  
  // Get site name by ID
  String getSiteName(String siteId) {
    if (siteId.isEmpty) return 'Unknown Site';
    try {
      final site = _sites.firstWhere(
        (s) => s.id == siteId,
        orElse: () => Site(id: '', name: 'Unknown Site', companyId: ''),
      );
      return site.name;
    } catch (e) {
      return 'Unknown Site';
    }
  }
}

class AttendanceScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;

  const AttendanceScreen({
    Key? key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
  }) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All';
  final List<String> _statusOptions = ['All', 'Present', 'Absent', 'Late'];
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    
    // Initialize provider with passed data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EmployeeProvider>(context, listen: false);
      provider.setSites(widget.sites);
      if (widget.selectedSiteId != null) {
        provider.setSelectedSite(widget.selectedSiteId!);
      }
    });
  }

  @override
  void didUpdateWidget(AttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final provider = Provider.of<EmployeeProvider>(context, listen: false);
    
    if (widget.sites != oldWidget.sites) {
       provider.setSites(widget.sites);
    }
    
    if (widget.selectedSiteId != oldWidget.selectedSiteId) {
        if (widget.selectedSiteId != null) {
           provider.setSelectedSite(widget.selectedSiteId!);
        } else {
           provider.setSelectedSite('');
        }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = Provider.of<EmployeeProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Track daily attendance',
              style: TextStyle(
                color: const Color.fromARGB(255, 255, 255, 255),
                fontWeight: FontWeight.w400,
                fontSize: 17.sp,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.selectedSiteId == null || widget.selectedSiteId!.isEmpty
                      ? 'All Sites'
                      : employeeProvider.getSiteName(widget.selectedSiteId!),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(width: 8.w),
              
              ],
            ),
            SizedBox(height: 4.h),
            
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white, size: 24.sp),
            onPressed: () => employeeProvider.refreshLocation(),
            tooltip: 'Refresh Location',
          ),
        ],
       toolbarHeight: 74.h,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(25),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4a63c0), Color(0xFF3a53b0),Color(0xFF2a43a0)],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF4a63c0).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          ),
        ),
      
      body: Column(
        children: [
          // Location Status Banner
          if (employeeProvider.currentLocation != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              color: Colors.green.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.green, size: 16.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Location: Lat ${employeeProvider.currentLocation!.latitude!.toStringAsFixed(4)}, '
                      'Lng ${employeeProvider.currentLocation!.longitude!.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Search and Filter Section
          Padding(
            padding: EdgeInsets.all(16.h),
            child: Column(
              children: [
                // Search Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search employees...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: Icon(Icons.search, color: Color(0xFF4a63c0)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                
                // Filter Chips
                SizedBox(
                  height: 36.h,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      SizedBox(width: 4.w),
                      ..._statusOptions.map((status) {
                        bool isSelected = _statusFilter == status;
                        return Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected ? Color(0xFF4a63c0) : Colors.white,
                              borderRadius: BorderRadius.circular(18.r),
                              border: Border.all(
                                color: isSelected
                                    ? Color(0xFF4a63c0)
                                    : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18.r),
                                onTap: () {
                                  setState(() {
                                    _statusFilter = status;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w, 
                                    vertical: 8.h
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: isSelected ? 
                                          Colors.white : Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Statistics Cards
          
          SizedBox(height: 16.h),

          // Date Display
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, 
                         color: Color(0xFF4a63c0), 
                         size: 18.sp),
                    SizedBox(width: 8.w),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                Text(
                  'Today',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Employee List
          Expanded(
            child: Consumer<EmployeeProvider>(
              builder: (context, provider, child) {
                final filteredEmployees = provider.getFilteredEmployees().where((employee) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      employee.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      employee.employeeId.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesStatus = _statusFilter == 'All' || 
                      employee.status == _statusFilter;
                  return matchesSearch && matchesStatus;
                }).toList();

                return filteredEmployees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 60.sp,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              _searchQuery.isNotEmpty || _statusFilter != 'All'
                                  ? 'No matching records found'
                                  : 'No employees at this site',
                              style: TextStyle(
                                fontSize: 18.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemCount: filteredEmployees.length,
                        itemBuilder: (context, index) {
                          final employee = filteredEmployees[index];
                          return _buildEmployeeCard(employee, provider);
                        },
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.h),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16.sp, color: color),
            ),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Employee employee, EmployeeProvider provider) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.h),
        child: Row(
          children: [
            // Profile Image with Camera
            Stack(
              children: [
                GestureDetector(
                  onTap: () => _showEmployeeProfile(employee, provider),
                  child: Container(
                    width: 60.w,
                    height: 60.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getStatusColor(employee.status),
                        width: 2.w,
                      ),
                    ),
                    child: employee.image != null
                        ? ClipOval(
                            child: Image.file(
                              employee.image!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : CircleAvatar(
                            backgroundColor: Color(0xFF4a63c0).withOpacity(0.1),
                            child: Text(
                              employee.name.substring(0, 1),
                              style: TextStyle(
                                fontSize: 24.sp,
                                color: Color(0xFF4a63c0),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () => _captureImage(employee.id, provider),
                    child: Container(
                      padding: EdgeInsets.all(4.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getStatusColor(employee.status),
                          width: 1.5.w,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: _getStatusColor(employee.status),
                        size: 14.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 16.w),

            // Employee Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          employee.name,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(employee.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: _getStatusColor(employee.status),
                            width: 1.w,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6.w,
                              height: 6.h,
                              decoration: BoxDecoration(
                                color: _getStatusColor(employee.status),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              employee.status,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: _getStatusColor(employee.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    employee.position,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'ID: ${employee.employeeId}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[500],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12.sp, color: Colors.grey[500]),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          provider.getSiteName(employee.siteId),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  
                  // Time Information
                  if (employee.timeIn != null && employee.timeIn!.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12.sp, color: Colors.grey[500]),
                        SizedBox(width: 4.w),
                        Text(
                          '${employee.timeIn} - ${employee.timeOut ?? "Not checked out"}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[700],
                          ),
                        ),
                        Spacer(),
                        if (employee.hours > 0)
                          Text(
                            '${employee.hours.toStringAsFixed(1)}h',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (employee.overtime > 0)
                          Padding(
                            padding: EdgeInsets.only(left: 4.w),
                            child: Text(
                              '+${employee.overtime.toStringAsFixed(1)}h',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    )
                  else
                    Text(
                      'Not checked in',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 8.w),

            // Action Buttons
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Color(0xFF4a63c0), size: 20.sp),
                  onPressed: () => _editEmployee(employee, provider),
                  tooltip: 'Edit',
                ),
                if (employee.status == 'Absent')
                  ElevatedButton(
                    onPressed: () => _markAttendance(employee.id, provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Mark\nPresent',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSiteSelectorBottomSheet(BuildContext context) {
    final provider = Provider.of<EmployeeProvider>(context, listen: false);
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final filteredSites = provider.sites.where((site) {
              return searchQuery.isEmpty ||
                  site.name.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                        searchQuery = value;
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
                      itemCount: filteredSites.length,
                      itemBuilder: (context, index) {
                        final site = filteredSites[index];
                        return ListTile(
                          title: Text(
                            widget.sites[index].name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16.sp,
                            ),
                          ),
                          onTap: () {
                             widget.onSiteChanged(widget.sites[index].id);
                             Navigator.pop(context);
                          },
                          trailing: widget.selectedSiteId == widget.sites[index].id
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
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onSiteChanged(''); // Clear selection
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4a63c0),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'View All Sites',
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
            );
          },
        );
      },
    );
  }

  Future<void> _captureImage(String employeeId, EmployeeProvider provider) async {
    if (!provider.permissionGranted || !provider.locationEnabled) {
      _showLocationWarning(provider);
      return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    
    if (image != null) {
      provider.updateEmployeeImage(employeeId, File(image.path));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image captured and attendance marked!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showLocationWarning(EmployeeProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Location Required'),
        content: Text('Please enable location services to mark attendance.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.refreshLocation();
            },
            child: Text('Enable Location'),
          ),
        ],
      ),
    );
  }

  void _markAttendance(String employeeId, EmployeeProvider provider) async {
    if (!provider.permissionGranted || !provider.locationEnabled) {
      _showLocationWarning(provider);
      return;
    }

    provider.markAttendance(employeeId, 'Present');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Attendance marked successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showEmployeeProfile(Employee employee, EmployeeProvider provider) {
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
            Container(
              margin: EdgeInsets.symmetric(vertical: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 100.w,
                      height: 100.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getStatusColor(employee.status),
                          width: 2.w,
                        ),
                      ),
                      child: employee.image != null
                          ? ClipOval(
                              child: Image.file(
                                employee.image!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Text(
                                employee.name.substring(0, 1),
                                style: TextStyle(
                                  fontSize: 36.sp,
                                  color: Color(0xFF4a63c0),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      employee.name,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      employee.position,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'ID: ${employee.employeeId}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                    SizedBox(height: 24.h),
                    _buildProfileDetailRow(
                      'Site',
                      provider.getSiteName(employee.siteId),
                      Icons.location_on,
                    ),
                    SizedBox(height: 12.h),
                    _buildProfileDetailRow(
                      'Status',
                      employee.status,
                      _getStatusIcon(employee.status),
                      iconColor: _getStatusColor(employee.status),
                    ),
                    SizedBox(height: 12.h),
                    _buildProfileDetailRow(
                      'Time In',
                      employee.timeIn ?? 'Not recorded',
                      Icons.access_time,
                    ),
                    SizedBox(height: 12.h),
                    _buildProfileDetailRow(
                      'Time Out',
                      employee.timeOut ?? 'Not recorded',
                      Icons.access_time,
                    ),
                    SizedBox(height: 12.h),
                    _buildProfileDetailRow(
                      'Hours Worked',
                      '${employee.hours.toStringAsFixed(1)}h',
                      Icons.timer,
                    ),
                    if (employee.overtime > 0) ...[
                      SizedBox(height: 12.h),
                      _buildProfileDetailRow(
                        'Overtime',
                        '+${employee.overtime.toStringAsFixed(1)}h',
                        Icons.timer_outlined,
                        iconColor: Colors.orange,
                      ),
                    ],
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _captureImage(employee.id, provider);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Color(0xFF4a63c0)),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, color: Color(0xFF4a63c0)),
                                SizedBox(width: 8.w),
                                Text('Capture Photo'),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _editEmployee(employee, provider);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4a63c0),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit, color: Colors.white),
                                SizedBox(width: 8.w),
                                Text('Edit', style: TextStyle(color: Colors.white)),
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

  Widget _buildProfileDetailRow(String title, String value, IconData icon, {Color? iconColor}) {
    return Row(
      children: [
        Container(
          width: 40.w,
          height: 40.h,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: iconColor ?? Color(0xFF4a63c0)),
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
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[900],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _editEmployee(Employee employee, EmployeeProvider provider) {
    final nameController = TextEditingController(text: employee.name);
    final positionController = TextEditingController(text: employee.position);
    final employeeIdController = TextEditingController(text: employee.employeeId);
    final timeInController = TextEditingController(text: employee.timeIn);
    final timeOutController = TextEditingController(text: employee.timeOut);
    String selectedStatus = employee.status;
    String? selectedSiteId = employee.siteId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.all(24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Employee',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4a63c0),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                SizedBox(height: 12.h),
                
                TextFormField(
                  controller: positionController,
                  decoration: InputDecoration(
                    labelText: 'Position',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    prefixIcon: Icon(Icons.work),
                  ),
                ),
                SizedBox(height: 12.h),
                
                TextFormField(
                  controller: employeeIdController,
                  decoration: InputDecoration(
                    labelText: 'Employee ID',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                SizedBox(height: 12.h),
                
                DropdownButtonFormField<String>(
                  value: selectedSiteId,
                  decoration: InputDecoration(
                    labelText: 'Site',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  items: provider.sites
                      .map((site) => DropdownMenuItem(
                            value: site.id,
                            child: Text(site.name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSiteId = value;
                    });
                  },
                ),
                SizedBox(height: 12.h),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: timeInController,
                        decoration: InputDecoration(
                          labelText: 'Time In',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          prefixIcon: Icon(Icons.login),
                        ),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            timeInController.text = 
                                DateFormat('hh:mm a').format(DateTime(
                                  DateTime.now().year,
                                  DateTime.now().month,
                                  DateTime.now().day,
                                  time.hour,
                                  time.minute,
                                ));
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: TextFormField(
                        controller: timeOutController,
                        decoration: InputDecoration(
                          labelText: 'Time Out',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          prefixIcon: Icon(Icons.logout),
                        ),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            timeOutController.text = 
                                DateFormat('hh:mm a').format(DateTime(
                                  DateTime.now().year,
                                  DateTime.now().month,
                                  DateTime.now().day,
                                  time.hour,
                                  time.minute,
                                ));
                          }
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  items: ['Present', 'Absent', 'Late']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
                  },
                ),
                SizedBox(height: 24.h),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final updatedEmployee = Employee(
                            id: employee.id,
                            name: nameController.text,
                            position: positionController.text,
                            employeeId: employeeIdController.text,
                            siteId: selectedSiteId ?? employee.siteId,
                            image: employee.image,
                            status: selectedStatus,
                            timeIn: timeInController.text.isNotEmpty ? timeInController.text : null,
                            timeOut: timeOutController.text.isNotEmpty ? timeOutController.text : null,
                            hours: employee.hours,
                            overtime: employee.overtime,
                            latitude: employee.latitude,
                            longitude: employee.longitude,
                            date: employee.date,
                          );
                          provider.updateEmployee(updatedEmployee);
                          Navigator.pop(context);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Employee updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4a63c0),
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }
}

// import 'dart:io';
// import 'package:ecoteam_app/contractor/services/report_services.dart';
// import 'package:ecoteam_app/contractor/view/auth/login_selector.dart';
// import 'package:ecoteam_app/contractor/view/contractor_dashboard/notification.dart';
// import 'package:ecoteam_app/contractor/view/contractor_dashboard/profilepage.dart';
// import 'package:file_selector/file_selector.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:ecoteam_app/contractor/models/site_model.dart';
// import 'package:ecoteam_app/contractor/provider/worker_provider.dart';

// class AttendanceScreen extends StatefulWidget {
//   final String? selectedSiteId;
//   final Function(String) onSiteChanged;
//   final List<Site> sites;
  
//   const AttendanceScreen({
//     super.key,
//     required this.selectedSiteId,
//     required this.onSiteChanged,
//     required this.sites,
//   });

//   @override
//   State<AttendanceScreen> createState() => _AttendanceScreenState();
// }

// class _AttendanceScreenState extends State<AttendanceScreen> {
//   late String _selectedSiteId;
//   DateTime _selectedDate = DateTime.now();
//   final ImagePicker _picker = ImagePicker();
//   String? _searchQueryForSites;
  
//   // New state variables for search and filter
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String _statusFilter = 'All';
//   final List<String> _statusOptions = ['All', 'Present', 'Absent', 'Late'];

//   @override
//   void initState() {
//     super.initState();
//     _selectedSiteId = widget.selectedSiteId ?? '';
//     _searchController.addListener(() {
//       setState(() {
//         _searchQuery = _searchController.text;
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   void didUpdateWidget(AttendanceScreen oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.selectedSiteId != oldWidget.selectedSiteId) {
//       setState(() {
//         _selectedSiteId = widget.selectedSiteId ?? '';
//       });
//     }
//   }

//   void _showSiteSelectorBottomSheet() {
//     setState(() {
//       _searchQueryForSites = '';
//     });
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
//       ),
//       builder: (context) {
//         return DraggableScrollableSheet(
//           initialChildSize: 0.6,
//           minChildSize: 0.4,
//           maxChildSize: 0.9,
//           expand: false,
//           builder: (context, scrollController) {
//             return Container(
//               padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
//               child: Column(
//                 children: [
//                   Container(
//                     width: 40.w,
//                     height: 4.h,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(2.r),
//                     ),
//                   ),
//                   SizedBox(height: 16.h),
//                   Text(
//                     'Select Site',
//                     style: TextStyle(
//                       fontSize: 20.sp,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.grey[800],
//                     ),
//                   ),
//                   SizedBox(height: 16.h),
//                   TextField(
//                     onChanged: (value) {
//                       setState(() {
//                         _searchQueryForSites = value;
//                       });
//                     },
//                     decoration: InputDecoration(
//                       hintText: 'Search sites...',
//                       prefixIcon: Icon(Icons.search, size: 20.sp),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12.r),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 16.h),
//                   Expanded(
//                     child: ListView.builder(
//                       controller: scrollController,
//                       itemCount: widget.sites.length,
//                       itemBuilder: (context, index) {
//                         final site = widget.sites[index];
//                         if (_searchQueryForSites != null &&
//                             _searchQueryForSites!.isNotEmpty &&
//                             !site.name.toLowerCase().contains(
//                               _searchQueryForSites!.toLowerCase(),
//                             )) {
//                           return const SizedBox.shrink();
//                         }
//                         return ListTile(
//                           title: Text(
//                             site.name,
//                             style: TextStyle(
//                               fontWeight: FontWeight.w600, 
//                               fontSize: 16.sp
//                             ),
//                           ),
//                           onTap: () {
//                             setState(() {
//                               _selectedSiteId = site.id;
//                             });
//                             widget.onSiteChanged(site.id);
//                             Navigator.pop(context);
//                           },
//                           trailing: _selectedSiteId == site.id
//                               ? Icon(
//                                   Icons.check_circle,
//                                   color: Color(0xFF4a63c0),
//                                   size: 24.sp,
//                                 )
//                               : null,
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Future<void> _captureImage(String recordId) async {
//     try {
//       final XFile? image = await _picker.pickImage(source: ImageSource.camera);
//       if (image != null) {
//         final workerProvider = Provider.of<WorkerProvider>(
//           context,
//           listen: false,
//         );
//         workerProvider.updateAttendanceImage(recordId, File(image.path));
        
//         // Update status if needed
//         final record = workerProvider.attendanceData.firstWhere(
//           (r) => r['id'] == recordId,
//         );
//         if (record['status'] == 'Absent') {
//           final updatedRecord = Map<String, dynamic>.from(record);
//           updatedRecord['status'] = 'Present';
//           updatedRecord['timeIn'] = TimeOfDay.now().format(context);
//           updatedRecord['date'] = DateTime.now();
//           workerProvider.updateAttendanceRecord(updatedRecord);
//         }
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error capturing image: ${e.toString()}')),
//       );
//     }
//   }

//   void _editAttendance(Map<String, dynamic> record) {
//     final timeInController = TextEditingController(text: record['timeIn']);
//     final timeOutController = TextEditingController(text: record['timeOut']);
//     String selectedStatus = record['status'];
    
//     _showEditBottomSheet(
//       context,
//       record: record,
//       timeInController: timeInController,
//       timeOutController: timeOutController,
//       selectedStatus: selectedStatus,
//       onStatusChanged: (value) {
//         setState(() {
//           selectedStatus = value!;
//         });
//       },
//       onSave: () {
//         _saveAttendanceChanges(
//           record['id'],
//           timeInController.text,
//           timeOutController.text,
//           selectedStatus,
//         );
//         Navigator.pop(context);
//       },
//     );
//   }

//   void _showEditBottomSheet(
//     BuildContext context, {
//     required Map<String, dynamic> record,
//     required TextEditingController timeInController,
//     required TextEditingController timeOutController,
//     required String selectedStatus,
//     required Function(String?) onStatusChanged,
//     required VoidCallback onSave,
//   }) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         height: MediaQuery.of(context).size.height * 0.85,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
//         ),
//         padding: EdgeInsets.only(
//           bottom: MediaQuery.of(context).viewInsets.bottom,
//         ),
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: EdgeInsets.all(24.h),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Edit Attendance',
//                       style: TextStyle(
//                         fontSize: 24.sp,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF4a63c0),
//                       ),
//                     ),
//                     IconButton(
//                       onPressed: () => Navigator.pop(context),
//                       icon: Icon(Icons.close, color: Colors.grey[600], size: 24.sp),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 8.h),
//                 Text(
//                   record['workerName'],
//                   style: TextStyle(fontSize: 18.sp, color: Colors.grey[700]),
//                 ),
//                 SizedBox(height: 24.h),
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.grey[50],
//                     borderRadius: BorderRadius.circular(16.r),
//                     border: Border.all(color: Colors.grey.withOpacity(0.3)),
//                   ),
//                   child: TextField(
//                     controller: timeInController,
//                     decoration: InputDecoration(
//                       labelText: 'Time In',
//                       border: InputBorder.none,
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: 16.w,
//                         vertical: 16.h,
//                       ),
//                       suffixIcon: IconButton(
//                         onPressed: () async {
//                           final time = await showTimePicker(
//                             context: context,
//                             initialTime: TimeOfDay.now(),
//                           );
//                           if (time != null) {
//                             timeInController.text = time.format(context);
//                           }
//                         },
//                         icon: Icon(Icons.access_time, 
//                                   color: Color(0xFF4a63c0), 
//                                   size: 20.sp),
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 16.h),
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.grey[50],
//                     borderRadius: BorderRadius.circular(16.r),
//                     border: Border.all(color: Colors.grey.withOpacity(0.3)),
//                   ),
//                   child: TextField(
//                     controller: timeOutController,
//                     decoration: InputDecoration(
//                       labelText: 'Time Out',
//                       border: InputBorder.none,
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: 16.w,
//                         vertical: 16.h,
//                       ),
//                       suffixIcon: IconButton(
//                         onPressed: () async {
//                           final time = await showTimePicker(
//                             context: context,
//                             initialTime: TimeOfDay.now(),
//                           );
//                           if (time != null) {
//                             timeOutController.text = time.format(context);
//                           }
//                         },
//                         icon: Icon(Icons.access_time, 
//                                   color: Color(0xFF4a63c0), 
//                                   size: 20.sp),
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 24.h),
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.grey[50],
//                     borderRadius: BorderRadius.circular(16.r),
//                     border: Border.all(color: Colors.grey.withOpacity(0.3)),
//                   ),
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 16.w),
//                     child: DropdownButtonFormField<String>(
//                       value: selectedStatus,
//                       items: ['Present', 'Absent', 'Late']
//                           .map(
//                             (status) => DropdownMenuItem(
//                               value: status,
//                               child: Text(status, style: TextStyle(fontSize: 16.sp)),
//                             ),
//                           )
//                           .toList(),
//                       onChanged: onStatusChanged,
//                       decoration: InputDecoration(
//                         labelText: 'Status',
//                         border: InputBorder.none,
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 32.h),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: onSave,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Color(0xFF4a63c0),
//                       padding: EdgeInsets.symmetric(vertical: 16.h),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16.r),
//                       ),
//                     ),
//                     child: Text(
//                       'Save Changes',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 16.sp,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _saveAttendanceChanges(
//     String recordId,
//     String timeIn,
//     String timeOut,
//     String status,
//   ) {
//     final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
//     final record = workerProvider.attendanceData.firstWhere(
//       (r) => r['id'] == recordId,
//     );
//     final updatedRecord = Map<String, dynamic>.from(record);
//     updatedRecord['timeIn'] = timeIn;
//     updatedRecord['timeOut'] = timeOut;
//     updatedRecord['status'] = status;
    
//     if (timeIn.isNotEmpty && timeOut.isNotEmpty) {
//       final inTime = _parseTime(timeIn);
//       final outTime = _parseTime(timeOut);
//       final hours = outTime.difference(inTime).inHours.toDouble();
//       updatedRecord['hours'] = hours >= 8 ? hours : 0.0;
//       updatedRecord['overtime'] = hours > 8 ? hours - 8 : 0.0;
//     } else {
//       updatedRecord['hours'] = 0.0;
//       updatedRecord['overtime'] = 0.0;
//     }
    
//     workerProvider.updateAttendanceRecord(updatedRecord);
    
//     final worker = workerProvider.workers.firstWhere(
//       (w) => w['id'] == record['workerId'],
//       orElse: () => {},
//     );
//     if (worker.isNotEmpty) {
//       final updatedWorker = Map<String, dynamic>.from(worker);
//       updatedWorker['status'] = status;
//       updatedWorker['timeIn'] = timeIn;
//       updatedWorker['late'] = status == 'Late';
//       workerProvider.updateWorker(updatedWorker);
//     }
//   }

//   DateTime _parseTime(String timeString) {
//     final now = DateTime.now();
//     final parts = timeString.split(' ');
//     final timeParts = parts[0].split(':');
//     final hour = int.parse(timeParts[0]);
//     final minute = int.parse(timeParts[1]);
//     final isPM = parts[1].toUpperCase() == 'PM';
//     return DateTime(
//       now.year,
//       now.month,
//       now.day,
//       isPM && hour != 12 ? hour + 12 : hour,
//       minute,
//     );
//   }

//   void _showWorkerProfile(Map<String, dynamic> record) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         height: MediaQuery.of(context).size.height * 0.7,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
//         ),
//         child: Column(
//           children: [
//             // Handle bar
//             Container(
//               margin: EdgeInsets.symmetric(vertical: 12.h),
//               width: 40.w,
//               height: 4.h,
//               decoration: BoxDecoration(
//                 color: Colors.grey[300],
//                 borderRadius: BorderRadius.circular(2.r),
//               ),
//             ),
//             // Profile content
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: EdgeInsets.all(24.h),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     // Profile image
//                     Container(
//                       width: 100.w,
//                       height: 100.h,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         border: Border.all(
//                           color: _getStatusColor(record['status']),
//                           width: 2.w,
//                         ),
//                       ),
//                       child: record['image'] != null
//                           ? ClipOval(
//                               child: Image.file(
//                                 record['image'] as File,
//                                 fit: BoxFit.cover,
//                                 width: 96.w,
//                                 height: 96.h,
//                               ),
//                             )
//                           : Center(
//                               child: Text(
//                                 record['workerName'].toString().substring(0, 1) +
//                                     (record['workerName'].toString().contains(' ')
//                                         ? record['workerName'].toString().split(' ')[1][0]
//                                         : ''),
//                                 style: TextStyle(
//                                   color: Color.fromARGB(255, 87, 87, 87),
//                                   fontWeight: FontWeight.w700,
//                                   fontSize: 36.sp,
//                                   letterSpacing: -0.5,
//                                 ),
//                               ),
//                             ),
//                     ),
//                     SizedBox(height: 16.h),
//                     // Name and status
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           record['workerName'],
//                           style: TextStyle(
//                             fontSize: 24.sp,
//                             fontWeight: FontWeight.bold,
//                             color: Color(0xFF1E293B),
//                           ),
//                         ),
//                         ],
//                     ),
//                          SizedBox(width: 20),
//                         Row(
//                           children: [
//                             _buildStatusIndicator(record['status']),
//                           ]
                          
//                         ),
                       
                        
                      
//                     SizedBox(height: 8.h),
//                     // ID
//                     Text(
//                       'ID: ${record['workerId']}',
//                       style: TextStyle(
//                         fontSize: 17.sp,
//                         color: Color(0xFF64748B),
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     SizedBox(height: 16.h),
//                     // Divider
                    
//                     // Details grid
//                     _buildProfileDetailRow(
//                       'Site',
//                       record['site'],
//                       Icons.location_on_rounded,
//                     ),
//                     SizedBox(height: 12.h),
//                     _buildProfileDetailRow(
//                       'Status',
//                       record['status'],
//                       _getStatusIcon(record['status']),
//                       iconColor: _getStatusColor(record['status']),
//                     ),
//                     SizedBox(height: 12.h),
//                     _buildProfileDetailRow(
//                       'Time In',
//                       record['timeIn'].isNotEmpty
//                           ? record['timeIn']
//                           : 'Not recorded',
//                       Icons.access_time_rounded,
//                     ),
//                     SizedBox(height: 12.h),
//                     _buildProfileDetailRow(
//                       'Time Out',
//                       record['timeOut'].isNotEmpty
//                           ? record['timeOut']
//                           : 'Not recorded',
//                       Icons.access_time_rounded,
//                     ),
//                     SizedBox(height: 12.h),
//                     _buildProfileDetailRow(
//                       'Hours Worked',
//                       '${record['hours']}h',
//                       Icons.schedule,
//                     ),
//                     if (record['overtime'] > 0) ...[
//                       SizedBox(height: 12.h),
//                       _buildProfileDetailRow(
//                         'Overtime',
//                         '+${record['overtime']}h',
//                         Icons.update,
//                         iconColor: const Color(0xFFe79315),
//                       ),
//                     ],
//                     SizedBox(height: 24.h),
//                     // Action buttons
//                     Row(
//                       children: [
//                         Expanded(
//                           child: OutlinedButton(
//                             onPressed: () {
//                               Navigator.pop(context);
//                               _captureImage(record['id']);
//                             },
//                             style: OutlinedButton.styleFrom(
//                               side: BorderSide(color: Color(0xFF4a63c0), width: 1.w),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12.r),
//                               ),
//                               padding: EdgeInsets.symmetric(vertical: 12.h),
//                             ),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(
//                                   Icons.camera_alt,
//                                   color: Color(0xFF4a63c0),
//                                   size: 20.sp,
//                                 ),
//                                 SizedBox(width: 8.w),
//                                 Text(
//                                   'Capture Photo',
//                                   style: TextStyle(
//                                     color: Color(0xFF4a63c0),
//                                     fontWeight: FontWeight.w600,
//                                     fontSize: 14.sp,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         SizedBox(width: 12.w),
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: () {
//                               Navigator.pop(context);
//                               _editAttendance(record);
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Color.fromARGB(255, 56, 59, 68),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12.r),
//                               ),
//                               padding: EdgeInsets.symmetric(vertical: 12.h),
//                             ),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(Icons.edit, color: Colors.white, size: 20.sp),
//                                 SizedBox(width: 8.w),
//                                 Text(
//                                   'Edit Details',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.w600,
//                                     fontSize: 14.sp,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildProfileDetailRow(
//     String title,
//     String value,
//     IconData icon, {
//     Color? iconColor,
//   }) {
//     return Row(
//       children: [
//         Container(
//           width: 40.w,
//           height: 40.h,
//           decoration: BoxDecoration(
//             color: Colors.grey[50],
//             borderRadius: BorderRadius.circular(8.r),
//           ),
//           child: Icon(icon, 
//                      color: iconColor ?? const Color(0xFF4a63c0), 
//                      size: 20.sp),
//         ),
//         SizedBox(width: 16.w),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: 14.sp,
//                   color: Colors.grey[600],
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               SizedBox(height: 2.h),
//               Text(
//                 value,
//                 style: TextStyle(
//                   fontSize: 16.sp,
//                   color: Colors.grey[800],
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   IconData _getStatusIcon(String status) {
//     switch (status) {
//       case 'Present':
//         return Icons.check_circle;
//       case 'Absent':
//         return Icons.cancel;
//       case 'Late':
//         return Icons.access_time;
//       default:
//         return Icons.help_outline;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         actions: [
//           IconButton(
//             icon: Icon(Icons.download, size: 24.sp),
//             onPressed: _showExportOptions,
//             tooltip: 'Export Report',
//           ),
//         ],
//         iconTheme: IconThemeData(color: Colors.white, size: 24.sp),
//         toolbarHeight: 80.h,
//         elevation: 0,
//         backgroundColor: Colors.transparent,
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             GestureDetector(
//               onTap: widget.sites.isEmpty ? null : _showSiteSelectorBottomSheet,
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     widget.sites.isEmpty
//                         ? 'No Sites'
//                         : (_selectedSiteId.isEmpty
//                               ? 'All Sites'
//                               : widget.sites
//                                     .firstWhere(
//                                       (site) => site.id == _selectedSiteId,
//                                       orElse: () => Site(
//                                         id: '',
//                                         name: 'Unknown Site',
//                                         description: '',
//                                         companyId: '',
                                        
//                                       ),
//                                     )
//                                     .name),
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.w500,
//                       fontSize: 22.sp,
//                     ),
//                   ),
//                   if (widget.sites.isNotEmpty) SizedBox(width: 8.w),
//                   if (widget.sites.isNotEmpty)
//                     Icon(Icons.keyboard_arrow_down, 
//                           color: Colors.white, 
//                           size: 24.sp),
//                 ],
//               ),
//             ),
//             SizedBox(height: 4.h),
//             Text(
//               'Track daily attendance',
//               style: TextStyle(
//                 color: Colors.white70,
//                 fontWeight: FontWeight.w400,
//                 fontSize: 16.sp,
//               ),
//             ),
//           ],
//         ),
//         flexibleSpace: ClipRRect(
//           borderRadius: BorderRadius.vertical(bottom: Radius.circular(25.r)),
//           child: Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   Color(0xFF4a63c0),
//                   Color(0xFF3a53b0),
//                   Color(0xFF2a43a0),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//       body: Consumer<WorkerProvider>(
//         builder: (context, workerProvider, child) {
//           // Filter attendance data using the provider instance
//           final attendanceData = workerProvider.attendanceData.where((record) {
//             // Site filter
//             final matchesSite =
//                 _selectedSiteId.isEmpty || record['siteId'] == _selectedSiteId;
//             // Date filter
//             final matchesDate =
//                 record['date'].year == _selectedDate.year &&
//                 record['date'].month == _selectedDate.month &&
//                 record['date'].day == _selectedDate.day;
//             // Status filter
//             final matchesStatus =
//                 _statusFilter == 'All' || record['status'] == _statusFilter;
//             // Search filter
//             final matchesSearch =
//                 _searchQuery.isEmpty ||
//                 record['workerName'].toLowerCase().contains(
//                   _searchQuery.toLowerCase(),
//                 ) ||
//                 record['workerId'].toLowerCase().contains(
//                   _searchQuery.toLowerCase(),
//                 );
//             return matchesSite && matchesDate && matchesStatus && matchesSearch;
//           }).toList();
          
//           return Column(
//             children: [
//               Padding(
//                 padding: EdgeInsets.all(20.h),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Row(
//                      children: [ 
//                       Icon(
//                         Icons.calendar_month_outlined,
//                         color: Color.fromARGB(255, 106, 131, 219),
//                         size: 20.sp,
//                       ),
//                       SizedBox(width: 10.w),
//                     Text(
//                       '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
//                       style: TextStyle(
//                         fontSize: 16.sp,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.grey[800],
//                       ),
//                     ),
//                      ]
//                     ),
                    
//                     Text("Todays date", 
//                           style: TextStyle(
//                             color: const Color.fromARGB(255, 143, 143, 143),
//                             fontSize: 14.sp
//                           )),
//                   ],
//                 ),
//               ),
//               // Search and Filter Row
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 16.w),
//                 child: Column(
//                   children: [
//                     // Search field
//                     Container(
//                       decoration: BoxDecoration(
//                         color: Colors.grey[50],
//                         borderRadius: BorderRadius.circular(12.r),
//                         border: Border.all(
//                           color: Colors.grey.withOpacity(0.3),
//                         ),
//                       ),
//                       child: TextField(
//                         controller: _searchController,
//                         decoration: InputDecoration(
//                           hintText: 'Search by name or ID...',
//                           hintStyle: TextStyle(
//                             color: Color(0xFF94A3B8),
//                             fontSize: 16.sp,
//                           ),
//                           prefixIcon: Icon(
//                             Icons.search_rounded,
//                             color: Color(0xFF667EEA),
//                             size: 20.sp,
//                           ),
//                           border: InputBorder.none,
//                           contentPadding: EdgeInsets.all(12.h),
//                           suffixIcon: _searchQuery.isNotEmpty
//                               ? IconButton(
//                                   icon: Icon(Icons.clear, size: 20.sp),
//                                   onPressed: () {
//                                     _searchController.clear();
//                                   },
//                                 )
//                               : null,
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 16.h),
//                     // Filter chips
//                     SizedBox(
//                       height: 36.h,
//                       child: ListView(
//                         scrollDirection: Axis.horizontal,
//                         children: [
//                           SizedBox(width: 4.w),
//                           _buildFilterChip('All'),
//                           _buildFilterChip('Present'),
//                           _buildFilterChip('Absent'),
//                           _buildFilterChip('Late'),
//                           SizedBox(width: 4.w),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: 16.h),
//               SizedBox(height: 16.h),
//               Expanded(
//                 child: attendanceData.isEmpty
//                     ? Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.event_busy,
//                               size: 60.sp,
//                               color: Colors.grey[400],
//                             ),
//                             SizedBox(height: 16.h),
//                             Text(
//                               _searchQuery.isNotEmpty || _statusFilter != 'All'
//                                   ? 'No matching records found'
//                                   : 'No attendance records',
//                               style: TextStyle(
//                                 fontSize: 18.sp,
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                             SizedBox(height: 8.h),
//                             Text(
//                               'Try changing your search or filters',
//                               style: TextStyle(
//                                 fontSize: 14.sp,
//                                 color: Colors.grey[500],
//                               ),
//                             ),
//                           ],
//                         ),
//                       )
//                     : ListView.builder(
//                         padding: EdgeInsets.symmetric(horizontal: 16.w),
//                         itemCount: attendanceData.length,
//                         itemBuilder: (context, index) {
//                           final record = attendanceData[index];
//                           return Padding(
//                             padding: EdgeInsets.only(bottom: 12.h),
//                             child: AnimatedContainer(
//                               duration: Duration(
//                                 milliseconds: 300 + (index * 50),
//                               ),
//                               curve: Curves.easeOutCubic,
//                               child: _buildAttendanceCard(
//                                 record,
//                                 workerProvider,
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildAttendanceCard(
//     Map<String, dynamic> record,
//     WorkerProvider workerProvider,
//   ) {
//     return Container(
//       height: 130.h,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12.r),
//         color: Colors.white,
//         border: Border.all(color: Colors.grey.withOpacity(0.2)),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: () => _showWorkerProfile(record),
//           borderRadius: BorderRadius.circular(12.r),
//           child: Padding(
//             padding: EdgeInsets.all(16.h),
//             child: Row(
//               children: [
//                 // Avatar Section with Camera
//                 Stack(
//                   children: [
//                     GestureDetector(
//                       onTap: () => _showWorkerProfile(record),
//                       child: Container(
//                         width: 65.w,
//                         height: 65.h,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           border: Border.all(
//                             color: _getStatusColor(record['status']),
//                             width: 1.5.w,
//                           ),
//                         ),
//                         child: record['image'] != null
//                             ? ClipOval(
//                                 child: Image.file(
//                                   record['image'] as File,
//                                   fit: BoxFit.cover,
//                                   width: 46.w,
//                                   height: 46.h,
//                                 ),
//                               )
//                             : Center(
//                                 child: Text(
//                                   record['workerName'].toString().substring(0, 1) +
//                                       (record['workerName'].toString().contains(' ')
//                                           ? record['workerName']
//                                                 .toString()
//                                                 .split(' ')[1][0]
//                                           : ''),
//                                   style: TextStyle(
//                                     color: Color.fromARGB(255, 87, 87, 87),
//                                     fontWeight: FontWeight.w700,
//                                     fontSize: 18.sp,
//                                     letterSpacing: -0.5,
//                                   ),
//                                 ),
//                               ),
//                       ),
//                     ),
//                     if (record['status'] != 'Absent')
//                       Positioned(
//                         right: 0,
//                         bottom: 0,
//                         child: GestureDetector(
//                           onTap: () => _captureImage(record['id']),
//                           child: Container(
//                             padding: EdgeInsets.all(2.h),
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               shape: BoxShape.circle,
//                               border: Border.all(
//                                 color: _getStatusColor(record['status']),
//                                 width: 1.5.w,
//                               ),
//                             ),
//                             child: Icon(
//                               Icons.camera_alt,
//                               color: _getStatusColor(record['status']),
//                               size: 14.sp,
//                             ),
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//                 SizedBox(width: 16.w),
//                 // Info Section
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Expanded(
//                             child: Text(
//                               record['workerName'],
//                               style: TextStyle(
//                                 fontSize: 17.sp,
//                                 fontWeight: FontWeight.w700,
//                                 color: Color(0xFF1E293B),
//                                 letterSpacing: -0.4,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                           SizedBox(width: 5.w),
//                           _buildStatusIndicator(record['status']),
//                         ],
//                       ),
//                       SizedBox(height: 4.h),
//                       Text(
//                         'ID: ${record['workerId']}',
//                         style: TextStyle(
//                           fontSize: 14.sp,
//                           color: Color(0xFF64748B),
//                           fontWeight: FontWeight.w500,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       SizedBox(height: 6.h),
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.location_on_rounded,
//                             size: 14.sp,
//                             color: const Color(0xFF94A3B8),
//                           ),
//                           SizedBox(width: 4.w),
//                           Expanded(
//                             child: Text(
//                               record['site'],
//                               style: TextStyle(
//                                 fontSize: 13.sp,
//                                 color: Color(0xFF64748B),
//                                 fontWeight: FontWeight.w500,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(width: 16.w),
//                 // Right Section - Time & Actions
//                 Column(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     // Time Info
//                     if (record['timeIn'].isNotEmpty) ...[
//                       Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(
//                             Icons.access_time_rounded,
//                             size: 14.sp,
//                             color: const Color.fromARGB(255, 107, 118, 133),
//                           ),
//                           SizedBox(width: 4.w),
//                           Text(
//                             '${record['timeIn']} - ${record['timeOut']}',
//                             style: TextStyle(
//                               fontSize: 12.sp,
//                               color: Colors.grey[700],
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ] else ...[
//                       Container(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: 8.w,
//                           vertical: 4.h,
//                         ),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFF1F5F9),
//                           borderRadius: BorderRadius.circular(8.r),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(
//                               Icons.access_time_rounded,
//                               size: 14.sp,
//                               color: const Color(0xFF94A3B8),
//                             ),
//                             SizedBox(width: 4.w),
//                             Text(
//                               'Not checked in',
//                               style: TextStyle(
//                                 fontSize: 11.sp,
//                                 color: Color(0xFF64748B),
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                     SizedBox(height: 8.h),
//                     // Hours Info
//                     Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           '${record['hours']}h',
//                           style: TextStyle(
//                             fontSize: 13.sp,
//                             color: Colors.grey[700],
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         if (record['overtime'] > 0) ...[
//                           SizedBox(width: 4.w),
//                           Text(
//                             '+${record['overtime']}h',
//                             style: TextStyle(
//                               fontSize: 12.sp,
//                               color: const Color(0xFFe79315),
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ],
//                     ),
//                     SizedBox(height: 8.h),
//                     // Action Button - Only Edit
//                     _buildActionButton(
//                       icon: Icons.edit_outlined,
//                       onPressed: () => _editAttendance(record),
//                       color: const Color(0xFF4a63c0),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // Add this method to your _AttendanceScreenState class
//   void _showExportOptions() {
//     _showPdfFilterBottomSheet();
//   }

//   void _showPdfFilterBottomSheet() {
//     String selectedPresence = 'All';

//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setSheetState) => Container(
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black26,
//                 blurRadius: 20,
//                 offset: Offset(0, -5),
//               ),
//             ],
//           ),
//           child: Padding(
//             padding: EdgeInsets.only(
//               bottom: MediaQuery.of(context).viewInsets.bottom + 24,
//               left: 20,
//               right: 20,
//               top: 24,
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 // Header with drag handle
//                 Center(
//                   child: Container(
//                     width: 40,
//                     height: 4,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),

//                 // Title
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF4a63c0).withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: const Icon(
//                         Icons.filter_list,
//                         color: Color(0xFF4a63c0),
//                         size: 28,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     const Expanded(
//                       child: Text(
//                         'Filter PDF Report',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF2D3748),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 32),

//                 // Presence Filter
//                 const Text('Presence Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
//                 const SizedBox(height: 8),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12),
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey.shade300),
//                     borderRadius: BorderRadius.circular(12),
//                     color: Colors.grey.shade50,
//                   ),
//                   child: DropdownButton<String>(
//                     value: selectedPresence,
//                     hint: const Text('All Status'),
//                     isExpanded: true,
//                     underline: Container(),
//                     items: ['All', 'Present', 'Absent', 'Late']
//                         .map((status) => DropdownMenuItem<String>(
//                               value: status,
//                               child: Text(status),
//                             ))
//                         .toList(),
//                     onChanged: (value) {
//                       if (value != null) {
//                         setSheetState(() => selectedPresence = value);
//                       }
//                     },
//                   ),
//                 ),
//                 const SizedBox(height: 32),

//                 // Action buttons
//                 Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: () => Navigator.pop(context),
//                         style: OutlinedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           side: BorderSide(color: Colors.grey.shade400),
//                         ),
//                         child: const Text(
//                           'Cancel',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: () {
//                           Navigator.pop(context);
//                           _exportPDF(presenceFilter: selectedPresence);
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF4a63c0),
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: const Text(
//                           'Download PDF',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _exportPDF({
//     String? presenceFilter,
//   }) async {
//     try {
//       final workerProvider = Provider.of<WorkerProvider>(
//         context,
//         listen: false,
//       );
//       // Filter attendance data
//       final attendanceData = workerProvider.attendanceData.where((record) {
//         final matchesSite =
//             _selectedSiteId.isEmpty || record['siteId'] == _selectedSiteId;

//         // Use current selected date
//         final matchesDate = record['date'].year == _selectedDate.year &&
//             record['date'].month == _selectedDate.month &&
//             record['date'].day == _selectedDate.day;

//         // Presence filter
//         final matchesPresence = presenceFilter == null ||
//             presenceFilter == 'All' ||
//             record['status'] == presenceFilter;

//         return matchesSite && matchesDate && matchesPresence;
//       }).toList();
      
//       if (attendanceData.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No attendance data to export')),
//         );
//         return;
//       }
      
//       // Get site name
//       String siteName = 'All Sites';
//       if (_selectedSiteId.isNotEmpty) {
//         final site = widget.sites.firstWhere(
//           (site) => site.id == _selectedSiteId,
//           orElse: () => Site(id: '', name: 'Unknown Site', companyId: ''),
//         );
//         siteName = site.name;
//       }
      
//       // Show loading indicator
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => Center(child: CircularProgressIndicator()),
//       );
      
//       final path = await ReportService.generateAttendancePDF(
//         attendanceData,
//         siteName,
//         null,
//         null,
//       );
      
//       // Close loading indicator
//       Navigator.of(context).pop();
      
//       await ReportService.openFile(path);
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('PDF exported successfully!')),
//       );
//     } catch (e) {
//       // Close loading indicator if still open
//       Navigator.of(context).pop();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error exporting PDF: ${e.toString()}')),
//       );
//       print('PDF Export Error: $e');
//     }
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required VoidCallback onPressed,
//     required Color color,
//   }) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onPressed,
//         borderRadius: BorderRadius.circular(8.r),
//         child: Icon(icon, size: 20.sp, color: color),
//       ),
//     );
//   }

//   Widget _buildStatusIndicator(String status) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           width: 8.w,
//           height: 8.h,
//           decoration: BoxDecoration(
//             color: _getStatusColor(status),
//             shape: BoxShape.circle,
//           ),
//         ),
//         SizedBox(width: 5.w),
//         Text(
//           status,
//           style: TextStyle(
//             color: _getStatusColor(status),
//             fontSize: 13.sp,
//             fontWeight: FontWeight.w600,
//             letterSpacing: -0.2,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildFilterChip(String filter) {
//     final isSelected = _statusFilter == filter;
//     return Padding(
//       padding: EdgeInsets.only(right: 8.w),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         decoration: BoxDecoration(
//           color: isSelected ? const Color(0xFF4a63c0) : Colors.white,
//           borderRadius: BorderRadius.circular(18.r),
//           border: Border.all(
//             color: isSelected
//                 ? const Color(0xFF4a63c0)
//                 : Colors.grey.withOpacity(0.3),
//           ),
//         ),
//         child: Material(
//           color: Colors.transparent,
//           child: InkWell(
//             borderRadius: BorderRadius.circular(18.r),
//             onTap: () {
//               setState(() {
//                 _statusFilter = filter;
//               });
//             },
//             child: Container(
//               padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
//               child: Text(
//                 filter,
//                 style: TextStyle(
//                   color: isSelected ? Colors.white : const Color(0xFF64748B),
//                   fontWeight: FontWeight.w600,
//                   fontSize: 14.sp,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Color _getStatusColor(String status) {
//     switch (status) {
//       case 'Present':
//         return const Color(0xFF0aa137);
//       case 'Absent':
//         return const Color(0xFFe94b1b);
//       case 'Late':
//         return const Color(0xFFe79315);
//       default:
//         return const Color(0xFF64748B);
//     }
//   }
// }