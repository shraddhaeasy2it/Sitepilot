import 'package:ecoteam_app/view/contractor_dashboard/more/docstorage.dart';
import 'package:ecoteam_app/view/contractor_dashboard/more/supplier.dart';
import '../../../models/dashboard/site_model.dart';
import 'inspection.dart';
import 'material_screen.dart';
import 'package:flutter/material.dart';
import 'mancount.dart';
import 'expences.dart';
import 'inventory.dart';
import 'paymentreq.dart';
import 'picking.dart';

class MoreScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  const MoreScreen({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
  });

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  late String _selectedSiteId;
  String? _searchQueryForSites; // Initialize this variable

  @override
  void initState() {
    super.initState();
    _selectedSiteId = widget.selectedSiteId ?? '';
    _searchQueryForSites = ''; // Initialize here
  }

  @override
  void didUpdateWidget(MoreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSiteId != oldWidget.selectedSiteId) {
      _selectedSiteId = widget.selectedSiteId ?? '';
    }
  }

  /// Dynamic module definitions
  late final List<Map<String, dynamic>> _modules = [
    {
      'title': 'Materials',
      'icon': Icons.inventory_2_rounded,
      'color': Colors.orange[50]!,
      'accentColor': Colors.orange,
      'builder': () => MaterialScreen(
        selectedSiteId: _selectedSiteId,
        onSiteChanged: widget.onSiteChanged,
        sites: widget.sites,
      ),
    },
    {
      'title': 'Machinery',
      'icon': Icons.precision_manufacturing_rounded,
      'color': Colors.purple[50]!,
      'accentColor': Colors.purple,
      'builder': () => MachineryDetailScreen(
        siteId: _selectedSiteId,
        siteName: _getSiteName(),
      ),
    },
    {
      'title': 'Inventory',
      'icon': Icons.insights_rounded,
      'color': Colors.blue[50]!,
      'accentColor': Colors.blue,
      'builder': () => InventoryDetailScreen(
        siteId: _selectedSiteId,
        siteName: _getSiteName(),
      ),
    },
    {
      'title': 'Payments',
      'icon': Icons.payment_rounded,
      'color': Colors.lightBlue[50]!,
      'accentColor': Colors.lightBlue[700]!,
      'builder': () => PaymentsDetailScreen(
        siteId: _selectedSiteId,
        siteName: _getSiteName(),
      ),
    },
    {
      'title': 'Manpower',
      'icon': Icons.groups_rounded,
      'color': Colors.green[50]!,
      'accentColor': Colors.green,
      'builder': () => ManpowerCountScreen(
        siteId: _selectedSiteId,
        siteName: _getSiteName(),
      ),
    },
    // {
    //   'title': 'Inspection',
    //   'icon': Icons.insert_page_break_rounded,
    //   'color': Colors.pink[50]!,
    //   'accentColor': Colors.pink[800]!,
    //   'builder': () => InspectionPage(
    //     siteId: _selectedSiteId,
    //     siteName: _getSiteName(),
    //     onTotalUpdate: (int _) {},
    //   ),
    // },
    // {
    //   'title': 'Picking',
    //   'icon': Icons.sign_language_rounded,
    //   'color': Colors.brown[50]!,
    //   'accentColor': Colors.brown[900],
    //   'builder': () =>
    //       PickingPage(siteId: _selectedSiteId, siteName: _getSiteName()),
    // },
    {
      'title': 'File Manager',
      'icon': Icons.folder_copy_rounded,
      'color': Colors.indigo[50]!,
      'accentColor': Colors.indigo,
      'builder': () => DocumentStorageScreen(
        selectedSiteId: _selectedSiteId,
        onSiteChanged: widget.onSiteChanged,
        sites: widget.sites, 
        siteId: '', 
        siteName: '',
      ),
    },
    {
      'title': 'Supplier Ledger',
      'icon': Icons.support_agent_rounded,
      'color': Colors.brown[50]!,
      'accentColor': const Color.fromARGB(255, 187, 74, 54),
      'builder': () => SupplierLedger(
        selectedSiteId: _selectedSiteId,
        onSiteChanged: widget.onSiteChanged,
        sites: widget.sites,
      ),
    }
  ];

  String _getSiteName() {
    return widget.sites
        .firstWhere(
          (site) => site.id == _selectedSiteId,
          orElse: () =>
              Site(id: '', name: 'Unknown', address: '', companyId: ''),
        )
        .name;
  }

  void _onSiteChanged(String siteId) {
    setState(() {
      _selectedSiteId = siteId;
    });
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        toolbarHeight: 80,
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
              'Construction Hub',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // Back arrow white
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
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
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Determine crossAxisCount based on screen width
          final screenWidth = constraints.maxWidth;
          int crossAxisCount;
          double childAspectRatio;
          
          if (screenWidth < 600) {
            // Small screens (phones)
            crossAxisCount = 3;
            childAspectRatio = 0.86;
          } else if (screenWidth < 900) {
            // Medium screens (small tablets)
            crossAxisCount = 4;
            childAspectRatio = 0.9;
          } else {
            // Large screens (large tablets, desktops)
            crossAxisCount = 5;
            childAspectRatio = 0.95;
          }
          
          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              
              Text(
                'Management Modules',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _modules.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: childAspectRatio,
                ),
                itemBuilder: (context, index) {
                  return _buildModuleCard(_modules[index]);
                },
              ),
            ],
          );
        },
      ),
    );
  }

 

  Widget _buildModuleCard(Map<String, dynamic> module) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconSize = constraints.maxWidth * 0.3;
        final fontSize = constraints.maxWidth * 0.09;
        
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => module['builder']()),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth * 0.05, 
              vertical: constraints.maxHeight * 0.05
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(iconSize * 0.3),
                  decoration: BoxDecoration(
                    color: module['color'],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    module['icon'],
                    size: iconSize,
                    color: module['accentColor'],
                  ),
                ),
                SizedBox(height: constraints.maxHeight * 0.05),
                Flexible(
                  child: Text(
                    module['title'],
                    style: TextStyle(
                      fontSize: fontSize.clamp(12, 16),
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: constraints.maxHeight * 0.03),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: module['color'],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Manage',
                    style: TextStyle(
                      fontSize: fontSize.clamp(10, 12),
                      color: module['accentColor'],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Extension to clamp values
extension Clamp on double {
  double clamp(double min, double max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
}