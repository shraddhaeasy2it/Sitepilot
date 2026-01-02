import 'package:ecoteam_app/admin/models/manpower_model.dart';
import 'package:ecoteam_app/admin/services/manpower_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ManpowerPage extends StatefulWidget {
  final String? selectedSiteName;
  final int? selectedSiteId;
  
  const ManpowerPage({
    super.key,
    this.selectedSiteName,
    this.selectedSiteId,
  });

  @override
  State<ManpowerPage> createState() => _ManpowerPageState();
}

class _ManpowerPageState extends State<ManpowerPage> {
  final List<ManpowerRecord> _records = [];
  final TextEditingController _searchController = TextEditingController();
  List<ManpowerRecord> _filteredRecords = [];
  final ManpowerService _manpowerService = ManpowerService();
  bool _isLoading = true;
  String _errorMessage = '';
  DropdownData? _dropdownData;
 
  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_filterRecords);
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('Loading dropdown data...');
      
      // Load dropdown data first
      _dropdownData = await _manpowerService.getDropdownData();
      
      // Check if we got any data
      if (_dropdownData!.manpowerTypes.isEmpty && 
          _dropdownData!.suppliers.isEmpty && 
          _dropdownData!.sites.isEmpty) {
        print('Warning: Empty dropdown data received');
        _showErrorSnackbar('No dropdown data available. Using default values.');
      } else {
        print('Dropdown data loaded successfully');
      }

      // Then load manpower records
      await _loadManpowerRecords();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _loadInitialData: $e');
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
      _showErrorSnackbar('Failed to load data: $e');
    }
  }

  Future<void> _loadManpowerRecords() async {
    try {
      final records = await _manpowerService.getManpowerRecords();
      setState(() {
        _records.clear();
        _records.addAll(records);
        
        if (widget.selectedSiteId != null) {
          _records.removeWhere((r) => r.siteId != widget.selectedSiteId);
        }

        _filteredRecords = List.from(_records);
      });
    } catch (e) {
      print('Error loading main records: $e');
      // Try with specific site and workspace if available
      try {
        final records = await _manpowerService.getManpowerRecordsBySiteAndWorkspace(2, 3);
        setState(() {
          _records.clear();
          _records.addAll(records);
          _filteredRecords = List.from(_records);
        });
      } catch (e2) {
        print('Error loading fallback records: $e2');
        // If both fail, show empty state but don't crash
        setState(() {
          _records.clear();
          _filteredRecords = [];
        });
        _showErrorSnackbar('Could not load records. Please try again.');
      }
    }
  }

  void _filterRecords() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredRecords = List.from(_records);
      } else {
        _filteredRecords = _records.where((record) {
          return record.workDate.toLowerCase().contains(query) ||
              record.supplier.toLowerCase().contains(query) ||
              record.site.toLowerCase().contains(query) ||
              (record.totalCount != null &&
                  record.totalCount.toString().contains(query));
        }).toList();
      }
    });
  }


  Future<void> _refreshData() async {
    await _loadInitialData();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Data refreshed')));
  }

  Future<void> _addNewRecord() async {
    if (_dropdownData == null) {
      _showErrorSnackbar('Please wait, loading dropdown data...');
      return;
    }

    final result = await showModalBottomSheet<ManpowerRecord?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        child: ManpowerBottomSheet(
          dropdownData: _dropdownData!,
          onSave: (newRecord) => newRecord,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        final createdRecord = await _manpowerService.createManpowerRecord(
          result,
        );
        setState(() {
          _records.add(createdRecord);
          _filterRecords();
          _isLoading = false;
        });
        _showSuccessSnackbar('Record created successfully');
        await _loadManpowerRecords();
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackbar('Failed to create record: $e');
      }
    }
  }

  Future<void> _editRecord(ManpowerRecord record) async {
    if (_dropdownData == null) {
      _showErrorSnackbar('Please wait, loading dropdown data...');
      return;
    }

    final result = await showModalBottomSheet<ManpowerRecord?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        height:
            MediaQuery.of(context).size.height * 0.85, // 85% of screen height
        child: ManpowerBottomSheet(
          record: record,
          dropdownData: _dropdownData!,
          onSave: (updatedRecord) => updatedRecord,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        final updatedRecord = await _manpowerService.updateManpowerRecord(
          result,
        );
        setState(() {
          final index = _records.indexWhere((r) => r.id == updatedRecord.id);
          if (index != -1) {
            _records[index] = updatedRecord;
          }
          _filterRecords();
          _isLoading = false;
        });
        _showSuccessSnackbar('Record updated successfully');
        await _loadManpowerRecords();
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackbar('Failed to update record: $e');
      }
    }
  }

  Future<void> _viewRecord(ManpowerRecord record) async {
    if (_dropdownData == null) {
      _showErrorSnackbar('Please wait, loading dropdown data...');
      return;
    }

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        child: ManpowerBottomSheet(
          
          record: record,
          dropdownData: _dropdownData!,
          isViewMode: true,
        ),
      ),
    );
  }

  Future<void> _deleteRecord(ManpowerRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text(
          'Are you sure you want to delete the record for ${record.workDate}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _manpowerService.deleteManpowerRecord(record.id!);
        setState(() {
          _records.removeWhere((r) => r.id == record.id);
          _filterRecords();
          _isLoading = false;
        });
        _showSuccessSnackbar('Record deleted successfully');
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackbar('Failed to delete record: $e');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }
  

  @override
  Widget build(BuildContext context) {
    final totalCards = _filteredRecords.length;

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Manpower Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              widget.selectedSiteName != null
                  ? 'Site: ${widget.selectedSiteName}'
                  : 'All Sites',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, size: 28.sp),
            onPressed: _addNewRecord,
            tooltip: 'Add New Record',
          ),
          IconButton(
            icon: Icon(Icons.refresh, size: 28.sp),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
          
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search records...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                // Total Count Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text(
                        'Total Records :',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        totalCards.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2a43a0),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_errorMessage.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Records List
                Expanded(
                  child: _filteredRecords.isEmpty
                      ? const Center(
                          child: Text(
                            'No records found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredRecords.length,
                          itemBuilder: (context, index) {
                            final record = _filteredRecords[index];
                            return _ManpowerCard(
                              record: record,
                              onView: () => _viewRecord(record),
                              onEdit: () => _editRecord(record),
                              onDelete: () => _deleteRecord(record),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _ManpowerCard extends StatelessWidget {
  final ManpowerRecord record;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ManpowerCard({
    required this.record,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onView,
      child: Card(
        margin: const EdgeInsets.only(bottom: 6),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  Text(
                    'Work Date: ${record.workDate}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                   Row(
                    children: [
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(
                          Icons.edit,
                          size: 19,
                          color: Color.fromARGB(255, 19, 55, 187),
                        ),
                      ),
                      
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete,
                          size: 19,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
             
              Text('Supplier: ${record.supplier}'),
              SizedBox(height: 12),
             

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 218, 226, 255),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Total: ${record.totalCount ?? 0}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 26, 51, 141),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (record.createdAt != null)
                        Text(
                          'Updated: ${_formatDate(record.updatedAt ?? record.createdAt!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 143, 143, 143),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
class ManpowerBottomSheet extends StatefulWidget {
  final ManpowerRecord? record;
  final DropdownData dropdownData;
  final Function(ManpowerRecord)? onSave;
  final bool isViewMode;

  const ManpowerBottomSheet({
    super.key,
    this.record,
    required this.dropdownData,
    this.onSave,
    this.isViewMode = false,
  });

  @override
  State<ManpowerBottomSheet> createState() => _ManpowerBottomSheetState();
}

class _ManpowerBottomSheetState extends State<ManpowerBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _dateController;
  late TextEditingController _manpowerTypeController;

  int? _selectedSupplierId;
  int? _selectedSiteId;

  /// Selected manpower type IDs
  final List<int> _selectedTypes = [];

  /// type name -> count
  final Map<String, int> _manpowerCounts = {};

  @override
  void initState() {
    super.initState();

    final record = widget.record;

    _dateController = TextEditingController(
      text: record?.workDate ?? DateTime.now().toString().split(' ')[0],
    );

    _manpowerTypeController = TextEditingController();

    // Validate and set supplier ID
    if (record?.supplierId != null) {
      _selectedSupplierId = _validateAndGetSupplierId(record!.supplierId!);
    }

    // Validate and set site ID
    if (record?.siteId != null) {
      _selectedSiteId = _validateAndGetSiteId(record!.siteId!);
    }

    // Edit Mode – pre-fill manpower types and counts
    if (record != null) {
      for (var entry in record.manpowerCounts.entries) {
        if (entry.value > 0) {
          final id = widget.dropdownData.manpowerTypes.entries
              .firstWhere(
                (e) => e.value == entry.key,
                orElse: () => const MapEntry(-1, ''),
              )
              .key;

          if (id != -1) {
            _selectedTypes.add(id);
            _manpowerCounts[entry.key] = entry.value;
          }
        }
      }

      _updateSelectedText();
    }
    
    // Debug print
    _debugDropdownValues();
  }

  void _debugDropdownValues() {
    print('=== DEBUG DROPDOWN VALUES ===');
    print('Supplier ID from record: ${widget.record?.supplierId}');
    print('Site ID from record: ${widget.record?.siteId}');
    print('Selected Supplier ID: $_selectedSupplierId');
    print('Selected Site ID: $_selectedSiteId');
    
    print('Available Supplier IDs: ${widget.dropdownData.suppliers.keys.toList()}');
    print('Available Site IDs: ${widget.dropdownData.sites.keys.toList()}');
    
    print('Is supplier ID valid: ${widget.dropdownData.suppliers.containsKey(_selectedSupplierId)}');
    print('Is site ID valid: ${widget.dropdownData.sites.containsKey(_selectedSiteId)}');
    print('=== END DEBUG ===');
  }

  /// Validate supplier ID and return a valid one
  int? _validateAndGetSupplierId(int originalId) {
    if (widget.dropdownData.suppliers.containsKey(originalId)) {
      return originalId;
    } else {
      print('Warning: Supplier ID $originalId not found in dropdown data');
      // Return the first available supplier ID or null
      if (widget.dropdownData.suppliers.isNotEmpty) {
        final firstId = widget.dropdownData.suppliers.keys.first;
        print('Falling back to first supplier ID: $firstId');
        return firstId;
      }
      return null;
    }
  }

  /// Validate site ID and return a valid one
  int? _validateAndGetSiteId(int originalId) {
    if (widget.dropdownData.sites.containsKey(originalId)) {
      return originalId;
    } else {
      print('Warning: Site ID $originalId not found in dropdown data');
      // Return the first available site ID or null
      if (widget.dropdownData.sites.isNotEmpty) {
        final firstId = widget.dropdownData.sites.keys.first;
        print('Falling back to first site ID: $firstId');
        return firstId;
      }
      return null;
    }
  }

  /// Update the text shown in the manpower type field
  void _updateSelectedText() {
    final types = widget.dropdownData.manpowerTypes;
    _manpowerTypeController.text =
        _selectedTypes.map((id) => types[id] ?? 'Unknown').join(", ");
  }

  /// Open multiple select bottom sheet
  void _selectManpowerTypes() async {
    final manpowerTypes = widget.dropdownData.manpowerTypes;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text("Select Manpower Types"),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Done", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                body: ListView(
                  padding: const EdgeInsets.all(16),
                  children: manpowerTypes.entries.map((e) {
                    return Row(
                      children: [
                        Checkbox(
                          value: _selectedTypes.contains(e.key),
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selectedTypes.add(e.key);
                                _manpowerCounts[e.value] = _manpowerCounts[e.value] ?? 0;
                              } else {
                                _selectedTypes.remove(e.key);
                                _manpowerCounts.remove(e.value);
                              }
                            });
                            _updateSelectedText();
                          },
                        ),
                        Expanded(child: Text(e.value)),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            enabled: _selectedTypes.contains(e.key),
                            decoration: const InputDecoration(hintText: 'Count'),
                            controller: TextEditingController(
                              text: _manpowerCounts[e.value]?.toString() ?? '',
                            ),
                            onChanged: (v) {
                              setState(() {
                                _manpowerCounts[e.value] = int.tryParse(v) ?? 0;
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _calculateTotalCount() =>
      _manpowerCounts.values.fold(0, (sum, c) => sum + c);

  void _saveRecord() {
    if (_formKey.currentState!.validate()) {
      final rec = ManpowerRecord(
        id: widget.record?.id,
        workDate: _dateController.text,
        supplier: widget.dropdownData.suppliers[_selectedSupplierId] ?? '',
        site: widget.dropdownData.sites[_selectedSiteId] ?? '',
        manpowerCounts: Map.from(_manpowerCounts),
        siteId: _selectedSiteId,
        supplierId: _selectedSupplierId,
        workspaceId: widget.record?.workspaceId ?? 1,
        createdBy: widget.record?.createdBy ?? 1,
        totalCount: _calculateTotalCount(),
      );

      widget.onSave?.call(rec);
      Navigator.pop(context, rec);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = widget.dropdownData.suppliers;
    final sites = widget.dropdownData.sites;
    final manpowerTypes = widget.dropdownData.manpowerTypes;

    if (widget.isViewMode) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("View Manpower"),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(14),
          children: [
           
            // Work Date
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Color(0xFF2a43a0)),
              title: const Text("Work Date"),
              subtitle: Text(_dateController.text),
            ),
            const SizedBox(height: 2),

            // Supplier
            ListTile(
              leading: const Icon(Icons.business, color: Color(0xFF2a43a0)),
              title: const Text("Supplier"),
              subtitle: Text(suppliers[_selectedSupplierId] ?? 'N/A'),
            ),
            const SizedBox(height: 2),

            // Site
            ListTile(
              leading: const Icon(Icons.location_on, color: Color(0xFF2a43a0)),
              title: const Text("Site"),
              subtitle: Text(sites[_selectedSiteId] ?? 'N/A'),
            ),
            const SizedBox(height: 6),
            Container(
              height: 1,
              color: const Color.fromARGB(255, 184, 184, 184),
            ),
            const SizedBox(height: 8),
            // Manpower Types
            const Text(
              "Manpower Types",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._selectedTypes.map((typeId) {
              final typeName = manpowerTypes[typeId]!;
              final count = _manpowerCounts[typeName] ?? 0;
              return ListTile(
                leading: const Icon(Icons.people, color: Color(0xFF2a43a0)),
                title: Text(typeName),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2a43a0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Count: $count',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2a43a0),
                    ),
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 20),

            // Total
            Card(
              elevation: 2,
              color: Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Manpower:",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _calculateTotalCount().toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2a43a0),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.record == null ? "Create Manpower" : "Edit Manpower"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date
            TextFormField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: "Work Date",
                prefixIcon: Icon(Icons.calendar_month),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return "Date required";
                try {
                  DateTime.parse(v);
                } catch (_) {
                  return "Invalid date format (YYYY-MM-DD)";
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Supplier - UPDATED with null safety
            DropdownButtonFormField<int>(
              value: _selectedSupplierId,
              decoration: const InputDecoration(
                labelText: "Supplier",
                border: OutlineInputBorder(),
              ),
              items: _buildSupplierItems(),
              onChanged: (v) => setState(() => _selectedSupplierId = v),
              validator: (v) => v == null ? "Select supplier" : null,
            ),
            const SizedBox(height: 12),

            // Site - UPDATED with null safety
            DropdownButtonFormField<int>(
              value: _selectedSiteId,
              decoration: const InputDecoration(
                labelText: "Site",
                border: OutlineInputBorder(),
              ),
              items: _buildSiteItems(),
              onChanged: (v) => setState(() => _selectedSiteId = v),
              validator: (v) => v == null ? "Select site" : null,
            ),

            const SizedBox(height: 20),

            // ------------------ MANPOWER TYPE FIELD (Tap to multi-select) ------------------
            TextFormField(
              controller: _manpowerTypeController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Manpower Types",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              onTap: _selectManpowerTypes,
              validator: (_) =>
                  _selectedTypes.isEmpty ? "Select at least one type" : null,
            ),

            const SizedBox(height: 20),

            // Total
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Manpower:",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    _calculateTotalCount().toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2a43a0),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: _saveRecord,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(12),
                backgroundColor: const Color(0xFF2a43a0),
                foregroundColor: Colors.white,
              ),
              child: Text(
                widget.record == null ? "Create Record" : "Update Record",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Build supplier dropdown items with validation
  List<DropdownMenuItem<int>> _buildSupplierItems() {
    final suppliers = widget.dropdownData.suppliers;
    final items = <DropdownMenuItem<int>>[];
    
    // Add a null item first for "Select"
    items.add(
      const DropdownMenuItem<int>(
        value: null,
        child: Text('Select Supplier', style: TextStyle(color: Colors.grey)),
      ),
    );
    
    // Add all valid supplier items
    suppliers.entries.forEach((entry) {
      items.add(
        DropdownMenuItem<int>(
          value: entry.key,
          child: Text(entry.value),
        ),
      );
    });
    
    // If the current selected value is not in the list (invalid), 
    // we need to handle it specially
    if (_selectedSupplierId != null && !suppliers.containsKey(_selectedSupplierId)) {
      print('Current supplier ID $_selectedSupplierId is not in dropdown, adding as disabled option');
      items.add(
        DropdownMenuItem<int>(
          value: _selectedSupplierId,
          enabled: false,
          child: Text('Invalid Supplier (ID: $_selectedSupplierId)', 
              style: const TextStyle(color: Colors.red, fontStyle: FontStyle.italic)),
        ),
      );
    }
    
    return items;
  }

  // Build site dropdown items with validation
  List<DropdownMenuItem<int>> _buildSiteItems() {
    final sites = widget.dropdownData.sites;
    final items = <DropdownMenuItem<int>>[];
    
    // Add a null item first for "Select"
    items.add(
      const DropdownMenuItem<int>(
        value: null,
        child: Text('Select Site', style: TextStyle(color: Colors.grey)),
      ),
    );
    
    // Add all valid site items
    sites.entries.forEach((entry) {
      items.add(
        DropdownMenuItem<int>(
          value: entry.key,
          child: Text(entry.value),
        ),
      );
    });
    
    // If the current selected value is not in the list (invalid), 
    // we need to handle it specially
    if (_selectedSiteId != null && !sites.containsKey(_selectedSiteId)) {
      print('Current site ID $_selectedSiteId is not in dropdown, adding as disabled option');
      items.add(
        DropdownMenuItem<int>(
          value: _selectedSiteId,
          enabled: false,
          child: Text('Invalid Site (ID: $_selectedSiteId)', 
              style: const TextStyle(color: Colors.red, fontStyle: FontStyle.italic)),
        ),
      );
    }
    
    return items;
  }
}