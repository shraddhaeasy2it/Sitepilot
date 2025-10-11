import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/unit_model.dart';
import '../provider/unit_provider.dart';

class UnitManagementPage extends StatefulWidget {
  const UnitManagementPage({super.key});

  @override
  State<UnitManagementPage> createState() => _UnitManagementPageState();
}

class _UnitManagementPageState extends State<UnitManagementPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUnits();
    });
    _searchController.addListener(() {
      final provider = Provider.of<UnitProvider>(context, listen: false);
      provider.setSearchQuery(_searchController.text);
    });
  }

  Future<void> _loadUnits() async {
    try {
      final provider = Provider.of<UnitProvider>(context, listen: false);
      await provider.fetchUnits();
    } catch (e) {
      print('Error loading units: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
  backgroundColor: Colors.grey[50],
  appBar: _buildAppBar(),
  body: Consumer<UnitProvider>(
    builder: (context, provider, child) {
      if (provider.isLoading && provider.units.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF4a63c0)),
        );
      }

      return RefreshIndicator(
        onRefresh: () => provider.refreshUnits(),
        color: const Color(0xFF4a63c0),
        child: Column(
          children: [
            _buildSearchSection(provider),
            Expanded(
              child: provider.filteredUnits.isEmpty
                  ? _buildEmptyState(provider)
                  : _buildUnitsList(provider),
            ),
          ],
        ),
      );
    },
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
        children: [
          Text(
            'Unit Management',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Manage measurement units',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white70,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        // IconButton(
        //     icon: Icon(
        //       Icons.refresh,
        //       size: 24.sp,
        //       color: Colors.white,
        //     ),
        //     onPressed: () => _loadUnits(),
        //     tooltip: 'Refresh',
        //   ),
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () => _showAddEditBottomSheet(context),
          tooltip: 'Add Unit',
        ),
      ],
    );
  }

  Widget _buildSearchSection(UnitProvider provider) {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search units by name or symbol...',
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
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
        ),
      ),
    );
  }

  Widget _buildUnitsList(UnitProvider provider) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: provider.filteredUnits.length,
      itemBuilder: (context, index) {
        final unit = provider.filteredUnits[index];
        return _buildUnitCard(unit, provider);
      },
    );
  }

  Widget _buildUnitCard(Unit unit, UnitProvider provider) {
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
            // Icon Section
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: const Color(0xFF4a63c0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.straighten,
                color: const Color(0xFF4a63c0),
                size: 20.sp,
              ),
            ),
            SizedBox(width: 16.w),
            // Info Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: unit.name,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                            letterSpacing: -0.4,
                          ),
                        ),
                        TextSpan(
                          text: " (${unit.symbol})",
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
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
                          'Updated: ${DateFormat('MMM dd').format(unit.updatedAt)}',
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
                ],
              ),
            ),
            // Right Section - Actions
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showAddEditBottomSheet(context, unit: unit);
                } else if (value == 'delete') {
                  _showDeleteDialog(context, unit, provider);
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

  Widget _buildEmptyState(UnitProvider provider) {
    final hasSearchQuery = _searchController.text.isNotEmpty;
    
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
              Icons.straighten_outlined,
              size: 64.sp,
              color: const Color(0xFF4a63c0),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            hasSearchQuery ? 'No Units Found' : 'No Units Added',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            hasSearchQuery 
                ? 'Try adjusting your search terms'
                : 'Add your first measurement unit to get started',
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          if (!hasSearchQuery) ...[
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => _showAddEditBottomSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4a63c0),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Add First Unit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddEditBottomSheet(BuildContext context, {Unit? unit}) {
    final isEditing = unit != null;
    final nameController = TextEditingController(text: unit?.name ?? '');
    final symbolController = TextEditingController(text: unit?.symbol ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.8,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24.w,
                    24.h,
                    24.w,
                    24.h + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle bar
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
                        // Title
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
                                isEditing ? 'Edit Unit' : 'Add New Unit',
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
                        // Form fields
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Unit Name',
                            hintText: 'e.g., Meter, Kilogram, Square Feet',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(
                                color: Color(0xFF4a63c0),
                                width: 2,
                              ),
                            ),
                            prefixIcon: const Icon(
                              Icons.straighten,
                              color: Color(0xFF4a63c0),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter unit name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20.h),
                        TextFormField(
                          controller: symbolController,
                          decoration: InputDecoration(
                            labelText: 'Unit Symbol',
                            hintText: 'e.g., m, kg, sq ft, bag, pcs',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(
                                color: Color(0xFF4a63c0),
                                width: 2,
                              ),
                            ),
                            prefixIcon: const Icon(
                              Icons.label,
                              color: Color(0xFF4a63c0),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter unit symbol';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 32.h),
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () => Navigator.pop(context),
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
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        if (formKey.currentState!.validate()) {
                                          setModalState(() {
                                            isSubmitting = true;
                                          });

                                          try {
                                            final provider =
                                                Provider.of<UnitProvider>(
                                              context,
                                              listen: false,
                                            );

                                            if (isEditing) {
                                              // Update existing unit
                                              final updatedUnit = unit.copyWith(
                                                name: nameController.text.trim(),
                                                symbol: symbolController.text.trim(),
                                                updatedAt: DateTime.now(),
                                              );
                                              await provider.updateUnit(updatedUnit);
                                            } else {
                                              // Create new unit with all required fields
                                              final newUnit = Unit(
                                                id: 0,
                                                name: nameController.text.trim(),
                                                symbol: symbolController.text.trim(),
                                                description: '',
                                                isActive: true,
                                                siteId: 1,
                                                workspaceId: 1,
                                                createdBy: 1, // This is the crucial field that was missing
                                                createdAt: DateTime.now(),
                                                updatedAt: DateTime.now(),
                                              );
                                              await provider.addUnit(newUnit);
                                            }

                                            Navigator.pop(context);
                                            _showSuccessSnackBar(
                                              isEditing
                                                  ? 'Unit updated successfully'
                                                  : 'Unit added successfully',
                                            );
                                          } catch (e) {
                                            // Extract meaningful error message
                                            String errorMessage = e.toString();
                                            if (errorMessage.contains('Exception: ')) {
                                              errorMessage = errorMessage.split('Exception: ').last;
                                            }
                                            _showErrorSnackBar(errorMessage);
                                          } finally {
                                            setModalState(() {
                                              isSubmitting = false;
                                            });
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4a63c0),
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  elevation: 2,
                                ),
                                child: isSubmitting
                                    ? SizedBox(
                                        width: 20.w,
                                        height: 20.h,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        isEditing ? 'Update Unit' : 'Add Unit',
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
          );
        },
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    // Clean up the error message
    String displayMessage = message;
    if (message.contains('422')) {
      displayMessage = 'Validation error: Please check all required fields are filled correctly.';
    } else if (message.contains('404')) {
      displayMessage = 'Server endpoint not found. Please check the API URL.';
    } else if (message.contains('500')) {
      displayMessage = 'Server error. Please try again later.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(displayMessage),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    Unit unit,
    UnitProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Delete Unit',
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
          'Are you sure you want to delete "${unit.name} (${unit.symbol})"?\n\nThis action cannot be undone.',
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
                print('Sending delete request for ID: ${unit.id}');
                await provider.deleteUnit(unit.id);
                Navigator.pop(context);
                _showSuccessSnackBar('Unit deleted successfully');
              } catch (e) {
                Navigator.pop(context);
                _showErrorSnackBar('Delete failed: ${e.toString()}');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}