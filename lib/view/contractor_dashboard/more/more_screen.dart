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

  @override
  void initState() {
    super.initState();
    _selectedSiteId = widget.selectedSiteId ?? '';
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
    {
      'title': 'Inspection',
      'icon': Icons.insert_page_break_rounded,
      'color': Colors.pink[50]!,
      'accentColor': Colors.pink[800]!,
      'builder': () => InspectionPage(
        siteId: _selectedSiteId,
        siteName: _getSiteName(),
        onTotalUpdate: (int _) {},
      ),
    },
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
        sites: widget.sites, siteId: '', siteName: '',
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        title: RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'Construction Hub- ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20, // keep title size bigger
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: _getSiteName(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16, // smaller font size only for siteName
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

        iconTheme: const IconThemeData(color: Colors.white),
      
        flexibleSpace: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4a63c0), Color(0xFF3a53b0), Color(0xFF2a43a0)],
            ),
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
              const SizedBox(height: 6),
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