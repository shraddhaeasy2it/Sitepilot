import 'package:ecoteam_app/models/dashboard/dashboard_model.dart';
import 'package:ecoteam_app/models/dashboard/site_model.dart';
import 'package:ecoteam_app/services/api_ser.dart';
import 'package:ecoteam_app/view/contractor_dashboard/attendance_screen.dart';
import 'package:ecoteam_app/view/contractor_dashboard/more/material_screen.dart';
import 'package:ecoteam_app/view/contractor_dashboard/more/more_screen.dart';
import 'package:ecoteam_app/view/contractor_dashboard/task.dart';
import 'package:ecoteam_app/view/contractor_dashboard/worker_screen.dart';
import 'package:ecoteam_app/widgets/bottom_navbar.dart';
import 'package:ecoteam_app/widgets/summary_card.dart';
import 'package:flutter/material.dart';


class DashboardScreen extends StatefulWidget {
  final Site? selectedSite;
  final String? companyName;

  const DashboardScreen({
    super.key,
    this.selectedSite,
    this.companyName,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String? _selectedSiteId;
  List<Site> _sites = [];
  DashboardData? _dashboardData;
  bool _isLoading = true;

  // Screens for navigation with PageStorageKeys
  List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    // Use the selected site from navigation if provided
    if (widget.selectedSite != null) {
      _selectedSiteId = widget.selectedSite!.id;
    }
    // Initialize screens with loading placeholders
    _initializeScreens();
    _loadData();
  }

  void _initializeScreens() {
    _screens = [
      const Center(child: CircularProgressIndicator()), // Dashboard loading
      const Center(child: CircularProgressIndicator()), // Workers loading
      const Center(child: CircularProgressIndicator()), // Tasks loading
      const Center(child: CircularProgressIndicator()), // Attendance loading
      const Center(child: CircularProgressIndicator()), // More loading
    ];
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      print('Loading dashboard data...');
      _dashboardData = await ApiService().fetchDashboardData().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Loading timeout - please check your connection');
        },
      );
      print('Dashboard data loaded: \n  sites: \${_dashboardData?.sites.length}, selectedSiteId: \${_dashboardData?.selectedSiteId}');
      _sites = _dashboardData!.sites;
      if (widget.selectedSite != null) {
        _selectedSiteId = widget.selectedSite!.id;
      } else {
        _selectedSiteId = _dashboardData!.selectedSiteId;
      }
      _screens = [
        DashboardContent(
          key: ValueKey('dashboard-\${DateTime.now().millisecondsSinceEpoch}'),
          selectedSiteId: _selectedSiteId,
          onSiteChanged: _onSiteChanged,
          sites: _sites,
          onSitesUpdated: _onSitesUpdated,
          dashboardData: _dashboardData,
        ),
        WorkersScreen(
          key: const PageStorageKey('workers'),
          selectedSiteId: _selectedSiteId,
          onSiteChanged: _onSiteChanged,
          sites: _sites,
        ),
        TaskPage(
          key: const PageStorageKey('Task'),
          selectedSiteId: _selectedSiteId,
          onSiteChanged: _onSiteChanged,
          sites: _sites,
          contractors: const ['John Doe', 'Supplier Team', 'Safety Officer', 'Electrician Team'],
        ),
        AttendanceScreen(
          key: const PageStorageKey('attendance'),
          selectedSiteId: _selectedSiteId,
          onSiteChanged: _onSiteChanged,
          sites: _sites,
        ),
        MoreScreen(
          key: const PageStorageKey('more'),
          selectedSiteId: _selectedSiteId,
          onSiteChanged: _onSiteChanged,
          sites: _sites,
        ),
      ];
    } catch (e) {
      print('Error loading dashboard data: \${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data: \${e.toString()}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadData,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSiteChanged(String siteId) {
    setState(() {
      _selectedSiteId = siteId;
    });
  }

  void _onSitesUpdated(List<Site> updatedSites) {
    setState(() {
      _sites = updatedSites;
      // Update all screens with new sites
      _screens = [
        DashboardContent(
          key: const PageStorageKey('dashboard'),
          selectedSiteId: _selectedSiteId,
          onSiteChanged: _onSiteChanged,
          sites: _sites,
          onSitesUpdated: _onSitesUpdated,
          dashboardData: _dashboardData,
        ),
        WorkersScreen(
          key: const PageStorageKey('workers'),
          selectedSiteId: _selectedSiteId,
          onSiteChanged: _onSiteChanged,
          sites: _sites,
        ),
        TaskPage(
          key: const PageStorageKey('Task'),
          selectedSiteId: _selectedSiteId,
          onSiteChanged: _onSiteChanged,
          sites: _sites,
          contractors: const ['John Doe', 'Supplier Team', 'Safety Officer', 'Electrician Team'],
        ),
        MaterialsScreen(
          key: const PageStorageKey('materials'),
          selectedSiteId: _selectedSiteId,
          onSiteChanged: _onSiteChanged,
          sites: _sites,
        ),
        AttendanceScreen(
          key: const PageStorageKey('attendance'),
          selectedSiteId: _selectedSiteId,
          onSiteChanged: _onSiteChanged,
          sites: _sites,
        ),
        MoreScreen(
          key: const PageStorageKey('more'),
          selectedSiteId: _selectedSiteId,
          onSiteChanged: _onSiteChanged,
          sites: _sites,
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading Dashboard...'),
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your dashboard data...'),
            ],
          ),
        ),
      );
    }
    // Fallback: If data is still missing after loading, show error
    if (_dashboardData == null || _screens.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text('Failed to load dashboard data.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _currentIndex == 0 
          ? AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Construction Dashboard'),
                  if (widget.companyName != null)
                    Text(
                      widget.companyName!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                ],
              ),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_business_rounded),
                  onPressed: _showSitesModal,
                  tooltip: 'Manage Sites',
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: _showNotifications,
                ),
              ],
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _handleNavigation,
      ),
    );
  }

  void _handleNavigation(int index) {
    if (index == _currentIndex) {
      // Scroll to top if current tab is tapped
      _scrollToTop();
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _scrollToTop() {
    if (_currentIndex == 0) {
      // Implement scroll to top for dashboard if needed
    }
  }

  void _showNotifications() {
    // Notification logic here
  }

  void _showSitesModal() {
    showDialog(
      context: context,
      builder: (context) => SitesManagementModal(
        sites: _sites,
        onSitesUpdated: _onSitesUpdated,
      ),
    );
  }
}

class SitesManagementModal extends StatefulWidget {
  final List<Site> sites;
  final Function(List<Site>) onSitesUpdated;

  const SitesManagementModal({
    super.key,
    required this.sites,
    required this.onSitesUpdated,
  });

  @override
  State<SitesManagementModal> createState() => _SitesManagementModalState();
}

class _SitesManagementModalState extends State<SitesManagementModal> {
  final TextEditingController _siteNameController = TextEditingController();
  final TextEditingController _siteAddressController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _siteNameController.dispose();
    _siteAddressController.dispose();
    super.dispose();
  }

  void _addNewSite() async {
    if (_formKey.currentState!.validate()) {
      // Generate unique site ID
      final existingIds = widget.sites.map((site) => int.tryParse(site.id.replaceAll('site', '')) ?? 0).toList();
      final nextId = existingIds.isEmpty ? 1 : existingIds.reduce((a, b) => a > b ? a : b) + 1;
      
      final newSite = Site(
        id: 'site$nextId',
        name: _siteNameController.text.trim(),
        address: _siteAddressController.text.trim(),
      );

      // Add to API service
      final success = await ApiService().addSite(newSite);
      
      if (success) {
        // Get updated sites from API service to avoid duplication
        final updatedSites = ApiService.sites;
        widget.onSitesUpdated(updatedSites);

        // Clear form
        _siteNameController.clear();
        _siteAddressController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Site "${newSite.name}" added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Site "${newSite.name}" already exists!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _deleteSite(Site site) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Site'),
        content: Text('Are you sure you want to delete "${site.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Delete from API service
              final success = await ApiService().deleteSite(site.id);
              
              if (success) {
                // Get updated sites from API service to avoid duplication
                final updatedSites = ApiService.sites;
                widget.onSitesUpdated(updatedSites);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Site "${site.name}" deleted successfully!'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete site "${site.name}"!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Manage Construction Sites',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Add new site form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add New Site',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _siteNameController,
                        decoration: const InputDecoration(
                          labelText: 'Site Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter site name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _siteAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Site Address',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.home),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter site address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addNewSite,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Site'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Existing sites list
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Existing Sites',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.sites.length,
                      itemBuilder: (context, index) {
                        final site = widget.sites[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.location_on, color: Colors.white),
                            ),
                            title: Text(site.name),
                            subtitle: Text(site.address),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteSite(site),
                            ),
                          ),
                        );
                      },
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
}

class DashboardContent extends StatelessWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  final Function(List<Site>)? onSitesUpdated;
  final DashboardData? dashboardData;

  const DashboardContent({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
    this.onSitesUpdated,
    required this.dashboardData,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSiteSelector(),
        Expanded(
          child: dashboardData == null
              ? const Center(child: CircularProgressIndicator())
              : _buildDashboardContent(context),
        ),
      ],
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
        value: selectedSiteId?.isNotEmpty == true ? selectedSiteId : null,
        decoration: const InputDecoration(
          labelText: 'Select Construction Site',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.location_on, color: Colors.blue),
        ),
        items: sites.map((site) {
          return DropdownMenuItem<String>(
            value: site.id,
            child: Text(site.name),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            onSiteChanged(newValue);
          }
        },
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    if (dashboardData == null) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      onRefresh: () async {}, // Parent handles refresh
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildSummaryGrid(dashboardData!),
            const SizedBox(height: 24),
            _buildRecentActivities(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(DashboardData data) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        SummaryCard(
          icon: Icons.inventory,
          title: 'Inventory Count',
          value: data.totalPicking,
          cardColor: const Color.fromARGB(255, 198, 228, 250),
        ),
        SummaryCard(
          icon: Icons.people,
          title: 'Total Workers',
          value: data.totalWorkers,
          cardColor: const Color.fromARGB(255, 199, 252, 203),
        ),
        SummaryCard(
          icon: Icons.checklist,
          title: 'Total Inspections',
          value: data.totalInspection,
          cardColor: const Color.fromARGB(255, 250, 228, 192),
        ),
        SummaryCard(
          icon: Icons.shopping_cart,
          title: 'Total Pickings',
          value: data.totalPicking,
          cardColor: const Color.fromARGB(255, 243, 209, 248),
        ),
      ],
    );
  }

  Widget _buildRecentActivities() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Site: ${sites.firstWhere((site) => site.id == selectedSiteId, orElse: () => Site(id: '', name: 'Unknown', address: '')).name}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                return const ListTile(
                  leading: Icon(Icons.update, color: Colors.blue),
                  title: Text('Project update'),
                  subtitle: Text('Foundation completed'),
                  trailing: Text('2h ago'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty, size: 48),
          SizedBox(height: 16),
          Text('No data available'),
        ],
      ),
    );
  }
}