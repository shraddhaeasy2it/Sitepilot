import 'package:ecoteam_app/models/dashboard/site_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  final List<String> categoryList = [
    'Construction',
    'Reinforcement',
    'Masonry',
    'Aggregates',
    'Electrical',
    'Plumbing'
  ];

  final List<String> supplierList = [
    'ABC Suppliers',
    'XYZ Steel Co.',
    'Brick Masters',
    'Sand & Gravel Co.'
  ];

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  void _loadMaterials() {
    setState(() => isLoading = true);

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
        ];
        isLoading = false;
      });
    });
  }

  List<Material> get filteredMaterials {
    if (searchQuery.isEmpty) return materials;
    return materials
        .where((material) =>
            material.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            material.category.toLowerCase().contains(searchQuery.toLowerCase()) ||
            material.supplier.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  void _showAddMaterialSheet() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final unitController = TextEditingController();
    final costController = TextEditingController();
    String selectedCategory = categoryList.first;
    String selectedSupplier = supplierList.first;
    String selectedStatus = 'In Stock';

    // Track validation errors
    bool nameError = false;
    bool quantityError = false;
    bool unitError = false;
    bool costError = false;

    void validateForm() {
      setState(() {
        nameError = nameController.text.isEmpty;
        quantityError = quantityController.text.isEmpty;
        unitError = unitController.text.isEmpty;
        costError = costController.text.isEmpty;
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 16,
              right: 16,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Text(
                    'Add New Material',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Material Name *',
                      hintText: 'e.g. Cement, Steel Bars',
                      prefixIcon: const Icon(Icons.inventory),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: nameError ? Colors.red : Colors.grey,
                        ),
                      ),
                      errorText: nameError ? 'This field is required' : null,
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && nameError) {
                        setState(() => nameError = false);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category *',
                      prefixIcon: const Icon(Icons.category),
                      border: const OutlineInputBorder(),
                    ),
                    items: categoryList
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                    onChanged: (val) => selectedCategory = val!,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Quantity *',
                            hintText: 'e.g. 100, 5.5',
                            prefixIcon: const Icon(Icons.numbers),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: quantityError ? Colors.red : Colors.grey,
                              ),
                            ),
                            errorText: quantityError ? 'This field is required' : null,
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && quantityError) {
                              setState(() => quantityError = false);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: unitController,
                          decoration: InputDecoration(
                            labelText: 'Unit *',
                            hintText: 'e.g. Bags, Tons, Kg',
                            prefixIcon: const Icon(Icons.straighten),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: unitError ? Colors.red : Colors.grey,
                              ),
                            ),
                            errorText: unitError ? 'This field is required' : null,
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && unitError) {
                              setState(() => unitError = false);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedSupplier,
                    decoration: const InputDecoration(
                      labelText: 'Supplier *',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    items: supplierList
                        .map((sup) => DropdownMenuItem(
                              value: sup,
                              child: Text(sup),
                            ))
                        .toList(),
                    onChanged: (val) => selectedSupplier = val!,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: costController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Cost per Unit *',
                      hintText: 'e.g. 25.50, 1200',
                      prefixIcon: const Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: costError ? Colors.red : Colors.grey,
                        ),
                      ),
                      errorText: costError ? 'This field is required' : null,
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && costError) {
                        setState(() => costError = false);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status *',
                      prefixIcon: Icon(Icons.info),
                      border: OutlineInputBorder(),
                    ),
                    items: ['In Stock', 'Low Stock', 'Out of Stock', 'On Order']
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                    onChanged: (val) => selectedStatus = val!,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Add Material'),
                    onPressed: () {
                      validateForm();
                      
                      if (nameError || quantityError || unitError || costError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all required fields'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final newMaterial = Material(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text,
                        category: selectedCategory,
                        quantity: double.tryParse(quantityController.text) ?? 0,
                        unit: unitController.text,
                        supplier: selectedSupplier,
                        cost: double.tryParse(costController.text) ?? 0,
                        status: selectedStatus,
                        lastUpdated: DateTime.now(),
                      );
                      setState(() => materials.add(newMaterial));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Material "${newMaterial.name}" added!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.lightBlue,
        onPressed: _showAddMaterialSheet,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Material", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
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
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Materials Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
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
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredMaterials.isEmpty
                    ? const Center(child: Text('No materials found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredMaterials.length,
                        itemBuilder: (context, index) {
                          final material = filteredMaterials[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(material.name),
                              subtitle: Text(
                                '${material.category} | ${material.quantity} ${material.unit} | ${material.supplier}',
                              ),
                              trailing: Text(
                                '₹${material.cost.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    getStatusColor(material.status).withOpacity(0.2),
                                child: Icon(
                                  Icons.inventory,
                                  color: getStatusColor(material.status),
                                ),
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