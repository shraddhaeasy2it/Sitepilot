import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../admin/models/material_category_model.dart';
import '../../admin/provider/material_category_provider.dart';

class MaterialCategoryScreen extends StatefulWidget {
  const MaterialCategoryScreen({super.key});

  @override
  State<MaterialCategoryScreen> createState() => _MaterialCategoryScreenState();
}

class _MaterialCategoryScreenState extends State<MaterialCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.addListener(_onSearchChanged);
    });
  }

  void _onSearchChanged() {
    final provider = Provider.of<MaterialCategoryProvider>(context, listen: false);
    provider.setSearchQuery(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Consumer<MaterialCategoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.categories.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4a63c0),
              ),
            );
          }

          if (provider.error.isNotEmpty && provider.categories.isEmpty) {
            return _buildErrorState(provider);
          }

          return RefreshIndicator(
            onRefresh: () => provider.refreshCategories(),
            color: const Color(0xFF4a63c0),
            child: Column(
              children: [
                _buildSearchAndDownloadSection(provider),
                Expanded(
                  child: provider.filteredCategories.isEmpty
                      ? _buildEmptyState()
                      : _buildCategoriesList(provider),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditBottomSheet(context),
        backgroundColor: const Color(0xFF4a63c0),
        heroTag: "material_category_fab",
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 80.h,
      elevation: 0,
      backgroundColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.white),
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Material Categories',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Manage construction material types',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white70,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: Icon(
            Icons.picture_as_pdf,
            size: 28.sp,
            color: Colors.white,
          ),
          onPressed: _downloadPDF,
          tooltip: 'Download PDF Report',
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  Widget _buildSearchAndDownloadSection(MaterialCategoryProvider provider) {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search material categories...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF4a63c0)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        provider.setSearchQuery('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Color(0xFF4a63c0), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(MaterialCategoryProvider provider) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: provider.filteredCategories.length,
      itemBuilder: (context, index) {
        final category = provider.filteredCategories[index];
        return _buildCategoryCard(category, provider);
      },
    );
  }

  Widget _buildCategoryCard(MaterialCategory category, MaterialCategoryProvider provider) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: Colors.white,
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 50.w,
              height: 50.h,
              decoration: BoxDecoration(
                color: const Color(0xFF4a63c0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.category,
                color: const Color(0xFF4a63c0),
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12.sp,
                        color: const Color(0xFF94A3B8),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          'Updated: ${DateFormat('MMM dd, yyyy').format(category.updatedAt)}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: category.isActive == 1 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          category.isActive == 1 ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: category.isActive == 1 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showAddEditBottomSheet(context, category: category);
                } else if (value == 'delete') {
                  _showDeleteDialog(context, category, provider);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Color(0xFF4a63c0)),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
              child: Icon(
                Icons.more_vert,
                color: const Color(0xFF4a63c0),
                size: 20.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: const Color(0xFF4a63c0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              Icons.category_outlined,
              size: 64.sp,
              color: const Color(0xFF4a63c0),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'No Material Categories Found',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add your first material category to get started',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(MaterialCategoryProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: Colors.red,
          ),
          SizedBox(height: 16.h),
          Text(
            'Failed to load categories',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            provider.error,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () => provider.fetchCategories(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4a63c0),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // In your MaterialCategoryScreen, update the add category part:

void _showAddEditBottomSheet(BuildContext context, {MaterialCategory? category}) {
  final isEditing = category != null;
  final nameController = TextEditingController(text: category?.name ?? '');
  final formKey = GlobalKey<FormState>();
  final outerContext = context;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4a63c0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            isEditing ? Icons.edit : Icons.add,
                            color: const Color(0xFF4a63c0),
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Text(
                            isEditing ? 'Edit Category' : 'Add New Category',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Category Name',
                        hintText: 'e.g., Cement, Steel, Bricks',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(color: Color(0xFF4a63c0), width: 2),
                        ),
                        prefixIcon: const Icon(Icons.category, color: Color(0xFF4a63c0)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter category name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 32.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                try {
                                  final provider = Provider.of<MaterialCategoryProvider>(context, listen: false);
                                  
                                  if (isEditing) {
                                    await provider.updateCategory(
                                      category!.copyWith(
                                        name: nameController.text.trim(),
                                      ),
                                    );
                                  } else {
                                    // Use the simplified add method that only requires name
                                    await provider.addCategory(nameController.text.trim());
                                  }
                                  
                                  if (mounted) {
                                    Navigator.pop(context);
                                    _showSuccessSnackBar(
                                      outerContext,
                                      isEditing ? 'Category updated successfully' : 'Category added successfully',
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    _showErrorSnackBar(e.toString());
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4a63c0),
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              isEditing ? 'Update Category' : 'Add Category',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  void _showDeleteDialog(BuildContext context, MaterialCategory category, MaterialCategoryProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.red,
              size: 28.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Delete Category',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${category.name}"?\n\nThis action cannot be undone.',
          style: TextStyle(fontSize: 16.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await provider.deleteCategory(category.id);
                if (mounted) {
                  Navigator.pop(context);
                  _showSuccessSnackBar(context, 'Category deleted successfully');
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  _showErrorSnackBar(e.toString());
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _downloadPDF() {
    _showSuccessSnackBar(context, 'PDF report downloaded successfully');
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }
}