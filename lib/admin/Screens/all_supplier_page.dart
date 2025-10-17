import 'package:ecoteam_app/admin/models/Allsupplier_model.dart';
import 'package:ecoteam_app/admin/services/Allsupplier_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class AllSupplierPage extends StatefulWidget {
  const AllSupplierPage({Key? key}) : super(key: key);

  @override
  State<AllSupplierPage> createState() => _AllSupplierPageState();
}

class _AllSupplierPageState extends State<AllSupplierPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Supplier> _allSuppliers = [];
  List<Supplier> _filteredSuppliers = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Dynamic lists for categories and types
  List<SupplierCategory> _categories = [];
  List<SupplierType> _types = [
    SupplierType(id: 1, name: 'individual', description: 'Individual'),
    SupplierType(id: 2, name: 'company', description: 'Company'),
    SupplierType(id: 3, name: 'partnership', description: 'Partnership'),
    SupplierType(id: 4, name: 'LLP', description: 'Limited Liability Partnership'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterSuppliers);
  }

  Future<void> _loadData() async {
  setState(() {
    _isLoading = true;
    _errorMessage = '';
  });

  try {
    final suppliers = await SupplierApiService.getSuppliers();
    final categories = await SupplierApiService.getSupplierCategories();

    setState(() {
      _allSuppliers = suppliers;
      _filteredSuppliers = suppliers;
      _categories = categories;
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _errorMessage = e.toString();
      _isLoading = false;
    });
    _showSnackBar('Failed to load data: $e');
  }
}

  void _filterSuppliers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSuppliers = _allSuppliers.where((supplier) {
        final categoryName = _getCategoryName(supplier.categoryId);
        return supplier.name.toLowerCase().contains(query) ||
               categoryName.toLowerCase().contains(query) ||
               supplier.contactPerson.toLowerCase().contains(query) ||
               supplier.phone.toLowerCase().contains(query);
      }).toList();
    });
  }

  String _getCategoryName(int categoryId) {
    try {
      final category = _categories.firstWhere((cat) => cat.id == categoryId);
      return category.name;
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showAddEditSupplierBottomSheet({Supplier? supplier}) {
    final isEditing = supplier != null;

    final nameController = TextEditingController(text: supplier?.name ?? '');
    final contactPersonController = TextEditingController(text: supplier?.contactPerson ?? '');
    final phoneController = TextEditingController(text: supplier?.phone ?? '');
    final emailController = TextEditingController(text: supplier?.email ?? '');
    final addressController = TextEditingController(text: supplier?.address ?? '');
    final cityController = TextEditingController(text: supplier?.city ?? '');
    final stateController = TextEditingController(text: supplier?.state ?? '');
    final pincodeController = TextEditingController(text: supplier?.pincode ?? '');
    final countryController = TextEditingController(text: supplier?.country ?? '');
    final gstController = TextEditingController(text: supplier?.gstNumber ?? '');
    final panController = TextEditingController(text: supplier?.panNumber ?? '');
    final registrationController = TextEditingController(text: supplier?.registrationNumber ?? '');
    final bankNameController = TextEditingController(text: supplier?.bankName ?? '');
    final accountNumberController = TextEditingController(text: supplier?.accountNumber ?? '');
    final ifscController = TextEditingController(text: supplier?.ifscCode ?? '');
    final paymentTermsController = TextEditingController(text: supplier?.paymentTerms ?? '');

    // Initialize selected values
    int? selectedCategoryId = supplier?.categoryId;
    String selectedType = supplier?.type ?? _types.first.name;

    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 30,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isEditing ? 'Edit Supplier' : 'Add New Supplier',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Supplier Name
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Supplier Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business, size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        style: const TextStyle(fontSize: 14),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter supplier name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Category and Type Row
                      Row(
  children: [
    Expanded(
      child: DropdownButtonFormField<int>(
        value: selectedCategoryId,
        decoration: const InputDecoration(
          labelText: 'Category *',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.category, size: 18),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 14),
        isExpanded: true, // Important for Row layout
        items: _categories.map((category) {
          return DropdownMenuItem<int>(
            value: category.id,
            child: Text(
              category.name, 
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (value) {
          setModalState(() {
            selectedCategoryId = value!;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Please select a category';
          }
          return null;
        },
      ),
    ),
    const SizedBox(width: 8),
    Expanded(
      child: DropdownButtonFormField<String>(
        value: selectedType,
        decoration: const InputDecoration(
          labelText: 'Type *',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.business_center, size: 18),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 14),
        isExpanded: true, // Important for Row layout
        items: _types.map((type) {
          return DropdownMenuItem<String>(
            value: type.name,
            child: Text(
              type.name[0].toUpperCase() + type.name.substring(1), 
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (value) {
          setModalState(() {
            selectedType = value!;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a type';
          }
          return null;
        },
      ),
    ),
  ],
),
                      const SizedBox(height: 8),

                      // Contact Person and Phone Row
                      Row(
                        children: [
                          Container(
                            width: (constraints.maxWidth - 8) / 2,
                            child: TextFormField(
                              controller: contactPersonController,
                              decoration: const InputDecoration(
                                labelText: 'Contact Person *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person, size: 18),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              style: const TextStyle(fontSize: 14),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter contact person';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: (constraints.maxWidth - 8) / 2,
                            child: TextFormField(
                              controller: phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone, size: 18),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              style: const TextStyle(fontSize: 14),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter phone number';
                                }
                                if (value.length < 10) {
                                  return 'Please enter a valid phone number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Email
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email, size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        style: const TextStyle(fontSize: 14),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Address
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on, size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),

                      // City, State Row
                      Row(
                        children: [
                          Container(
                            width: (constraints.maxWidth - 8) / 2,
                            child: TextFormField(
                              controller: cityController,
                              decoration: const InputDecoration(
                                labelText: 'City',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_city, size: 18),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: (constraints.maxWidth - 8) / 2,
                            child: TextFormField(
                              controller: stateController,
                              decoration: const InputDecoration(
                                labelText: 'State',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.map, size: 18),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Pincode and Country Row
                      Row(
                        children: [
                          Container(
                            width: (constraints.maxWidth - 8) / 2,
                            child: TextFormField(
                              controller: pincodeController,
                              decoration: const InputDecoration(
                                labelText: 'Pincode',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.pin_drop, size: 18),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              style: const TextStyle(fontSize: 14),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: (constraints.maxWidth - 8) / 2,
                            child: TextFormField(
                              controller: countryController,
                              decoration: const InputDecoration(
                                labelText: 'Country',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.public, size: 18),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // GST and PAN Row
                      Row(
                        children: [
                          Container(
                            width: (constraints.maxWidth - 8) / 2,
                            child: TextFormField(
                              controller: gstController,
                              decoration: const InputDecoration(
                                labelText: 'GST Number',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.receipt, size: 18),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: (constraints.maxWidth - 8) / 2,
                            child: TextFormField(
                              controller: panController,
                              decoration: const InputDecoration(
                                labelText: 'PAN Number',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.credit_card, size: 18),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Registration Number
                      TextFormField(
                        controller: registrationController,
                        decoration: const InputDecoration(
                          labelText: 'Registration Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.assignment, size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),

                      // Bank Details
                      const Text(
                        'Bank Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Bank Name and Account Number Row
                      Row(
                        children: [
                          Container(
                            width: (constraints.maxWidth - 8) / 2,
                            child: TextFormField(
                              controller: bankNameController,
                              decoration: const InputDecoration(
                                labelText: 'Bank Name',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.account_balance, size: 18),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: (constraints.maxWidth - 8) / 2,
                            child: TextFormField(
                              controller: accountNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Account Number',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.account_box, size: 18),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              style: const TextStyle(fontSize: 14),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: ifscController,
                        decoration: const InputDecoration(
                          labelText: 'IFSC Code',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.code, size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),

                      // Payment Terms
                      TextFormField(
                        controller: paymentTermsController,
                        decoration: const InputDecoration(
                          labelText: 'Payment Terms',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.schedule, size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSubmitting ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: const Text('Cancel', style: TextStyle(fontSize: 14)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      if (formKey.currentState!.validate() && selectedCategoryId != null) {
                                        setModalState(() {
                                          isSubmitting = true;
                                        });

                                        try {
                                          final supplierData = Supplier(
                                            id: supplier?.id,
                                            name: nameController.text.trim(),
                                            categoryId: selectedCategoryId!,
                                            type: selectedType,
                                            contactPerson: contactPersonController.text.trim(),
                                            phone: phoneController.text.trim(),
                                            email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                                            address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                                            city: cityController.text.trim().isEmpty ? null : cityController.text.trim(),
                                            state: stateController.text.trim().isEmpty ? null : stateController.text.trim(),
                                            pincode: pincodeController.text.trim().isEmpty ? null : pincodeController.text.trim(),
                                            country: countryController.text.trim().isEmpty ? null : countryController.text.trim(),
                                            gstNumber: gstController.text.trim().isEmpty ? null : gstController.text.trim(),
                                            panNumber: panController.text.trim().isEmpty ? null : panController.text.trim(),
                                            registrationNumber: registrationController.text.trim().isEmpty ? null : registrationController.text.trim(),
                                            bankName: bankNameController.text.trim().isEmpty ? null : bankNameController.text.trim(),
                                            accountNumber: accountNumberController.text.trim().isEmpty ? null : accountNumberController.text.trim(),
                                            ifscCode: ifscController.text.trim().isEmpty ? null : ifscController.text.trim(),
                                            paymentTerms: paymentTermsController.text.trim().isEmpty ? null : paymentTermsController.text.trim(),
                                            siteId: supplier?.siteId ?? 2, // Default site ID
                                            workspaceId: supplier?.workspaceId ?? 0,
                                            createdBy: supplier?.createdBy ?? 1,
                                            isActive: supplier?.isActive ?? 1,
                                            status: supplier?.status ?? '0',
                                            createdAt: supplier?.createdAt,
                                            updatedAt: DateTime.now().toIso8601String(),
                                          );

                                          if (isEditing) {
                                            await SupplierApiService.updateSupplier(supplierData);
                                          } else {
                                            await SupplierApiService.addSupplier(supplierData);
                                          }

                                          await _loadData();
                                          Navigator.pop(context);
                                          _showSnackBar(
                                            isEditing
                                                ? 'Supplier updated successfully'
                                                : 'Supplier added successfully',
                                          );
                                        } catch (e) {
                                          _showSnackBar('Failed to ${isEditing ? 'update' : 'add'} supplier: $e');
                                        } finally {
                                          setModalState(() {
                                            isSubmitting = false;
                                          });
                                        }
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
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(isEditing ? 'Update' : 'Add', style: const TextStyle(fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _deleteSupplier(Supplier supplier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${supplier.name}?'),
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
        await SupplierApiService.deleteSupplier(supplier.id!);
        await _loadData();
        _showSnackBar('Supplier deleted successfully');
      } catch (e) {
        _showSnackBar('Failed to delete supplier: $e');
      }
    }
  }

  void _showSupplierDetailsBottomSheet(Supplier supplier) {
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
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
                const Text(
                  'Supplier Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 24),

                // Row 1: Supplier Name & Category
                Row(
                  children: [
                    Expanded(child: _buildDetailRow('Supplier Name', supplier.name, Icons.business)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDetailRow('Category', _getCategoryName(supplier.categoryId), Icons.category)),
                  ],
                ),
                const SizedBox(height: 16),

                // Row 2: Contact Person & Phone
                Row(
                  children: [
                    Expanded(child: _buildDetailRow('Contact Person', supplier.contactPerson, Icons.person)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDetailRow('Phone', supplier.phone, Icons.phone)),
                  ],
                ),
                const SizedBox(height: 16),

                // Email (full width)
                _buildDetailRow('Email', supplier.email ?? 'N/A', Icons.email),
                const SizedBox(height: 16),

                // Address (full width)
                if (supplier.address != null && supplier.address!.isNotEmpty)
                  _buildDetailRow('Address', supplier.address!, Icons.location_on),
                if (supplier.address != null && supplier.address!.isNotEmpty)
                  const SizedBox(height: 16),

                // Row 3: City & State
                if ((supplier.city != null && supplier.city!.isNotEmpty) ||
                    (supplier.state != null && supplier.state!.isNotEmpty))
                  Row(
                    children: [
                      if (supplier.city != null && supplier.city!.isNotEmpty)
                        Expanded(child: _buildDetailRow('City', supplier.city!, Icons.location_city)),
                      if (supplier.state != null && supplier.state!.isNotEmpty)
                        Expanded(child: _buildDetailRow('State', supplier.state!, Icons.map)),
                    ],
                  ),
                if ((supplier.city != null && supplier.city!.isNotEmpty) ||
                    (supplier.state != null && supplier.state!.isNotEmpty))
                  const SizedBox(height: 16),

                // Row 4: Pincode & Country
                if ((supplier.pincode != null && supplier.pincode!.isNotEmpty) ||
                    (supplier.country != null && supplier.country!.isNotEmpty))
                  Row(
                    children: [
                      if (supplier.pincode != null && supplier.pincode!.isNotEmpty)
                        Expanded(child: _buildDetailRow('Pincode', supplier.pincode!, Icons.pin_drop)),
                      if (supplier.country != null && supplier.country!.isNotEmpty)
                        Expanded(child: _buildDetailRow('Country', supplier.country!, Icons.public)),
                    ],
                  ),
                if ((supplier.pincode != null && supplier.pincode!.isNotEmpty) ||
                    (supplier.country != null && supplier.country!.isNotEmpty))
                  const SizedBox(height: 16),

                // UPI Screenshot (compact)
                if ((supplier.upiScreenshot1 != null && supplier.upiScreenshot1!.isNotEmpty) ||
                    (supplier.upiScreenshot2 != null && supplier.upiScreenshot2!.isNotEmpty))
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.image, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'UPI Screenshot Available',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Row 5: GST & PAN
                if ((supplier.gstNumber != null && supplier.gstNumber!.isNotEmpty) ||
                    (supplier.panNumber != null && supplier.panNumber!.isNotEmpty))
                  Row(
                    children: [
                      if (supplier.gstNumber != null && supplier.gstNumber!.isNotEmpty)
                        Expanded(child: _buildDetailRow('GST Number', supplier.gstNumber!, Icons.receipt)),
                      if (supplier.panNumber != null && supplier.panNumber!.isNotEmpty)
                        Expanded(child: _buildDetailRow('PAN Number', supplier.panNumber!, Icons.credit_card)),
                    ],
                  ),
                if ((supplier.gstNumber != null && supplier.gstNumber!.isNotEmpty) ||
                    (supplier.panNumber != null && supplier.panNumber!.isNotEmpty))
                  const SizedBox(height: 16),

                // Registration Number (full width if present)
                if (supplier.registrationNumber != null && supplier.registrationNumber!.isNotEmpty)
                  _buildDetailRow('Registration Number', supplier.registrationNumber!, Icons.assignment),
                if (supplier.registrationNumber != null && supplier.registrationNumber!.isNotEmpty)
                  const SizedBox(height: 16),

                // Bank Details Section
                if ((supplier.bankName != null && supplier.bankName!.isNotEmpty) ||
                    (supplier.accountNumber != null && supplier.accountNumber!.isNotEmpty) ||
                    (supplier.ifscCode != null && supplier.ifscCode!.isNotEmpty))
                  const Text(
                    'Bank Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                if ((supplier.bankName != null && supplier.bankName!.isNotEmpty) ||
                    (supplier.accountNumber != null && supplier.accountNumber!.isNotEmpty) ||
                    (supplier.ifscCode != null && supplier.ifscCode!.isNotEmpty))
                  const SizedBox(height: 8),

                // Row 6: Bank Name & Account Number
                if ((supplier.bankName != null && supplier.bankName!.isNotEmpty) ||
                    (supplier.accountNumber != null && supplier.accountNumber!.isNotEmpty))
                  Row(
                    children: [
                      if (supplier.bankName != null && supplier.bankName!.isNotEmpty)
                        Expanded(child: _buildDetailRow('Bank Name', supplier.bankName!, Icons.account_balance)),
                      if (supplier.accountNumber != null && supplier.accountNumber!.isNotEmpty)
                        Expanded(child: _buildDetailRow('Account Number', supplier.accountNumber!, Icons.account_box)),
                    ],
                  ),
                if ((supplier.bankName != null && supplier.bankName!.isNotEmpty) ||
                    (supplier.accountNumber != null && supplier.accountNumber!.isNotEmpty))
                  const SizedBox(height: 8),

                // IFSC Code (full width if present)
                if (supplier.ifscCode != null && supplier.ifscCode!.isNotEmpty)
                  _buildDetailRow('IFSC Code', supplier.ifscCode!, Icons.code),
                if (supplier.ifscCode != null && supplier.ifscCode!.isNotEmpty)
                  const SizedBox(height: 16),

                // Row 7: Payment Terms & Status
                Row(
                  children: [
                    if (supplier.paymentTerms != null && supplier.paymentTerms!.isNotEmpty)
                      Expanded(child: _buildDetailRow('Payment Terms', supplier.paymentTerms!, Icons.schedule)),
                    Expanded(
                      child: _buildDetailRow('Status', supplier.status == '1' ? 'Active' : 'Inactive',
                          Icons.info, supplier.status == '1' ? Colors.green : Colors.red),
                    ),
                  ],
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddEditSupplierBottomSheet(supplier: supplier);
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
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, [Color? valueColor]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF2a43a0),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF1F2937),
                ),
              ),
            ],
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
        title: const Text('All Suppliers', style: TextStyle(color: Colors.white)),
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: 24.sp,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddEditSupplierBottomSheet(),
            tooltip: 'Add Supplier',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'Refresh',
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
                hintText: 'Search by name, category, contact person or phone',
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
                      Icon(
                        Icons.error_outline,
                        size: 48.sp,
                        color: Colors.red,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Error loading suppliers',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _errorMessage,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2a43a0),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_filteredSuppliers.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 64.sp,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        _searchController.text.isEmpty
                            ? 'No suppliers found'
                            : 'No suppliers match your search',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_searchController.text.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            _filterSuppliers();
                          },
                          child: const Text('Clear search'),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else ...[
              // Total Entries
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total entries: ${_filteredSuppliers.length}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        _filterSuppliers();
                      },
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: const Color(0xFF2a43a0),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16.h),
              // Supplier Cards
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    itemCount: _filteredSuppliers.length,
                    itemBuilder: (context, index) {
                      final supplier = _filteredSuppliers[index];
                      return InkWell(
                        onTap: () => _showSupplierDetailsBottomSheet(supplier),
                        child: Card(
                          margin: EdgeInsets.only(bottom: 12.h),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24.r,
                                  backgroundColor: const Color(0xFF2a43a0).withOpacity(0.1),
                                  child: Icon(
                                    Icons.business,
                                    color: const Color(0xFF2a43a0),
                                    size: 24.sp,
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        supplier.name,
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1F2937),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        'Contact: ${supplier.contactPerson}',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        'Category: ${_getCategoryName(supplier.categoryId)}',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.grey[500],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert, size: 20.sp),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showAddEditSupplierBottomSheet(supplier: supplier);
                                    } else if (value == 'delete') {
                                      _deleteSupplier(supplier);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, color: Colors.blue),
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