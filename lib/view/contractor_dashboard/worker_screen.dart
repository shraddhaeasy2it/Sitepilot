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

class _WorkersScreenState extends State<WorkersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  late String _selectedSiteId;

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
      body: Column(
        children: [
          _buildSiteSelector(),
          Expanded(
            child: _buildWorkerContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        //onPressed: _addNewWorker,
        onPressed: () {
          
        },
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Add New Worker',
      ),
    );
  }

  Widget _buildSiteSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedSiteId.isNotEmpty ? _selectedSiteId : null,
        decoration: const InputDecoration(
          labelText: 'Select Site for Workers',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.people, color: Colors.blue),
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
      ),
    );
  }

  Widget _buildWorkerContent() {
    return Column(
      children: [
        _buildSummaryCards(),
        _buildSearchAndFilters(),
        Expanded(
          child: _buildWorkerList(),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Total',
              value: totalWorkers.toString(),
              color: Colors.blue,
              icon: Icons.people,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              title: 'Present',
              value: presentToday.toString(),
              color: Colors.green,
              icon: Icons.check_circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              title: 'Absent',
              value: absentToday.toString(),
              color: Colors.red,
              icon: Icons.cancel,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              title: 'Late',
              value: lateToday.toString(),
              color: Colors.orange,
              icon: Icons.schedule,
            ),
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
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search workers...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('Present'),
                _buildFilterChip('Absent'),
                _buildFilterChip('Late'),
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
      child: FilterChip(
        label: Text(filter),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = filter;
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.blue[100],
        checkmarkColor: Colors.blue,
      ),
    );
  }

  Widget _buildWorkerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredWorkers.length,
      itemBuilder: (context, index) {
        final worker = filteredWorkers[index];
        return _buildWorkerCard(worker);
      },
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: _getStatusColor(worker['status']),
                  child: Text(
                    worker['avatar'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        worker['role'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            worker['site'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(worker['status']),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (worker['timeIn'].isNotEmpty) ...[
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: worker['late'] ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Time In: ${worker['timeIn']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: worker['late'] ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const Spacer(),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat, color: Colors.blue),
                      onPressed: () => _startChat(worker),
                      tooltip: 'Chat with ${worker['name']}',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => _editWorker(worker),
                      tooltip: 'Edit ${worker['name']}',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteWorker(worker),
                      tooltip: 'Delete ${worker['name']}',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  worker['phone'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.email,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    worker['email'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
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

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status) {
      case 'Present':
        chipColor = Colors.green;
        break;
      case 'Absent':
        chipColor = Colors.red;
        break;
      case 'Late':
        chipColor = Colors.orange;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }



  void _startChat(Map<String, dynamic> worker) {
    // Navigate to worker chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkerChatScreen(worker: worker),
      ),
    );
  }

  void _editWorker(Map<String, dynamic> worker) {
    // Navigate to worker edit screen
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
    // Generate unique worker ID
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                workers.removeWhere((w) => w['id'] == worker['id']);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}