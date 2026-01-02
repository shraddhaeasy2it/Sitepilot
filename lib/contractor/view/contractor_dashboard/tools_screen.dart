import 'package:ecoteam_app/admin/models/tools_model.dart';
import 'package:ecoteam_app/admin/services/tools_services.dart';
import 'package:ecoteam_app/admin/services/transfer_tool_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../models/site_model.dart';

class ToolsScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;

  const ToolsScreen({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
  });

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<ToolModel> _tools = [];
  List<ToolModel> _filteredTools = [];
  List<MaterialModel> _materials = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedSiteFilter;

  // UI Colors
  static const Color primaryColor = Color(0xFF2a43a0);
  static const Color primaryDark = Color.fromARGB(255, 53, 86, 206);
  static const Color backgroundColor = Color.fromARGB(255, 249, 249, 253);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  // Status colors mapping
  final Map<String, Color> _statusColors = {
    'active': Colors.green,
    'breakdown': Colors.orange,
    'scrap': Colors.red,
    'available': Colors.green,
    'in use': Color.fromARGB(255, 23, 121, 201),
    'under maintenance': Colors.orange,
    'lost/damaged': Colors.red,
  };

  // Category icons mapping
  final Map<String, IconData> _categoryIcons = {
    'power tools': Icons.electrical_services,
    'hand tools': Icons.build,
    'safety equipment': Icons.health_and_safety,
    'measuring tools': Icons.straighten,
    'heavy machinery': Icons.agriculture,
  };

  @override
  void initState() {
    super.initState();
    _selectedSiteFilter = widget.selectedSiteId;
    _loadData();
  }

  // Helper method to get the current site name
  String _getCurrentSiteName() {
    if (_selectedSiteFilter == null) {
      return 'All Sites';
    }
    try {
      final site = widget.sites.firstWhere(
        (site) => site.id == _selectedSiteFilter,
      );
      return site.name;
    } catch (e) {
      return 'Unknown Site';
    }
  }

  // Helper method to get current site ID
  int? _getCurrentSiteId() {
    if (_selectedSiteFilter == null) {
      return null;
    }
    return int.tryParse(_selectedSiteFilter!);
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load tools and materials separately
      final tools = await _apiService.getTools();
      final materials = await _apiService.getMaterialsByCategory(
        3,
      ); // Tools & Equipment category

      setState(() {
        _tools = tools;
        // Sort by createdAt in descending order (newest first) to show new cards at top
        _tools.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _filteredTools = _tools;
        _materials = materials;
        _isLoading = false;
      });

      // Apply site filter if any
      if (_selectedSiteFilter != null) {
        _filterToolsBySite(_selectedSiteFilter);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load data: $e');
    }
  }

  void _filterTools(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty && _selectedSiteFilter == null) {
        _filteredTools = _tools;
      } else {
        _filteredTools = _tools.where((tool) {
          final materialName = _getMaterialName(tool.materialId);
          final materialCategory = _getMaterialCategory(tool.materialId);

          // Site filter - Convert siteId to string for comparison
          final siteMatch =
              _selectedSiteFilter == null ||
              tool.siteId.toString() == _selectedSiteFilter;

          // Search filter
          final searchMatch =
              query.isEmpty ||
              materialName.toLowerCase().contains(query.toLowerCase()) ||
              tool.operationalStatus.toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              materialCategory.toLowerCase().contains(query.toLowerCase());

          return siteMatch && searchMatch;
        }).toList();
      }
    });
  }

  void _filterToolsBySite(String? siteId) {
    setState(() {
      _selectedSiteFilter = siteId;
      if (siteId == null && _searchQuery.isEmpty) {
        _filteredTools = _tools;
      } else {
        _filteredTools = _tools.where((tool) {
          final siteMatch = siteId == null || tool.siteId.toString() == siteId;
          final searchMatch =
              _searchQuery.isEmpty ||
              _getMaterialName(
                tool.materialId,
              ).toLowerCase().contains(_searchQuery.toLowerCase()) ||
              tool.operationalStatus.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );

          return siteMatch && searchMatch;
        }).toList();
      }
    });

    // Notify parent if callback exists
    widget.onSiteChanged(siteId ?? '');
  }

  String _getMaterialName(int materialId) {
    try {
      final material = _materials.firstWhere((m) => m.id == materialId);
      return material.name;
    } catch (e) {
      return 'Unknown Material';
    }
  }

  String _getMaterialCategory(int materialId) {
    try {
      final material = _materials.firstWhere((m) => m.id == materialId);
      return material.category?.name ?? 'Uncategorized';
    } catch (e) {
      return 'Uncategorized';
    }
  }

  String _getSiteName(String siteId) {
    try {
      final site = widget.sites.firstWhere((site) => site.id == siteId);
      return site.name;
    } catch (e) {
      return 'Unknown Site';
    }
  }

  MaterialModel? _getMaterial(int materialId) {
    try {
      return _materials.firstWhere((m) => m.id == materialId);
    } catch (e) {
      return null;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _openAddToolSheet() {
    if (_materials.isEmpty) {
      _showErrorSnackBar('No materials available. Please try again later.');
      return;
    }

    // Check if a site is selected
    if (_selectedSiteFilter == null) {
      _showErrorSnackBar('Please select a site first to add tools.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ToolBottomSheet(
        materials: _materials,
        selectedSiteId: _selectedSiteFilter,
        onSave: (tool) async {
          try {
            await _apiService.createTool(tool);
            if (!mounted) return;
            Navigator.pop(context);
            _showSuccessSnackBar('Tool created successfully');
            // Reload data from API to get the fresh sorted list
            _loadData();
          } catch (e) {
            if (!mounted) return;
            _showErrorSnackBar('Failed to create tool: $e');
          }
        },
      ),
    );
  }

  void _openEditToolSheet(ToolModel tool) {
    if (_materials.isEmpty) {
      _showErrorSnackBar('No materials available. Please try again later.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ToolBottomSheet(
        materials: _materials,
        selectedSiteId: _selectedSiteFilter,
        tool: tool,
        onSave: (updatedTool) async {
          try {
            await _apiService.updateTool(tool.id, updatedTool);
            if (!mounted) return;
            Navigator.pop(context);
            _showSuccessSnackBar('Tool updated successfully');
            // Reload data from API to get the fresh sorted list
            _loadData();
          } catch (e) {
            if (!mounted) return;
            _showErrorSnackBar('Failed to update tool: $e');
          }
        },
      ),
    );
  }

  void _deleteTool(int toolId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this tool?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteTool(toolId);
        _showSuccessSnackBar('Tool deleted successfully');
        // Reload data from API to get the fresh sorted list
        _loadData();
      } catch (e) {
        _showErrorSnackBar('Failed to delete tool: $e');
      }
    }
  }

  // Helper method to get status color
  Color _getStatusColor(String status) {
    return _statusColors[status.toLowerCase()] ?? Colors.grey;
  }

  // Helper method to get category icon
  IconData _getCategoryIcon(String category) {
    return _categoryIcons[category.toLowerCase()] ?? Icons.build;
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? backgroundColor,
    required VoidCallback onTap,
    Color color = const Color(0xFF2D3748),
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor ?? primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 14.sp,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  void _showToolOptionsBottomSheet(ToolModel tool) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(
              icon: Icons.visibility_outlined,
              title: 'View Full Details',
              iconColor: const Color.fromARGB(255, 37, 49, 158),
              backgroundColor: const Color.fromARGB(
                255,
                37,
                49,
                158,
              ).withOpacity(0.1),
              onTap: () {
                Navigator.pop(context);
                final material = _getMaterial(tool.materialId);
                _showToolDetailsBottomSheet(tool, material);
              },
            ),
            _buildOptionTile(
              icon: Icons.swap_horiz,
              title: 'Transfer Tool',
              iconColor: Colors.orange,
              backgroundColor: Colors.orange.withOpacity(0.1),
              onTap: () {
                Navigator.pop(context);
                _showToolTransferSheet(tool);
              },
            ),
            _buildOptionTile(
              icon: Icons.edit_outlined,
              title: 'Edit Tool',
              iconColor: Colors.blue,
              backgroundColor: Colors.blue.withOpacity(0.1),
              onTap: () {
                Navigator.pop(context);
                _openEditToolSheet(tool);
              },
            ),
            _buildOptionTile(
              icon: Icons.delete_outline,
              title: 'Delete Tool',
              color: Colors.red,
              iconColor: Colors.red,
              backgroundColor: Colors.red.withOpacity(0.1),
              onTap: () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 200), () {
                  _deleteTool(tool.id);
                });
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showToolDetailsBottomSheet(ToolModel tool, MaterialModel? material) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tool Details',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                       
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        tool.operationalStatus,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(
                          tool.operationalStatus,
                        ).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      tool.operationalStatus.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(tool.operationalStatus),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    _buildDetailRowInfo(
                      Icons.build,
                      'Material Name',
                      material?.name ?? 'N/A',
                    ),
                   
                    const SizedBox(height: 12),
                    _buildDetailRowInfo(
                      Icons.category,
                      'Category',
                      _getMaterialCategory(tool.materialId),
                    ),
                    const SizedBox(height: 12),
                    if (material?.description != null &&
                        material!.description.isNotEmpty) ...[
                      _buildDetailRowInfo(
                        Icons.description,
                        'Description',
                        material!.description,
                      ),
                      const SizedBox(height: 12),
                    ],
                   
                    const SizedBox(height: 12),
                    _buildDetailRowInfo(
                      Icons.inventory_2,
                      'Quantity',
                      '${tool.quantity} ${material?.unit?.symbol ?? ''}'.trim(),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRowInfo(
                      Icons.currency_rupee,
                      'Price per unit',
                      '₹${material?.price ?? '0.00'}',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRowInfo(
                      Icons.low_priority,
                      'Reorder Level',
                      '${material?.reorderLevel ?? 0}',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRowInfo(
                      Icons.calendar_today,
                      'Added On',
                      DateFormat(
                        'MMM dd, yyyy',
                      ).format(DateTime.parse(tool.createdAt)),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRowInfo(
                      Icons.update,
                      'Last Updated',
                      DateFormat(
                        'MMM dd, yyyy',
                      ).format(DateTime.parse(tool.updatedAt)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRowInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: textSecondary),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: textSecondary)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // Enhanced search and filter bar
  Widget _buildSearchBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return Container(
          margin: const EdgeInsets.all(16),
          child: isSmallScreen
              ? Column(
                  children: [
                    // Search field
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterTools,
                        decoration: InputDecoration(
                          hintText: 'Search tools...',
                          hintStyle: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: primaryColor,
                            size: 22,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterTools('');
                                  },
                                  color: textSecondary,
                                )
                              : null,
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.grey.withOpacity(0.1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2,
                              size: 18,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Total: ${_filteredTools.length}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Search field
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterTools,
                          decoration: InputDecoration(
                            hintText: 'Search tools...',
                            hintStyle: TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: primaryColor,
                              size: 22,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterTools('');
                                    },
                                    color: textSecondary,
                                  )
                                : null,
                            filled: true,
                            fillColor: cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.grey.withOpacity(0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (widget.sites.isNotEmpty) ...[
                      const SizedBox(width: 16),

                      // Site filter for desktop
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          child: DropdownButton<String?>(
                            value: _selectedSiteFilter,
                            hint: const Text('All Sites'),
                            isExpanded: true,
                            icon: Icon(Icons.filter_list, color: primaryColor),
                            underline: Container(),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('All Sites'),
                              ),
                              ...widget.sites.map(
                                (site) => DropdownMenuItem<String?>(
                                  value: site.id,
                                  child: Text(site.name),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              _filterToolsBySite(value);
                            },
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(width: 16),

                    // Stats
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.inventory_2,
                            size: 18,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tools',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                              Text(
                                '${_filteredTools.length}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  // Modern tool card
  Widget _buildToolCard(ToolModel tool, MaterialModel? material) {
    final categoryName = _getMaterialCategory(tool.materialId);
    final statusColor = _getStatusColor(tool.operationalStatus);
    final categoryIcon = _getCategoryIcon(categoryName);
    final siteName = _getSiteName(tool.siteId.toString());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.white,
          child: InkWell(
           
            splashColor: primaryColor.withOpacity(0.1),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and name
                  Row(
                    children: [
                      // Category icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          categoryIcon,
                          color: primaryColor,
                          size: 16,
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Tool name and category
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              material?.name ?? 'Unknown Material',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              categoryName,
                              style: TextStyle(
                                fontSize: 11,
                                color: const Color.fromARGB(255, 66, 66, 66).withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Status badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tool.operationalStatus.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          
                             // More Options Button
                             Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => _showToolOptionsBottomSheet(tool),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.more_vert,
                                    color: textSecondary,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Quantity : ${tool.quantity} ${material?.unit?.symbol ?? ''}'.trim(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 54, 65, 85),
                    ),
                  ),
                  
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Info item widget
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: const Color.fromARGB(
                    255,
                    79,
                    92,
                    110,
                  ).withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(255, 54, 65, 85),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.1),
                    primaryDark.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(Icons.build_outlined, size: 64, color: primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              'No tools found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty && _selectedSiteFilter == null
                  ? 'Start by adding your first tool'
                  : 'Try adjusting your search criteria',
              style: TextStyle(fontSize: 16, color: textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (_searchQuery.isEmpty && _selectedSiteFilter == null)
              ElevatedButton.icon(
                onPressed: _openAddToolSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Tool'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 74.h,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assets Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              "Site: ${_getCurrentSiteName()}",

              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: ClipRRect(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25.r)),
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
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.refresh),
        //     onPressed: _loadData,
        //     tooltip: 'Refresh',
        //   ),
        // ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: primaryColor,
                strokeWidth: 3,
              ),
            )
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: _filteredTools.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: _filteredTools.length,
                          itemBuilder: (context, index) {
                            final tool = _filteredTools[index];
                            final material = _getMaterial(tool.materialId);
                            return _buildToolCard(tool, material);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddToolSheet,
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color.fromRGBO(
          42,
          67,
          160,
          1,
        ), // Any color you want
        tooltip: 'Add New Invoice',
      ),
    );
  }

  void _showToolTransferSheet(ToolModel tool) {
    final TextEditingController transferDateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );

    String? selectedToSite;
    bool loading = true;
    String error = '';
    Map<String, String> siteMap = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> loadSites() async {
              try {
                final result = await TransfertoolService.fetchToSites(
                  siteId: tool.siteId,
                  workspaceId: tool.workspaceId,
                  machineryId: tool.materialId, // backend expects id
                  userId: 1,
                );

                /// ❌ remove FROM SITE
                result.remove(tool.siteId.toString());

                setSheetState(() {
                  siteMap = result;
                  loading = false;
                });
              } catch (e) {
                setSheetState(() {
                  loading = false;
                  error = 'Failed to load sites';
                });
              }
            }

            if (loading) loadSites();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Transfer Tool / Equipment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      /// 🔒 TYPE
                      _readOnlyField(
                        label: 'Transfer Type',
                        value: 'Tools & Equipment',
                        icon: Icons.swap_horiz,
                      ),

                      /// 🔒 TOOL NAME
                      _readOnlyField(
                        label: 'Tool',
                        value: _getMaterialName(tool.materialId),
                        icon: Icons.build,
                      ),

                      /// 🔒 FROM SITE
                      _readOnlyField(
                        label: 'From Site',
                        value: _getSiteName(tool.siteId.toString()),
                        icon: Icons.location_on,
                      ),

                      /// 🔒 DATE
                      _readOnlyTextField(
                        controller: transferDateController,
                        label: 'Transfer Date',
                        icon: Icons.calendar_today,
                      ),

                      const SizedBox(height: 16),

                      /// ✅ TO SITE
                      if (loading)
                        const CircularProgressIndicator()
                      else if (error.isNotEmpty)
                        Text(error, style: const TextStyle(color: Colors.red))
                      else
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          hint: const Text('Select To Site'),
                          value: selectedToSite,
                          items: siteMap.entries.map((e) {
                            return DropdownMenuItem(
                              value: e.key,
                              child: Text(
                                e.value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setSheetState(() => selectedToSite = val),
                          decoration: InputDecoration(
                            labelText: 'To Site',
                            prefixIcon: Icon(
                              Icons.location_on,
                              color: Color(0xFF4a63c0),
                              size: 20.sp,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: Color.fromARGB(255, 214, 215, 216),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: Color.fromARGB(255, 189, 190, 197),
                                width: 1.0,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 2,
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      /// ✅ SUBMIT
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: selectedToSite == null
                              ? null
                              : () async {
                                  try {
                                    await TransfertoolService.createTransfer({
                                      'transfer_type': 'tools_and_equipment',
                                      'machinery_id': tool.materialId
                                          .toString(),
                                      'transfer_date':
                                          transferDateController.text,
                                      'from_site_id': tool.siteId.toString(),
                                      'to_site_id': selectedToSite!,
                                      'created_by': '1',
                                    });

                                    Navigator.pop(context);
                                    _showSuccessSnackBar(
                                      'Tool transferred successfully',
                                    );
                                    _loadData();
                                  } catch (_) {
                                    _showErrorSnackBar('Transfer failed');
                                  }
                                },
                          child: const Text('Transfer'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _readOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: Color(0xFF4a63c0),
            size: 20.sp,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(
              color: Color.fromARGB(255, 214, 215, 216),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(
              color: Color.fromARGB(255, 189, 190, 197),
              width: 1.0,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            vertical: 2,
          ),
        ),
      ),
    );
  }

  Widget _readOnlyTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: Color(0xFF4a63c0),
            size: 20.sp,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(
              color: Color.fromARGB(255, 214, 215, 216),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(
              color: Color.fromARGB(255, 189, 190, 197),
              width: 1.0,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            vertical: 2,
          ),
        ),
      ),
    );
  }
}

class ToolBottomSheet extends StatefulWidget {
  final List<MaterialModel> materials;
  final ToolModel? tool;
  final String? selectedSiteId;
  final Function(ToolModel) onSave;

  const ToolBottomSheet({
    super.key,
    required this.materials,
    this.tool,
    this.selectedSiteId,
    required this.onSave,
  });

  @override
  State<ToolBottomSheet> createState() => _ToolBottomSheetState();
}

class _ToolBottomSheetState extends State<ToolBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  MaterialModel? _selectedMaterial;
  final TextEditingController _quantityController = TextEditingController();
  String _selectedStatus = 'active';
  final int _createdBy = 1;
  final int _workspaceId = 1;

  final List<String> _operationalStatuses = ['active', 'breakdown', 'scrap'];

  @override
  void initState() {
    super.initState();
    if (widget.tool != null) {
      // Edit mode
      _selectedMaterial = widget.materials.firstWhere(
        (m) => m.id == widget.tool!.materialId,
        orElse: () => widget.materials.first,
      );
      _quantityController.text = widget.tool!.quantity.toString();
      _selectedStatus = widget.tool!.operationalStatus;
    } else {
      // Add mode
      _selectedMaterial = widget.materials.isNotEmpty
          ? widget.materials.first
          : null;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _saveTool() {
    if (_formKey.currentState!.validate() &&
        _selectedMaterial != null &&
        widget.selectedSiteId != null) {
      final tool = ToolModel(
        id: widget.tool?.id ?? 0,
        materialId: _selectedMaterial!.id,
        quantity: int.parse(_quantityController.text),
        operationalStatus: _selectedStatus,
        siteId: int.parse(widget.selectedSiteId!),
        createdBy: _createdBy,
        workspaceId: _workspaceId,
        status: widget.tool?.status ?? '0',
        createdAt: widget.tool?.createdAt ?? '',
        updatedAt: widget.tool?.updatedAt ?? '',
      );
      widget.onSave(tool);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.tool == null
                  ? 'Add Tool/Equipment'
                  : 'Edit Tool/Equipment',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Material Dropdown
            DropdownButtonFormField<MaterialModel>(
              value: _selectedMaterial,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Material',
                hintText: 'Select Material',
                prefixIcon: Icon(
                  Icons.construction,
                  color: Color(0xFF4a63c0),
                  size: 20.sp,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 214, 215, 216),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 189, 190, 197),
                    width: 1.0,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 2,
                ),
              ),
              items: widget.materials.map((material) {
                return DropdownMenuItem<MaterialModel>(
                  value: material,
                  child: Text('${material.name} (${material.sku})'),
                );
              }).toList(),
              onChanged: (material) {
                setState(() {
                  _selectedMaterial = material;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a material';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Quantity TextField
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity',
                hintText: 'Enter quantity',
                prefixIcon: Icon(
                  Icons.numbers,
                  color: Color(0xFF4a63c0),
                  size: 20.sp,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 214, 215, 216),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 189, 190, 197),
                    width: 1.0,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 2,
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter quantity';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Operational Status Dropdown
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Operational Status',
                hintText: 'Select Status',
                prefixIcon: Icon(
                  Icons.info_outline,
                  color: Color(0xFF4a63c0),
                  size: 20.sp,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 214, 215, 216),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 189, 190, 197),
                    width: 1.0,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 2,
                ),
              ),
              items: _operationalStatuses.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status.toUpperCase()),
                );
              }).toList(),
              onChanged: (status) {
                setState(() {
                  _selectedStatus = status!;
                });
              },
            ),

            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _saveTool,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 38, 69, 172),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.tool == null ? 'Add Tool' : 'Update Tool',
                style: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 8),

            // Cancel Button
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
