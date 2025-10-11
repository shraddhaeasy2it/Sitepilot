// screens/supplier_categories_screen.dart
import 'dart:convert';
import 'package:ecoteam_app/admin/models/supplier_categary_model.dart';
import 'package:ecoteam_app/admin/services/supplier_category_ser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;


class SupplierCategoriesScreen extends StatefulWidget {
  const SupplierCategoriesScreen({super.key});

  @override
  State<SupplierCategoriesScreen> createState() => _SupplierCategoriesScreenState();
}

class _SupplierCategoriesScreenState extends State<SupplierCategoriesScreen> {
  final SupplierCategoryService _service = SupplierCategoryService();
  List<SupplierCategory> _categories = [];
  List<SupplierCategory> _filteredCategories = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await _service.getSupplierCategories();
      setState(() {
        _categories = response.data;
        _filteredCategories = _categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load categories: $e');
    }
  }

  void _filterCategories(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCategories = _categories;
      } else {
        _filteredCategories = _categories
            .where((category) =>
                category.name.toLowerCase().contains(query.toLowerCase()) ||
                (category.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
            .toList();
      }
    });
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

  void _showAddEditBottomSheet({SupplierCategory? category}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditCategoryBottomSheet(
        category: category,
        onSaved: () {
          _loadCategories();
          Navigator.pop(context);
          _showSuccessSnackBar(
            category == null ? 'Category added successfully' : 'Category updated successfully',
          );
        },
        onError: _showErrorSnackBar,
      ),
    );
  }

  Future<void> _deleteCategory(int id) async {
    try {
      await _service.deleteSupplierCategory(id);
      _loadCategories();
      _showSuccessSnackBar('Category deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to delete category: $e');
    }
  }

  void _confirmDelete(SupplierCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(category.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Categories',style: TextStyle(color:Colors.white),),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditBottomSheet(),
          ),
        ],
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: _filterCategories,
                  ),
                ),
                // Total Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Categories: ${_filteredCategories.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        Text(
                          'Search results: ${_filteredCategories.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Categories List
                Expanded(
                  child: _filteredCategories.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No categories found'
                                : 'No categories match your search',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _filteredCategories.length,
                          itemBuilder: (context, index) {
                            final category = _filteredCategories[index];
                            return _CategoryCard(
                              category: category,
                              onEdit: () => _showAddEditBottomSheet(category: category),
                              onDelete: () => _confirmDelete(category),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final SupplierCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
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
                    category.name,
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
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              category.description ?? 'No description',
              style: TextStyle(
                color: category.description == null ? Colors.grey : Colors.black87,
                fontStyle: category.description == null ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatusChip(isActive: category.isActive == 1),
                const SizedBox(width: 8),
                Text(
                  'ID: ${category.id}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? Colors.white : Colors.black87,
          fontSize: 12,
        ),
      ),
      backgroundColor: isActive ? Colors.green : Colors.grey[300],
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class AddEditCategoryBottomSheet extends StatefulWidget {
  final SupplierCategory? category;
  final VoidCallback onSaved;
  final Function(String) onError;

  const AddEditCategoryBottomSheet({
    super.key,
    this.category,
    required this.onSaved,
    required this.onError,
  });

  @override
  State<AddEditCategoryBottomSheet> createState() => _AddEditCategoryBottomSheetState();
}

class _AddEditCategoryBottomSheetState extends State<AddEditCategoryBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _service = SupplierCategoryService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category?.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.category == null) {
        // For creating new category, send minimal data
        final Map<String, dynamic> categoryData = {
          'name': _nameController.text.trim(),
          'is_active': 1,
          'site_id': null,
          'created_by': 1,
          'workspace_id': 1,
          'status': '1',
        };

        final response = await http.post(
          Uri.parse('${SupplierCategoryService.baseUrl}supplier-categories'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode(categoryData),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          widget.onSaved();
        } else {
          throw Exception('Failed to create category: ${response.statusCode} - ${response.body}');
        }
      } else {
        // For updating existing category
        final Map<String, dynamic> categoryData = {
          'name': _nameController.text.trim(),
          'is_active': widget.category!.isActive,
          'site_id': widget.category!.siteId,
          'created_by': widget.category!.createdBy,
          'workspace_id': widget.category!.workspaceId,
          'status': widget.category!.status,
        };

        final response = await http.put(
          Uri.parse('${SupplierCategoryService.baseUrl}supplier-categories/${widget.category!.id}'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode(categoryData),
        );

        if (response.statusCode == 200) {
          widget.onSaved();
        } else {
          throw Exception('Failed to update category: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      widget.onError('Failed to save category: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEdit ? 'Edit Category' : 'Add New Category',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter category name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveCategory,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEdit ? 'Update' : 'Save'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}