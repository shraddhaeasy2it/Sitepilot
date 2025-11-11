import 'package:ecoteam_app/admin/models/consumptionLog_model.dart';
import 'package:ecoteam_app/admin/models/Allmachinery_model.dart';
import 'package:ecoteam_app/admin/models/project_site_model.dart';
import 'package:ecoteam_app/admin/models/tools_model.dart';
import 'package:ecoteam_app/admin/provider/project_site_provider.dart';
import 'package:ecoteam_app/admin/services/Allmachinery_services.dart';
import 'package:ecoteam_app/admin/services/tools_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

class MaterialModel {
  final int id;
  final String name;
  final Unit? unit;
  final int? categoryId;
  final String? category;

  MaterialModel({
    required this.id,
    required this.name,
    this.unit,
    this.categoryId,
    this.category,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json, int id) {
    return MaterialModel(
      id: id,
      name: json['name']?.toString() ?? 'Unknown',
      unit: json['unit'] != null ? Unit.fromJson(json['unit']) : null,
      categoryId: json['category_id'] != null ? int.tryParse(json['category_id'].toString()) : null,
      category: json['category']?.toString(),
    );
  }
}

class Unit {
  final int id;
  final String name;

  Unit({required this.id, required this.name});

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      name: json['name']?.toString() ?? 'unit',
    );
  }
}

class ConsumptionLogPage extends StatefulWidget {
  const ConsumptionLogPage({super.key});

  @override
  State<ConsumptionLogPage> createState() => _ConsumptionLogPageState();
}

class _ConsumptionLogPageState extends State<ConsumptionLogPage> {
  List<Consumption> consumptions = [];
  final List<Consumption> _allConsumptions = [];

