import 'package:ecoteam_app/admin/models/role_model.dart';
import 'package:ecoteam_app/admin/Screens/role_edit_page.dart';
import 'package:ecoteam_app/admin/services/admin_role_provider.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AdminRoleManagementPage extends StatelessWidget {
  const AdminRoleManagementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Role Management',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2a43a0),
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
        color: const Color.fromARGB(255, 239, 239, 239),
        child: Column(
          children: [
            // Header
            Column(
              children: [
                const SizedBox(height: 10,),
                Text(
                  'Role Management',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                
                Text(
                  'Manage user roles and permissions',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            // Role Grid
            Expanded(
              child: Consumer<AdminRoleProvider>(
                builder: (context, roleProvider, child) {
                  if (roleProvider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (roleProvider.roles.isEmpty) {
                    return Center(
                      child: Text(
                        'No roles found',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: EdgeInsets.all(30.w),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _getCrossAxisCount(context),
                        
                        crossAxisSpacing: 8.w,
                        mainAxisSpacing: 8.h,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: roleProvider.roles.length,
                      itemBuilder: (context, index) {
                        final role = roleProvider.roles[index];
                        return _buildRoleCard(context, role);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildRoleCard(BuildContext context, AdminRole role) {
    final keyPermissions = role.getKeyPermissions();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Role Name and Edit Button
            Row(
              children: [
                Expanded(
                  child: Text(
                    role.name,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: const Color(0xFF2a43a0),
                    size: 20.sp,
                  ),
                  onPressed: () => _navigateToRoleEdit(context, role),
                  tooltip: 'Edit Role',
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Permissions Section
            Text(
              'Key Permissions',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),

            SizedBox(height: 8.h),

            // Permission Chips
            Expanded(
              child: keyPermissions.isNotEmpty
                  ? Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      children: keyPermissions.map((permission) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2a43a0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            permission,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: const Color(0xFF2a43a0),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  : Text(
                      'No permissions assigned',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ),

            // Permission Count
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                '${_getTotalPermissions(role)} permissions',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getTotalPermissions(AdminRole role) {
    // Fix: Directly count the enabled permissions from the Map<String, bool>
    if (role.permissions is Map<String, bool>) {
      return (role.permissions as Map<String, bool>)
          .values
          .where((enabled) => enabled == true)
          .length;
    }
    
    // Fallback for other possible structures
    int count = 0;
    if (role.permissions is Map) {
      role.permissions.forEach((key, value) {
        if (value == true) {
          count++;
        } else if (value is Map) {
          // Handle nested structure if needed
          (value as Map).forEach((subKey, subValue) {
            if (subValue == true) {
              count++;
            }
          });
        }
      });
    }
    return count;
  }

  void _navigateToRoleEdit(BuildContext context, AdminRole role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminRoleEditPage(role: role),
      ),
    );
  }
}