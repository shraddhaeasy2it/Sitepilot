import 'package:ecoteam_app/admin/models/manpower_model.dart';
import 'package:ecoteam_app/admin/services/manpower_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ManpowerPage extends StatefulWidget {
  const ManpowerPage({super.key});

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
    _filteredRecords = _records;
    _searchController.addListener(_filterRecords);
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load dropdown data first
      _dropdownData = await _manpowerService.getDropdownData();

      // Then load manpower records
      await _loadManpowerRecords();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
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
        _filteredRecords = _records;
      });
    } catch (e) {
      throw Exception('Failed to load records: $e');
    }
  }

  void _filterRecords() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredRecords = _records;
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
        title: const Text(
          'Manpower Management',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewRecord,
            tooltip: 'Add New Record',
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
              Text(
                'Work Date: ${record.workDate}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text('Supplier: ${record.supplier}'),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Site: ${record.site}'),
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
              const SizedBox(height: 8),

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

              const SizedBox(height: 12),
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
  final Map<String, TextEditingController> _controllers = {};
  late TextEditingController _dateController;

  late int? _selectedSupplierId;
  late int? _selectedSiteId;
  final Map<String, int> _manpowerCounts = {};

  @override
  void initState() {
    super.initState();

    // Initialize with existing record or default values
    final record = widget.record;

    // Initialize date controller
    _dateController = TextEditingController(
      text: record?.workDate ?? DateTime.now().toString().split(' ')[0],
    );

    // Initialize supplier and site selections
    _selectedSupplierId =
        (record?.supplierId != null &&
            widget.dropdownData.suppliers.containsKey(record!.supplierId))
        ? record!.supplierId
        : null;
    _selectedSiteId =
        (record?.siteId != null &&
            widget.dropdownData.sites.containsKey(record!.siteId))
        ? record!.siteId
        : null;

    // Initialize all manpower counts from API data
    for (var typeEntry in widget.dropdownData.manpowerTypes.entries) {
      final typeName = typeEntry.value;
      _controllers[typeName] = TextEditingController(
        text: (record?.manpowerCounts[typeName] ?? 0).toString(),
      );
      _manpowerCounts[typeName] = record?.manpowerCounts[typeName] ?? 0;
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _saveRecord() {
    if (_formKey.currentState!.validate()) {
      // Update manpower counts from controllers
      _controllers.forEach((role, controller) {
        _manpowerCounts[role] = int.tryParse(controller.text) ?? 0;
      });

      final record = ManpowerRecord(
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

      widget.onSave?.call(record);
      Navigator.of(context).pop(record);
    }
  }

  int _calculateTotalCount() {
    return _manpowerCounts.values.fold(0, (sum, count) => sum + count);
  }

  Widget _buildManpowerField(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: _controllers[title],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                isDense: true,
              ),
              validator: (value) {
                if (value != null &&
                    value.isNotEmpty &&
                    int.tryParse(value) == null) {
                  return 'Invalid number';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildViewContent() {
    final record = widget.record!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manpower Details'),
        backgroundColor: const Color.fromARGB(255, 229, 233, 250),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color.fromARGB(255, 8, 8, 8)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Basic Info Section
          _buildSectionHeader('Basic Information'),
          _buildInfoCard(record),

          const SizedBox(height: 20),

          // Manpower Section
          _buildSectionHeader('Team Composition'),
          _buildManpowerCard(record),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoCard(ManpowerRecord record) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSimpleInfoRow('Date', record.workDate),
            const Divider(height: 20),
            _buildSimpleInfoRow('Supplier', record.supplier),
            const Divider(height: 20),
            _buildSimpleInfoRow('Site', record.site),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildManpowerCard(ManpowerRecord record) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Manpower Items
            ...record.manpowerCounts.entries
                .where((e) => e.value > 0)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildSimpleManpowerRow(entry.key, entry.value),
                  ),
                )
                .toList(),

            // Total
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Workforce',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${record.totalCount ?? 0}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2a43a0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleManpowerRow(String role, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            role,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
        SizedBox(width: 5),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2a43a0),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isViewMode) {
      return _buildViewContent();
    }

    final manpowerTypes = widget.dropdownData.manpowerTypes;
    final suppliers = widget.dropdownData.suppliers;
    final sites = widget.dropdownData.sites;

    // Group manpower types into chunks of 4 for grid layout
    final typeEntries = manpowerTypes.entries.toList();
    final List<List<MapEntry<int, String>>> typeChunks = [];
    for (int i = 0; i < typeEntries.length; i += 4) {
      typeChunks.add(
        typeEntries.sublist(
          i,
          i + 4 > typeEntries.length ? typeEntries.length : i + 4,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
        ),
        title: Text(
          widget.record == null
              ? 'Create Manpower Record'
              : 'Edit Manpower Record',
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Work Date
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Work Date*',
                  border: OutlineInputBorder(),
                  hintText: 'YYYY-MM-DD',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Work Date is required';
                  }
                  try {
                    DateTime.parse(value);
                  } catch (e) {
                    return 'Please use YYYY-MM-DD format';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Supplier Dropdown
              DropdownButtonFormField<int>(
                value: _selectedSupplierId,
                decoration: const InputDecoration(
                  labelText: 'Supplier*',
                  border: OutlineInputBorder(),
                ),
                items: suppliers.entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSupplierId = value!;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a supplier';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Site Dropdown
              DropdownButtonFormField<int>(
                value: _selectedSiteId,
                decoration: const InputDecoration(
                  labelText: 'Site*',
                  border: OutlineInputBorder(),
                ),
                items: sites.entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSiteId = value!;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a site';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              const Text(
                'Manpower Counts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Manpower Counts Grid
              ...typeChunks.map((chunk) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 3,
                    children: chunk.map((entry) {
                      return _buildManpowerField(entry.value);
                    }).toList(),
                  ),
                );
              }),

              const SizedBox(height: 20),

              // Total Count Display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Manpower:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

              const SizedBox(height: 20),

              // Save Button
              ElevatedButton(
                onPressed: _saveRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2a43a0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  widget.record == null ? 'Create Record' : 'Update Record',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
