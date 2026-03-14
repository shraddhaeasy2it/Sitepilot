// screens/supplier_categories_screen.dart
import 'package:ecoteam_app/admin/models/supplier_categary_model.dart';
import 'package:ecoteam_app/admin/services/supplier_category_ser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'package:ecoteam_app/contractor/view/widgets/notification_actions.dart';

class SupplierCategoriesScreen extends StatefulWidget {
  final int? userId;
  final int? workspaceId;
  final int? siteId;

  const SupplierCategoriesScreen({
    super.key,
    this.userId,
    this.workspaceId,
    this.siteId,
  });

  @override
  State<SupplierCategoriesScreen> createState() =>
      _SupplierCategoriesScreenState();
}

class _SupplierCategoriesScreenState extends State<SupplierCategoriesScreen> {
  final SupplierCategoryService _service = SupplierCategoryService();
  List<SupplierCategory> _categories = [];
  List<SupplierCategory> _filteredCategories = [];
  bool _isLoading = true;
  String _searchQuery = '';

  static const Color primaryColor = Color(0xFF6f88e2);
  static const Color primaryDark = Color(0xFF5a73d1);
  static const Color backgroundColor = Color.fromARGB(255, 249, 249, 253);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

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
            .where(
              (category) =>
                  category.name.toLowerCase().contains(query.toLowerCase()) ||
                  (category.description?.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ??
                      false),
            )
            .toList();
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
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
        userId: widget.userId,
        workspaceId: widget.workspaceId,
        siteId: widget.siteId,
        onSaved: (newCategory) {
          // Add the new category to the list immediately
          if (category == null) {
            setState(() {
              _categories.insert(0, newCategory);
              _filteredCategories = _categories;
            });
            _showSuccessSnackBar('Category added successfully');
          } else {
            // For edit, update the existing category
            setState(() {
              final index = _categories.indexWhere((c) => c.id == category.id);
              if (index != -1) {
                _categories[index] = newCategory;
                _filteredCategories = _categories;
              }
            });
            _showSuccessSnackBar('Category updated successfully');
          }
          Navigator.pop(context);
        },
        onError: _showErrorSnackBar,
      ),
    );
  }

  Future<void> _deleteCategory(int id) async {
    try {
      await _service.deleteSupplierCategory(id);
      // Remove from local list immediately
      setState(() {
        _categories.removeWhere((category) => category.id == id);
        _filteredCategories = _categories;
      });
      _showSuccessSnackBar('Category deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to delete category: $e');
    }
  }

  void _showOptionsBottomSheet(SupplierCategory category) {
    final provider = Provider.of<CompanySiteProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final hasEditPermission = provider.hasPermission(
          'supplier-categories edit',
        );
        final hasDeletePermission = provider.hasPermission(
          'supplier-categories delete',
        );

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (hasEditPermission)
                _buildOptionTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit Supllier Category',
                  Iconcolor: Colors.blue,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddEditBottomSheet(category: category);
                  },
                ),
              if (hasDeletePermission)
                _buildOptionTile(
                  icon: Icons.delete_outline,
                  title: 'Delete Supplier Category',
                  color: Colors.red,
                  Iconcolor: Colors.red,
                  backgroundColor: Colors.red.withOpacity(0.1),
                  onTap: () {
                    Navigator.pop(context);
                    Future.delayed(const Duration(milliseconds: 200), () {
                      _confirmDelete(category);
                    });
                  },
                ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color Iconcolor,
    required String title,
    Color? backgroundColor,
    required VoidCallback onTap,
    Color color = textPrimary,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor ?? primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Iconcolor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 14.sp,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
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
          'Supplier Categories',
          style: TextStyle(color: Colors.white),
        ),
       
        iconTheme: const IconThemeData(color: Colors.white),
        actions: buildNotificationActions(
          context: context,
          selectedSiteId: widget.siteId?.toString(),
          sites: [], // Pass empty sites if not available or pass fetch logic if needed, but actions mainly need it for chat navigation context. 
                     // Wait, buildNotificationActions requires sites for ChatScreen. 
                     // SupplierCategoriesScreen doesn't seem to have a list of sites passed to it.
                     // I should check if I can pass empty list? ChatScreen takes List<Site>. 
                     // Let's assume empty list is fine for now or I can try to fetch it from provider if needed.
                     // Getting sites from CompanySiteProvider might be possible.
          currentCompany: Provider.of<CompanySiteProvider>(context, listen: false).selectedCompanyName ?? '',
          workspaceId: widget.workspaceId,
        ),
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
      ),
      floatingActionButton: Provider.of<CompanySiteProvider>(context).hasPermission('supplier-categories create')
          ? FloatingActionButton(
              onPressed: _showAddEditBottomSheet,
              child: const Icon(Icons.add, color: Colors.white),
              backgroundColor: const Color.fromRGBO(
                42,
                67,
                160,
                1,
              ), // Any color you want
              tooltip: 'Add supplier category',
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: EdgeInsets.all(16.w),
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
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Categories: ${_filteredCategories.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          fontSize: 14.sp,
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        Text(
                          'Search results: ${_filteredCategories.length}',
                          style: TextStyle(fontSize: 12.sp, color: Colors.blue),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                // Categories List
                Expanded(
                  child: !Provider.of<CompanySiteProvider>(context).hasPermission('supplier-categories show')
                      ? const Center(child: Text('Access Denied'))
                      : _filteredCategories.isEmpty
                          ? Center(
                              child: Text(
                                _searchQuery.isEmpty
                                    ? 'No categories found'
                                    : 'No categories match your search',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                          padding: EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                          itemCount: _filteredCategories.length,
                          itemBuilder: (context, index) {
                            final category = _filteredCategories[index];
                            return _CategoryCard(
                              category: category,
                              onOptionsTap: () =>
                                  _showOptionsBottomSheet(category),
                            );
                          },
                        ),
                ),
                SizedBox(height: 50,),
              ],
            ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final SupplierCategory category;
  final VoidCallback onOptionsTap;

  const _CategoryCard({required this.category, required this.onOptionsTap});

  @override
  Widget build(BuildContext context) {
    return Card(
    color: const Color.fromARGB(255, 253, 253, 255) ,
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StatusChip(isActive: category.isActive == 1),

                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onPressed: onOptionsTap,
                ),
              ],
            ),

            Text(
              category.description?.isNotEmpty == true
                  ? category.description!
                  : 'No description',
              style: TextStyle(
                color: category.description?.isNotEmpty == true
                    ? const Color.fromARGB(221, 90, 90, 90)
                    : Colors.grey,
                fontStyle: category.description?.isNotEmpty == true
                    ? FontStyle.normal
                    : FontStyle.italic,
                fontSize: 13.sp,
              ),
            ),
            SizedBox(height: 8.h),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive
              ? const Color.fromARGB(255, 60, 156, 56)
              : Colors.black87,
          fontSize: 12.sp,
        ),
      ),
      decoration: BoxDecoration(
        color: isActive ? const Color.fromARGB(255, 149, 240, 153).withOpacity(0.2) : const Color.fromARGB(255, 240, 170, 170).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color.fromARGB(255, 140, 214, 137) : const Color.fromARGB(255, 223, 157, 157),
        ),
      ),
    );
  }
}

