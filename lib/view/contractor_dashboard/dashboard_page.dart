import 'package:ecoteam_app/models/dashboard/dashboard_model.dart';
import 'package:ecoteam_app/models/dashboard/site_model.dart';
import 'package:ecoteam_app/services/api_ser.dart';
import 'package:ecoteam_app/services/company_site_provider.dart';
import 'package:ecoteam_app/view/contractor_dashboard/attendance_screen.dart';
import 'package:ecoteam_app/view/contractor_dashboard/more/material_screen.dart';
import 'package:ecoteam_app/view/contractor_dashboard/more/more_screen.dart';
import 'package:ecoteam_app/view/contractor_dashboard/task.dart';
import 'package:ecoteam_app/view/contractor_dashboard/worker_screen.dart';
import 'package:ecoteam_app/widgets/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      
      // Get the company provider
      final companyProvider = Provider.of<CompanySiteProvider>(context, listen: false);
      
      // Get dashboard data for the selected company
      _dashboardData = await ApiService().fetchDashboardData(
        companyId: companyProvider.selectedCompanyId
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Loading timeout - please check your connection');
        },
      );
      
      print('Dashboard data loaded: \n  sites: ${_dashboardData?.sites.length}, selectedSiteId: ${_dashboardData?.selectedSiteId}');
      
      // Use sites from the provider instead of dashboard data
      _sites = companyProvider.sites;
      
      if (widget.selectedSite != null) {
        _selectedSiteId = widget.selectedSite!.id;
      } else if (_sites.isNotEmpty) {
        _selectedSiteId = _sites.first.id;
      } else {
        _selectedSiteId = null;
      }
      _screens = [
        DashboardContent(
          key: ValueKey('dashboard-${DateTime.now().millisecondsSinceEpoch}'),
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
      print('Error loading dashboard data: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data: ${e.toString()}'),
            backgroundColor: const Color(0xFF1A1A2E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'Retry',
              textColor: const Color(0xFF6366F1),
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
    backgroundColor: const Color(0xFFf4f4f4),
    body: Container(
      // Added constraints to ensure full screen coverage
      // width: double.infinity,
      // height: double.infinity,
      // decoration: const BoxDecoration(
      //   gradient: LinearGradient(
      //     begin: Alignment.topLeft,
      //     end: Alignment.bottomRight,
      //     colors: [Color.fromARGB(255, 246, 247, 248), Color.fromARGB(255, 209, 195, 223)],
      //   ),
      // ),
      child: Center(
        child: SingleChildScrollView( // Prevents overflow issues
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
              
            ],
          ),
        ),
      ),
    ),
  );
}

    // Fallback: If data is still missing after loading, show error
    if (_dashboardData == null || _screens.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFf4f4f4),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Failed to load dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please check your connection and try again',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFf4f4f4),
      appBar: _currentIndex == 0 
          ? AppBar(
            toolbarHeight: 90,
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
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
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Construction',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (widget.companyName != null)
                  SizedBox(height: 10,),
                    Text(
                      widget.companyName!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(214, 255, 255, 255),
                      ),
                    ),
                ],
              ),
              centerTitle: false,
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: _showNotifications,
                  ),
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

  // Removed site management modal as it's now handled by the company site provider
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
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Site "${newSite.name}" already exists!'),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _deleteSite(Site site) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Site',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${site.name}"?\n\nThis action cannot be undone.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete site "${site.name}"!'),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: const Color(0xFFf4f4f4),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8FAFC)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Sites',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Add and manage construction sites',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Add new site form
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add New Site',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _siteNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Site Name',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.location_on, color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.redAccent),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter site name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _siteAddressController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Site Address',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.home, color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.redAccent),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter site address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addNewSite,
                        icon: const Icon(Icons.add, color: Color(0xFF667EEA)),
                        label: const Text(
                          'Add Site',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF667EEA),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Existing sites list
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Existing Sites (${widget.sites.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.sites.length,
                      itemBuilder: (context, index) {
                        final site = widget.sites[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white,
                                Colors.grey[50]!,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                            ),
                            title: Text(
                              site.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            subtitle: Text(
                              site.address,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 14,
                              ),
                            ),
                            trailing: Container(
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.red[600]),
                                onPressed: () => _deleteSite(site),
                              ),
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
    return Container(
      // decoration: const BoxDecoration(
      //   gradient: LinearGradient(
      //     begin: Alignment.topCenter,
      //     end: Alignment.bottomCenter,
      //     colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
      //   ),
      // ),
      color: const Color(0xFFf4f4f4),
      child: Column(
        children: [
          _buildSiteSelector(),
          Expanded(
            child: dashboardData == null
                ? const Center(child: CircularProgressIndicator())
                : _buildDashboardContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSiteSelector() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: DropdownButtonFormField<String>(
          value: selectedSiteId?.isNotEmpty == true ? selectedSiteId : null,
          decoration: const InputDecoration(
            labelText: 'Select Construction Site',
            labelStyle: TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
            prefixIcon: Icon(
              Icons.location_on,
              color: Color(0xFF667EEA),
            ),
          ),
          dropdownColor: Colors.white,
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 16,
            fontWeight: FontWeight.w500,
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
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    if (dashboardData == null) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      onRefresh: () async {}, // Parent handles refresh
      color: const Color(0xFF667EEA),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildSummaryGrid(dashboardData!),
            const SizedBox(height: 32),
            _buildRecentActivities(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(DashboardData data) {
    final summaryItems = [
      {
        'icon': Icons.inventory_2_outlined,
        'title': 'Inventory Count',
        'value': data.totalPicking.toString(),
        'colors': [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
        'bgColors': [const Color(0xFFDBEAFE), const Color(0xFFBFDBFE)],
      },
      {
        'icon': Icons.groups_outlined,
        'title': 'Total Workers',
        'value': data.totalWorkers.toString(),
        'colors': [const Color(0xFF10B981), const Color(0xFF059669)],
        'bgColors': [const Color(0xFFD1FAE5), const Color(0xFFA7F3D0)],
      },
      {
        'icon': Icons.fact_check_outlined,
        'title': 'Total Inspections',
        'value': data.totalInspection.toString(),
        'colors': [const Color.fromARGB(255, 245, 165, 26), const Color.fromARGB(255, 226, 137, 36)],
        'bgColors': [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
      },
      {
        'icon': Icons.shopping_cart_outlined,
        'title': 'Total Pickings',
        'value': data.totalPicking.toString(),
        'colors': [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
        'bgColors': [const Color(0xFFEDE9FE), const Color(0xFFDDD6FE)],
      },
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.30,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: summaryItems.length,
      itemBuilder: (context, index) {
        final item = summaryItems[index];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: item['bgColors'] as List<Color>,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (item['colors'] as List<Color>)[0].withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.grey.shade400,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: item['colors'] as List<Color>,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (item['colors'] as List<Color>)[0].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['value'] as String,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: (item['colors'] as List<Color>)[1],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['title'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: (item['colors'] as List<Color>)[1].withOpacity(0.8),
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

  Widget _buildRecentActivities() {
    final activities = [
      {
        'icon': Icons.update,
        'title': 'Foundation Progress',
        'subtitle': 'Foundation work 85% completed',
        'time': '2h ago',
        'color': const Color(0xFF10B981),
      },
      {
        'icon': Icons.engineering,
        'title': 'Safety Inspection',
        'subtitle': 'Monthly safety check completed',
        'time': '4h ago',
        'color': const Color(0xFF3B82F6),
      },
      {
        'icon': Icons.local_shipping,
        'title': 'Material Delivery',
        'subtitle': 'Steel beams delivered to site',
        'time': '6h ago',
        'color': const Color(0xFFF59E0B),
      },
      {
        'icon': Icons.assignment_turned_in,
        'title': 'Task Completed',
        'subtitle': 'Concrete pouring finished',
        'time': '1d ago',
        'color': const Color(0xFF8B5CF6),
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFf4f4f4),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Activities',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Latest updates from your site',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    sites.firstWhere(
                      (site) => site.id == selectedSiteId, 
                      orElse: () => Site(id: '', name: 'All Sites', address: '')
                    ).name,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (activity['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          activity['icon'] as IconData,
                          color: activity['color'] as Color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity['title'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activity['subtitle'] as String,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        activity['time'] as String,
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.hourglass_empty,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No data available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Data will appear here once available',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}