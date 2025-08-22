import 'package:ecoteam_app/models/dashboard/site_model.dart';
import 'package:ecoteam_app/view/contractor_dashboard/worker_chat_screen.dart';
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
          color: Colors.white,
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
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getStatusGradient(worker['status']),
                    ),
                    shape: BoxShape.circle,
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
                            color: const Color.fromARGB(255, 107, 118, 133),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            worker['timeIn'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
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
                        const SizedBox(width: 20),
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
        return [const Color.fromARGB(255, 37, 218, 157), const Color.fromARGB(255, 40, 209, 155)];
      case 'Absent':
        return [const Color.fromARGB(255, 253, 106, 106), const Color.fromARGB(255, 247, 98, 98)];
      case 'Late':
        return [const Color.fromARGB(255, 243, 167, 37), const Color.fromARGB(255, 231, 139, 34)];
      default:
        return [const Color.fromARGB(255, 108, 166, 247), const Color.fromARGB(255, 90, 154, 243)];
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return const Color.fromARGB(255, 31, 211, 151);
      case 'Absent':
        return const Color.fromARGB(255, 245, 78, 78);
      case 'Late':
        return const Color.fromARGB(255, 245, 166, 30);
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
          scrollDirection: Axis.vertical,
          child: Container(
             
            child: WorkerEditForm(
              
              worker: worker,
              sites: widget.sites,
              onWorkerUpdated: (updatedWorker) {
                setState(() {
                  final index = workers.indexWhere((w) => w['id'] == updatedWorker['id']);
                  if (index != -1) {
                    workers[index] = updatedWorker;
                  }
                });
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.80,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: WorkerEditForm(
            worker: newWorker,
            sites: widget.sites,
            onWorkerUpdated: (updatedWorker) {
              setState(() {
                workers.add(updatedWorker);
              });
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }
}

class WorkerEditForm extends StatefulWidget {
  final Map<String, dynamic> worker;
  final List<Site> sites;
  final Function(Map<String, dynamic>) onWorkerUpdated;

  const WorkerEditForm({
    super.key,
    required this.worker,
    required this.sites,
    required this.onWorkerUpdated,
  });

  @override
  State<WorkerEditForm> createState() => _WorkerEditFormState();
}

class _WorkerEditFormState extends State<WorkerEditForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late String _selectedSiteId;
  late String _selectedStatus;

  final List<String> _roles = [
    'Welder',
    'Supervisor',
    'Carpenter',
    'Electrician',
    'Plumber',
    'Mason',
    'Laborer',
    'Operator',
    'Foreman',
    'Engineer',
  ];

  final List<String> _statuses = ['Present', 'Absent', 'Late', 'On Leave'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.worker['name']);
    _roleController = TextEditingController(text: widget.worker['role']);
    _phoneController = TextEditingController(text: widget.worker['phone']);
    _emailController = TextEditingController(text: widget.worker['email']);
    _selectedSiteId = widget.worker['siteId'];
    _selectedStatus = widget.worker['status'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveWorker() {
    if (_formKey.currentState!.validate()) {
      final updatedWorker = Map<String, dynamic>.from(widget.worker);
      updatedWorker['name'] = _nameController.text.trim();
      updatedWorker['role'] = _roleController.text.trim();
      updatedWorker['phone'] = _phoneController.text.trim();
      updatedWorker['email'] = _emailController.text.trim();
      updatedWorker['siteId'] = _selectedSiteId;
      updatedWorker['site'] = widget.sites
          .firstWhere((site) => site.id == _selectedSiteId)
          .name;
      updatedWorker['status'] = _selectedStatus;
      updatedWorker['avatar'] = _generateAvatar(_nameController.text.trim());

      widget.onWorkerUpdated(updatedWorker);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Worker ${updatedWorker['name']} updated successfully!',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  String _generateAvatar(String name) {
    if (name.isEmpty) return '';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.worker['id'] == '' ?'Add New Worker' : ' Edit Worker',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildProfileSection(),
            
            _buildPersonalInfoSection(),
            
            _buildWorkInfoSection(),
            const SizedBox(height: 10),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      color: const Color.fromARGB(239, 248, 247, 247),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getStatusColor(_selectedStatus),
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 36,
                backgroundColor: _getStatusColor(
                  _selectedStatus,
                ).withOpacity(0.2),
                child: Text(
                  _generateAvatar(_nameController.text),
                  style: TextStyle(
                    color: _getStatusColor(_selectedStatus),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nameController.text,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _roleController.text,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_selectedStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _selectedStatus,
                      style: TextStyle(
                        color: _getStatusColor(_selectedStatus),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      color: const Color.fromARGB(239, 248, 247, 247),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: Colors.blue.shade800),
                const SizedBox(width: 8),
                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                prefixIcon: Icon(Icons.person, color: Colors.grey.shade600),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter worker name';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                prefixIcon: Icon(Icons.phone, color: Colors.grey.shade600),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                prefixIcon: Icon(Icons.email, color: Colors.grey.shade600),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter email address';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkInfoSection() {
    return Card(
      color: const Color.fromARGB(239, 248, 247, 247),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.work_outline, color: Colors.blue.shade800),
                const SizedBox(width: 8),
                Text(
                  'Work Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _roleController.text,
              decoration: InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                prefixIcon: Icon(Icons.work, color: Colors.grey.shade600),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 8,
                ),
              ),
              dropdownColor: Colors.white,
              icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              borderRadius: BorderRadius.circular(12),
              items: _roles.map((role) {
                return DropdownMenuItem<String>(value: role, child: Text(role));
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _roleController.text = newValue;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a role';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSiteId,
              decoration: InputDecoration(
                labelText: 'Assigned Site',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                prefixIcon: Icon(
                  Icons.location_on,
                  color: Colors.grey.shade600,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 8,
                ),
              ),
              dropdownColor: Colors.white,
              icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              borderRadius: BorderRadius.circular(12),
              items: widget.sites.map((site) {
                return DropdownMenuItem<String>(
                  value: site.id,
                  child: Text(site.name),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedSiteId = newValue;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a site';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Current Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                prefixIcon: Icon(Icons.person_pin, color: Colors.grey.shade600),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 8,
                ),
              ),
              dropdownColor: Colors.white,
              icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              borderRadius: BorderRadius.circular(12),
              items: _statuses.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(status),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedStatus = newValue;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a status';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _saveWorker,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade800,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save, size: 22),
            SizedBox(width: 8),
            Text(
              'Save Changes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return Colors.green.shade600;
      case 'Absent':
        return Colors.red.shade600;
      case 'Late':
        return Colors.orange.shade600;
      case 'On Leave':
        return Colors.purple.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}