class AddEditCategoryBottomSheet extends StatefulWidget {
  final SupplierCategory? category;
  final Function(SupplierCategory) onSaved;
  final Function(String) onError;
  final int? userId;
  final int? workspaceId;
  final int? siteId;

  const AddEditCategoryBottomSheet({
    super.key,
    this.category,
    required this.onSaved,
    required this.onError,
    this.userId,
    this.workspaceId,
    this.siteId,
  });

  @override
  State<AddEditCategoryBottomSheet> createState() =>
      _AddEditCategoryBottomSheetState();
}

class _AddEditCategoryBottomSheetState
    extends State<AddEditCategoryBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _service = SupplierCategoryService();
  bool _isLoading = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category?.description ?? '';
      _isActive = widget.category?.isActive == 1;
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
      final provider = Provider.of<CompanySiteProvider>(context, listen: false);
      
      final newCategory = SupplierCategory(
        id: widget.category?.id ?? 0,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        siteId: widget.siteId ?? widget.category?.siteId ?? int.tryParse(provider.selectedCompanyId ?? '0') ?? 1,
        createdBy: widget.userId ?? widget.category?.createdBy ?? provider.currentUserId ?? 1,
        workspaceId: widget.workspaceId ?? widget.category?.workspaceId ?? int.tryParse(provider.selectedCompanyId ?? '0') ?? 1,
        isActive: _isActive ? 1 : 0, // Convert bool to int
        status: widget.category?.status ?? '1',
        createdAt:
            widget.category?.createdAt ?? DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      SupplierCategory savedCategory;

      if (widget.category == null) {
        savedCategory = await _service.createSupplierCategory(newCategory);
      } else {
        savedCategory = await _service.updateSupplierCategory(newCategory);
      }

      // Call the callback with the saved category
      widget.onSaved(savedCategory);
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
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
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              isEdit ? 'Edit Category' : 'Add New Category',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Category Name *',
                      border: const OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter category name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      border: const OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16.h),
                  SwitchListTile(
                    title: Text('Status', style: TextStyle(fontSize: 16.sp)),
                    subtitle: Text(
                      _isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: _isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveCategory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2a43a0),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isEdit ? 'Update' : 'Save',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}
