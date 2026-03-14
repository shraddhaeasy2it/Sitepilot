import 'package:ecoteam_app/admin/models/MachineryCategory_model.dart';
import 'package:ecoteam_app/admin/services/machineryCategory_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'package:ecoteam_app/contractor/view/widgets/notification_actions.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/chat_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/notification.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MachineryCategoriesScreen extends StatefulWidget {
  final int? siteId;
  const MachineryCategoriesScreen({super.key, this.siteId});

  @override
  State<MachineryCategoriesScreen> createState() =>
      _MachineryCategoriesScreenState();
}

class _MachineryCategoriesScreenState extends State<MachineryCategoriesScreen> {
  final MachineryCategoryService _service = MachineryCategoryService();
  final TextEditingController _searchController = TextEditingController();

  List<MachineryCategory> _categories = [];
  List<MachineryCategory> _filteredCategories = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final companyProvider = Provider.of<CompanySiteProvider>(
        context,
        listen: false,
      );
      final dynamicWorkspaceId = int.tryParse(companyProvider.selectedCompanyId ?? '');
      
      print('DEBUG: Loading Machinery Categories - WorkspaceID: $dynamicWorkspaceId, SiteID: 0');

      final categories = await _service.getCategories(
        workspaceId: dynamicWorkspaceId,
        siteId: 0,
      );
      setState(() {
        _categories = categories;
        _filteredCategories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = _categories;
      } else {
        _filteredCategories = _categories
            .where(
              (category) =>
                  category.name.toLowerCase().contains(query) ||
                  category.description.toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  void _showAddCategorySheet() {
    final provider = Provider.of<CompanySiteProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CategoryFormBottomSheet(
        onSave: (categoryData) async {
          try {
            await _service.createCategory(
              categoryData['name']!,
              categoryData['description']!,

              status: categoryData['status'] ?? '0',
              createdBy: provider.currentUserId ?? 0,

              workspaceId: int.tryParse(provider.selectedCompanyId ?? '0') ?? 0,
              siteId: widget.siteId,
            );
            if (!mounted) return;
            Navigator.pop(context);
            _loadCategories();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Category created successfully')),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
      ),
    );
  }

  void _showEditCategorySheet(MachineryCategory category) {
    final provider = Provider.of<CompanySiteProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CategoryFormBottomSheet(
        category: category,
        onSave: (categoryData) async {
          try {
            await _service.updateCategory(
              category.id,
              categoryData['name']!,
              categoryData['description']!,

              status: categoryData['status'] ?? '0',
              createdBy: provider.currentUserId ?? 0,

              workspaceId: int.tryParse(provider.selectedCompanyId ?? '0') ?? 0,
              siteId: widget.siteId,
            );
            if (!mounted) return;
            Navigator.pop(context);
            _loadCategories();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Category updated successfully')),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
      ),
    );
  }

  void _showDeleteDialog(MachineryCategory category) {
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
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _service.deleteCategory(category.id);
                _loadCategories();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Category deleted successfully'),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showOptionsBottomSheet(MachineryCategory category) {
    final provider = Provider.of<CompanySiteProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              if (provider.hasPermission('machinery-categories edit'))
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF2a43a0)),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditCategorySheet(category);
                },
              ),
              if (provider.hasPermission('machinery-categories delete'))
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(category);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Machinery Categories',
          style: TextStyle(color: Colors.white),
        ),
        toolbarHeight: 80.h,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
        actions: buildNotificationActions(
          context: context,
          selectedSiteId: null,
          sites: Provider.of<CompanySiteProvider>(context, listen: false).sites,
          currentCompany: Provider.of<CompanySiteProvider>(context, listen: false).selectedCompanyName ?? '',
          workspaceId: int.tryParse(Provider.of<CompanySiteProvider>(context, listen: false).selectedCompanyId ?? '0'),
        ),
      ),
      floatingActionButton: Provider.of<CompanySiteProvider>(context).hasPermission('machinery-categories create')
          ? FloatingActionButton(
              onPressed: _showAddCategorySheet,
              child: const Icon(Icons.add, color: Colors.white),
              backgroundColor: const Color.fromRGBO(
                42,
                67,
                160,
                1,
              ), // Any color you want
              tooltip: 'Add New Machinery Category',
            )
          : null,
      body: Column(
        children: [
          // Search Bar and Total Count
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Entries: ${_filteredCategories.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Error Message
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        setState(() {
                          _errorMessage = '';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Categories List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCategories.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No categories found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                   // padding: const EdgeInsets.only(bottom: 90),
                    padding: EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                    itemCount: _filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = _filteredCategories[index];
                      return CategoryCard(
                        category: category,
                        onOptionsTap: () => _showOptionsBottomSheet(category),
                      );
                      
                    },
                    
                  ),
                  
          ),
          SizedBox(height: 60,),
        ],
      ),
    );
  }
}

// Category Card Widget
class CategoryCard extends StatelessWidget {
  final MachineryCategory category;
  final VoidCallback onOptionsTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onOptionsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Color.fromARGB(255, 136, 136, 136),
                  ),
                  onPressed: onOptionsTap,
                  tooltip: 'Options',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String text, Color color) {
    return Chip(
      label: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      labelPadding: const EdgeInsets.symmetric(horizontal: 3),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Bottom Sheet Form
class CategoryFormBottomSheet extends StatefulWidget {
  final MachineryCategory? category;
  final Function(Map<String, dynamic> categoryData) onSave;

  const CategoryFormBottomSheet({
    super.key,
    this.category,
    required this.onSave,
  });

  @override
  State<CategoryFormBottomSheet> createState() =>
      _CategoryFormBottomSheetState();
}

class _CategoryFormBottomSheetState extends State<CategoryFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _status = '0';

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category!.description;
      _status = widget.category!.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveCategory() {
    if (_formKey.currentState!.validate()) {
      final categoryData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': _status,
      };
      widget.onSave(categoryData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
      ),
      child: Form(
        key: _formKey,
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
              widget.category == null
                  ? 'Create Machinery Category'
                  : 'Edit Machinery Category',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name*',
                border: OutlineInputBorder(),
                hintText: 'Enter Category Name',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter category name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description*',
                border: OutlineInputBorder(),
                hintText: 'Enter Description',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // // Status Field
            // DropdownButtonFormField<String>(
            //   value: _status,
            //   decoration: const InputDecoration(
            //     labelText: 'Status*',
            //     border: OutlineInputBorder(),
            //   ),
            //   items: const [
            //     DropdownMenuItem(value: '0', child: Text('Inactive')),
            //     DropdownMenuItem(value: '1', child: Text('Active')),
            //   ],
            //   onChanged: (value) {
            //     setState(() {
            //       _status = value!;
            //     });
            //   },
            //   validator: (value) {
            //     if (value == null || value.isEmpty) {
            //       return 'Please select status';
            //     }
            //     return null;
            //   },
            // ),
            // const SizedBox(height: 24),

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
                    onPressed: _saveCategory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:  Color(0xFF2a43a0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(widget.category == null ? 'Create' : 'Update'),
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
