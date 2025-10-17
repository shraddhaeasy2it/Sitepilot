import 'package:ecoteam_app/admin/models/consumptionLog_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ConsumptionLogPage extends StatefulWidget {
  const ConsumptionLogPage({super.key});

  @override
  State<ConsumptionLogPage> createState() => _ConsumptionLogPageState();
}

class _ConsumptionLogPageState extends State<ConsumptionLogPage> {
  List<Consumption> consumptions = [];
  final List<Consumption> _allConsumptions = [
    Consumption(
      id: 1,
      consumptionNo: 'DCM-0010',
      consumptionDate: DateTime(2025, 10, 6),
      consumptionType: 'fuel',
      site: 'Vijay Residency',
      consumptionFile: 'N/A',
      items: [
        ConsumptionItem(material: 'Diesel', quantity: 50, unit: 'liters', price: 85.5),
      ],
    ),
    Consumption(
      id: 2,
      consumptionNo: 'DCM-0009',
      consumptionDate: DateTime(2025, 10, 7),
      consumptionType: 'all',
      site: 'LandMark Towers',
      consumptionFile: 'N/A',
      items: [
        ConsumptionItem(material: 'Cement', quantity: 100, unit: 'kg', price: 420),
        ConsumptionItem(material: 'Steel Rods', quantity: 50, unit: 'kg', price: 65),
      ],
    ),
    Consumption(
      id: 3,
      consumptionNo: 'DCM-0008',
      consumptionDate: DateTime(2025, 10, 8),
      consumptionType: 'fuel',
      site: 'Nisarg Residency',
      consumptionFile: 'N/A',
      items: [
        ConsumptionItem(material: 'Petrol', quantity: 30, unit: 'liters', price: 96.7),
      ],
    ),
    Consumption(
      id: 4,
      consumptionNo: 'DCM-0007',
      consumptionDate: DateTime(2025, 10, 9),
      consumptionType: 'all',
      site: 'LandMark Towers',
      consumptionFile: 'N/A',
      items: [
        ConsumptionItem(material: 'Bricks', quantity: 500, unit: 'pieces', price: 2500),
      ],
    ),
    Consumption(
      id: 5,
      consumptionNo: 'DCM-0006',
      consumptionDate: DateTime(2025, 10, 10),
      consumptionType: 'fuel',
      site: 'Easy2IT SEO',
      consumptionFile: 'N/A',
    ),
    Consumption(
      id: 6,
      consumptionNo: 'DCM-0005',
      consumptionDate: DateTime(2025, 10, 11),
      consumptionType: 'all',
      site: 'Vijay Residency',
      consumptionFile: 'N/A',
    ),
  ];

  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Fuel', 'All Material'];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConsumptions();
  }

  void _loadConsumptions() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      consumptions = _allConsumptions;
      _isLoading = false;
    });
  }

  void _filterConsumptions(String type) {
    setState(() {
      _selectedFilter = type;
      if (type == 'All') {
        consumptions = _allConsumptions;
      } else if (type == 'Fuel') {
        consumptions = _allConsumptions.where((c) => c.consumptionType == 'fuel').toList();
      } else if (type == 'All Material') {
        consumptions = _allConsumptions.where((c) => c.consumptionType == 'all').toList();
      }
    });
  }

  void _addConsumption() async {
    final result = await showModalBottomSheet<Consumption>(
  context: context,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  builder: (context) => Container(
    height: MediaQuery.of(context).size.height * 0.8, // 60% of screen height
    child: Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: ConsumptionFormSheet(),
    ),
  ),
);

    if (result != null) {
      setState(() {
        _allConsumptions.insert(0, result);
        _filterConsumptions(_selectedFilter);
      });
      _showSuccessSnackBar('Consumption ${result.consumptionNo} added successfully');
    }
  }

  void _editConsumption(Consumption consumption) async {
    final result = await showModalBottomSheet<Consumption>(
  context: context,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  builder: (context) => Container(
    height: MediaQuery.of(context).size.height * 0.8, // 60% of screen height
    child: Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: ConsumptionFormSheet(),
    ),
  ),
);
    if (result != null) {
      setState(() {
        final index = _allConsumptions.indexWhere((c) => c.id == consumption.id);
        if (index != -1) {
          _allConsumptions[index] = result;
          _filterConsumptions(_selectedFilter);
        }
      });
      _showSuccessSnackBar('Consumption ${result.consumptionNo} updated successfully');
    }
  }

  void _deleteConsumption(Consumption consumption) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Consumption',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to delete ${consumption.consumptionNo}?',
              style: const TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _allConsumptions.removeWhere((c) => c.id == consumption.id);
                  _filterConsumptions(_selectedFilter);
                });
                Navigator.of(context).pop();
                _showSuccessSnackBar('Consumption ${consumption.consumptionNo} deleted');
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Manage Consumption Log',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white)),
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
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadConsumptions,
          ),
          IconButton(onPressed:_addConsumption , icon: Icon(Icons.add)),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // Search Bar
                Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search consumption logs...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          Container(height: 1, color: Colors.grey.shade200),
          
          // Filter Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.white,
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => _filterConsumptions(filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade50 : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Divider
          Container(height: 1, color: Colors.grey.shade200),

          // Consumption List
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : consumptions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(0),
                        itemCount: consumptions.length,
                        itemBuilder: (context, index) {
                          final consumption = consumptions[index];
                          return ConsumptionCard(
                            consumption: consumption,
                            onEdit: () => _editConsumption(consumption),
                            onDelete: () => _deleteConsumption(consumption),
                            isLast: index == consumptions.length - 1,
                          );
                        },
                      ),
          ),
          
          // Pagination Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Page 1 of 1',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${consumptions.length} items total',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading consumption logs...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No consumption logs found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a new consumption log to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

