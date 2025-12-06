import 'package:ecoteam_app/admin/models/tools_model.dart';
import 'package:ecoteam_app/admin/services/tools_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../models/site_model.dart';

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
            onTap: () => _openEditToolSheet(tool),
            splashColor: primaryColor.withOpacity(0.1),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and name
                  Row(
                    children: [
                      // Category icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          categoryIcon,
                          color: primaryColor,
                          size: 24,
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
                                fontSize: 18,
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
                                fontSize: 13,
                                color: primaryColor.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Status badge
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
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Info grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 4.0,
                    children: [

                      // Quantity
                      _buildInfoItem(
                        Icons.inventory_2,
                        'Quantity',
                        '${tool.quantity}',
                        Colors.green,
                      ),

                      // SKU
                      _buildInfoItem(
                        Icons.code,
                        'SKU',
                        material?.sku ?? 'N/A',
                        Colors.orange,
                      ),

                      // Price
                      _buildInfoItem(
                        Icons.currency_rupee,
                        'Price',
                        '₹${material?.price ?? '0.00'}',
                        Colors.purple,
                      ),
                    ],
                  ),

                  // Description and actions row
                  if ((material?.description?.isNotEmpty ?? false) &&
                      material!.description!.length < 100)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          material.description!,
                          style: TextStyle(color: textSecondary, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      // Last updated
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: textSecondary.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Updated ${DateFormat('MMM dd, yyyy').format(DateTime.parse(tool.updatedAt))}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textSecondary.withOpacity(0.8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Delete button
                      GestureDetector(
                        onTap: () => _deleteTool(tool.id),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
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
  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 40,
      ),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: textSecondary.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
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
        toolbarHeight: 80.h,
        backgroundColor: Colors.transparent,
        title: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Assets/Tools - ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: _getCurrentSiteName(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _openAddToolSheet,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.add),
          label: const Text(
            'Add Tool',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
      _selectedMaterial = widget.materials.isNotEmpty ? widget.materials.first : null;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _saveTool() {
    if (_formKey.currentState!.validate() && _selectedMaterial != null && widget.selectedSiteId != null) {
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
              widget.tool == null ? 'Add Tool/Equipment' : 'Edit Tool/Equipment',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Material Dropdown
            DropdownButtonFormField<MaterialModel>(
              value: _selectedMaterial,
              decoration: const InputDecoration(
                labelText: 'Material',
                border: OutlineInputBorder(),
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
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
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
              decoration: const InputDecoration(
                labelText: 'Operational Status',
                border: OutlineInputBorder(),
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
                backgroundColor: Colors.blue,
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