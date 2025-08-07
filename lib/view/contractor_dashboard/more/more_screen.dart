import 'package:ecoteam_app/models/dashboard/site_model.dart';
import 'package:ecoteam_app/view/contractor_dashboard/more/inspection.dart';
import 'package:ecoteam_app/view/contractor_dashboard/more/material_screen.dart';
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

  final List<Map<String, dynamic>> _modules = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _modules.clear();
    _modules.addAll([
      {
        'title': 'Materials',
        'icon': Icons.inventory_2_rounded,
        'color': Colors.orange[50]!,
        'accentColor': Colors.orange,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MaterialsScreen(
                  selectedSiteId: _selectedSiteId,
                  onSiteChanged: widget.onSiteChanged,
                  sites: widget.sites,
                ),
              ),
            ),
      },
      {
        'title': 'Machinery',
        'icon': Icons.precision_manufacturing_rounded,
        'color': Colors.purple[50]!,
        'accentColor': Colors.purple,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MachineryDetailScreen(
                  siteId: _selectedSiteId,
                  siteName: _getSiteName(),
                ),
              ),
            ),
      },
      {
        'title': 'Inventory',
        'icon': Icons.insights_rounded,
        'color': Colors.blue[50]!,
        'accentColor': Colors.blue,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InventoryDetailScreen(
                  siteId: _selectedSiteId,
                  siteName: _getSiteName(),
                ),
              ),
            ),
      },
      {
        'title': 'Payments',
        'icon': Icons.payment_rounded,
        'color': Colors.lightBlue[50]!,
        'accentColor': Colors.lightBlue[700]!,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentsDetailScreen(
                  siteId: _selectedSiteId,
                  siteName: _getSiteName(),
                ),
              ),
            ),
      },
      {
        'title': 'Manpower',
        'icon': Icons.groups_rounded,
        'color': Colors.green[50]!,
        'accentColor': Colors.green,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManpowerCountScreen(
                  siteId: _selectedSiteId,
                  siteName: _getSiteName(),
                ),
              ),
            ),
      },
      {
        'title': 'Inspection',
        'icon': Icons.insert_page_break_rounded,
        'color': Colors.pink[50]!,
        'accentColor': Colors.pink[800]!,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InspectionPage(
                  siteId: _selectedSiteId,
                  siteName: _getSiteName(),
                  onTotalUpdate: (int _) {},
                ),
              ),
            ),
      },
      {
        'title': 'Picking',
        'icon': Icons.sign_language_rounded,
        'color': Colors.brown[50]!,
        'accentColor': Colors.brown[900],
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PickingPage(
                  siteId: _selectedSiteId,
                  siteName: _getSiteName(),
                ),
              ),
            ),
      },
    ]);
  }

  String _getSiteName() {
    return widget.sites.firstWhere(
      (site) => site.id == _selectedSiteId,
      orElse: () => Site(id: '', name: 'Unknown', address: ''),
    ).name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Construction Hub',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSiteDropdown(),
          const SizedBox(height: 16),
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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.86,
            ),
            itemBuilder: (context, index) {
              return _buildModuleCard(_modules[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSiteDropdown() {
    return Container(
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
          Icon(Icons.location_on_outlined, color: Colors.blue[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedSiteId.isNotEmpty ? _selectedSiteId : null,
                hint: const Text('Select Site', style: TextStyle(fontSize: 14)),
                items: widget.sites.map((site) {
                  return DropdownMenuItem<String>(
                    value: site.id,
                    child: Text(site.name, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedSiteId = newValue);
                    widget.onSiteChanged(newValue);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(Map<String, dynamic> module) {
    return GestureDetector(
      onTap: module['onTap'],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: module['color'],
                shape: BoxShape.circle,
              ),
              child: Icon(
                module['icon'],
                size: 26,
                color: module['accentColor'],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              module['title'],
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
