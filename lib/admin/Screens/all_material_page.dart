import 'package:ecoteam_app/contractor/view/contractor_dashboard/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Material Model based on API response
class MaterialItem {
  final int id;
  final String name;
  final String sku;
  final int categoryId;
  final int unitId;
  final String description;
  final double price;
  final int reorderLevel;
  final String status;
  final String? image;
  final int? siteId;
  final int createdBy;
  final int workspaceId;
  final String createdAt;
  final String updatedAt;
  final Unit? unit;
  final Category? category;

  MaterialItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.categoryId,
    required this.unitId,
    required this.description,
    required this.price,
    required this.reorderLevel,
    required this.status,
    this.image,
    this.siteId,
    required this.createdBy,
    required this.workspaceId,
    required this.createdAt,
    required this.updatedAt,
    this.unit,
    this.category,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      categoryId: json['category_id'] ?? 0,
      unitId: json['unit_id'] ?? 0,
      description: json['description'] ?? '',
      price: double.tryParse(json['price']?.toString().replaceAll(',', '') ?? '0') ?? 0.0,
      reorderLevel: json['reorder_level'] ?? 0,
      status: json['status'] ?? 'inactive',
      image: json['image'],
      siteId: json['site_id'],
      createdBy: json['created_by'] ?? 0,
      workspaceId: json['workspace_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      unit: json['unit'] != null ? Unit.fromJson(json['unit']) : null,
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sku': sku,
      'category_id': categoryId,
      'unit_id': unitId,
      'description': description,
      'price': price,
      'reorder_level': reorderLevel,
      'status': status,
      'image': image,
    };
  }
}

class Unit {
  final int id;
  final String name;
  final String symbol;
  final String? description;
  final int isActive;

  Unit({
    required this.id,
    required this.name,
    required this.symbol,
    this.description,
    required this.isActive,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
      description: json['description'],
      isActive: json['is_active'] ?? 0,
    );
  }
}

class Category {
  final int id;
  final String name;

  Category({
    required this.id,
    required this.name,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class MaterialApiService {
  static const String baseUrl = 'http://sitepilot.easy2it.in/api';
  
  // Add your authorization token here
  static String? authToken;

  static Future<Map<String, String>> getHeaders() async {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };
  }

  static Future<List<MaterialItem>> getMaterials() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/materials'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 1) {
          final List<dynamic> data = responseData['data']['data'];
          return data.map((item) => MaterialItem.fromJson(item)).toList();
        } else {
          throw Exception('API returned error status');
        }
      } else {
        throw Exception('Failed to load materials: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load materials: $e');
    }
  }

  static Future<MaterialItem> addMaterial(MaterialItem material) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/materials'),
        headers: await getHeaders(),
        body: json.encode(material.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return MaterialItem.fromJson(responseData['data']);
      } else {
        throw Exception('Failed to add material: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to add material: $e');
    }
  }

  static Future<MaterialItem> updateMaterial(MaterialItem material) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/materials/${material.id}'),
        headers: await getHeaders(),
        body: json.encode(material.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return MaterialItem.fromJson(responseData['data']);
      } else {
        throw Exception('Failed to update material: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update material: $e');
    }
  }

  static Future<bool> deleteMaterial(int materialId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/materials/$materialId'),
        headers: await getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to delete material: $e');
    }
  }
}

class AdminAllMaterialPage extends StatefulWidget {
  const AdminAllMaterialPage({Key? key}) : super(key: key);

  @override
  State<AdminAllMaterialPage> createState() => _AdminAllMaterialPageState();
}

