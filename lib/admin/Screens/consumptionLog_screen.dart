import 'package:ecoteam_app/admin/models/consumptionLog_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Simple Project class for sites
class Project {
  final String id;
  final String name;

  Project({required this.id, required this.name});
}

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

  factory MaterialModel.fromJson(Map<String, dynamic> json, String id) {
    return MaterialModel(
      id: int.tryParse(id) ?? 0,
      name: json['name']?.toString() ?? 'Unknown',
      unit: json['unit'] != null ? Unit.fromJson(json['unit']) : null,
      categoryId: json['category_id'] != null
          ? int.tryParse(json['category_id'].toString())
          : null,
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

class Machinery {
  final int id;
  final String name;

  Machinery({required this.id, required this.name});
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
  List<Machinery> _machineries = [];
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
      // Load all form data from create-data endpoint
      final formData = await _fetchCreateData();

      // Load sites from create-data response
      _sites = _parseSitesFromCreateData(formData);

      // Load machineries from create-data response
      _machineries = _parseMachineriesFromCreateData(formData);

      // Load materials from create-data response
      _materialsAll = _parseMaterialsFromCreateData(formData, 'materials_all');
      _materialsFuel = _parseMaterialsFromCreateData(
        formData,
        'materials_fuels',
      );

      setState(() => _isDataLoading = false);
    } catch (e) {
      setState(() => _isDataLoading = false);
      _showErrorSnackBar('Error loading form data: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchCreateData() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/daily-consumptions/create-data'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({"site_id": 0, "workspace_id": 0}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load form data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading form data: $e');
    }
  }

  List<Project> _parseSitesFromCreateData(Map<String, dynamic> formData) {
    final List<Project> sites = [];

    if (formData.containsKey('sites')) {
      final sitesMap = formData['sites'] as Map<String, dynamic>;

      sitesMap.forEach((key, value) {
        sites.add(Project(id: key, name: value.toString()));
      });
    }

    // Add default site if empty
    if (sites.isEmpty) {
      sites.add(Project(id: '1', name: 'Default Site'));
    }

    return sites;
  }

  List<Machinery> _parseMachineriesFromCreateData(
    Map<String, dynamic> formData,
  ) {
    final List<Machinery> machineries = [];

    if (formData.containsKey('machinery_options')) {
      final machineryMap =
          formData['machinery_options'] as Map<String, dynamic>;

      machineryMap.forEach((key, value) {
        machineries.add(
          Machinery(id: int.tryParse(key) ?? 0, name: value.toString()),
        );
      });
    }

    // Add default machinery if empty
    if (machineries.isEmpty) {
      machineries.add(Machinery(id: 1, name: 'Default Machinery'));
    }

    // Sort by name for better UX
    machineries.sort((a, b) => a.name.compareTo(b.name));

    return machineries;
  }

  List<MaterialModel> _parseMaterialsFromCreateData(
    Map<String, dynamic> formData,
    String materialsKey,
  ) {
    final List<MaterialModel> materials = [];

    if (formData.containsKey(materialsKey)) {
      final materialsMap = formData[materialsKey] as Map<String, dynamic>;

      materialsMap.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          materials.add(MaterialModel.fromJson(value, key));
        }
      });
    }

    // Sort by name for better UX
    materials.sort((a, b) => a.name.compareTo(b.name));

    return materials;
  }

  List<Consumption> _parseApiResponse(List<dynamic> apiData) {
    return apiData.map((item) {
      final consumptionType = item['consumption_type']?.toString() ?? '';
      final machineryType = item['machinery_type']?.toString() ?? '';
      final siteData = item['site'] is Map ? item['site'] : {};

      List<ConsumptionItem> items = [];
      if (item['details'] is List) {
        items = (item['details'] as List).map((detail) {
          final materialData = detail['material'] is Map
              ? detail['material']
              : {};
          return ConsumptionItem(
            material: materialData['name']?.toString() ?? 'Unknown Material',
            quantity:
                double.tryParse(detail['quantity']?.toString() ?? '0') ?? 0,
            unit: detail['unit']?.toString() ?? 'unit',
            price:
                double.tryParse(materialData['price']?.toString() ?? '0') ?? 0,
            materialId: detail['material_id'] != null
                ? int.tryParse(detail['material_id'].toString())
                : null,
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
        machineryId: item['machinery_id'] != null
            ? int.tryParse(item['machinery_id'].toString())
            : null,
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
        consumptions = _allConsumptions
            .where((c) => c.consumptionType.toLowerCase().contains('fuel'))
            .toList();
      } else if (type == 'All Material') {
        consumptions = _allConsumptions
            .where((c) => !c.consumptionType.toLowerCase().contains('fuel'))
            .toList();
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
        "consumption_date": consumption.consumptionDate.toIso8601String().split(
          'T',
        )[0],
        "site_id": int.parse(consumption.siteId ?? '1'),
        "consumption_type": consumption.consumptionType,
        "created_by": 1,
        "workspace_id": 1,
        "items":
            consumption.items
                ?.map(
                  (item) => {
                    "material_id": item.materialId ?? 8,
                    "quantity": item.quantity.toString(),
                    "unit": item.unit,
                    "remarks": consumption.remarks ?? "Added from app",
                  },
                )
                .toList() ??
            [],
        "remarks": consumption.remarks ?? "",
      };

      // Add machinery fields only if they exist and consumption type is fuel
      if (consumption.consumptionType == 'fuel') {
        if (consumption.machineryType != null) {
          requestBody["machinery_type"] = consumption.machineryType;
        }
        if (consumption.machineryId != null) {
          requestBody["machinery_id"] = consumption.machineryId;
        }
      }

      print('Sending request: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl$apiEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await _loadConsumptions();
        _showSuccessSnackBar('Consumption added successfully');
      } else {
        _showErrorSnackBar(
          'Failed to add consumption: ${response.statusCode} - ${response.body}',
        );
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
        "consumption_date": consumption.consumptionDate.toIso8601String().split(
          'T',
        )[0],
        "site_id": int.parse(consumption.siteId ?? '1'),
        "consumption_type": consumption.consumptionType,
        "created_by": 1,
        "workspace_id": 1,
        "items":
            consumption.items
                ?.map(
                  (item) => {
                    "material_id": item.materialId ?? 8,
                    "quantity": item.quantity.toString(),
                    "unit": item.unit,
                    "remarks": consumption.remarks ?? "Updated from app",
                  },
                )
                .toList() ??
            [],
        "remarks": consumption.remarks ?? "",
      };

      // Add machinery fields only if they exist and consumption type is fuel
      if (consumption.consumptionType == 'fuel') {
        if (consumption.machineryType != null) {
          requestBody["machinery_type"] = consumption.machineryType;
        }
        if (consumption.machineryId != null) {
          requestBody["machinery_id"] = consumption.machineryId;
        }
      }

      print('Sending update request: ${json.encode(requestBody)}');

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
        _showErrorSnackBar(
          'Failed to update consumption: ${response.statusCode} - ${response.body}',
        );
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
        _showErrorSnackBar(
          'Failed to delete consumption: ${response.statusCode}',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error deleting consumption: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _viewConsumption(Consumption consumption) async {
    if (_isDataLoading) {
      _showErrorSnackBar('Loading form data, please wait...');
      return;
    }

    await showModalBottomSheet(
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
            isViewMode: true,
          ),
        ),
      ),
    );
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
          title: const Text(
            'Delete Consumption',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete ${consumption.consumptionNo}?',
            style: const TextStyle(fontSize: 16),
          ),
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
        title: const Text(
          'Manage Consumption Log',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
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
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadConsumptions,
          ),
          IconButton(
            onPressed: _addConsumption,
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Container(
                  height: 40,
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
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey.shade500,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(8),
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
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => _filterConsumptions(filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.shade50
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue.shade300
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.blue.shade700
                              : Colors.grey.shade700,
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
                        onView: () => _viewConsumption(consumption),
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
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                Text(
                  '${consumptions.length} items total',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
        return consumption.consumptionNo.toLowerCase().contains(
              query.toLowerCase(),
            ) ||
            consumption.site.toLowerCase().contains(query.toLowerCase()) ||
            (consumption.items?.any(
                  (item) =>
                      item.material.toLowerCase().contains(query.toLowerCase()),
                ) ??
                false);
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
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
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
  final VoidCallback onView;
  final VoidCallback onDelete;
  final bool isLast;

  const ConsumptionCard({
    super.key,
    required this.consumption,
    required this.onEdit,
    required this.onView,
    required this.onDelete,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isFuel = consumption.consumptionType.toLowerCase().contains('fuel');
    final totalItems = consumption.items?.length ?? 0;

    return GestureDetector(
      onTap: onView,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: isLast
                ? BorderSide.none
                : BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 12),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: onEdit,
                        icon: Icon(Icons.edit),
                        color: const Color.fromARGB(255, 27, 53, 170),
                        iconSize: 20,
                      ),

                      IconButton(
                        onPressed: onDelete,
                        icon: Icon(Icons.delete),
                        color: Colors.red,
                        iconSize: 20,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Site Information
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
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
                const SizedBox(height: 10),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isFuel
                          ? Colors.orange.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isFuel
                            ? Colors.orange.shade200
                            : Colors.green.shade200,
                      ),
                    ),
                    child: Text(
                      isFuel ? 'FUEL' : 'MATERIAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isFuel
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(consumption.consumptionDate),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),

              // File Attachment
              if (consumption.consumptionFile != 'N/A') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
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
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

class ConsumptionFormSheet extends StatefulWidget {
  final Consumption? consumption;
  final List<Project> sites;
  final List<Machinery> machineries;
  final List<MaterialModel> materialsAll;
  final List<MaterialModel> materialsFuel;
  final Function(Consumption)? onSave;
  final bool isViewMode;

  const ConsumptionFormSheet({
    super.key,
    this.consumption,
    required this.sites,
    required this.machineries,
    required this.materialsAll,
    required this.materialsFuel,
    this.onSave,
    this.isViewMode = false,
  });

  @override
  State<ConsumptionFormSheet> createState() => _ConsumptionFormSheetState();
}

class _ConsumptionFormSheetState extends State<ConsumptionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final List<ConsumptionItem> _items = [];

  // Form controllers
  final TextEditingController _consumptionNoController =
      TextEditingController();
  final TextEditingController _consumptionDateController =
      TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  String _selectedConsumptionType = 'All Material';
  String? _selectedSiteId;
  String? _selectedMachineryType;
  int? _selectedMachineryId;

  final List<String> _consumptionTypes = ['All Material', 'Fuel'];
  final List<String> _machineryTypes = ['own', 'rental'];

  String _capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1).toLowerCase() : s;

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
      _consumptionDateController.text = _formatDate(
        consumption.consumptionDate,
      );

      // Set consumption type based on actual data
      if (consumption.consumptionType == 'fuel') {
        _selectedConsumptionType = 'Fuel';
      } else {
        _selectedConsumptionType = 'All Material';
      }

      // Set site ID - ensure it's in the list
      _selectedSiteId = _findSiteId(consumption);
      _remarksController.text = consumption.remarks ?? '';

      // Set machinery fields only if consumption type is Fuel
      if (_selectedConsumptionType == 'Fuel') {
        _selectedMachineryType = consumption.machineryType?.toLowerCase();
        _selectedMachineryId = consumption.machineryId;
        if (_selectedMachineryId != null &&
            !widget.machineries.any((m) => m.id == _selectedMachineryId)) {
          _selectedMachineryId = null;
        }
      }

      // Initialize items
      if (consumption.items != null && consumption.items!.isNotEmpty) {
        for (var item in consumption.items!) {
          _quantityControllers.add(
            TextEditingController(text: item.quantity.toString()),
          );
          _selectedMaterialIds.add(item.materialId);
          _selectedUnits.add(item.unit);
        }
        // Check if materials are in the current list
        for (int i = 0; i < _selectedMaterialIds.length; i++) {
          final currentMaterials = _selectedConsumptionType == 'Fuel'
              ? widget.materialsFuel
              : widget.materialsAll;
          if (_selectedMaterialIds[i] != null &&
              !currentMaterials.any((m) => m.id == _selectedMaterialIds[i])) {
            _selectedMaterialIds[i] = null;
            _selectedUnits[i] = 'unit';
          }
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

  String? _findSiteId(Consumption consumption) {
    if (consumption.siteId != null &&
        widget.sites.any((s) => s.id == consumption.siteId)) {
      return consumption.siteId;
    }

    // Try to find by name
    final matchingSite = widget.sites.firstWhere(
      (s) => s.name == consumption.site,
      orElse: () => widget.sites.isNotEmpty
          ? widget.sites.first
          : Project(id: '1', name: 'Default Site'),
    );

    return matchingSite.id;
  }

  int? _findMachineryId(Consumption consumption) {
    if (consumption.machineryId != null &&
        widget.machineries.any((m) => m.id == consumption.machineryId)) {
      return consumption.machineryId;
    }

    // Try to find by name
    if (consumption.machinery != null) {
      final matchingMachinery = widget.machineries.firstWhere(
        (m) => m.name == consumption.machinery,
        orElse: () => widget.machineries.isNotEmpty
            ? widget.machineries.first
            : Machinery(id: 1, name: 'Default Machinery'),
      );
      return matchingMachinery.id;
    }

    return widget.machineries.isNotEmpty ? widget.machineries.first.id : null;
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
      final currentMaterials = _selectedConsumptionType == 'Fuel'
          ? widget.materialsFuel
          : widget.materialsAll;
      final selectedMaterial = currentMaterials.firstWhere(
        (m) => m.id == newValue,
      );

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
        if (_selectedMaterialIds[i] == null ||
            _quantityControllers[i].text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill all item fields')),
          );
          return;
        }
      }

      // Build items list
      final List<ConsumptionItem> items = [];
      final currentMaterials = _selectedConsumptionType == 'Fuel'
          ? widget.materialsFuel
          : widget.materialsAll;

      for (int i = 0; i < _quantityControllers.length; i++) {
        final materialId = _selectedMaterialIds[i];
        if (materialId != null) {
          final material = currentMaterials.firstWhere(
            (m) => m.id == materialId,
          );
          items.add(
            ConsumptionItem(
              material: material.name,
              quantity: double.parse(_quantityControllers[i].text),
              unit: _selectedUnits[i],
              materialId: materialId,
            ),
          );
        }
      }

      // For rental machinery type, clear machinery selection
      if (_selectedConsumptionType == 'Fuel' &&
          _selectedMachineryType == 'rental') {
        _selectedMachineryId = null;
      }

      final siteName = widget.sites
          .firstWhere((s) => s.id == _selectedSiteId)
          .name;
      final machineryName = _selectedMachineryId != null
          ? widget.machineries
                .firstWhere((m) => m.id == _selectedMachineryId)
                .name
          : null;

      final consumption = Consumption(
        id: widget.consumption?.id ?? 0,
        consumptionNo: _consumptionNoController.text,
        consumptionDate: _parseDate(_consumptionDateController.text),
        consumptionType: _selectedConsumptionType == 'Fuel' ? 'fuel' : 'all',
        site: siteName,
        consumptionFile: 'N/A',
        remarks: _remarksController.text.isEmpty
            ? null
            : _remarksController.text,
        items: items.isEmpty ? null : items,
        machineryType: _selectedConsumptionType == 'Fuel'
            ? _selectedMachineryType?.toLowerCase()
            : null,
        machinery: _selectedConsumptionType == 'Fuel' ? machineryName : null,
        siteId: _selectedSiteId,
        machineryId: _selectedConsumptionType == 'Fuel'
            ? _selectedMachineryId
            : null,
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
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
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
    if (newValue != null) {
      setState(() {
        _selectedConsumptionType = newValue;

        // Reset machinery fields when switching from Fuel to All Material
        if (newValue == 'All Material') {
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
  }

  Widget _buildItemField(int index) {
    final currentMaterials = _selectedConsumptionType == 'Fuel'
        ? (widget.materialsFuel.isNotEmpty
              ? widget.materialsFuel
              : widget.materialsAll)
        : widget.materialsAll;

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
                if (_quantityControllers.length > 1 && !widget.isViewMode)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _removeItemField(index),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: _selectedMaterialIds[index],
              decoration:  InputDecoration(
                labelText: 'Material *',
                border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // or any value you prefer
                            ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Select Material'),
                ),
                ...currentMaterials.map((MaterialModel material) {
                  return DropdownMenuItem<int?>(
                    value: material.id,
                    child: Text(material.name),
                  );
                }).toList(),
              ],
              onChanged: widget.isViewMode
                  ? null
                  : (value) => _onMaterialChanged(value, index),
              validator: widget.isViewMode
                  ? null
                  : (value) {
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
                    readOnly: widget.isViewMode,
                    decoration: InputDecoration(
                      labelText: 'Quantity *',
                      border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // or any value you prefer
                            ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    validator: widget.isViewMode
                        ? null
                        : (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter quantity';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: TextEditingController(
                      text: _selectedUnits[index],
                    ),
                    decoration:  InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // or any value you prefer
                            ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
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

  Widget _buildMachineryTypeField() {
    return DropdownButtonFormField<String?>(
      value: _selectedMachineryType,
      decoration:  InputDecoration(
        labelText: 'Machinery Type *',
        border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // or any value you prefer
                            ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Select Machinery Type'),
        ),
        ..._machineryTypes.map((String type) {
          return DropdownMenuItem<String?>(
            value: type,
            child: Text(_capitalize(type)),
          );
        }).toList(),
      ],
      onChanged: widget.isViewMode
          ? null
          : (String? newValue) {
              setState(() {
                _selectedMachineryType = newValue;
                // Reset machinery selection when type changes
                _selectedMachineryId = null;
              });
            },
    );
  }

  Widget _buildMachineryField() {
    return DropdownButtonFormField<int?>(
      value: _selectedMachineryId,
      decoration:  InputDecoration(
        labelText: 'Machinery *',
        border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // or any value you prefer
                            ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('Select Machinery'),
        ),
        ...widget.machineries.map((Machinery machinery) {
          return DropdownMenuItem<int?>(
            value: machinery.id,
            child: Text(machinery.name),
          );
        }).toList(),
      ],
      onChanged: widget.isViewMode
          ? null
          : (int? newValue) {
              setState(() {
                _selectedMachineryId = newValue;
              });
            },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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

  Widget _buildItemView(int index) {
    final currentMaterials = _selectedConsumptionType == 'Fuel'
        ? widget.materialsFuel
        : widget.materialsAll;
    final material = _selectedMaterialIds[index] != null
        ? currentMaterials.firstWhere(
            (m) => m.id == _selectedMaterialIds[index],
            orElse: () => MaterialModel(id: 0, name: 'Unknown'),
          )
        : MaterialModel(id: 0, name: 'Unknown');

    return Card(
      margin: const EdgeInsets.only(bottom: 2),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            _buildInfoRow('Material', material.name),
            _buildInfoRow(
              'Quantity',
              '${_quantityControllers[index].text} ${material.unit?.name ?? 'unit'}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewContent() {
    final showMachineryFields = _selectedConsumptionType == 'Fuel';
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Consumption Number', _consumptionNoController.text),
          _buildInfoRow('Consumption Date', _consumptionDateController.text),
          _buildInfoRow('Consumption Type', _selectedConsumptionType),
          _buildInfoRow(
            'Site',
            widget.sites
                .firstWhere(
                  (s) => s.id == _selectedSiteId,
                  orElse: () => Project(id: '', name: 'Unknown'),
                )
                .name,
          ),
          if (showMachineryFields) ...[
            _buildInfoRow(
              'Machinery Type',
              _selectedMachineryType != null
                  ? _capitalize(_selectedMachineryType!)
                  : 'N/A',
            ),
            if (_selectedMachineryType == 'own')
              _buildInfoRow(
                'Machinery',
                _selectedMachineryId != null
                    ? widget.machineries
                          .firstWhere(
                            (m) => m.id == _selectedMachineryId,
                            orElse: () => Machinery(id: 0, name: 'Unknown'),
                          )
                          .name
                    : 'N/A',
              ),
          ],
          const SizedBox(height: 19),
          const Text(
            'Consumption Items',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          
          ...List.generate(
            _quantityControllers.length,
            (index) => _buildItemView(index),
          ),
          if (_remarksController.text.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildInfoRow('Remarks', _remarksController.text),
          ],
        ],
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
          widget.isViewMode
              ? 'View Consumption'
              : (isEdit ? 'Edit Consumption' : 'Add Consumption'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: widget.isViewMode
              ? _buildViewContent()
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Consumption Number
                        TextFormField(
                          controller: _consumptionNoController,
                          readOnly: widget.isViewMode,
                          decoration: InputDecoration(
                            labelText: 'Consumption Number *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // or any value you prefer
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          validator: widget.isViewMode
                              ? null
                              : (value) {
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
                          decoration: InputDecoration(
                            labelText: 'Consumption Type *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // or any value you prefer
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: _consumptionTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: widget.isViewMode
                              ? null
                              : _onConsumptionTypeChanged,
                          validator: widget.isViewMode
                              ? null
                              : (value) {
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
                          decoration:  InputDecoration(
                            labelText: 'Consumption Date *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // or any value you prefer
                            ),
                            suffixIcon: Icon(Icons.calendar_today),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          readOnly: true,
                          onTap: widget.isViewMode ? null : _selectDate,
                          validator: widget.isViewMode
                              ? null
                              : (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select consumption date';
                                  }
                                  return null;
                                },
                        ),
                        const SizedBox(height: 10),

                        // Site
                        DropdownButtonFormField<String?>(
                          value: _selectedSiteId,
                          decoration:  InputDecoration(
                            labelText: 'Site *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // or any value you prefer
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Select Site'),
                            ),
                            ...widget.sites.map((Project site) {
                              return DropdownMenuItem<String?>(
                                value: site.id,
                                child: Text(site.name),
                              );
                            }).toList(),
                          ],
                          onChanged: widget.isViewMode
                              ? null
                              : (String? newValue) {
                                  setState(() {
                                    _selectedSiteId = newValue;
                                  });
                                },
                          validator: widget.isViewMode
                              ? null
                              : (value) {
                                  if (value == null) {
                                    return 'Please select a site';
                                  }
                                  return null;
                                },
                        ),
                        const SizedBox(height: 10),

                        // Machinery Type (only for Fuel) - REQUIRED
                        if (showMachineryFields) ...[
                          _buildMachineryTypeField(),
                          const SizedBox(height: 10),
                        ],

                        // Machinery (only for Fuel and Own type)
                        if (showMachineryFields &&
                            _selectedMachineryType == 'own') ...[
                          _buildMachineryField(),
                          const SizedBox(height: 10),
                        ],

                        const SizedBox(height: 12),

                        // Items Section
                        const Text(
                          'Consumption Items',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        

                        // Dynamic Item Fields
                        ...List.generate(
                          _quantityControllers.length,
                          (index) => _buildItemField(index),
                        ),

                        // Add Item Button
                        if (!widget.isViewMode)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _addNewItemField,
                              icon: const Icon(Icons.add),
                              label: const Text('Add New Item'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade50,
                                foregroundColor: const Color.fromARGB(
                                  255,
                                  25,
                                  53,
                                  210,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),

                        // Remarks
                        TextFormField(
                          controller: _remarksController,
                          maxLines: 2,
                          readOnly: widget.isViewMode,
                          decoration:  InputDecoration(
                            labelText: 'Remarks',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // or any value you prefer
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 14),
        if (!widget.isViewMode)
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
              child: Text(
                isEdit ? 'Update' : 'Add',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Close', style: TextStyle(fontSize: 16)),
            ),
          ),
        const SizedBox(height: 14),
      ],
    );
  }
}

class Consumption {
  final int id;
  final String consumptionNo;
  final DateTime consumptionDate;
  final String consumptionType;
  final String site;
  final String consumptionFile;
  final String? remarks;
  final List<ConsumptionItem>? items;
  final String? machineryType;
  final String? machinery;
  final String? siteId;
  final int? machineryId;

  Consumption({
    required this.id,
    required this.consumptionNo,
    required this.consumptionDate,
    required this.consumptionType,
    required this.site,
    required this.consumptionFile,
    this.remarks,
    this.items,
    this.machineryType,
    this.machinery,
    this.siteId,
    this.machineryId,
  });

  Consumption copyWith({
    int? id,
    String? consumptionNo,
    DateTime? consumptionDate,
    String? consumptionType,
    String? site,
    String? consumptionFile,
    String? remarks,
    List<ConsumptionItem>? items,
    String? machineryType,
    String? machinery,
    String? siteId,
    int? machineryId,
  }) {
    return Consumption(
      id: id ?? this.id,
      consumptionNo: consumptionNo ?? this.consumptionNo,
      consumptionDate: consumptionDate ?? this.consumptionDate,
      consumptionType: consumptionType ?? this.consumptionType,
      site: site ?? this.site,
      consumptionFile: consumptionFile ?? this.consumptionFile,
      remarks: remarks ?? this.remarks,
      items: items ?? this.items,
      machineryType: machineryType ?? this.machineryType,
      machinery: machinery ?? this.machinery,
      siteId: siteId ?? this.siteId,
      machineryId: machineryId ?? this.machineryId,
    );
  }
}

class ConsumptionItem {
  final String material;
  final double quantity;
  final String unit;
  final double? price;
  final int? materialId;

  ConsumptionItem({
    required this.material,
    required this.quantity,
    required this.unit,
    this.price,
    this.materialId,
  });
}
