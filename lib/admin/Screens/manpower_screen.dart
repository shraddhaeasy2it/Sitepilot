// screens/manpower_types_screen.dart
import 'package:ecoteam_app/admin/models/mapower_model.dart';
import 'package:ecoteam_app/admin/services/manpower_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ManpowerTypesScreen extends StatefulWidget {
  const ManpowerTypesScreen({super.key});

  @override
  State<ManpowerTypesScreen> createState() => _ManpowerTypesScreenState();
}

class _ManpowerTypesScreenState extends State<ManpowerTypesScreen> {
  final ManpowerTypeService _service = ManpowerTypeService();
  List<ManpowerType> _manpowerTypes = [];
  List<ManpowerType> _filteredManpowerTypes = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadManpowerTypes();
    _searchController.addListener(_filterManpowerTypes);
  }

  Future<void> _loadManpowerTypes() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final types = await _service.getManpowerTypes();
      if (mounted) {
        setState(() {
          _manpowerTypes = types;
          _filteredManpowerTypes = types;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load manpower types: $e');
      }
    }
  }

  void _filterManpowerTypes() {
    final query = _searchController.text.toLowerCase();
    if (mounted) {
      setState(() {
        _filteredManpowerTypes = _manpowerTypes
            .where((type) => type.name.toLowerCase().contains(query))
            .toList();
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAddEditBottomSheet({ManpowerType? manpowerType}) {
    final bool isEditing = manpowerType != null;
    final TextEditingController nameController = TextEditingController(
      text: manpowerType?.name ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEditing ? 'Edit Manpower Type' : 'Add Manpower Type',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    hintText: 'Enter manpower type name',
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final String name = nameController.text.trim();
                          if (name.isEmpty) {
                            _showErrorSnackBar('Please enter a name');
                            return;
                          }

                          Navigator.pop(context);
                          await _handleSaveManpowerType(
                            isEditing: isEditing,
                            manpowerType: manpowerType,
                            name: name,
                          );
                        },
                        child: Text(isEditing ? 'Update' : 'Add'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSaveManpowerType({
    required bool isEditing,
    required String name,
    ManpowerType? manpowerType,
  }) async {
    try {
      if (isEditing && manpowerType != null) {
        final updatedType = manpowerType.copyWith(name: name);
        await _service.updateManpowerType(updatedType);
        _showSuccessSnackBar('Updated successfully');
      } else {
        // Create new manpower type
        final newType = ManpowerType(
          id: 0,
          name: name,
          status: 0,
          siteId: 1,
          createdBy: 1,
          workspaceId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _service.createManpowerType(newType);
        _showSuccessSnackBar('Added successfully');
      }
      
      await _loadManpowerTypes();
    } catch (e) {
      _showErrorSnackBar(
        'Failed to ${isEditing ? 'update' : 'add'} manpower type: $e',
      );
    }
  }

  Future<void> _deleteManpowerType(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        setState(() {
          _isLoading = true;
        });

        final success = await _service.deleteManpowerType(id);
        
        if (success) {
          _showSuccessSnackBar('"$name" deleted successfully');
          await _loadManpowerTypes();
        } else {
          _showErrorSnackBar('Failed to delete "$name"');
        }
      } catch (e) {
        _showErrorSnackBar('Failed to delete "$name": $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Alternative delete method if the above doesn't work
  Future<void> _deleteManpowerTypeAlternative(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Remove from local list first for immediate UI update
        setState(() {
          _manpowerTypes.removeWhere((type) => type.id == id);
          _filteredManpowerTypes.removeWhere((type) => type.id == id);
        });

        // Then call API
        final success = await _service.deleteManpowerType(id);
        
        if (!success) {
          // If API call fails, reload the list to restore the item
          await _loadManpowerTypes();
          _showErrorSnackBar('Failed to delete "$name"');
        } else {
          _showSuccessSnackBar('"$name" deleted successfully');
        }
      } catch (e) {
        // If any error occurs, reload the list
        await _loadManpowerTypes();
        _showErrorSnackBar('Failed to delete "$name": $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manpower Types', style: TextStyle(color: Colors.white)),
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
            onPressed: _loadManpowerTypes,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: () => _showAddEditBottomSheet(),
            icon: const Icon(Icons.add),
            tooltip: 'Add New',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search manpower types...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                // Total Count Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        const Icon(Icons.people, color: Color(0xFF2a43a0), size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Total Types: ${_filteredManpowerTypes.length}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2a43a0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Manpower Types List
                Expanded(
                  child: _filteredManpowerTypes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                _manpowerTypes.isEmpty
                                    ? 'No manpower types found'
                                    : 'No results found for "${_searchController.text}"',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              if (_manpowerTypes.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: ElevatedButton(
                                    onPressed: () => _showAddEditBottomSheet(),
                                    child: const Text('Add First Manpower Type'),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadManpowerTypes,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredManpowerTypes.length,
                            itemBuilder: (context, index) {
                              final manpowerType = _filteredManpowerTypes[index];
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.work,
                                      color: Color(0xFF2a43a0),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    manpowerType.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        'ID: ${manpowerType.id}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        'Site ID: ${manpowerType.siteId}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: SizedBox(
                                    width: 100.w,
                                    child: Row(
                                      children: [
                                        IconButton(
                                          onPressed: () => _showAddEditBottomSheet(
                                            manpowerType: manpowerType,
                                          ),
                                          icon: const Icon(Icons.edit, color: Color(0xFF2a43a0), size: 20),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        
                                        IconButton(
                                          onPressed: () => _deleteManpowerType(manpowerType.id, manpowerType.name),
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
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
            ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}