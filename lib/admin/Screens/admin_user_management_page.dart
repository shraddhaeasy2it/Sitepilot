import 'dart:io';
import 'package:ecoteam_app/admin/models/user_model.dart';
import 'package:ecoteam_app/admin/services/admin_user_provider.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Admin Colors
class AdminColors {
  static const primary = Color(0xFF2a43a0);
  static const primaryLight = Color(0xFF4a63c0);
  static const primaryDark = Color(0xFF1a33a0);
  static const background = Color(0xFFFFFFFF);
  static const cardBackground = Colors.white;
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
}

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({Key? key}) : super(key: key);

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  String _selectedRoleFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User Management',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AdminColors.primary,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: 24.sp,
            color: Colors.white,
          ),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen())),
          tooltip: 'Back',
        ),
      ),
      body: Container(
        color: AdminColors.background,
        child: Column(
          children: [
            // Filters
            Container(
              padding: EdgeInsets.all(10.w),
              color: Colors.white,
              child: Column(
                children: [
                  Text(
                    'Filter Users',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40.h, // Reduced height
                          child: TextField(
                            style: TextStyle(fontSize: 14.sp), // Smaller font
                            decoration: InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6), // Smaller radius
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h), // Reduced padding
                              prefixIcon: Icon(Icons.person, size: 18.sp), 
                              prefixIconConstraints: BoxConstraints(minWidth: 30.w),// Smaller icon
                              //isDense: true, // Makes it more compact
                            ),
                            onChanged: (value) {
                              Provider.of<AdminUserProvider>(context, listen: false)
                                  .setNameFilter(value);
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w), // Reduced spacing
                      Expanded(
                        child: Container(
                          height: 40.h,
                         
                          child: TextField(
                            style: TextStyle(fontSize: 14.sp), // Smaller font
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6), // Smaller radius
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h), // Reduced padding
                              prefixIcon: Icon(Icons.email, size: 18.sp), 
                              prefixIconConstraints: BoxConstraints(minWidth: 30.w),
                              // Smaller icon
                              //isDense: true, // Makes it more compact
                            ),
                            onChanged: (value) {
                              Provider.of<AdminUserProvider>(context, listen: false)
                                  .setEmailFilter(value);
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w), // Reduced spacing
                      Expanded(
                        
                        child: Container(
                          height: 40.h,
                          child: DropdownButtonFormField<String>(
                            value: _selectedRoleFilter,
                            style: TextStyle(fontSize: 14.sp, color: Colors.black), // Smaller font
                            decoration: InputDecoration(
                              labelText: 'Role',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6), // Smaller radius
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h), // Reduced padding
                              prefixIcon: Icon(Icons.work, size: 18.sp), // Smaller icon
                              prefixIconConstraints: BoxConstraints(minWidth: 30.w), // Reduce space between icon and text
                              //isDense: true, // Makes it more compact
                            ),
                            items: ['All', 'Admin', 'Manager', 'User', 'Supervisor']
                                .map((role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(role),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedRoleFilter = value;
                                });
                                Provider.of<AdminUserProvider>(context, listen: false)
                                    .setRoleFilter(value == 'All' ? '' : value);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // User Cards
            Expanded(
              child: Consumer<AdminUserProvider>(
                builder: (context, userProvider, child) {
                  if (userProvider.users.isEmpty) {
                    return Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: userProvider.users.length,
                    itemBuilder: (context, index) {
                      final user = userProvider.users[index];
                      return _buildUserListItem(user);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserBottomSheet(context),
        backgroundColor: AdminColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add User',
      ),
    );
  }

  Widget _buildUserListItem(AdminUser user) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 8.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 30.r,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: user.displayImage != null
                      ? (user.imageFile != null
                          ? FileImage(user.imageFile!)
                          : NetworkImage(user.imageUrl)) as ImageProvider
                      : null,
                ),
                Icon(Icons.person, color: Colors.grey[600], size: 24),
              ],
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AdminColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    user.role,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AdminColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: AdminColors.primary, size: 24.sp),
                  onPressed: () => _showEditUserBottomSheet(context, user),
                  tooltip: 'Edit User',
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red, size: 24.sp),
                  onPressed: () => _showDeleteUserDialog(context, user),
                  tooltip: 'Delete User',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  void _showAddUserBottomSheet(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final imagePicker = ImagePicker();
    File? selectedImage;
    String selectedRole = 'User'; // Default role
    final userProvider = Provider.of<AdminUserProvider>(context, listen: false);

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
                    'Add New User',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Image Picker
                  GestureDetector(
                    onTap: () async {
                      final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setState(() {
                          selectedImage = File(pickedFile.path);
                        });
                      }
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(selectedImage!, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.person, size: 30, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  // Role Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work),
                    ),
                    items: ['Admin', 'Manager', 'User', 'Supervisor']
                        .map((role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedRole = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final email = emailController.text.trim();

                        if (name.isNotEmpty && email.isNotEmpty) {
                          final newUser = AdminUser(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: name,
                            email: email,
                            role: selectedRole,
                            imageUrl: '',
                            imageFile: selectedImage,
                          );
                          userProvider.addUser(newUser);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Add User'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditUserBottomSheet(BuildContext context, AdminUser user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final imagePicker = ImagePicker();
    File? selectedImage = user.imageFile;
    String selectedRole = user.role;
    final userProvider = Provider.of<AdminUserProvider>(context, listen: false);

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
                    'Edit User',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Image Picker
                  GestureDetector(
                    onTap: () async {
                      final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setState(() {
                          selectedImage = File(pickedFile.path);
                        });
                      }
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(selectedImage!, fit: BoxFit.cover),
                            )
                          : (user.displayImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: user.imageFile != null
                                      ? Image.file(user.imageFile!, fit: BoxFit.cover)
                                      : Image.network(user.imageUrl, fit: BoxFit.cover),
                                )
                              : const Icon(Icons.person, size: 30, color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  // Role Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work),
                    ),
                    items: ['Admin', 'Manager', 'User', 'Supervisor']
                        .map((role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedRole = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final email = emailController.text.trim();

                        if (name.isNotEmpty && email.isNotEmpty) {
                          final updatedUser = AdminUser(
                            id: user.id,
                            name: name,
                            email: email,
                            role: selectedRole,
                            imageUrl: user.imageUrl,
                            imageFile: selectedImage,
                          );
                          userProvider.updateUser(user.id, updatedUser);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Update User'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteUserDialog(BuildContext context, AdminUser user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: Text('Are you sure you want to delete ${user.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<AdminUserProvider>(context, listen: false)
                    .deleteUser(user.id);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }


}