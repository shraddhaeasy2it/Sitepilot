import 'package:ecoteam_app/admin/services/materialTransfer_services.dart';
import 'package:flutter/material.dart' hide Material;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/material_transfer_model.dart';

class AdminMaterialtransferScreen extends StatefulWidget {
  
  final int? selectedSiteId;
  final String? selectedSiteName;

  const AdminMaterialtransferScreen({
    super.key,
 
    this.selectedSiteId,
    this.selectedSiteName,
  });

  @override
  State<AdminMaterialtransferScreen> createState() => _AdminMaterialtransferScreenState();
}

class _AdminMaterialtransferScreenState extends State<AdminMaterialtransferScreen> {
  List<MaterialTransfer> _transfers = [];
  List<MaterialTransfer> _filteredTransfers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMaterialTransfers();
  }

  Future<void> _loadMaterialTransfers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transfers = await MaterialTransferService.getMaterialTransfers();
      setState(() {
        _transfers = transfers.where((transfer) {
          if (transfer.id == null) return false;
          if (widget.selectedSiteId != null) {
            return transfer.fromSiteId == widget.selectedSiteId ||
                transfer.toSiteId == widget.selectedSiteId;
          }
          return true;
        }).toList();
        _filteredTransfers = _transfers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load material transfers: $e');
    }
  }

  void _filterTransfers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredTransfers = _transfers;
      } else {
        _filteredTransfers = _transfers.where((transfer) {
          final recordNumber = transfer.recordNumber?.toLowerCase() ?? '';
          final fromSiteName = transfer.fromSiteName.toLowerCase();
          final toSiteName = transfer.toSiteName.toLowerCase();
          final searchLower = query.toLowerCase();

          return recordNumber.contains(searchLower) ||
              fromSiteName.contains(searchLower) ||
              toSiteName.contains(searchLower);
        }).toList();
      }
    });
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showMaterialTransferForm({MaterialTransfer? transfer}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MaterialTransferForm(
        transfer: transfer,
        currentSiteId: widget.selectedSiteId,
        currentSiteName: widget.selectedSiteName,
        onSave: (savedTransfer) async {
          if (transfer == null) {
            // Add new transfer
            setState(() {
              _transfers.insert(0, savedTransfer);
              _filterTransfers(_searchQuery);
            });
            _showSuccessSnackBar('Material transfer created successfully');
          } else {
            // Update existing transfer
            setState(() {
              final index = _transfers.indexWhere((t) => t.id == transfer.id);
              if (index != -1) {
                _transfers[index] = savedTransfer;
                _filterTransfers(_searchQuery);
              }
            });
            _showSuccessSnackBar('Material transfer updated successfully');
          }
          // Refresh the list from server
          await _loadMaterialTransfers();
        },
        onDelete: (deletedId) {
          setState(() {
            _transfers.removeWhere((t) => t.id == deletedId);
            _filterTransfers(_searchQuery);
          });
          _showSuccessSnackBar('Material transfer deleted successfully');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 80.h,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4a63c0), Color(0xFF3a53b0), Color(0xFF2a43a0)],
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
        title:Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Material Transfer Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4.h),
            Text("Site: ${widget.selectedSiteName ?? 'All Sites'}",
              
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showMaterialTransferForm(),
            icon: Icon(Icons.add, color: Colors.white,size: 28.sp,),
            tooltip: 'Add Material Transfer',
          ),
          IconButton(
            icon:  Icon(Icons.refresh, color: Colors.white,size: 28.sp,),
            onPressed: _loadMaterialTransfers,
            tooltip: 'Refresh',
          ),

          
        ],
      ),
      body: Column(
        children: [
          _buildSearchSection(),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2a43a0)),
                    ),
                  )
                : _filteredTransfers.isEmpty
                ? _buildEmptyState()
                : _buildTransferList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              onChanged: _filterTransfers,
              decoration: InputDecoration(
                hintText: 'Search by record number or site names...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
          // Count
          Text(
            'Total: ${_filteredTransfers.length} transfer${_filteredTransfers.length != 1 ? 's' : ''}',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferList() {
    return RefreshIndicator(
      onRefresh: _loadMaterialTransfers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredTransfers.length,
        itemBuilder: (context, index) {
          final transfer = _filteredTransfers[index];
          return MaterialTransferCard(
            transfer: transfer,
            onEdit: () => _showMaterialTransferForm(transfer: transfer),
            onDelete: () => _showDeleteConfirmation(transfer),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No Material Transfers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Add your first material transfer to get started'
                : 'No transfers found for "$_searchQuery"',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showMaterialTransferForm(),
            child: Text('Add Material Transfer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(MaterialTransfer transfer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Transfer'),
        content: Text(
          'Are you sure you want to delete transfer ${transfer.recordNumber}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final success =
                    await MaterialTransferService.deleteMaterialTransfer(
                      transfer.id!,
                    );
                if (success) {
                  setState(() {
                    _transfers.removeWhere((t) => t.id == transfer.id);
                    _filterTransfers(_searchQuery);
                  });
                  _showSuccessSnackBar(
                    'Material transfer deleted successfully',
                  );
                } else {
                  _showErrorSnackBar('Failed to delete transfer');
                }
              } catch (e) {
                _showErrorSnackBar('Failed to delete transfer: $e');
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class MaterialTransferCard extends StatelessWidget {
  final MaterialTransfer transfer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MaterialTransferCard({
    super.key,
    required this.transfer,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Record Number and Actions
            Row(
              children: [
                Expanded(
                  child: Text(
                    transfer.recordNumber ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2a43a0),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: Color(0xFF2a43a0), size: 20),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  tooltip: 'Edit',
                ),
                SizedBox(width: 9),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  tooltip: 'Delete',
                ),
              ],
            ),
            SizedBox(height: 4),

            // Record Date
            _buildInfoRow('Record Date:', _formatDate(transfer.recordDate)),

            // From Site
            _buildInfoRow('From Site:', transfer.fromSiteName),

            // To Site
            _buildInfoRow('To Site:', transfer.toSiteName),


            // Total Amount
            _buildInfoRow(
              'Total Amount:',
              '₹${transfer.totalAmount ?? '0.00'}',
              isAmount: true,
            ),

            // Status
            if (transfer.status != null) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(transfer.status!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  transfer.status!.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isAmount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isAmount ? FontWeight.bold : FontWeight.normal,
                color: isAmount ? Colors.green : Colors.black87,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color.fromARGB(255, 211, 138, 28);
      case 'completed':
        return const Color.fromARGB(255, 68, 170, 72);
      case 'approved':
        return Color(0xFF2a43a0);
      case 'cancelled':
      case 'rejected':
        return const Color.fromARGB(255, 204, 51, 40);
      default:
        return Colors.grey;
    }
  }
}

class MaterialTransferForm extends StatefulWidget {
  final MaterialTransfer? transfer;
  final Function(MaterialTransfer) onSave;
  final Function(int)? onDelete;
  final int? currentSiteId;
  final String? currentSiteName;
  final int? workspaceId;
  final String? workspaceName;

  const MaterialTransferForm({
    super.key,
    this.transfer,
    required this.onSave,
    this.onDelete,
    this.currentSiteId,
    this.currentSiteName,
    this.workspaceId,
    this.workspaceName,
  });

  @override
  State<MaterialTransferForm> createState() => _MaterialTransferFormState();
}

class _MaterialTransferFormState extends State<MaterialTransferForm> {
  final _formKey = GlobalKey<FormState>();
  late MaterialTransfer _transfer;
  List<TransferItem> _items = [];
  List<Material> _availableMaterials = [];
  List<Site> _sites = [];
  bool _isLoading = false;
  bool _isLoadingFormData = false;
  String? _errorMessage;
  int? _selectedFromSiteId;

  @override
  void initState() {
    super.initState();
    _transfer = widget.transfer ?? MaterialTransfer();
    _items = widget.transfer?.items.toList() ?? [];
    
    // Set from site ID based on current site (for new transfers) or existing transfer
    if (widget.transfer == null && widget.currentSiteId != null) {
      // For new transfer, set from site to current site
      _transfer.fromSiteId = widget.currentSiteId;
    }
    
    _selectedFromSiteId = _transfer.fromSiteId;
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    setState(() {
      _isLoadingFormData = true;
      _errorMessage = null;
    });

    try {
      final formData = await MaterialTransferService.getFormData(
        workspaceId: widget.workspaceId,
      );

      // Get all sites
      List<Site> allSites = formData.sites;

      // Log initial site information
      print('Total sites from API: ${allSites.length}');
      for (var site in allSites) {
        print('Site: ${site.id} - ${site.name}');
      }

      // Filter sites for workspace if workspaceId is provided
      if (widget.workspaceId != null) {
        allSites = allSites
            .where((site) => site.workspace == widget.workspaceId)
            .toList();
        print('Sites after workspace filter (workspace: ${widget.workspaceId}): ${allSites.length}');
      }

      // If no sites found with workspace filter, use all sites
      if (allSites.isEmpty) {
        allSites = formData.sites;
        print('Using all sites (no workspace filter applied)');
      }

      final baseMaterials = formData.materials.values.toList();

      final materials = _selectedFromSiteId != null
          ? await _fetchMaterialsBySite(
              _selectedFromSiteId!,
              fallbackMaterials: baseMaterials,
            )
          : baseMaterials;

      final mergedMaterials = _mergeSelectedMaterials(materials);

      setState(() {
        _sites = allSites;
        _availableMaterials = mergedMaterials;
        _isLoadingFormData = false;
      });

      print('Loaded ${_sites.length} sites for workspace ${widget.workspaceId}');
      print('Loaded ${_availableMaterials.length} materials via form data');
      print('Current fromSiteId: ${_transfer.fromSiteId}');
      print('Current toSiteId: ${_transfer.toSiteId}');
      
      // Log available sites for dropdown
      print('Available sites for To Site dropdown:');
      for (var site in _sites) {
        if (site.id != _transfer.fromSiteId) {
          print('  - ${site.id}: ${site.name}');
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingFormData = false;
        _errorMessage = 'Failed to load form data: $e';
      });
      print('Error loading form data: $e');
    }
  }
  Future<void> _loadMaterialsForSite(int siteId) async {
    try {
      setState(() {
        _isLoadingFormData = true;
      });

      final materials = await _fetchMaterialsBySite(siteId);
      final mergedMaterials = _mergeSelectedMaterials(materials);

      setState(() {
        _availableMaterials = mergedMaterials;
        _isLoadingFormData = false;
      });

      print('Loaded ${_availableMaterials.length} materials for site $siteId via form data');
    } catch (e) {
      setState(() {
        _isLoadingFormData = false;
      });
      print('Error loading materials for site $siteId: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to fetch latest materials. Showing previous list.'),
          ),
        );
      }
    }
  }

  List<Material> _mergeSelectedMaterials(List<Material> materials) {
    final merged = List<Material>.from(materials);
    for (final item in _items) {
      Material? material = item.material;
      if (material == null && item.materialId != null) {
        material = Material(
          id: item.materialId,
          name: 'Material #${item.materialId}',
          price: item.price,
          unit: item.unit != null ? Unit(name: item.unit) : null,
        );
      }

      final materialId = material?.id;
      if (material != null &&
          materialId != null &&
          !merged.any((m) => m.id == materialId)) {
        merged.add(material);
      }
    }
    return merged;
  }

  Future<List<Material>> _fetchMaterialsBySite(
    int siteId, {
    List<Material>? fallbackMaterials,
  }) async {
    try {
      final materials = await MaterialTransferService.getMaterialsBySite(siteId);
      if (materials.isNotEmpty) {
        return materials;
      }
    } catch (e) {
      print('Primary materials fetch failed for site $siteId: $e');
    }

    if (fallbackMaterials != null && fallbackMaterials.isNotEmpty) {
      final filteredFallback =
          fallbackMaterials.where((material) => material.siteId == siteId).toList();
      if (filteredFallback.isNotEmpty) {
        return filteredFallback;
      }
    }

    try {
      final fallbackFormData = await MaterialTransferService.getFormData(
        siteId: siteId,
        workspaceId: widget.workspaceId,
      );
      return fallbackFormData.materials.values.toList();
    } catch (e) {
      print('Fallback form data fetch failed for site $siteId: $e');
    }

    return _availableMaterials;
  }

  void _addItem() {
    setState(() {
      _items.add(TransferItem());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    _calculateTotal();
  }

  void _updateItem(int index, TransferItem item) {
    setState(() {
      _items[index] = item;
    });
    _calculateTotal();
  }

  void _calculateTotal() {
    double total = 0;
    for (var item in _items) {
      if (item.quantity != null && item.price != null) {
        final quantity = double.tryParse(item.quantity!) ?? 0;
        final price = double.tryParse(item.price!) ?? 0;
        total += quantity * price;
      }
    }
    setState(() {
      _transfer.totalAmount = total.toStringAsFixed(2);
    });
  }

  Future<void> _saveTransfer() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Validate items
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one item')),
        );
        return;
      }

      for (var item in _items) {
        if (item.materialId == null || item.quantity == null || item.quantity!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill all item fields')),
          );
          return;
        }
      }

      setState(() {
        _isLoading = true;
      });

      try {
        _transfer.items = _items;
        MaterialTransfer savedTransfer;

        if (_transfer.id == null) {
          savedTransfer = await MaterialTransferService.createMaterialTransfer(_transfer);
        } else {
          savedTransfer = await MaterialTransferService.updateMaterialTransfer(_transfer);
        }

        Navigator.of(context).pop();
        widget.onSave(savedTransfer);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save transfer: $e')),
        );
      }
    }
  }

  void _deleteTransfer() {
    if (_transfer.id != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Transfer'),
          content: const Text('Are you sure you want to delete this transfer?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await MaterialTransferService.deleteMaterialTransfer(_transfer.id!);
                  Navigator.of(context).pop();
                  widget.onDelete?.call(_transfer.id!);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete transfer: $e')),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoadingFormData
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildBasicInfoSection(),
                              const SizedBox(height: 20),
                              _buildItemsSection(),
                              _buildTotalSection(),
                              _buildActionButtons(),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2a43a0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            widget.transfer == null
                ? 'Add Material Transfer'
                : 'Edit Material Transfer',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading form data...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Failed to load form data',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFormData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Record Date
        TextFormField(
          initialValue: _transfer.recordDate ?? DateTime.now().toIso8601String().split('T')[0],
          decoration: const InputDecoration(
            labelText: 'Record Date*',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_today),
          ),
          onTap: () => _selectDate(context),
          readOnly: true,
          onSaved: (value) => _transfer.recordDate = value,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select record date';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        // From Site - Shows current site or selected site
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF2a43a0)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'From Project / Site*',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getFromSiteDisplayName(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // To Site - Shows all sites except the current from site
        DropdownButtonFormField<int>(
          value: _transfer.toSiteId,
          decoration: const InputDecoration(
            labelText: 'To Project / Site*',
            border: OutlineInputBorder(),
          ),
          isExpanded: true,
          items: _getToSiteDropdownItems(),
          onChanged: (value) {
            setState(() {
              _transfer.toSiteId = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Please select to site';
            }
            if (value == _transfer.fromSiteId) {
              return 'To site must be different from from site';
            }
            return null;
          },
        ),
      ],
    );
  }

  List<DropdownMenuItem<int>> _getToSiteDropdownItems() {
    // If no sites loaded, return empty list
    if (_sites.isEmpty) {
      return [];
    }

    // If fromSiteId is null, show all sites
    if (_transfer.fromSiteId == null) {
      return _sites.map((site) {
        return DropdownMenuItem<int>(
          value: site.id,
          child: Text(
            site.name ?? 'Unknown Site',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList();
    }

    // Show all sites except the from site
    return _sites
        .where((site) => site.id != _transfer.fromSiteId)
        .map((site) {
          return DropdownMenuItem<int>(
            value: site.id,
            child: Text(
              site.name ?? 'Unknown Site',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList();
  }

  String _getFromSiteDisplayName() {
    if (_transfer.fromSiteId == null) {
      return widget.currentSiteName ?? 'Not selected';
    }
    
    // Try to find site in the list
    try {
      final fromSite = _sites.firstWhere(
        (site) => site.id == _transfer.fromSiteId,
      );
      return fromSite.name ?? 'Site ${_transfer.fromSiteId}';
    } catch (e) {
      // If not found in list, try to get from current site name
      return widget.currentSiteName ?? 'Site ${_transfer.fromSiteId}';
    }
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Transfer Items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Item'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_items.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'No items added. Click "Add Item" to start.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          )
        else
          ..._items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildItemRow(index, item);
          }).toList(),
      ],
    );
  }

  Widget _buildItemRow(int index, TransferItem item) {
    Material? material;
    if (item.materialId != null) {
      try {
        material = _availableMaterials.firstWhere(
          (m) => m.id == item.materialId,
        );
      } catch (e) {
        material = null;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Item ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  onPressed: () => _removeItem(index),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Material Dropdown with stock information
            DropdownButtonFormField<int>(
              value: material?.id,
              decoration: const InputDecoration(
                labelText: 'Material*',
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              items: _availableMaterials.map((mat) {
                return DropdownMenuItem<int>(
                  value: mat.id,
                  child: Text(
                    '${mat.name ?? 'Unknown'} (₹${mat.price ?? '0.00'}) - Stock: ${mat.totalQty ?? 'N/A'}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (selectedId) {
                if (selectedId != null) {
                  final selectedMaterial = _availableMaterials.firstWhere((m) => m.id == selectedId);
                  final updatedItem = TransferItem(
                    id: item.id,
                    materialTransferId: item.materialTransferId,
                    materialId: selectedMaterial.id,
                    material: selectedMaterial,
                    unit: selectedMaterial.unit?.name ?? 'unit',
                    price: selectedMaterial.price ?? '0.00', // Ensure price is set
                    quantity: item.quantity,
                    subtotal: item.subtotal,
                    receivedAt: item.receivedAt,
                    createdAt: item.createdAt,
                    updatedAt: item.updatedAt,
                  );
                  _updateItem(index, updatedItem);

                  // Recalculate subtotal if quantity exists
                  if (item.quantity != null && item.quantity!.isNotEmpty) {
                    final quantity = double.tryParse(item.quantity!) ?? 0;
                    final price = double.tryParse(selectedMaterial.price ?? '0.00') ?? 0;
                    final subtotal = (quantity * price).toStringAsFixed(2);

                    final updatedItemWithSubtotal = TransferItem(
                      id: item.id,
                      materialTransferId: item.materialTransferId,
                      materialId: selectedMaterial.id,
                      material: selectedMaterial,
                      unit: selectedMaterial.unit?.name ?? 'unit',
                      price: selectedMaterial.price ?? '0.00',
                      quantity: item.quantity,
                      subtotal: subtotal,
                      receivedAt: item.receivedAt,
                      createdAt: item.createdAt,
                      updatedAt: item.updatedAt,
                    );
                    _updateItem(index, updatedItemWithSubtotal);
                  }
                }
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select material';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Quantity and Price Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.quantity,
                    decoration: InputDecoration(
                      labelText: 'Quantity*',
                      border: const OutlineInputBorder(),
                      suffixText: material?.unit?.name ?? 'unit',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        final quantity = double.tryParse(value) ?? 0;
                        final price = double.tryParse(item.price ?? material?.price ?? '0.00') ?? 0;
                        final subtotal = (quantity * price).toStringAsFixed(2);

                        final updatedItem = TransferItem(
                          id: item.id,
                          materialTransferId: item.materialTransferId,
                          materialId: item.materialId,
                          material: item.material,
                          unit: item.unit,
                          price: item.price ?? material?.price ?? '0.00',
                          quantity: value,
                          subtotal: subtotal,
                          receivedAt: item.receivedAt,
                          createdAt: item.createdAt,
                          updatedAt: item.updatedAt,
                        );
                        _updateItem(index, updatedItem);
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter quantity';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      // Check stock availability
                      if (material != null && material.totalQty != null) {
                        final requestedQty = double.tryParse(value) ?? 0;
                        if (requestedQty > material.totalQty!) {
                          return 'Insufficient stock. Available: ${material.totalQty}';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: TextEditingController(text: item.price ?? material?.price ?? '0.00'),
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                      prefixText: '₹',
                    ),
                    readOnly: true,
                    onChanged: (value) {
                      // This shouldn't be called since it's read-only, but just in case
                      if (value.isNotEmpty && item.quantity != null && item.quantity!.isNotEmpty) {
                        final quantity = double.tryParse(item.quantity!) ?? 0;
                        final price = double.tryParse(value) ?? 0;
                        final subtotal = (quantity * price).toStringAsFixed(2);

                        final updatedItem = TransferItem(
                          id: item.id,
                          materialTransferId: item.materialTransferId,
                          materialId: item.materialId,
                          material: item.material,
                          unit: item.unit,
                          price: value,
                          quantity: item.quantity,
                          subtotal: subtotal,
                          receivedAt: item.receivedAt,
                          createdAt: item.createdAt,
                          updatedAt: item.updatedAt,
                        );
                        _updateItem(index, updatedItem);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stock Information
            if (material != null && material.totalQty != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 44, 74, 184).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory, size: 16, color: Color.fromARGB(255, 47, 79, 192)),
                    const SizedBox(width: 8),
                    Text(
                      'Available Stock: ${material.totalQty} ${material.unit?.name ?? 'units'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 44, 74, 180),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),

            // Subtotal
            TextFormField(
              controller: TextEditingController(text: item.subtotal ?? '0.00'),
              decoration: const InputDecoration(
                labelText: 'Subtotal',
                border: OutlineInputBorder(),
                prefixText: '₹',
              ),
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const Text(
            'Total Amount:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            '₹${_transfer.totalAmount ?? '0.00'}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Row(
        children: [
          if (widget.transfer != null) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _deleteTransfer,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Delete'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveTransfer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2a43a0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(widget.transfer == null ? 'Create Transfer' : 'Update Transfer'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _transfer.recordDate = picked.toIso8601String().split('T')[0];
      });
    }
  }
}