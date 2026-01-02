import 'package:ecoteam_app/admin/models/tools_model.dart';
import 'package:ecoteam_app/admin/services/tools_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecoteam_app/admin/services/transfer_tool_services.dart';
import 'package:ecoteam_app/admin/services/purchase_services.dart';
import 'package:ecoteam_app/admin/models/purchase_model.dart' hide MaterialModel; // Assuming SiteModel is here or similar
import 'package:intl/intl.dart'; // For date formatting

class ToolsEquipmentPage extends StatefulWidget {
  final String? selectedSiteName;
  final int? selectedSiteId;

  const ToolsEquipmentPage({
    super.key,
    this.selectedSiteName,
    this.selectedSiteId,
  });

  @override
  State<ToolsEquipmentPage> createState() => _ToolsEquipmentPageState();
}

class _ToolsEquipmentPageState extends State<ToolsEquipmentPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<ToolModel> _tools = [];
  List<ToolModel> _filteredTools = [];
  List<MaterialModel> _materials = [];
  List<SiteModel> _sites = []; // Add sites list
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadSites(); // Load sites
  }

  Future<void> _loadSites() async {
    try {
      final sites = await ApiServicePurchaseInvoice.getSites();
      setState(() {
        _sites = sites;
      });
    } catch (e) {
      print('Failed to load sites: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load tools and materials separately
      final tools = await _apiService.getTools();
      final materials = await _apiService.getMaterialsByCategory(3); // Tools & Equipment category

      setState(() {
        _tools = tools;
        // Sort by createdAt in descending order (newest first) to show new cards at top
        _tools.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        if (widget.selectedSiteId != null) {
          _tools = _tools.where((t) => t.siteId == widget.selectedSiteId).toList();
        }

        _filteredTools = _tools;
        _materials = materials;
        _isLoading = false;
      });
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
      if (query.isEmpty) {
        _filteredTools = _tools;
      } else {
        _filteredTools = _tools.where((tool) {
          final materialName = _getMaterialName(tool.materialId);
          return materialName.toLowerCase().contains(query.toLowerCase()) ||
                 tool.operationalStatus.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  String _getMaterialName(int materialId) {
    try {
      final material = _materials.firstWhere((m) => m.id == materialId);
      return material.name;
    } catch (e) {
      return 'Unknown Material';
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
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _openAddToolSheet() {
    if (_materials.isEmpty) {
      _showErrorSnackBar('No materials available. Please try again later.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ToolBottomSheet(
        materials: _materials,
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
        selectedSiteId: widget.selectedSiteId,
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

  String _getSiteName(int siteId) {
    try {
      final site = _sites.firstWhere((s) => s.id == siteId);
      return site.name;
    } catch (e) {
      if (widget.selectedSiteId == siteId && widget.selectedSiteName != null) {
        return widget.selectedSiteName!;
      }
      return 'Unknown Site';
    }
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
                  machineryId: tool.materialId,
                  userId: 1, // Using 1 as default/admin user ID
                );

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

                      _readOnlyField(
                        label: 'Transfer Type',
                        value: 'Tools & Equipment',
                        icon: Icons.swap_horiz,
                      ),

                      _readOnlyField(
                        label: 'Tool',
                        value: _getMaterialName(tool.materialId),
                        icon: Icons.build,
                      ),

                      _readOnlyField(
                        label: 'From Site',
                        value: _getSiteName(tool.siteId),
                        icon: Icons.location_on,
                      ),

                      _readOnlyTextField(
                        controller: transferDateController,
                        label: 'Transfer Date',
                        icon: Icons.calendar_today,
                      ),

                      const SizedBox(height: 16),

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
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: selectedToSite == null
                              ? null
                              : () async {
                                  try {
                                    await TransfertoolService.createTransfer(
                                      {
                                        'transfer_type': 'tools_and_equipment',
                                        'machinery_id': tool.materialId.toString(),
                                        'transfer_date': transferDateController.text,
                                        'from_site_id': tool.siteId.toString(),
                                        'to_site_id': selectedToSite!,
                                        'created_by': '1',
                                      },
                                    );

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
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: const OutlineInputBorder(),
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
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tools & Equipment',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3),
            Text(
              widget.selectedSiteName != null 
                  ? 'Site: ${widget.selectedSiteName}' 
                  : 'Manage your tools and equipment',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 80.h,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(25),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF4a63c0),
                Color(0xFF3a53b0),
                Color(0xFF2a43a0),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openAddToolSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar and Total Count
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search tools...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onChanged: _filterTools,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Entries: ${_filteredTools.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            Text(
                              'Filtered: ${_filteredTools.length}',
                              style: const TextStyle(
                                color: Colors.blue,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Tools List
                Expanded(
                  child: _filteredTools.isEmpty
                      ? const Center(
                          child: Text('No tools found'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: _filteredTools.length,
                          itemBuilder: (context, index) {
                            final tool = _filteredTools[index];
                            final material = _getMaterial(tool.materialId);
                            return _ToolCard(
                              tool: tool,
                              material: material,
                              onTransfer: () => _showToolTransferSheet(tool),
                              onEdit: () => _openEditToolSheet(tool),
                              onDelete: () => _deleteTool(tool.id),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final ToolModel tool;
  final MaterialModel? material;
  final VoidCallback onTransfer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ToolCard({
    required this.tool,
    required this.material,
    required this.onTransfer,
    required this.onEdit,
    required this.onDelete,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'breakdown':
        return Colors.orange;
      case 'scrap':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    material?.name ?? 'Unknown Material',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.swap_horiz, size: 20, color: Color(0xFF2a43a0)),
                      onPressed: onTransfer,
                      tooltip: 'Transfer',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF2a43a0), size: 20),
                      onPressed: onEdit,
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: onDelete,
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.inventory,
                  label: 'Qty: ${tool.quantity}',
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.circle,
                  label: tool.operationalStatus,
                  color: _getStatusColor(tool.operationalStatus),
                ),
              ],
            ),
            if (material?.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                material!.description!,
                style: const TextStyle(color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = const Color.fromARGB(255, 21, 61, 170),
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: color.withOpacity(0.1),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class ToolBottomSheet extends StatefulWidget {
  final List<MaterialModel> materials;
  final ToolModel? tool;
  final Function(ToolModel) onSave;
  final int? selectedSiteId;

  const ToolBottomSheet({
    super.key,
    required this.materials,
    this.tool,
    required this.onSave,
    this.selectedSiteId,
  });

  @override
  State<ToolBottomSheet> createState() => _ToolBottomSheetState();
}

class _ToolBottomSheetState extends State<ToolBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  
  MaterialModel? _selectedMaterial;
  final TextEditingController _quantityController = TextEditingController();
  String _selectedStatus = 'active';
  late int _siteId;
  final int _createdBy = 1;
  final int _workspaceId = 1;

  final List<String> _operationalStatuses = ['active', 'breakdown', 'scrap'];

  @override
  void initState() {
    super.initState();
    _siteId = widget.selectedSiteId ?? 1; // Use selected site or default
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
    if (_formKey.currentState!.validate() && _selectedMaterial != null) {
      final tool = ToolModel(
        id: widget.tool?.id ?? 0,
        materialId: _selectedMaterial!.id,
        quantity: int.parse(_quantityController.text),
        operationalStatus: _selectedStatus,
        siteId: _siteId,
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