  // API Configuration
  final String baseUrl = 'http://sitepilot.easy2it.in';
  final String apiEndpoint = '/api/daily-consumptions';

  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Fuel', 'All Material'];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  // Data for form
  List<Project> _sites = [];
  List<AllMachinery> _machineries = [];
  List<MaterialModel> _materialsAll = [];
  List<MaterialModel> _materialsFuel = [];
  bool _isDataLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConsumptions();
    _loadFormData();
  }

  Future<void> _loadConsumptions() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl$apiEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        setState(() {
          _allConsumptions.clear();
          _allConsumptions.addAll(_parseApiResponse(responseData));
          consumptions = _allConsumptions;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading data: $e');
    }
  }

  Future<void> _loadFormData() async {
    setState(() => _isDataLoading = true);

    try {
      // Load sites
      final siteProvider = Provider.of<ProjectSiteProvider>(context, listen: false);
      await siteProvider.loadProjects();
      _sites = siteProvider.projects;

      // Load machineries
      final machineryService = MachineryService();
      final machineryResponse = await machineryService.getMachineries();
      _machineries = machineryResponse.data;

      // Load materials
      _materialsAll = await _fetchMaterialsByCategory(1); // Building Materials
      _materialsFuel = await _fetchMaterialsByCategory(2); // Fuels

      setState(() => _isDataLoading = false);
    } catch (e) {
      setState(() => _isDataLoading = false);
      _showErrorSnackBar('Error loading form data: $e');
    }
  }

  Future<List<MaterialModel>> _fetchMaterialsByCategory(int categoryId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/daily-consumptions/create-data'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          "site_id": 0,
          "workspace_id": 0
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<MaterialModel> materials = [];

        String materialsKey = categoryId == 1 ? 'materials_all' : 'materials_fuels';
        
        if (responseData.containsKey(materialsKey)) {
          final materialsMap = responseData[materialsKey] as Map<String, dynamic>;
          
          int index = 1;
          materialsMap.forEach((key, value) {
            materials.add(MaterialModel.fromJson(value, index));
            index++;
          });
        }

        return materials;
      } else {
        throw Exception('Failed to load materials: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading materials: $e');
    }
  }

  List<Consumption> _parseApiResponse(List<dynamic> apiData) {
    return apiData.map((item) {
      final consumptionType = item['consumption_type']?.toString() ?? '';
      final machineryType = item['machinery_type']?.toString() ?? '';
      final siteData = item['site'] is Map ? item['site'] : {};
      
      List<ConsumptionItem> items = [];
      if (item['details'] is List) {
        items = (item['details'] as List).map((detail) {
          final materialData = detail['material'] is Map ? detail['material'] : {};
          return ConsumptionItem(
            material: materialData['name']?.toString() ?? 'Unknown Material',
            quantity: double.tryParse(detail['quantity']?.toString() ?? '0') ?? 0,
            unit: detail['unit']?.toString() ?? 'unit',
            price: double.tryParse(materialData['price']?.toString() ?? '0') ?? 0,
            materialId: detail['material_id'] != null ? int.tryParse(detail['material_id'].toString()) : null,
          );
        }).toList();
      }

      final machineryData = item['machinery'] is Map ? item['machinery'] : {};

      return Consumption(
        id: item['id'] ?? 0,
        consumptionNo: item['consumption_number']?.toString() ?? 'N/A',
        consumptionDate: _parseDate(item['consumption_date']?.toString()),
        consumptionType: consumptionType,
        site: siteData['name']?.toString() ?? 'Unknown Site',
        consumptionFile: item['consumption_file']?.toString() ?? 'N/A',
        remarks: item['remarks']?.toString(),
        items: items.isNotEmpty ? items : null,
        machineryType: machineryType.isNotEmpty ? machineryType : null,
        machinery: machineryData['name']?.toString(),
        siteId: item['site_id']?.toString(),
        machineryId: item['machinery_id'] != null ? int.tryParse(item['machinery_id'].toString()) : null,
      );
    }).toList();
  }

  DateTime _parseDate(String? dateString) {
    if (dateString == null) return DateTime.now();
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return DateTime.now();
    }
  }

  void _filterConsumptions(String type) {
    setState(() {
      _selectedFilter = type;
      if (type == 'All') {
        consumptions = _allConsumptions;
      } else if (type == 'Fuel') {
        consumptions = _allConsumptions.where((c) => 
          c.consumptionType.toLowerCase().contains('fuel')).toList();
      } else if (type == 'All Material') {
        consumptions = _allConsumptions.where((c) => 
          !c.consumptionType.toLowerCase().contains('fuel')).toList();
      }
    });
  }

  Future<void> _addConsumption() async {
    if (_isDataLoading) {
      _showErrorSnackBar('Loading form data, please wait...');
      return;
    }

    final result = await showModalBottomSheet<Consumption>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: ConsumptionFormSheet(
            sites: _sites,
            machineries: _machineries,
            materialsAll: _materialsAll,
            materialsFuel: _materialsFuel,
            onSave: _saveConsumptionToAPI,
          ),
        ),
      ),
    );

    if (result != null) {
      await _saveConsumptionToAPI(result);
    }
  }

  Future<void> _saveConsumptionToAPI(Consumption consumption) async {
    try {
      setState(() => _isLoading = true);

      // Prepare the request body according to your API structure
      final Map<String, dynamic> requestBody = {
        "consumption_date": consumption.consumptionDate.toIso8601String().split('T')[0],
        "site_id": int.parse(consumption.siteId ?? '1'),
        "consumption_type": consumption.consumptionType,
        "machinery_type": consumption.machineryType,
        "machinery_id": consumption.machineryId ?? 2,
        "created_by": 1,
        "workspace_id": 1,
        "items": consumption.items?.map((item) => {
          "material_id": item.materialId ?? 8,
          "quantity": item.quantity,
          "unit": item.unit,
          "remarks": consumption.remarks ?? "Added from app"
        }).toList() ?? [],
        "remarks": consumption.remarks
      };

      final response = await http.post(
        Uri.parse('$baseUrl$apiEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Reload the consumptions to get the updated list from API
        await _loadConsumptions();
        _showSuccessSnackBar('Consumption added successfully');
      } else {
        _showErrorSnackBar('Failed to add consumption: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('Error adding consumption: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateConsumptionInAPI(Consumption consumption) async {
    try {
      setState(() => _isLoading = true);

      final Map<String, dynamic> requestBody = {
        "consumption_date": consumption.consumptionDate.toIso8601String().split('T')[0],
        "site_id": int.parse(consumption.siteId ?? '1'),
        "consumption_type": consumption.consumptionType,
        "machinery_type": consumption.machineryType,
        "machinery_id": consumption.machineryId ?? 2,
        "created_by": 1,
        "workspace_id": 1,
        "items": consumption.items?.map((item) => {
          "material_id": item.materialId ?? 8,
          "quantity": item.quantity,
          "unit": item.unit,
          "remarks": consumption.remarks ?? "Updated from app"
        }).toList() ?? [],
        "remarks": consumption.remarks
      };

      final response = await http.put(
        Uri.parse('$baseUrl$apiEndpoint/${consumption.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        await _loadConsumptions();
        _showSuccessSnackBar('Consumption updated successfully');
      } else {
        _showErrorSnackBar('Failed to update consumption: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating consumption: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteConsumptionFromAPI(Consumption consumption) async {
    try {
      setState(() => _isLoading = true);

      final response = await http.delete(
        Uri.parse('$baseUrl$apiEndpoint/${consumption.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await _loadConsumptions();
        _showSuccessSnackBar('Consumption deleted successfully');
      } else {
        _showErrorSnackBar('Failed to delete consumption: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('Error deleting consumption: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _editConsumption(Consumption consumption) async {
    if (_isDataLoading) {
      _showErrorSnackBar('Loading form data, please wait...');
      return;
    }

    final result = await showModalBottomSheet<Consumption>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: ConsumptionFormSheet(
            consumption: consumption,
            sites: _sites,
            machineries: _machineries,
            materialsAll: _materialsAll,
            materialsFuel: _materialsFuel,
            onSave: _updateConsumptionInAPI,
          ),
        ),
      ),
    );

    if (result != null) {
      await _updateConsumptionInAPI(result);
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
                Navigator.of(context).pop();
                _deleteConsumptionFromAPI(consumption);
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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
          IconButton(
            onPressed: _addConsumption, 
            icon: const Icon(Icons.add, color: Colors.white)
          ),
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
                    onChanged: (value) {
                      _performSearch(value);
                    },
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

  void _performSearch(String query) {
    if (query.isEmpty) {
      _filterConsumptions(_selectedFilter);
    } else {
      final filtered = _allConsumptions.where((consumption) {
        return consumption.consumptionNo.toLowerCase().contains(query.toLowerCase()) ||
               consumption.site.toLowerCase().contains(query.toLowerCase()) ||
               (consumption.items?.any((item) => 
                  item.material.toLowerCase().contains(query.toLowerCase())) ?? false);
      }).toList();
      
      setState(() {
        consumptions = filtered;
      });
    }
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadConsumptions,
            child: const Text('Retry'),
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
    final isFuel = consumption.consumptionType.toLowerCase().contains('fuel');
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

            // Machinery Information (if available)
            if (consumption.machinery != null) ...[
              Row(
                children: [
                  Icon(Icons.build, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      consumption.machinery!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

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

class ConsumptionFormSheet extends StatefulWidget {
  final Consumption? consumption;
  final List<Project> sites;
  final List<AllMachinery> machineries;
  final List<MaterialModel> materialsAll;
  final List<MaterialModel> materialsFuel;
  final Function(Consumption)? onSave;

  const ConsumptionFormSheet({
    super.key,
    this.consumption,
    required this.sites,
    required this.machineries,
    required this.materialsAll,
    required this.materialsFuel,
    this.onSave,
  });

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
  String? _selectedSiteId;
  String? _selectedMachineryType;
  int? _selectedMachineryId;

  final List<String> _consumptionTypes = ['All Material', 'Fuel'];
  final List<String> _machineryTypes = ['Own', 'Rental'];

  // Item fields controllers (for multiple items)
  final List<TextEditingController> _quantityControllers = [];
  final List<int?> _selectedMaterialIds = [];
  final List<String> _selectedUnits = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.consumption != null) {
      // Edit mode - populate fields
      final consumption = widget.consumption!;
      _consumptionNoController.text = consumption.consumptionNo;
      _consumptionDateController.text = _formatDate(consumption.consumptionDate);
      _selectedConsumptionType = consumption.consumptionType == 'fuel' ? 'Fuel' : 'All Material';
      
      // Set site ID - ensure it's in the list
      _selectedSiteId = (consumption.siteId != null && widget.sites.any((s) => s.id == consumption.siteId))
          ? consumption.siteId
          : (widget.sites.any((s) => s.name == consumption.site)
              ? widget.sites.firstWhere((s) => s.name == consumption.site).id
              : (widget.sites.isNotEmpty ? widget.sites.first.id : null));
      _remarksController.text = consumption.remarks ?? '';
      
      // Set machinery fields only if consumption type is Fuel
      if (_selectedConsumptionType == 'Fuel') {
        _selectedMachineryType = consumption.machineryType;
        _selectedMachineryId = (consumption.machineryId != null && widget.machineries.any((m) => m.id == consumption.machineryId))
            ? consumption.machineryId
            : (consumption.machinery != null && widget.machineries.any((m) => m.name == consumption.machinery)
                ? widget.machineries.firstWhere((m) => m.name == consumption.machinery).id
                : null);
      }
      
      // Initialize items
      if (consumption.items != null && consumption.items!.isNotEmpty) {
        for (var item in consumption.items!) {
          _items.add(item);
          _quantityControllers.add(TextEditingController(text: item.quantity.toString()));
          _selectedMaterialIds.add(item.materialId);
          _selectedUnits.add(item.unit);
        }
      } else {
        // Add one empty item field by default
        _addNewItemField();
      }
    } else {
      // Add mode - set default values
      _consumptionNoController.text = 'DCM-0011';
      _consumptionDateController.text = _formatDate(DateTime.now());
      // Add one empty item field by default
      _addNewItemField();
    }
  }

  void _addNewItemField() {
    setState(() {
      _quantityControllers.add(TextEditingController());
      _selectedMaterialIds.add(null);
      _selectedUnits.add('unit');
    });
  }

  void _removeItemField(int index) {
    setState(() {
      if (_quantityControllers.length > index) {
        _quantityControllers.removeAt(index);
      }
      if (_selectedMaterialIds.length > index) {
        _selectedMaterialIds.removeAt(index);
      }
      if (_selectedUnits.length > index) {
        _selectedUnits.removeAt(index);
      }
      if (_items.length > index) {
        _items.removeAt(index);
      }
    });
  }

  void _onMaterialChanged(int? newValue, int index) {
    if (newValue != null) {
      final currentMaterials = _selectedConsumptionType == 'Fuel' ? widget.materialsFuel : widget.materialsAll;
      final selectedMaterial = currentMaterials.firstWhere((m) => m.id == newValue);
      
      setState(() {
        _selectedMaterialIds[index] = newValue;
        _selectedUnits[index] = selectedMaterial.unit?.name ?? 'unit';
      });
    }
  }

  @override
  void dispose() {
    _consumptionNoController.dispose();
    _consumptionDateController.dispose();
    _remarksController.dispose();
    for (var controller in _quantityControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _selectedSiteId != null) {
      // Validate items
      for (int i = 0; i < _quantityControllers.length; i++) {
        if (_selectedMaterialIds[i] == null || _quantityControllers[i].text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill all item fields')),
          );
          return;
        }
      }

      // Build items list
      final List<ConsumptionItem> items = [];
      final currentMaterials = _selectedConsumptionType == 'Fuel' ? widget.materialsFuel : widget.materialsAll;

      for (int i = 0; i < _quantityControllers.length; i++) {
        final materialId = _selectedMaterialIds[i];
        if (materialId != null) {
          final material = currentMaterials.firstWhere((m) => m.id == materialId);
          items.add(ConsumptionItem(
            material: material.name,
            quantity: double.parse(_quantityControllers[i].text),
            unit: _selectedUnits[i],
            materialId: materialId,
          ));
        }
      }

      final siteName = widget.sites.firstWhere((s) => s.id == _selectedSiteId).name;
      final machineryName = _selectedMachineryId != null ? 
          widget.machineries.firstWhere((m) => m.id == _selectedMachineryId).name : null;

      final consumption = Consumption(
        id: widget.consumption?.id ?? 0, // API will assign ID
        consumptionNo: _consumptionNoController.text,
        consumptionDate: _parseDate(_consumptionDateController.text),
        consumptionType: _selectedConsumptionType.toLowerCase().contains('fuel') ? 'fuel' : 'all',
        site: siteName,
        consumptionFile: 'N/A',
        remarks: _remarksController.text.isEmpty ? null : _remarksController.text,
        items: items.isEmpty ? null : items,
        machineryType: _selectedConsumptionType == 'Fuel' ? _selectedMachineryType : null,
        machinery: _selectedConsumptionType == 'Fuel' ? machineryName : null,
        siteId: _selectedSiteId,
        machineryId: _selectedConsumptionType == 'Fuel' ? _selectedMachineryId : null,
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

  void _onConsumptionTypeChanged(String? newValue) {
    setState(() {
      _selectedConsumptionType = newValue!;
      // Reset machinery fields when switching consumption type
      if (_selectedConsumptionType == 'All Material') {
        _selectedMachineryType = null;
        _selectedMachineryId = null;
      }
      // Reset material selections
      for (int i = 0; i < _selectedMaterialIds.length; i++) {
        _selectedMaterialIds[i] = null;
        _selectedUnits[i] = 'unit';
      }
    });
  }

  Widget _buildItemField(int index) {
    final currentMaterials = _selectedConsumptionType == 'Fuel' ? widget.materialsFuel : widget.materialsAll;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_quantityControllers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _removeItemField(index),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedMaterialIds[index],
              decoration: const InputDecoration(
                labelText: 'Material *',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: currentMaterials.map((MaterialModel material) {
                return DropdownMenuItem<int>(
                  value: material.id,
                  child: Text(material.name),
                );
              }).toList(),
              onChanged: (value) => _onMaterialChanged(value, index),
              validator: (value) {
                if (value == null) {
                  return 'Please select material';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityControllers[index],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter quantity';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: TextEditingController(text: _selectedUnits[index]),
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    readOnly: true,
                    enabled: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.consumption != null;
    final showMachineryFields = _selectedConsumptionType == 'Fuel';

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
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
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
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _consumptionTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: _onConsumptionTypeChanged,
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
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  const SizedBox(height: 10),

                  // Site
                  DropdownButtonFormField<String>(
                    value: _selectedSiteId,
                    decoration: const InputDecoration(
                      labelText: 'Site *',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: widget.sites.map((Project site) {
                      return DropdownMenuItem<String>(
                        value: site.id,
                        child: Text(site.name),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSiteId = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a site';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Machinery Type (only for Fuel)
                  if (showMachineryFields) ...[
                    DropdownButtonFormField<String>(
                      value: _selectedMachineryType,
                      decoration: const InputDecoration(
                        labelText: 'Machinery Type *',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _machineryTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedMachineryType = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select machinery type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Machinery (only for Fuel)
                  if (showMachineryFields) ...[
                    DropdownButtonFormField<int>(
                      value: _selectedMachineryId,
                      decoration: const InputDecoration(
                        labelText: 'Machinery *',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: widget.machineries.map((AllMachinery machinery) {
                        return DropdownMenuItem<int>(
                          value: machinery.id,
                          child: Text(machinery.name),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedMachineryId = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select machinery';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  const SizedBox(height: 14),

                  // Items Section
                  const Text(
                    'Consumption Items',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Dynamic Item Fields
                  ...List.generate(_quantityControllers.length, (index) => _buildItemField(index)),

                  // Add Item Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addNewItemField,
                      icon: const Icon(Icons.add),
                      label: const Text('Add New Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: const Color.fromARGB(255, 25, 53, 210),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Remarks
                  TextFormField(
                    controller: _remarksController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Remarks',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
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