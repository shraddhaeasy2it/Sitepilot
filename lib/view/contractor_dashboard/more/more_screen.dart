import 'package:ecoteam_app/models/dashboard/site_model.dart';
import 'package:ecoteam_app/view/contractor_dashboard/more/material_screen.dart';
import 'package:flutter/material.dart';
import 'mancount.dart';
import 'expences.dart';
import 'inventory.dart';
import 'paymentreq.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Compact AppBar
          SliverAppBar(
            expandedHeight: 80,
            floating: false,
            pinned: true,
            elevation: 1,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Construction Hub',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE8F3F1), Color(0xFFF0F4FF)],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // Compact Site Selector
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, 
                          color: Colors.blue[600], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedSiteId.isNotEmpty ? _selectedSiteId : null,
                            hint: const Text('Select Site',
                                style: TextStyle(fontSize: 14)),
                            items: widget.sites.map((site) {
                              return DropdownMenuItem<String>(
                                value: site.id,
                                child: Text(site.name,
                                    style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedSiteId = newValue;
                                });
                                widget.onSiteChanged(newValue);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Module Grid
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 12),
                        child: Text(
                          'Management Modules',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: _modules.length,
                        itemBuilder: (context, index) {
                          return _buildModuleCard(_modules[index]);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  final List<Map<String, dynamic>> _modules = [
    {
      'title': 'Materials',
      'icon': Icons.inventory_2_rounded,
      'color': Colors.orange[50]!,
      'accentColor': Colors.orange,
      'onTap': (context, siteId, sites, onChanged) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MaterialsScreen(
            selectedSiteId: siteId,
            onSiteChanged: onChanged,
            sites: sites,
          ),
        ),
      ),
    },
    {
      'title': 'Machinery',
      'icon': Icons.precision_manufacturing_rounded,
      'color': Colors.purple[50]!,
      'accentColor': Colors.purple,
      'onTap': (context, siteId, sites, onChanged) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MachineryDetailScreen(
            siteId: siteId,
            siteName: sites.firstWhere(
              (site) => site.id == siteId,
              orElse: () => Site(id: '', name: 'Unknown', address: ''),
            ).name,
          ),
        ),
      ),
    },
    {
      'title': 'Inventory',
      'icon': Icons.insights_rounded,
      'color': Colors.blue[50]!,
      'accentColor': Colors.blue,
      'onTap': (context, siteId, sites, onChanged) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InventoryDetailScreen(
            siteId: siteId,
            siteName: sites.firstWhere(
              (site) => site.id == siteId,
              orElse: () => Site(id: '', name: 'Unknown', address: ''),
            ).name,
          ),
        ),
      ),
    },
    {
      'title': 'Payments',
      'icon': Icons.payment_rounded,
      'color': Colors.amber[50]!,
      'accentColor': Colors.amber[700]!,
      'onTap': (context, siteId, sites, onChanged) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentsDetailScreen(
            siteId: siteId,
            siteName: sites.firstWhere(
              (site) => site.id == siteId,
              orElse: () => Site(id: '', name: 'Unknown', address: ''),
            ).name,
          ),
        ),
      ),
    },
    {
      'title': 'Manpower',
      'icon': Icons.groups_rounded,
      'color': Colors.green[50]!,
      'accentColor': Colors.green,
      'onTap': (context, siteId, sites, onChanged) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ManpowerCountScreen(
            siteId: siteId,
            siteName: sites.firstWhere(
              (site) => site.id == siteId,
              orElse: () => Site(id: '', name: 'Unknown', address: ''),
            ).name,
          ),
        ),
      ),
    },
  ];

  Widget _buildModuleCard(Map<String, dynamic> module) {
    return GestureDetector(
      onTap: () => module['onTap'](
        context, 
        _selectedSiteId, 
        widget.sites, 
        widget.onSiteChanged
      ),
      child: Container(
        
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 228, 226, 226),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
          ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: module['color'],
                shape: BoxShape.circle,
              ),
              child: Icon(
                module['icon'],
                size: 24,
                color: module['accentColor'],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              module['title'],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: module['color'],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Manage',
                style: TextStyle(
                  fontSize: 12,
                  color: module['accentColor'],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}