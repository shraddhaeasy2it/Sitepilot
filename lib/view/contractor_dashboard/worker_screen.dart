
import 'package:ecoteam_app/models/dashboard/site_model.dart';
import 'package:ecoteam_app/provider/worker_provider.dart';
import 'package:ecoteam_app/view/contractor_dashboard/worker_chat_screen.dart';
import 'package:ecoteam_app/view/contractor_dashboard/worker_edit_screen.dart';
import 'package:flutter/material.dart';
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
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    'Select Site',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search bar
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 22,
                    ),
                  ),
                  if (widget.sites.isNotEmpty) const SizedBox(width: 8),
                  if (widget.sites.isNotEmpty)
                    const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'Present',
              value: presentToday.toString(),
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF0aa137),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'Absent',
              value: absentToday.toString(),
              icon: Icons.cancel_outlined,
              color: const Color(0xFFe94b1b),
            ),
          ),
          const SizedBox(width: 12),
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

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
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
          color: isSelected ? const Color(0xFF4a63c0) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4a63c0)
                : Colors.grey.withOpacity(0.3),
          ),
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
                Icon(Icons.person_off, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No workers found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try changing your search or filter',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
              padding: const EdgeInsets.only(bottom: 12),
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
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editWorker(worker),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar Section
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getStatusGradient(
                        worker['status'],
                      ).first, // use first color
                      width: 2, // border thickness
                    ),
                  ),
                  child: Center(
                    child: Text(
                      worker['avatar'],
                      style: const TextStyle(
                        color: Color.fromARGB(255, 87, 87, 87),
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
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
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          _buildStatusIndicator(worker['status']),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        worker['role'],
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
                    // Action Buttons
                    Row(
                      children: [
                        _buildActionButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          onPressed: () => _startChat(worker),
                          color: const Color(0xFF4a63c0),
                        ),
                        const SizedBox(width: 16),
                        _buildActionButton(
                          icon: Icons.edit_outlined,
                          onPressed: () => _editWorker(worker),
                          color: const Color(0xFF4a63c0),
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
        const SizedBox(width: 6),
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

  List<Color> _getStatusGradient(String status) {
    switch (status) {
      case 'Present':
        return [
          const Color.fromARGB(255, 67, 209, 79),
          const Color.fromARGB(255, 31, 189, 26),
        ];
      case 'Absent':
        return [
          const Color.fromARGB(255, 223, 85, 43),
          const Color.fromARGB(255, 233, 77, 30),
        ];
      case 'Late':
        return [
          const Color.fromARGB(255, 221, 150, 43),
          const Color.fromARGB(255, 204, 130, 20),
        ];
      default:
        return [
          const Color.fromARGB(255, 57, 129, 230),
          const Color.fromARGB(255, 34, 104, 201),
        ];
    }
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

  Widget _buildFloatingActionButton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF4a63c0),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _addNewWorker,
          borderRadius: BorderRadius.circular(28),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
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