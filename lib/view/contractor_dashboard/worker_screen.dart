import 'package:ecoteam_app/models/birthday_model.dart';
import 'package:ecoteam_app/models/site_model.dart';
import 'package:ecoteam_app/provider/worker_provider.dart';
import 'package:ecoteam_app/view/contractor_dashboard/worker_chat_screen.dart';
import 'package:ecoteam_app/view/contractor_dashboard/worker_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class WorkersScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;

  const WorkersScreen({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
  });

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  late String _selectedSiteId;
  AnimationController? _animationController;
  String? _searchQueryForSites;

  @override
  void initState() {
    super.initState();
    _selectedSiteId = widget.selectedSiteId ?? '';
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController?.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WorkersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSiteId != oldWidget.selectedSiteId) {
      _selectedSiteId = widget.selectedSiteId ?? '';
    }
  }

  // Calculate summary data
  int get totalWorkers => filteredWorkers.length;
  int get presentToday =>
      filteredWorkers.where((w) => w['status'] == 'Present').length;
  int get absentToday =>
      filteredWorkers.where((w) => w['status'] == 'Absent').length;
  int get lateToday => filteredWorkers.where((w) => w['late'] == true).length;

  // Filter workers based on search and filters
  List<Map<String, dynamic>> get filteredWorkers {
    final workerProvider = Provider.of<WorkerProvider>(context);
    return workerProvider.workers.where((worker) {
      final matchesSearch =
          worker['name'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              worker['role'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
      final matchesFilter =
          _selectedFilter == 'All' || worker['status'] == _selectedFilter;
      final matchesSite =
          _selectedSiteId.isEmpty || worker['siteId'] == _selectedSiteId;
      return matchesSearch && matchesFilter && matchesSite;
    }).toList();
  }

  void _showSiteSelectorBottomSheet() {
    setState(() {
      _searchQueryForSites = ''; // Reset search query when opening
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
                  // Handle bar
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Title
                  Text(
                    'Select Site',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Search bar
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
                  // List of sites
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: widget.sites.length,
                      itemBuilder: (context, index) {
                        final site = widget.sites[index];
                        // Filter sites based on search query
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
                                fontWeight: FontWeight.w600, fontSize: 16.sp),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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
                'Manage worker details',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                  fontSize: 16.sp,
                ),
              ),
          ],
        ),
        flexibleSpace: ClipRRect(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(25.r),
          ),
          child: Container(
            decoration: const BoxDecoration(
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSummaryCards(),
            _buildSearchAndFilters(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _buildWorkerList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Total',
              value: totalWorkers.toString(),
              icon: Icons.people_outline_rounded,
              color: const Color(0xFF4a63c0),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildSummaryCard(
              title: 'Present',
              value: presentToday.toString(),
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF0aa137),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildSummaryCard(
              title: 'Absent',
              value: absentToday.toString(),
              icon: Icons.cancel_outlined,
              color: const Color(0xFFe94b1b),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildSummaryCard(
              title: 'Late',
              value: lateToday.toString(),
              icon: Icons.schedule_rounded,
              color: const Color(0xFFe79315),
            ),
          ),
        ],
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
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: Colors.white,
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 17.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              color: Colors.white,
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search workers by name or role...',
                hintStyle: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 16.sp,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Color(0xFF667EEA),
                  size: 20.sp,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20.sp,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 16.h,
                  horizontal: 20.w,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          SizedBox(height: 16.h),
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
    );
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedFilter == filter;
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
                _selectedFilter = filter;
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

  Widget _buildWorkerList() {
    return Consumer<WorkerProvider>(
      builder: (context, workerProvider, child) {
        final workers = workerProvider.workers.where((worker) {
          final matchesSearch =
              worker['name'].toString().toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  worker['role'].toString().toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );
          final matchesFilter =
              _selectedFilter == 'All' || worker['status'] == _selectedFilter;
          final matchesSite =
              _selectedSiteId.isEmpty || worker['siteId'] == _selectedSiteId;
          return matchesSearch && matchesFilter && matchesSite;
        }).toList();

        if (workers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 60.sp, color: Colors.grey[400]),
                SizedBox(height: 16.h),
                Text(
                  'No workers found',
                  style: TextStyle(fontSize: 18.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Try changing your search or filter',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: workers.length,
          itemBuilder: (context, index) {
            final worker = workers[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeOutCubic,
                child: _buildWorkerCard(worker),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker) {
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
          onTap: () => _editWorker(worker),
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.h),
            child: Row(
              children: [
                // Avatar Section
                Container(
                  width: 50.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4a63c0),
                      width: 2.w, // border thickness
                    ),
                  ),
                  child: Center(
                    child: Text(
                      worker['avatar'],
                      style: TextStyle(
                        color: Color.fromARGB(255, 87, 87, 87),
                        fontWeight: FontWeight.w700,
                        fontSize: 18.sp,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
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
                              worker['name'],
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        worker['role'],
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
                              worker['site'],
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
                // Right Section - Actions
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Action Buttons
                    _buildActionButton(
                      icon: Icons.edit_outlined,
                      onPressed: () => _editWorker(worker),
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
        borderRadius: BorderRadius.circular(8.r),
        child: Icon(icon, size: 20.sp, color: color),
      ),
    );
  }



  Widget _buildFloatingActionButton() {
    return Container(
      width: 56.w,
      height: 56.h,
      decoration: BoxDecoration(
        color: const Color(0xFF4a63c0),
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _addNewWorker,
          borderRadius: BorderRadius.circular(28.r),
          child: Icon(Icons.add_rounded, color: Colors.white, size: 24.sp),
        ),
      ),
    );
  }

  void _startChat(Map<String, dynamic> worker) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WorkerChatScreen(worker: worker)),
    );
  }

  void _editWorker(Map<String, dynamic> worker) {
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
          scrollDirection: Axis.vertical,
          child: Container(
            child: WorkerEditForm(
              worker: worker,
              sites: widget.sites,
              onWorkerUpdated: (updatedWorker) {
                // Update worker through provider
                Provider.of<WorkerProvider>(context, listen: false)
                    .updateWorker(updatedWorker);
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _addNewWorker() {
    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    final existingIds = workerProvider.workers.map((w) => int.tryParse(w['id']) ?? 0).toList();
    final nextId = existingIds.isEmpty
        ? 1
        : existingIds.reduce((a, b) => a > b ? a : b) + 1;
    final newWorker = {
      'id': nextId.toString(),
      'name': '', // Empty instead of 'New Worker'
      'role': '', // Empty instead of 'Laborer'
      'siteId': _selectedSiteId.isNotEmpty
          ? _selectedSiteId
          : widget.sites.isNotEmpty
          ? widget.sites.first.id
          : '',
      'site': _selectedSiteId.isNotEmpty
          ? widget.sites
              .firstWhere(
                (s) => s.id == _selectedSiteId,
                orElse: () => widget.sites.first,
              )
              .name
          : widget.sites.isNotEmpty
          ? widget.sites.first.name
          : 'Unassigned',
      'status': 'Present',
      'avatar': '', // Empty instead of 'NW'
      'timeIn': '08:00 AM',
      'late': false,
      'phone': '', // Empty instead of '+1 555-000-0000'
      'email': '', // Empty instead of 'new.worker@example.com'
      'birthdate': null,
    };
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: WorkerEditForm(
            worker: newWorker,
            sites: widget.sites,
            onWorkerUpdated: (updatedWorker) {
              // Add worker through provider
              Provider.of<WorkerProvider>(context, listen: false)
                  .addWorker(updatedWorker);
              
              // Force a rebuild to show the new worker immediately
              setState(() {});
              
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

}