class _AdminAllMaterialPageState extends State<AdminAllMaterialPage> {
  final TextEditingController _searchController = TextEditingController();
  List<MaterialItem> _allMaterials = [];
  List<MaterialItem> _filteredMaterials = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMaterials();
    _searchController.addListener(_filterMaterials);
  }

  Future<void> _loadMaterials() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final materials = await MaterialApiService.getMaterials();
      setState(() {
        _allMaterials = materials;
        _filteredMaterials = materials;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      _showSnackBar('Failed to load materials: $e');
    }
  }

  void _filterMaterials() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMaterials = _allMaterials.where((material) {
        return material.name.toLowerCase().contains(query) ||
               (material.category?.name.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  void _showAddMaterialBottomSheet() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController skuController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController reorderController = TextEditingController();
    String status = 'active';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Add New Material',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              // Row for Name and SKU
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Material Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: skuController,
                      decoration: const InputDecoration(
                        labelText: 'SKU',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.qr_code, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description, size: 18),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                maxLines: 2,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              // Row for Price and Reorder Level
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: reorderController,
                      decoration: const InputDecoration(
                        labelText: 'Reorder Level',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.warning, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setState) {
                  return SwitchListTile(
                    title: const Text('Status', style: TextStyle(fontSize: 14)),
                    value: status == 'active',
                    onChanged: (value) {
                      setState(() {
                        status = value ? 'active' : 'inactive';
                      });
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final sku = skuController.text.trim();
                    final description = descriptionController.text.trim();
                    final price = double.tryParse(priceController.text) ?? 0.0;
                    final reorder = int.tryParse(reorderController.text) ?? 0;

                    if (name.isNotEmpty && sku.isNotEmpty) {
                      try {
                        final newMaterial = MaterialItem(
                          id: 0, // Will be assigned by API
                          name: name,
                          sku: sku,
                          categoryId: 1, // Default category ID
                          unitId: 8, // Default unit ID (bag)
                          description: description,
                          price: price,
                          reorderLevel: reorder,
                          status: status,
                          createdBy: 1,
                          workspaceId: 1,
                          createdAt: DateTime.now().toIso8601String(),
                          updatedAt: DateTime.now().toIso8601String(),
                        );

                        await MaterialApiService.addMaterial(newMaterial);
                        await _loadMaterials(); // Refresh the list
                        Navigator.pop(context);
                        _showSnackBar('Material added successfully');
                      } catch (e) {
                        _showSnackBar('Failed to add material: $e');
                      }
                    } else {
                      _showSnackBar('Please fill all required fields');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2a43a0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Add Material', style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showEditMaterialBottomSheet(MaterialItem material) {
    final TextEditingController nameController = TextEditingController(text: material.name);
    final TextEditingController skuController = TextEditingController(text: material.sku);
    final TextEditingController descriptionController = TextEditingController(text: material.description);
    final TextEditingController priceController = TextEditingController(text: material.price.toString());
    final TextEditingController reorderController = TextEditingController(text: material.reorderLevel.toString());
    String status = material.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Edit Material',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              // Row for Name and SKU
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Material Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: skuController,
                      decoration: const InputDecoration(
                        labelText: 'SKU',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.qr_code, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description, size: 18),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                maxLines: 2,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              // Row for Price and Reorder Level
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: reorderController,
                      decoration: const InputDecoration(
                        labelText: 'Reorder Level',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.warning, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setState) {
                  return SwitchListTile(
                    title: const Text('Status', style: TextStyle(fontSize: 14)),
                    value: status == 'active',
                    onChanged: (value) {
                      setState(() {
                        status = value ? 'active' : 'inactive';
                      });
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final sku = skuController.text.trim();
                    final description = descriptionController.text.trim();
                    final price = double.tryParse(priceController.text) ?? 0.0;
                    final reorder = int.tryParse(reorderController.text) ?? 0;

                    if (name.isNotEmpty && sku.isNotEmpty) {
                      try {
                        final updatedMaterial = MaterialItem(
                          id: material.id,
                          name: name,
                          sku: sku,
                          categoryId: material.categoryId,
                          unitId: material.unitId,
                          description: description,
                          price: price,
                          reorderLevel: reorder,
                          status: status,
                          image: material.image,
                          siteId: material.siteId,
                          createdBy: material.createdBy,
                          workspaceId: material.workspaceId,
                          createdAt: material.createdAt,
                          updatedAt: DateTime.now().toIso8601String(),
                          unit: material.unit,
                          category: material.category,
                        );

                        await MaterialApiService.updateMaterial(updatedMaterial);
                        await _loadMaterials(); // Refresh the list
                        Navigator.pop(context);
                        _showSnackBar('Material updated successfully');
                      } catch (e) {
                        _showSnackBar('Failed to update material: $e');
                      }
                    } else {
                      _showSnackBar('Please fill all required fields');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2a43a0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Update Material', style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _deleteMaterial(MaterialItem material) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${material.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await MaterialApiService.deleteMaterial(material.id);
        await _loadMaterials(); // Refresh the list
        _showSnackBar('Material deleted successfully');
      } catch (e) {
        _showSnackBar('Failed to delete material: $e');
      }
    }
  }

  void _showMaterialDetailsBottomSheet(MaterialItem material) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Material Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 24),
              // Image
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[300],
                child: Icon(
                  Icons.inventory,
                  color: Colors.grey[600],
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              // Material Name
              Text(
                material.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Details Grid
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('SKU', material.sku),
                    const Divider(),
                    _buildDetailRow('Category', material.category?.name ?? 'N/A'),
                    const Divider(),
                    _buildDetailRow('Unit', material.unit?.name ?? 'N/A'),
                    const Divider(),
                    _buildDetailRow('Price', '₹${material.price}'),
                    const Divider(),
                    _buildDetailRow('Reorder Level', material.reorderLevel.toString()),
                    const Divider(),
                    _buildDetailRow('Status', material.status == 'active' ? 'Active' : 'Inactive',
                        valueColor: material.status == 'active' ? Colors.green : Colors.red),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditMaterialBottomSheet(material);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2a43a0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Edit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('All Material', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2a43a0),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: 24.sp,
            color: Colors.white,
          ),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen())),
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              size: 24.sp,
              color: Colors.white,
            ),
            onPressed: _loadMaterials,
            tooltip: 'Refresh',
          ),
          IconButton(onPressed: _showAddMaterialBottomSheet, icon: Icon(Icons.add, size: 24.sp, color: Colors.white), tooltip: 'Add Material')
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or category',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage.isNotEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading materials',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      ElevatedButton(
                        onPressed: _loadMaterials,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Total Entries
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Total entries: ${_filteredMaterials.length}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              // Material List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadMaterials,
                  child: ListView.builder(
                    itemCount: _filteredMaterials.length,
                    itemBuilder: (context, index) {
                      final material = _filteredMaterials[index];
                      return InkWell(
                        onTap: () => _showMaterialDetailsBottomSheet(material),
                        child: Card(
                          margin: EdgeInsets.only(bottom: 8.h),
                          child: Padding(
                            padding: EdgeInsets.all(12.w),
                            child: Row(
                              children: [
                                // Image
                                CircleAvatar(
                                  radius: 24.r,
                                  backgroundColor: Colors.grey[300],
                                  child: Icon(
                                    Icons.inventory,
                                    color: Colors.grey[600],
                                    size: 24.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                // Details - Limited info as requested
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        material.name,
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        'Category: ${material.category?.name ?? 'N/A'}',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        'Unit: ${material.unit?.name ?? 'N/A'}   |   Price: ₹${material.price}',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        'Status: ${material.status == 'active' ? 'Active' : 'Inactive'}',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: material.status == 'active' ? Colors.green : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Actions
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showEditMaterialBottomSheet(material),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteMaterial(material),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}