class ConsumptionCard extends StatelessWidget {
  final Consumption consumption;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isLast;

  const ConsumptionCard({
    super.key,
    required this.consumption,
    required this.onEdit,
    required this.onDelete,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isFuel = consumption.consumptionType == 'fuel';
    final totalItems = consumption.items?.length ?? 0;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast 
              ? BorderSide.none 
              : BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        consumption.consumptionNo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(consumption.consumptionDate),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFuel ? Colors.orange.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isFuel ? Colors.orange.shade200 : Colors.green.shade200,
                        ),
                      ),
                      child: Text(
                        isFuel ? 'FUEL' : 'MATERIAL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isFuel ? Colors.orange.shade700 : Colors.green.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Action Menu
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade600),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              const Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red.shade600),
                              const SizedBox(width: 8),
                              const Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Site Information
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    consumption.site,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Items Information
            if (totalItems > 0) ...[
              Row(
                children: [
                  Icon(Icons.inventory_2, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    '$totalItems item${totalItems > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Item List
              ...consumption.items!.take(2).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.material,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Text(
                      '${item.quantity} ${item.unit}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),
              if (totalItems > 2) ...[
                const SizedBox(height: 4),
                Text(
                  '+ ${totalItems - 2} more items',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],

            // File Attachment
            if (consumption.consumptionFile != 'N/A') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_file, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    consumption.consumptionFile,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

// ConsumptionFormSheet for bottom sheet
class ConsumptionFormSheet extends StatefulWidget {
  final Consumption? consumption;

  const ConsumptionFormSheet({super.key, this.consumption});

  @override
  State<ConsumptionFormSheet> createState() => _ConsumptionFormSheetState();
}

class _ConsumptionFormSheetState extends State<ConsumptionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final List<ConsumptionItem> _items = [];

  // Form controllers
  final TextEditingController _consumptionNoController = TextEditingController();
  final TextEditingController _consumptionDateController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  String _selectedConsumptionType = 'All Material';
  String _selectedSite = 'Select Site';
  String? _selectedMaterial;
  final TextEditingController _quantityController = TextEditingController();
  String _selectedUnit = 'unit';

  final List<String> _consumptionTypes = ['All Material', 'Fuel'];
  final List<String> _sites = [
    'Select Site',
    'Vijay Residency',
    'Nisarg Residency',
    'LandMark Towers',
    'Easy2IT SEO'

    
  ];
  final List<String> _materials = [
    'Select Material',
    'Material 1',
    'Material 2',
    'Material 3',
    'Material 4'
  ];
  final List<String> _units = ['unit', 'kg', 'liters', 'pieces'];

  @override
  void initState() {
    super.initState();
    if (widget.consumption != null) {
      // Edit mode - populate fields
      final consumption = widget.consumption!;
      _consumptionNoController.text = consumption.consumptionNo;
      _consumptionDateController.text = _formatDate(consumption.consumptionDate);
      _selectedConsumptionType = consumption.consumptionType == 'fuel' ? 'Fuel' : 'All Material';
      _selectedSite = consumption.site;
      _remarksController.text = consumption.remarks ?? '';
      if (consumption.items != null) {
        _items.addAll(consumption.items!);
      }
    } else {
      // Add mode - set default values
      _consumptionNoController.text = 'DCM-0011';
      _consumptionDateController.text = _formatDate(DateTime(2025, 10, 17));
    }
  }

  @override
  void dispose() {
    _consumptionNoController.dispose();
    _consumptionDateController.dispose();
    _remarksController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _addItem() {
    if (_selectedMaterial == null || _selectedMaterial == 'Select Material' || _quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select material and enter quantity')),
      );
      return;
    }

    setState(() {
      _items.add(ConsumptionItem(
        material: _selectedMaterial!,
        quantity: double.parse(_quantityController.text),
        unit: _selectedUnit,
      ));

      // Reset item fields
      _selectedMaterial = 'Select Material';
      _quantityController.clear();
      _selectedUnit = 'unit';
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _selectedSite != 'Select Site') {
      final consumption = Consumption(
        id: widget.consumption?.id ?? DateTime.now().millisecondsSinceEpoch,
        consumptionNo: _consumptionNoController.text,
        consumptionDate: _parseDate(_consumptionDateController.text),
        consumptionType: _selectedConsumptionType.toLowerCase().contains('fuel') ? 'fuel' : 'all',
        site: _selectedSite,
        consumptionFile: 'N/A',
        remarks: _remarksController.text.isEmpty ? null : _remarksController.text,
        items: _items.isEmpty ? null : _items,
      );

      Navigator.pop(context, consumption);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
    }
  }

  DateTime _parseDate(String dateString) {
    final parts = dateString.split('/');
    return DateTime(int.parse(parts[2]), int.parse(parts[0]), int.parse(parts[1]));
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _parseDate(_consumptionDateController.text),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _consumptionDateController.text = _formatDate(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.consumption != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 2,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isEdit ? 'Edit Consumption' : 'Add Consumption',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Consumption Number
                  TextFormField(
                    controller: _consumptionNoController,
                    decoration: const InputDecoration(
                      labelText: 'Consumption Number *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 14),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter consumption number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Consumption Type
                  DropdownButtonFormField<String>(
                    value: _selectedConsumptionType,
                    decoration: const InputDecoration(
                      labelText: 'Consumption Type *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 14),
                    items: _consumptionTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedConsumptionType = newValue!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select consumption type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Consumption Date
                  TextFormField(
                    controller: _consumptionDateController,
                    decoration: const InputDecoration(
                      labelText: 'Consumption Date *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      suffixIcon: Icon(Icons.calendar_today),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 14),
                    readOnly: true,
                    onTap: _selectDate,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select consumption date';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Site
                  DropdownButtonFormField<String>(
                    value: _selectedSite,
                    decoration: const InputDecoration(
                      labelText: 'Site *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 14),
                    items: _sites.map((String site) {
                      return DropdownMenuItem<String>(
                        value: site,
                        child: Text(site),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSite = newValue!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value == 'Select Site') {
                        return 'Please select a site';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Material Selection
                  const Text(
                    'Consumption Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: _selectedMaterial,
                    decoration: const InputDecoration(
                      labelText: 'Material',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 14),
                    items: _materials.map((String material) {
                      return DropdownMenuItem<String>(
                        value: material,
                        child: Text(material),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedMaterial = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  // Quantity and Unit
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          style: const TextStyle(fontSize: 14),
                          items: _units.map((String unit) {
                            return DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedUnit = newValue!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Add Item Button
                  SizedBox(
                    width: 50,
                    child: ElevatedButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: const Color.fromARGB(255, 25, 53, 210),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Added Items List
                  if (_items.isNotEmpty) ...[
                    const Text(
                      'Added Items:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: ListTile(
                          dense: true,
                          title: Text(item.material, style: const TextStyle(fontSize: 14)),
                          subtitle: Text('${item.quantity} ${item.unit}', style: const TextStyle(fontSize: 12)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => _removeItem(index),
                          ),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 10),

                  // Remarks
                  TextFormField(
                    controller: _remarksController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Remarks',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2a43a0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(isEdit ? 'Update' : 'Add', style: const TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

// AddEditConsumptionPage remains the same as in previous code...
class AddEditConsumptionPage extends StatefulWidget {
  final Consumption? consumption;

  const AddEditConsumptionPage({super.key, this.consumption});

  @override
  State<AddEditConsumptionPage> createState() => _AddEditConsumptionPageState();
}

class _AddEditConsumptionPageState extends State<AddEditConsumptionPage> {
  final _formKey = GlobalKey<FormState>();
  final List<ConsumptionItem> _items = [];

  // Form controllers
  final TextEditingController _consumptionNoController = TextEditingController();
  final TextEditingController _consumptionDateController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  String _selectedConsumptionType = 'All Material';
  String _selectedSite = 'Select Site';
  String? _selectedMaterial;
  final TextEditingController _quantityController = TextEditingController();
  String _selectedUnit = 'unit';

  final List<String> _consumptionTypes = ['All Material', 'Fuel'];
  final List<String> _sites = [
    'Select Site',
    'Vijay Residency',
    'LandMark Towers',
    'Nisarg Residency',
    'Easy2IT SEO'
  ];
  final List<String> _materials = [
    'Select Material',
    'Material 1',
    'Material 2',
    'Material 3',
    'Material 4'
  ];
  final List<String> _units = ['unit', 'kg', 'liters', 'pieces'];

  @override
  void initState() {
    super.initState();
    if (widget.consumption != null) {
      // Edit mode - populate fields
      final consumption = widget.consumption!;
      _consumptionNoController.text = consumption.consumptionNo;
      _consumptionDateController.text = _formatDate(consumption.consumptionDate);
      _selectedConsumptionType = consumption.consumptionType == 'fuel' ? 'Fuel' : 'All Material';
      _selectedSite = consumption.site;
      _remarksController.text = consumption.remarks ?? '';
    } else {
      // Add mode - set default values
      _consumptionNoController.text = 'DCM-0011';
      _consumptionDateController.text = _formatDate(DateTime(2025, 10, 17));
    }
  }

  @override
  void dispose() {
    _consumptionNoController.dispose();
    _consumptionDateController.dispose();
    _remarksController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _addItem() {
    if (_selectedMaterial == null || _selectedMaterial == 'Select Material' || _quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select material and enter quantity')),
      );
      return;
    }

    setState(() {
      _items.add(ConsumptionItem(
        material: _selectedMaterial!,
        quantity: double.parse(_quantityController.text),
        unit: _selectedUnit,
      ));
      
      // Reset item fields
      _selectedMaterial = 'Select Material';
      _quantityController.clear();
      _selectedUnit = 'unit';
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _selectedSite != 'Select Site') {
      final consumption = Consumption(
        id: widget.consumption?.id ?? DateTime.now().millisecondsSinceEpoch,
        consumptionNo: _consumptionNoController.text,
        consumptionDate: _parseDate(_consumptionDateController.text),
        consumptionType: _selectedConsumptionType.toLowerCase().contains('fuel') ? 'fuel' : 'all',
        site: _selectedSite,
        consumptionFile: 'N/A',
        remarks: _remarksController.text.isEmpty ? null : _remarksController.text,
        items: _items.isEmpty ? null : _items,
      );

      Navigator.pop(context, consumption);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
    }
  }

  DateTime _parseDate(String dateString) {
    final parts = dateString.split('/');
    return DateTime(int.parse(parts[2]), int.parse(parts[0]), int.parse(parts[1]));
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _parseDate(_consumptionDateController.text),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _consumptionDateController.text = _formatDate(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.consumption != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Consumption' : 'Create Consumption Log'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Consumption Number
              _buildFormField(
                'Consumption Number *',
                TextFormField(
                  controller: _consumptionNoController,
                  decoration: const InputDecoration(
                    hintText: 'Enter consumption number',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter consumption number';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Consumption Type
              _buildFormField(
                'Consumption Type *',
                DropdownButtonFormField<String>(
                  value: _selectedConsumptionType,
                  items: _consumptionTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedConsumptionType = newValue!;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Select consumption type',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select consumption type';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Consumption Date
              _buildFormField(
                'Consumption Date *',
                TextFormField(
                  controller: _consumptionDateController,
                  decoration: const InputDecoration(
                    hintText: 'MM/DD/YYYY',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: _selectDate,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select consumption date';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Site
              _buildFormField(
                'Site *',
                DropdownButtonFormField<String>(
                  value: _selectedSite,
                  items: _sites.map((String site) {
                    return DropdownMenuItem<String>(
                      value: site,
                      child: Text(site),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSite = newValue!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value == 'Select Site') {
                      return 'Please select a site';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Reference File Section
              const Text(
                'Reference File',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  // File picker implementation would go here
                },
                icon: const Icon(Icons.attach_file),
                label: const Text('Choose File'),
              ),
              const SizedBox(height: 4),
              const Text(
                'No file chosen',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 4),
              const Text(
                'Allowed: pdf, jpg, jpeg, png, doc, docx',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),

              const SizedBox(height: 24),

              // Consumption Details Section
              const Text(
                'Consumption Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Material Selection
              const Text(
                'MATERIAL',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: _selectedMaterial,
                items: _materials.map((String material) {
                  return DropdownMenuItem<String>(
                    value: material,
                    child: Text(material),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedMaterial = newValue;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select Material',
                ),
              ),

              const SizedBox(height: 16),

              // Quantity and Unit
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'QUANTITY',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      items: _units.map((String unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedUnit = newValue!;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'UNIT',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Add Item Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade700,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Added Items List
              if (_items.isNotEmpty) ...[
                const Text(
                  'Added Items:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(item.material),
                      subtitle: Text('${item.quantity} ${item.unit}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeItem(index),
                      ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 24),

              // Remarks
              const Text(
                'REMARKS',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _remarksController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter remarks...',
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(isEdit ? 'Update' : 'Create'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }
}