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
      price:
          double.tryParse(
            json['price']?.toString().replaceAll(',', '') ?? '0',
          ) ??
          0.0,
      reorderLevel: json['reorder_level'] ?? 0,
      status: json['status'] ?? 'inactive',
      image: json['image'],
      siteId: json['site_id'],
      createdBy: json['created_by'] ?? 0,
      workspaceId: json['workspace_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      unit: json['unit'] != null ? Unit.fromJson(json['unit']) : null,
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,
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
      'site_id': siteId ?? 1,
      'created_by': createdBy,
      'workspace_id': workspaceId,
    };
  }

  // Helper method to get category name from available categories list
  String getCategoryName(List<Category> categories) {
    if (category != null && category!.name.isNotEmpty) {
      return category!.name;
    }
    final categoryFromList = categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => Category(
        id: 0,
        name: 'N/A',
        isActive: 0,
        createdBy: 0,
        workspaceId: 0,
        status: '0',
        createdAt: '',
        updatedAt: '',
      ),
    );
    return categoryFromList.name;
  }

  // Helper method to get unit name from available units list
  String getUnitName(List<Unit> units) {
    if (unit != null && unit!.name.isNotEmpty) {
      return unit!.name;
    }
    final unitFromList = units.firstWhere(
      (u) => u.id == unitId,
      orElse: () => Unit(id: 0, name: 'N/A', symbol: '', isActive: 0),
    );
    return unitFromList.name;
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
  final int isActive;
  final int? siteId;
  final int createdBy;
  final int workspaceId;
  final String status;
  final String createdAt;
  final String updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.isActive,
    this.siteId,
    required this.createdBy,
    required this.workspaceId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      isActive: json['is_active'] ?? 0,
      siteId: json['site_id'],
      createdBy: json['created_by'] ?? 0,
      workspaceId: json['workspace_id'] ?? 0,
      status: json['status'] ?? '0',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

// Pagination Response Model
class PaginatedMaterialsResponse {
  final int currentPage;
  final List<MaterialItem> data;
  final String firstPageUrl;
  final int from;
  final int lastPage;
  final String lastPageUrl;
  final List<PaginationLink> links;
  final String? nextPageUrl;
  final String path;
  final int perPage;
  final String? prevPageUrl;
  final int to;
  final int total;

  PaginatedMaterialsResponse({
    required this.currentPage,
    required this.data,
    required this.firstPageUrl,
    required this.from,
    required this.lastPage,
    required this.lastPageUrl,
    required this.links,
    this.nextPageUrl,
    required this.path,
    required this.perPage,
    this.prevPageUrl,
    required this.to,
    required this.total,
  });

  factory PaginatedMaterialsResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedMaterialsResponse(
      currentPage: json['current_page'] ?? 1,
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => MaterialItem.fromJson(item))
              .toList() ??
          [],
      firstPageUrl: json['first_page_url'] ?? '',
      from: json['from'] ?? 0,
      lastPage: json['last_page'] ?? 1,
      lastPageUrl: json['last_page_url'] ?? '',
      links:
          (json['links'] as List<dynamic>?)
              ?.map((link) => PaginationLink.fromJson(link))
              .toList() ??
          [],
      nextPageUrl: json['next_page_url'],
      path: json['path'] ?? '',
      perPage: json['per_page'] ?? 10,
      prevPageUrl: json['prev_page_url'],
      to: json['to'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}

class PaginationLink {
  final String? url;
  final String label;
  final bool active;

  PaginationLink({this.url, required this.label, required this.active});

  factory PaginationLink.fromJson(Map<String, dynamic> json) {
    return PaginationLink(
      url: json['url'],
      label: json['label'] ?? '',
      active: json['active'] ?? false,
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

  static Future<PaginatedMaterialsResponse> getMaterials({int page = 1}) async {
    try {
      print('Fetching materials from: $baseUrl/materials?page=$page');
      final response = await http.get(
        Uri.parse('$baseUrl/materials?page=$page'),
        headers: await getHeaders(),
      );

      print('Materials Response Status: ${response.statusCode}');
      print('Materials Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Check if status is 1 (success)
        if (responseData['status'] == 1) {
          // Handle different possible response structures
          if (responseData['data'] != null && responseData['data'] is Map) {
            // This is a paginated response
            return PaginatedMaterialsResponse.fromJson(responseData['data']);
          } else {
            // This might be a non-paginated response, create a paginated response with single page
            List<dynamic> data = [];

            if (responseData['data'] != null) {
              if (responseData['data'] is List) {
                data = responseData['data'];
              } else if (responseData['data'] is Map) {
                // Single material object
                data = [responseData['data']];
              }
            }

            return PaginatedMaterialsResponse(
              currentPage: 1,
              data: data.map((item) => MaterialItem.fromJson(item)).toList(),
              firstPageUrl: '$baseUrl/materials?page=1',
              from: 1,
              lastPage: 1,
              lastPageUrl: '$baseUrl/materials?page=1',
              links: [],
              nextPageUrl: null,
              path: '$baseUrl/materials',
              perPage: data.length,
              prevPageUrl: null,
              to: data.length,
              total: data.length,
            );
          }
        } else {
          throw Exception(
            'API returned error status: ${responseData['message']}',
          );
        }
      } else {
        throw Exception(
          'Failed to load materials: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error in getMaterials: $e');
      throw Exception('Failed to load materials: $e');
    }
  }

  static Future<List<Category>> getCategories() async {
    try {
      print('Fetching categories from: $baseUrl/material-categories');
      final response = await http.get(
        Uri.parse('$baseUrl/material-categories'),
        headers: await getHeaders(),
      );

      print('Categories Response Status: ${response.statusCode}');
      print('Categories Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        List<dynamic> data = [];

        if (responseData is Map) {
          // Check if status is 1 (success) or if there's no status field (assume success)
          if (responseData['status'] == 1 || responseData['status'] == null) {
            // Handle different possible response structures
            if (responseData['data'] != null) {
              if (responseData['data'] is List) {
                data = responseData['data'];
              } else if (responseData['data'] is Map &&
                  responseData['data']['data'] != null) {
                data = responseData['data']['data'];
              } else if (responseData['data'] is Map &&
                  responseData['data']['data'] == null) {
                // If data is a map but no nested data, try to use the data map directly
                data = [responseData['data']];
              }
            }
          } else {
            // Only throw error if status is explicitly not 1 and not null
            if (responseData['status'] != null && responseData['status'] != 1) {
              throw Exception(
                'API returned error status: ${responseData['message']}',
              );
            }
          }
        } else if (responseData is List) {
          data = responseData;
        }

        if (data.isNotEmpty) {
          return data.map((item) => Category.fromJson(item)).toList();
        } else {
          // Return empty list instead of throwing error
          print('No categories data found, returning empty list');
          return [];
        }
      } else {
        throw Exception(
          'Failed to load categories: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error in getCategories: $e');
      // Return empty list instead of throwing error
      return [];
    }
  }

  static Future<List<Unit>> getUnits() async {
    try {
      print('Fetching units from: $baseUrl/units');
      final response = await http.get(
        Uri.parse('$baseUrl/units'),
        headers: await getHeaders(),
      );

      print('Units Response Status: ${response.statusCode}');
      print('Units Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        List<dynamic> data = [];

        if (responseData is Map) {
          // Check if status is 1 (success) or if there's no status field (assume success)
          if (responseData['status'] == 1 || responseData['status'] == null) {
            // Handle different possible response structures
            if (responseData['data'] != null) {
              if (responseData['data'] is List) {
                data = responseData['data'];
              } else if (responseData['data'] is Map &&
                  responseData['data']['data'] != null) {
                data = responseData['data']['data'];
              } else if (responseData['data'] is Map &&
                  responseData['data']['data'] == null) {
                // If data is a map but no nested data, try to use the data map directly
                data = [responseData['data']];
              }
            }
          } else {
            // Only throw error if status is explicitly not 1 and not null
            if (responseData['status'] != null && responseData['status'] != 1) {
              throw Exception(
                'API returned error status: ${responseData['message']}',
              );
            }
          }
        } else if (responseData is List) {
          data = responseData;
        }

        if (data.isNotEmpty) {
          return data.map((item) => Unit.fromJson(item)).toList();
        } else {
          // Return empty list instead of throwing error
          print('No units data found, returning empty list');
          return [];
        }
      } else {
        throw Exception(
          'Failed to load units: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error in getUnits: $e');
      // Return empty list instead of throwing error
      return [];
    }
  }

  static Future<MaterialItem> addMaterial(MaterialItem material) async {
    try {
      print('Adding material: ${material.toJson()}');
      final response = await http.post(
        Uri.parse('$baseUrl/materials'),
        headers: await getHeaders(),
        body: json.encode(material.toJson()),
      );

      print('Add Material Response Status: ${response.statusCode}');
      print('Add Material Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 1) {
          // Return the created material with proper category and unit data
          final createdMaterial = MaterialItem.fromJson(responseData['data']);

          // If the response doesn't include category/unit objects, we'll handle it in the UI
          return createdMaterial;
        } else {
          throw Exception(
            'API returned error status: ${responseData['message']}',
          );
        }
      } else {
        throw Exception(
          'Failed to add material: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error in addMaterial: $e');
      throw Exception('Failed to add material: $e');
    }
  }

  static Future<MaterialItem> updateMaterial(MaterialItem material) async {
    try {
      print('Updating material ${material.id}: ${material.toJson()}');
      final response = await http.put(
        Uri.parse('$baseUrl/materials/${material.id}'),
        headers: await getHeaders(),
        body: json.encode(material.toJson()),
      );

      print('Update Material Response Status: ${response.statusCode}');
      print('Update Material Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 1) {
          return MaterialItem.fromJson(responseData['data']);
        } else {
          throw Exception(
            'API returned error status: ${responseData['message']}',
          );
        }
      } else {
        throw Exception(
          'Failed to update material: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error in updateMaterial: $e');
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
  List<Category> _categories = [];
  List<Unit> _units = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Pagination variables
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalItems = 0;
  int _perPage = 10;
  bool _isLoadingMore = false;
  bool _hasNextPage = false;
  bool _hasPrevPage = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterMaterials);
  }

  Future<void> _loadData({int page = 1, bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      // Load materials with pagination
      final materialsResponse = await MaterialApiService.getMaterials(
        page: page,
      );
      // Load categories and units only on first load
      final categories = _categories.isEmpty
          ? await MaterialApiService.getCategories()
          : _categories;
      final units = _units.isEmpty
          ? await MaterialApiService.getUnits()
          : _units;

      setState(() {
        if (loadMore) {
          // Append new materials when loading more
          _allMaterials.addAll(materialsResponse.data);
        } else {
          // Replace materials when loading first page or refreshing
          _allMaterials = materialsResponse.data;
        }

        _filteredMaterials = _allMaterials;
        _categories = categories;
        _units = units;

        // Update pagination info
        _currentPage = materialsResponse.currentPage;
        _lastPage = materialsResponse.lastPage;
        _totalItems = materialsResponse.total;
        _perPage = materialsResponse.perPage;
        _hasNextPage = materialsResponse.nextPageUrl != null;
        _hasPrevPage = materialsResponse.prevPageUrl != null;

        _isLoading = false;
        _isLoadingMore = false;
      });

      print(
        'Loaded ${_allMaterials.length} materials, ${_categories.length} categories, ${_units.length} units',
      );
      print(
        'Pagination: Page $_currentPage of $_lastPage, Total: $_totalItems',
      );
    } catch (e) {
      print('Error in _loadData: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
      _showSnackBar('Failed to load materials: $e');
    }
  }

  void _filterMaterials() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMaterials = _allMaterials.where((material) {
        return material.name.toLowerCase().contains(query) ||
            material.getCategoryName(_categories).toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _loadNextPage() async {
    if (_hasNextPage && _currentPage < _lastPage) {
      await _loadData(page: _currentPage + 1, loadMore: false);
    }
  }

  Future<void> _loadPrevPage() async {
    if (_hasPrevPage && _currentPage > 1) {
      await _loadData(page: _currentPage - 1, loadMore: false);
    }
  }

  void _goToPage(int page) async {
    if (page >= 1 && page <= _lastPage && page != _currentPage) {
      await _loadData(page: page, loadMore: false);
    }
  }

  String _generateAutoSKU() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'MAT$timestamp';
  }

  void _showAddMaterialBottomSheet() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController skuController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController reorderController = TextEditingController();
    String status = 'active';
    int? selectedCategoryId = _categories.isNotEmpty
        ? _categories.first.id
        : null;
    int? selectedUnitId = _units.isNotEmpty ? _units.first.id : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                            labelText: 'Material Name *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.inventory, size: 18),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: skuController,
                          decoration: InputDecoration(
                            labelText: 'SKU *',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.qr_code, size: 18),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.qr_code_2_outlined,
                                size: 18,
                              ),
                              onPressed: () {
                                skuController.text = _generateAutoSKU();
                              },
                              tooltip: 'Generate Auto SKU',
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Category Dropdown
                  DropdownButtonFormField<int>(
                    value: selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category, size: 18),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Text(
                          category.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategoryId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  // Unit Dropdown
                  DropdownButtonFormField<int>(
                    value: selectedUnitId,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.straighten, size: 18),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    items: _units.map((unit) {
                      return DropdownMenuItem<int>(
                        value: unit.id,
                        child: Text(
                          '${unit.name} (${unit.symbol})',
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedUnitId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a unit';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description, size: 18),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
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
                            labelText: 'Price *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.currency_rupee, size: 18),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
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
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Status', style: TextStyle(fontSize: 14)),
                    value: status == 'active',
                    onChanged: (value) {
                      setState(() {
                        status = value ? 'active' : 'inactive';
                      });
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
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
                        final price =
                            double.tryParse(priceController.text) ?? 0.0;
                        final reorder =
                            int.tryParse(reorderController.text) ?? 0;

                        if (name.isEmpty ||
                            sku.isEmpty ||
                            selectedCategoryId == null ||
                            selectedUnitId == null) {
                          _showSnackBar('Please fill all required fields (*)');
                          return;
                        }

                        try {
                          final newMaterial = MaterialItem(
                            id: 0,
                            name: name,
                            sku: sku,
                            categoryId: selectedCategoryId!,
                            unitId: selectedUnitId!,
                            description: description,
                            price: price,
                            reorderLevel: reorder,
                            status: status,
                            siteId: 1,
                            createdBy: 1,
                            workspaceId: 1,
                            createdAt: DateTime.now().toIso8601String(),
                            updatedAt: DateTime.now().toIso8601String(),
                          );

                          final addedMaterial =
                              await MaterialApiService.addMaterial(newMaterial);

                          // Create a new material with proper category and unit data from our lists
                          final category = _categories.firstWhere(
                            (cat) => cat.id == selectedCategoryId,
                            orElse: () => Category(
                              id: selectedCategoryId!,
                              name: 'Unknown',
                              isActive: 1,
                              createdBy: 1,
                              workspaceId: 1,
                              status: '0',
                              createdAt: DateTime.now().toIso8601String(),
                              updatedAt: DateTime.now().toIso8601String(),
                            ),
                          );

                          final unit = _units.firstWhere(
                            (u) => u.id == selectedUnitId,
                            orElse: () => Unit(
                              id: selectedUnitId!,
                              name: 'Unknown',
                              symbol: '',
                              isActive: 1,
                            ),
                          );

                          final completeMaterial = MaterialItem(
                            id: addedMaterial.id,
                            name: addedMaterial.name,
                            sku: addedMaterial.sku,
                            categoryId: addedMaterial.categoryId,
                            unitId: addedMaterial.unitId,
                            description: addedMaterial.description,
                            price: addedMaterial.price,
                            reorderLevel: addedMaterial.reorderLevel,
                            status: addedMaterial.status,
                            image: addedMaterial.image,
                            siteId: addedMaterial.siteId,
                            createdBy: addedMaterial.createdBy,
                            workspaceId: addedMaterial.workspaceId,
                            createdAt: addedMaterial.createdAt,
                            updatedAt: addedMaterial.updatedAt,
                            category: category,
                            unit: unit,
                          );

                          setState(() {
                            _allMaterials.insert(0, completeMaterial);
                            _filterMaterials();
                          });

                          Navigator.pop(context);
                          _showSnackBar('Material added successfully');
                        } catch (e) {
                          _showSnackBar('Failed to add material: $e');
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
                      child: const Text(
                        'Add Material',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditMaterialBottomSheet(MaterialItem material) {
    final TextEditingController nameController = TextEditingController(
      text: material.name,
    );
    final TextEditingController skuController = TextEditingController(
      text: material.sku,
    );
    final TextEditingController descriptionController = TextEditingController(
      text: material.description,
    );
    final TextEditingController priceController = TextEditingController(
      text: material.price.toString(),
    );
    final TextEditingController reorderController = TextEditingController(
      text: material.reorderLevel.toString(),
    );
    String status = material.status;
    int? selectedCategoryId = material.categoryId;
    int? selectedUnitId = material.unitId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                            labelText: 'Material Name *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.inventory, size: 18),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: skuController,
                          decoration: InputDecoration(
                            labelText: 'SKU *',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.qr_code, size: 18),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.refresh, size: 18),
                              onPressed: () {
                                skuController.text = _generateAutoSKU();
                              },
                              tooltip: 'Generate Auto SKU',
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Category Dropdown
                  DropdownButtonFormField<int>(
                    value: selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category, size: 18),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Text(
                          category.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategoryId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  // Unit Dropdown
                  DropdownButtonFormField<int>(
                    value: selectedUnitId,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.straighten, size: 18),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    items: _units.map((unit) {
                      return DropdownMenuItem<int>(
                        value: unit.id,
                        child: Text(
                          '${unit.name} (${unit.symbol})',
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedUnitId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description, size: 18),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
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
                            labelText: 'Price *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.currency_rupee, size: 18),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
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
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Status', style: TextStyle(fontSize: 14)),
                    value: status == 'active',
                    onChanged: (value) {
                      setState(() {
                        status = value ? 'active' : 'inactive';
                      });
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
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
                        final price =
                            double.tryParse(priceController.text) ?? 0.0;
                        final reorder =
                            int.tryParse(reorderController.text) ?? 0;

                        if (name.isEmpty ||
                            sku.isEmpty ||
                            selectedCategoryId == null ||
                            selectedUnitId == null) {
                          _showSnackBar('Please fill all required fields (*)');
                          return;
                        }

                        try {
                          final updatedMaterial = MaterialItem(
                            id: material.id,
                            name: name,
                            sku: sku,
                            categoryId: selectedCategoryId!,
                            unitId: selectedUnitId!,
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

                          await MaterialApiService.updateMaterial(
                            updatedMaterial,
                          );
                          await _loadData(); // Refresh the entire list to get updated data
                          Navigator.pop(context);
                          _showSnackBar('Material updated successfully');
                        } catch (e) {
                          _showSnackBar('Failed to update material: $e');
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
                      child: const Text(
                        'Update Material',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
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
        await _loadData(); // Refresh the list
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
                child: Icon(Icons.inventory, color: Colors.grey[600], size: 40),
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
                    _buildDetailRow(
                      'Category',
                      material.getCategoryName(_categories),
                    ),
                    const Divider(),
                    _buildDetailRow('Unit', material.getUnitName(_units)),
                    const Divider(),
                    _buildDetailRow('Price', '₹${material.price}'),
                    const Divider(),
                    _buildDetailRow(
                      'Reorder Level',
                      material.reorderLevel.toString(),
                    ),
                    const Divider(),
                    _buildDetailRow(
                      'Status',
                      material.status == 'active' ? 'Active' : 'Inactive',
                      valueColor: material.status == 'active'
                          ? Colors.green
                          : Colors.red,
                    ),
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

  // Build pagination controls widget
  Widget _buildPaginationControls() {
    return Container(
      margin: EdgeInsets.only(top: 10.h),
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Page info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Page $_currentPage of $_lastPage',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '$_totalItems items total',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Pagination buttons - Simple layout
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Previous button
              Flexible(
                child: GestureDetector(
                  onTap: _hasPrevPage ? _loadPrevPage : null,
                  child: Container(
                    height: 30,
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _hasPrevPage
                          ? const Color(0xFF2a43a0)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chevron_left,
                          size: 18.sp,
                          color: _hasPrevPage ? Colors.white : Colors.grey[500],
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Prev',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: _hasPrevPage
                                ? Colors.white
                                : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),

              // Current page indicator
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  '$_currentPage',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2a43a0),
                  ),
                ),
              ),

              SizedBox(width: 8.w),

              // Next button
              Flexible(
                child: GestureDetector(
                  onTap: _hasNextPage ? _loadNextPage : null,
                  child: Container(
                    height: 30,
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _hasNextPage
                          ? const Color(0xFF2a43a0)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chevron_right,
                          size: 18.sp,
                          color: _hasNextPage ? Colors.white : Colors.grey[500],
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: _hasNextPage
                                ? Colors.white
                                : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSmartPageNumbers() {
    final List<Widget> pages = [];

    // Always show first page
    pages.add(_buildPageNumberButton(1));

    if (_currentPage > 3) {
      pages.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            '...',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
          ),
        ),
      );
    }

    // Show pages around current page
    final start = _currentPage > 2 ? _currentPage - 1 : 2;
    final end = _currentPage < _lastPage - 1 ? _currentPage + 1 : _lastPage - 1;

    for (int i = start; i <= end; i++) {
      if (i > 1 && i < _lastPage) {
        pages.add(_buildPageNumberButton(i));
      }
    }

    if (_currentPage < _lastPage - 2) {
      pages.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            '...',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
          ),
        ),
      );
    }

    // Always show last page
    if (_lastPage > 1) {
      pages.add(_buildPageNumberButton(_lastPage));
    }

    return pages;
  }

  Widget _buildPageNumberButton(int pageNumber) {
    final isActive = pageNumber == _currentPage;
    return GestureDetector(
      onTap: () => _goToPage(pageNumber),
      child: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2a43a0) : Colors.transparent,
          border: Border.all(
            color: isActive ? const Color(0xFF2a43a0) : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Text(
            '$pageNumber',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Material',
          style: TextStyle(color: Colors.white),
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
            icon: Icon(Icons.refresh, size: 24.sp, color: Colors.white),
            onPressed: () => _loadData(),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _showAddMaterialBottomSheet,
            icon: Icon(Icons.add, size: 24.sp, color: Colors.white),
            tooltip: 'Add Material',
          ),
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
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_errorMessage.isNotEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading materials',
                        style: TextStyle(fontSize: 16.sp, color: Colors.red),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _errorMessage,
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_allMaterials.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64.sp,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'No materials found',
                        style: TextStyle(
                          fontSize: 18.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Add your first material to get started',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: _showAddMaterialBottomSheet,
                        child: const Text('Add Material'),
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
                  'Showing ${_filteredMaterials.length} of $_totalItems entries',
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
                child: Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _loadData(),
                        child: ListView.builder(
                          itemCount:
                              _filteredMaterials.length +
                              (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _filteredMaterials.length &&
                                _isLoadingMore) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final material = _filteredMaterials[index];
                            return InkWell(
                              onTap: () =>
                                  _showMaterialDetailsBottomSheet(material),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                              'Category: ${material.getCategoryName(_categories)}',
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              'Unit: ${material.getUnitName(_units)}   |   Price: ₹${material.price}',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              'Status: ${material.status == 'active' ? 'Active' : 'Inactive'}',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color:
                                                    material.status == 'active'
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Actions
                                      Column(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () =>
                                                _showEditMaterialBottomSheet(
                                                  material,
                                                ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () =>
                                                _deleteMaterial(material),
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

                    // Pagination Controls
                    if (_lastPage > 1) _buildPaginationControls(),
                  ],
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
