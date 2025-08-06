import 'package:ecoteam_app/models/dashboard/site_model.dart';
import 'package:flutter/material.dart';


class MaterialsScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;

  const MaterialsScreen({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
  });

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  List<Material> materials = [];
  bool isLoading = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  void _loadMaterials() {
    setState(() {
      isLoading = true;
    });

    // Simulate API call
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        materials = [
          Material(
            id: '1',
            name: 'Cement',
            category: 'Construction',
            quantity: 500,
            unit: 'Bags',
            supplier: 'ABC Suppliers',
            cost: 25.0,
            status: 'In Stock',
            lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
          ),
          Material(
            id: '2',
            name: 'Steel Bars',
            category: 'Reinforcement',
            quantity: 200,
            unit: 'Tons',
            supplier: 'XYZ Steel Co.',
            cost: 1200.0,
            status: 'Low Stock',
            lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
          ),
          Material(
            id: '3',
            name: 'Bricks',
            category: 'Masonry',
            quantity: 10000,
            unit: 'Pieces',
            supplier: 'Brick Masters',
            cost: 0.5,
            status: 'In Stock',
            lastUpdated: DateTime.now().subtract(const Duration(hours: 6)),
          ),
          Material(
            id: '4',
            name: 'Sand',
            category: 'Aggregates',
            quantity: 50,
            unit: 'Cubic Meters',
            supplier: 'Sand & Gravel Co.',
            cost: 45.0,
            status: 'Out of Stock',
            lastUpdated: DateTime.now().subtract(const Duration(days: 3)),
          ),
        ];
        isLoading = false;
      });
    });
  }

  List<Material> get filteredMaterials {
    if (searchQuery.isEmpty) return materials;
    return materials.where((material) =>
        material.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
        material.category.toLowerCase().contains(searchQuery.toLowerCase()) ||
        material.supplier.toLowerCase().contains(searchQuery.toLowerCase())).toList();
  }

  void _showAddMaterialDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController categoryController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController unitController = TextEditingController();
    final TextEditingController supplierController = TextEditingController();
    final TextEditingController costController = TextEditingController();
    String selectedStatus = 'In Stock';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Material'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Material Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.straighten),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: supplierController,
                decoration: const InputDecoration(
                  labelText: 'Supplier',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cost per Unit',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info),
                ),
                items: ['In Stock', 'Low Stock', 'Out of Stock', 'On Order']
                    .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                    .toList(),
                onChanged: (value) => selectedStatus = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  categoryController.text.isNotEmpty &&
                  quantityController.text.isNotEmpty &&
                  unitController.text.isNotEmpty &&
                  supplierController.text.isNotEmpty &&
                  costController.text.isNotEmpty) {
                final newMaterial = Material(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  category: categoryController.text,
                  quantity: double.tryParse(quantityController.text) ?? 0,
                  unit: unitController.text,
                  supplier: supplierController.text,
                  cost: double.tryParse(costController.text) ?? 0,
                  status: selectedStatus,
                  lastUpdated: DateTime.now(),
                );
                setState(() {
                  materials.add(newMaterial);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Material "${newMaterial.name}" added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditMaterialDialog(Material material) {
    final TextEditingController nameController = TextEditingController(text: material.name);
    final TextEditingController categoryController = TextEditingController(text: material.category);
    final TextEditingController quantityController = TextEditingController(text: material.quantity.toString());
    final TextEditingController unitController = TextEditingController(text: material.unit);
    final TextEditingController supplierController = TextEditingController(text: material.supplier);
    final TextEditingController costController = TextEditingController(text: material.cost.toString());
    String selectedStatus = material.status;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Material'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Material Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.straighten),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: supplierController,
                decoration: const InputDecoration(
                  labelText: 'Supplier',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cost per Unit',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info),
                ),
                items: ['In Stock', 'Low Stock', 'Out of Stock', 'On Order']
                    .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                    .toList(),
                onChanged: (value) => selectedStatus = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  categoryController.text.isNotEmpty &&
                  quantityController.text.isNotEmpty &&
                  unitController.text.isNotEmpty &&
                  supplierController.text.isNotEmpty &&
                  costController.text.isNotEmpty) {
                setState(() {
                  final index = materials.indexWhere((m) => m.id == material.id);
                  if (index != -1) {
                    materials[index] = Material(
                      id: material.id,
                      name: nameController.text,
                      category: categoryController.text,
                      quantity: double.tryParse(quantityController.text) ?? 0,
                      unit: unitController.text,
                      supplier: supplierController.text,
                      cost: double.tryParse(costController.text) ?? 0,
                      status: selectedStatus,
                      lastUpdated: DateTime.now(),
                    );
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Material "${nameController.text}" updated successfully!'),
                    backgroundColor: Colors.blue,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteMaterialDialog(Material material) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text('Are you sure you want to delete "${material.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                materials.removeWhere((m) => m.id == material.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Material "${material.name}" deleted successfully!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'In Stock':
        return Colors.green;
      case 'Low Stock':
        return Colors.orange;
      case 'Out of Stock':
        return Colors.red;
      case 'On Order':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    body: Column(
      children: [
        // Header with search and add button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Materials Management',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddMaterialDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Material'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search materials...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ],
          ),
        ),
        
        // Materials list
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredMaterials.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No materials found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredMaterials.length,
                      itemBuilder: (context, index) {
                        final material = filteredMaterials[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: getStatusColor(material.status).withOpacity(0.2),
                              child: Icon(
                                Icons.inventory,
                                color: getStatusColor(material.status),
                              ),
                            ),
                            title: Text(
                              material.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.category, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      material.category,
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.numbers, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${material.quantity} ${material.unit}',
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.business, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      material.supplier,
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: getStatusColor(material.status).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        material.status,
                                        style: TextStyle(
                                          color: getStatusColor(material.status),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '\$${material.cost.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit':
                                    _showEditMaterialDialog(material);
                                    break;
                                  case 'delete':
                                    _showDeleteMaterialDialog(material);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 16),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 16, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    ),
    );
  }
}

class Material {
  final String id;
  final String name;
  final String category;
  final double quantity;
  final String unit;
  final String supplier;
  final double cost;
  final String status;
  final DateTime lastUpdated;

  Material({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.supplier,
    required this.cost,
    required this.status,
    required this.lastUpdated,
  });
}