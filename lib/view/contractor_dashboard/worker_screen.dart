import 'package:ecoteam_app/models/dashboard/site_model.dart';
import 'package:ecoteam_app/view/contractor_dashboard/worker_chat_screen.dart';
import 'package:ecoteam_app/view/contractor_dashboard/worker_edit_screen.dart';
import 'package:flutter/material.dart';

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

class _WorkersScreenState extends State<WorkersScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  late String _selectedSiteId;
  AnimationController? _animationController;

  // Worker data
  List<Map<String, dynamic>> workers = [
    {
      'id': '1',
      'name': 'John Smith',
      'role': 'Welder',
      'siteId': 'site1',
      'site': 'Site A',
      'status': 'Present',
      'avatar': 'JS',
      'timeIn': '08:00 AM',
      'late': false,
      'phone': '+1 555-123-4567',
      'email': 'john.smith@example.com',
    },
    {
      'id': '2',
      'name': 'Maria Garcia',
      'role': 'Supervisor',
      'siteId': 'site2',
      'site': 'Site B',
      'status': 'Present',
      'avatar': 'MG',
      'timeIn': '07:45 AM',
      'late': false,
      'phone': '+1 555-234-5678',
      'email': 'maria.garcia@example.com',
    },
    {
      'id': '3',
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
      'id': '4',
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
  int get presentToday => filteredWorkers.where((w) => w['status'] == 'Present').length;
  int get absentToday => filteredWorkers.where((w) => w['status'] == 'Absent').length;
  int get lateToday => filteredWorkers.where((w) => w['late'] == true).length;

  // Filter workers based on search and filters
  List<Map<String, dynamic>> get filteredWorkers {
    return workers.where((worker) {
      final matchesSearch = worker['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          worker['role'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesFilter = _selectedFilter == 'All' || worker['status'] == _selectedFilter;
      
      final matchesSite = _selectedSiteId.isEmpty || worker['siteId'] == _selectedSiteId;
      
      return matchesSearch && matchesFilter && matchesSite;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white, // Back arrow white
        ),
  toolbarHeight: 90,
  elevation: 0,
  backgroundColor: Colors.transparent,
  title: const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Worker',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 30,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'Manage worker details',
        style: TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
      ),
    ],
  ),
  flexibleSpace: ClipRRect(
    borderRadius: const BorderRadius.vertical(
      bottom: Radius.circular(25),
    ),
    child: Container(
      decoration: const BoxDecoration(
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
),

      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSiteSelector(),
            _buildSummaryCards(),
            _buildSearchAndFilters(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildWorkerList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSiteSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: DropdownButtonFormField<String>(
          value: _selectedSiteId.isNotEmpty ? _selectedSiteId : null,
          decoration: const InputDecoration(
            labelText: 'Filter by Site',
            labelStyle: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
            prefixIcon: Icon(
              Icons.location_on,
              color: Color(0xFF667EEA),
              size: 20,
            ),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: '',
              child: Text('All Sites'),
            ),
            ...widget.sites.map((site) {
              return DropdownMenuItem<String>(
                value: site.id,
                child: Text(site.name),
              );
            }).toList(),
          ],
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedSiteId = newValue;
              });
              widget.onSiteChanged(newValue);
            }
          },
          dropdownColor: Colors.white,
          
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Total',
              value: totalWorkers.toString(),
              icon: Icons.people_outline_rounded,
              color: const Color.fromARGB(255, 43, 84, 196),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'Present',
              value: presentToday.toString(),
              icon: Icons.check_circle_outline_rounded,
              color: const Color.fromARGB(255, 10, 161, 55),
              
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'Absent',
              value: absentToday.toString(),
              icon: Icons.cancel_outlined,
              color: const Color.fromARGB(255, 233, 75, 27),
              
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'Late',
              value: lateToday.toString(),
              icon: Icons.schedule_rounded,
              color: const Color.fromARGB(255, 231, 147, 21),
              
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          const SizedBox(height: 12),
          
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search workers by name or role...',
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 16,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF667EEA),
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
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
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                const SizedBox(width: 4),
                _buildFilterChip('All'),
                _buildFilterChip('Present'),
                _buildFilterChip('Absent'),
                _buildFilterChip('Late'),
                const SizedBox(width: 4),
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
      padding: const EdgeInsets.only(right: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF4a63c0),],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF667EEA).withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkerList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredWorkers.length,
      itemBuilder: (context, index) {
        final worker = filteredWorkers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOutCubic,
            child: _buildWorkerCard(worker),
          ),
        );
      },
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editWorker(worker),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar Section
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getStatusGradient(worker['status']),
                    ),
                    shape: BoxShape.circle,
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: _getStatusColor(worker['status']).withOpacity(0.4),
                    //     blurRadius: 12,
                    //     spreadRadius: 0,
                    //     offset: const Offset(0, 4),
                    //   ),
                    // ],
                  ),
                  child: Center(
                    child: Text(
                      worker['avatar'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
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
                              worker['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusIndicator(worker['status']),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      Text(
                        worker['role'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              worker['site'],
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
                    if (worker['timeIn'].isNotEmpty) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: worker['late'] 
                                ? const Color(0xFFF59E0B) 
                                : const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            worker['timeIn'],
                            style: TextStyle(
                              fontSize: 12,
                              color: worker['late'] 
                                  ? const Color(0xFFF59E0B) 
                                  : const Color(0xFF10B981),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    
                    // Action Buttons
                    Row(
                      children: [
                        _buildActionButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          onPressed: () => _startChat(worker),
                          color: const Color.fromARGB(255, 54, 54, 54),
                        ),
                        const SizedBox(width: 17),
                        _buildActionButton(
                          icon: Icons.edit_outlined,
                          onPressed: () => _editWorker(worker),
                          color: const Color.fromARGB(255, 56, 56, 56),
                        ),
                      ],
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
        borderRadius: BorderRadius.circular(10),
        child: Icon(
          icon,
          size: 22,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _getStatusColor(status),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getStatusColor(status).withOpacity(0.5),
                blurRadius: 3,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          status,
          style: TextStyle(
            color: _getStatusColor(status),
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  List<Color> _getStatusGradient(String status) {
    switch (status) {
      case 'Present':
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case 'Absent':
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      case 'Late':
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      default:
        return [const Color(0xFF64748B), const Color(0xFF475569)];
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return const Color(0xFF10B981);
      case 'Absent':
        return const Color(0xFFEF4444);
      case 'Late':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  Widget _buildFloatingActionButton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF4a63c0),],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _addNewWorker,
          borderRadius: BorderRadius.circular(28),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _startChat(Map<String, dynamic> worker) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkerChatScreen(worker: worker),
      ),
    );
  }

  void _editWorker(Map<String, dynamic> worker) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkerEditScreen(
          worker: worker,
          sites: widget.sites,
          onWorkerUpdated: _updateWorker,
        ),
      ),
    );
  }

  void _updateWorker(Map<String, dynamic> updatedWorker) {
    setState(() {
      final index = workers.indexWhere((w) => w['id'] == updatedWorker['id']);
      if (index != -1) {
        workers[index] = updatedWorker;
      }
    });
  }

  void _addNewWorker() {
    final existingIds = workers.map((w) => int.tryParse(w['id']) ?? 0).toList();
    final nextId = existingIds.isEmpty ? 1 : existingIds.reduce((a, b) => a > b ? a : b) + 1;
    
    final newWorker = {
      'id': nextId.toString(),
      'name': 'New Worker',
      'role': 'Laborer',
      'siteId': _selectedSiteId.isNotEmpty ? _selectedSiteId : widget.sites.isNotEmpty ? widget.sites.first.id : '',
      'site': _selectedSiteId.isNotEmpty 
          ? widget.sites.firstWhere((s) => s.id == _selectedSiteId, orElse: () => widget.sites.first).name
          : widget.sites.isNotEmpty ? widget.sites.first.name : 'Unassigned',
      'status': 'Present',
      'avatar': 'NW',
      'timeIn': '08:00 AM',
      'late': false,
      'phone': '+1 555-000-0000',
      'email': 'new.worker@example.com',
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkerEditScreen(
          worker: newWorker,
          sites: widget.sites,
          onWorkerUpdated: (updatedWorker) {
            setState(() {
              workers.add(updatedWorker);
            });
          },
        ),
      ),
    );
  }

  void _deleteWorker(Map<String, dynamic> worker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Worker'),
        content: Text('Are you sure you want to delete ${worker['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                workers.removeWhere((w) => w['id'] == worker['id']);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}