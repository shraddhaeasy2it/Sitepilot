import 'package:ecoteam_app/admin/models/role_model.dart';
import 'package:ecoteam_app/admin/services/admin_role_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AdminRoleEditPage extends StatefulWidget {
  final AdminRole role;

  const AdminRoleEditPage({Key? key, required this.role}) : super(key: key);

  @override
  State<AdminRoleEditPage> createState() => _AdminRoleEditPageState();
}

class _AdminRoleEditPageState extends State<AdminRoleEditPage> {
  late TextEditingController _nameController;
  late Map<String, Map<String, dynamic>> _permissions;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.role.name);
    _permissions = _deepCopyPermissions(widget.role.permissions);
  }

  Map<String, Map<String, dynamic>> _deepCopyPermissions(
    Map<String, Map<String, dynamic>> original,
  ) {
    Map<String, Map<String, dynamic>> copy = {};

    original.forEach((categoryKey, categoryValue) {
      copy[categoryKey] = {};
      if (categoryValue is Map<String, dynamic>) {
        categoryValue.forEach((moduleKey, moduleValue) {
          if (moduleValue is Map<String, dynamic>) {
            copy[categoryKey]![moduleKey] = Map<String, dynamic>.from(
              moduleValue,
            );
          } else {
            copy[categoryKey]![moduleKey] = moduleValue;
          }
        });
      } else {
        copy[categoryKey] = Map<String, dynamic>.from(categoryValue);
      }
    });

    return copy;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Role', style: TextStyle(fontSize: 18.sp)),
        backgroundColor: const Color(0xFF2a43a0),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _hasChanges ? _saveChanges : null,
            child: Text(
              'Save',
              style: TextStyle(
                color: _hasChanges
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
                fontSize: 16.sp,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Role Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Role Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
              onChanged: (_) => _checkForChanges(),
            ),

            SizedBox(height: 24.h),

            // Permissions Sections
            Text(
              'Permissions',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),

            SizedBox(height: 16.h),

            _buildGeneralPermissionsSection(),

            _buildSimplePermissionsSection(
              'Product Services',
              'product_services',
              ['manage', 'create', 'edit', 'delete'],
            ),

            _buildSimplePermissionsSection('Project', 'project', [
              'manage',
              'create',
              'edit',
              'delete',
            ]),

            _buildHRMPermissionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralPermissionsSection() {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: ExpansionTile(
        title: Text(
          'General',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModulePermissions('User', 'user', 'general', [
                  'manage',
                  'profile',
                  'logs_history',
                  'create',
                  'reset_password',
                  'chat_manage',
                  'edit',
                  'login_manage',
                  'delete',
                  'import',
                ]),
                _buildModulePermissions('Setting', 'setting', 'general', ['manage']),
                _buildModulePermissions('Plan', 'plan', 'general', [
                  'manage',
                  'order',
                  'purchase',
                  'subscribe',
                ]),
                _buildModulePermissions('Helpdesk', 'helpdesk', 'general', [
                  'ticket_manage',
                  'create',
                  'edit',
                  'show',
                  'reply',
                  'delete',
                ]),
                _buildModulePermissions('Referral', 'referral', 'general', [
                  'program_manage',
                ]),
                _buildModulePermissions('Workspace', 'workspace', 'general', [
                  'manage',
                  'create',
                  'edit',
                  'delete',
                ]),
                _buildModulePermissions('Roles', 'roles', 'general', [
                  'manage',
                  'create',
                  'edit',
                  'delete',
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHRMPermissionsSection() {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: ExpansionTile(
        title: Text(
          'HRM',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModulePermissions('HRM', 'hrm', 'hrm', [
                  'manage',
                  'dashboard_manager',
                ]),
                _buildModulePermissions('Sidebar', 'sidebar', 'hrm', [
                  'hrm_report_manager',
                  'payroll_manager',
                  'hr_admin_manager',
                ]),
                _buildModulePermissions('Document', 'document', 'hrm', [
                  'manage',
                  'create',
                  'edit',
                  'delete',
                ]),
                _buildModulePermissions('Attendance', 'attendance', 'hrm', [
                  'manage',
                  'create',
                  'edit',
                  'delete',
                ]),
                _buildModulePermissions('Import', 'import', 'hrm', ['report_manager']),
                _buildModulePermissions('Branch', 'branch', 'hrm', [
                  'manage',
                  'create',
                  'edit',
                  'delete',
                  'name_edit',
                ]),
                _buildModulePermissions('Department', 'department', 'hrm', [
                  'manage',
                  'create',
                  'edit',
                  'delete',
                  'name_edit',
                ]),
                _buildModulePermissions('Designation', 'designation', 'hrm', [
                  'manage',
                  'create',
                  'edit',
                  'delete',
                  'name_edit',
                ]),
                _buildModulePermissions('Employee', 'employee', 'hrm', [
                  'manage',
                  'create',
                  'edit',
                  'delete',
                  'profile Show',
                  'import',
                  'Show',
                  'Profile Manage',
                ]),
                _buildModulePermissions('documentType', 'documenttype', 'hrm', [
                  'manage','create','edit','delete',
                ]),
                _buildModulePermissions('CompanyPolicy', 'companypolicy', 'hrm', [
                  'manage','create','edit','delete',
                ]),
                _buildModulePermissions('Leave', 'leave', 'hrm', [
                  'manage','create','edit','delete','approver manager','report manage'
                ]),
                _buildModulePermissions('LeaveType', 'leavetype', 'hrm', [
                  'manage','create','edit','delete'
                ]),
                _buildModulePermissions('Transfer', 'transfer', 'hrm', [
                  'manage','create','edit','delete'
                ])
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulePermissions(
    String moduleName,
    String moduleKey,
    String category,
    List<String> permissions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Text(
            moduleName,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2a43a0),
            ),
          ),
        ),
        Wrap(
          spacing: 8.w,
          runSpacing: 4.h,
          children: permissions.map((permission) {
            final currentValue = _getPermissionValue(
              category,
              moduleKey,
              permission,
            );
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 2.w) / 3, // 3 items per row
              child: CheckboxListTile(
                title: Text(
                  _formatPermissionName(permission),
                  style: TextStyle(fontSize: 13.sp),
                ),
                value: currentValue,
                onChanged: (value) {
                  _setPermissionValue(
                    category,
                    moduleKey,
                    permission,
                    value ?? false,
                  );
                },
                activeColor: const Color(0xFF2a43a0),
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            );
          }).toList(),
        ),
        Divider(height: 5.h,color: const Color.fromARGB(255, 220, 220, 220),),
      ],
    );
  }

  bool _getPermissionValue(String category, String module, String permission) {
    try {
      final categoryPerms = _permissions[category];
      if (categoryPerms == null || categoryPerms[module] == null) {
        return false;
      }
      final modulePerms = categoryPerms[module];
      if (modulePerms is Map<String, dynamic>) {
        final value = modulePerms[permission];
        return value is bool ? value : false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void _setPermissionValue(
    String category,
    String module,
    String permission,
    bool value,
  ) {
    setState(() {
      if (_permissions[category] == null) {
        _permissions[category] = <String, dynamic>{};
      }
      if (_permissions[category]![module] == null) {
        _permissions[category]![module] = <String, dynamic>{};
      }
      if (_permissions[category]![module] is Map<String, dynamic>) {
        (_permissions[category]![module] as Map<String, dynamic>)[permission] =
            value;
      }
      _checkForChanges();
    });
  }

  Widget _buildSimplePermissionsSection(
    String title,
    String category,
    List<String> permissions,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: ExpansionTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2a43a0),
                    ),
                  ),
                ),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 4.h,
                  children: permissions.map((permission) {
                    final currentValue = _getSimplePermissionValue(
                      category,
                      permission,
                    );
                    return SizedBox(
                      width: (MediaQuery.of(context).size.width - 2.w) / 3, // 3 items per row
                      child: CheckboxListTile(
                        title: Text(
                          _formatPermissionName(permission),
                          style: TextStyle(fontSize: 13.sp),
                        ),
                        value: currentValue,
                        onChanged: (value) {
                          _setSimplePermissionValue(
                            category,
                            permission,
                            value ?? false,
                          );
                        },
                        activeColor: const Color(0xFF2a43a0),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    );
                  }).toList(),
                ),
                Divider(height: 16.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _getSimplePermissionValue(String category, String permission) {
    try {
      final categoryPerms = _permissions[category];
      if (categoryPerms == null || categoryPerms[permission] == null)
        return false;
      final value = categoryPerms[permission];
      return value is bool ? value : false;
    } catch (e) {
      return false;
    }
  }

  void _setSimplePermissionValue(
    String category,
    String permission,
    bool value,
  ) {
    setState(() {
      if (_permissions[category] == null) {
        _permissions[category] = <String, dynamic>{};
      }
      _permissions[category]![permission] = value;
      _checkForChanges();
    });
  }

  String _formatPermissionName(String permission) {
    return permission
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1)
              : word,
        )
        .join(' ');
  }

  void _checkForChanges() {
    final nameChanged = _nameController.text != widget.role.name;
    final permissionsChanged = !_arePermissionsEqual(
      _permissions,
      widget.role.permissions,
    );

    setState(() {
      _hasChanges = nameChanged || permissionsChanged;
    });
  }

  bool _arePermissionsEqual(
    Map<String, Map<String, dynamic>> a,
    Map<String, Map<String, dynamic>> b,
  ) {
    try {
      if (a.length != b.length) return false;

      for (final category in a.keys) {
        if (!b.containsKey(category)) return false;

        final aPerms = a[category]!;
        final bPerms = b[category]!;

        if (aPerms is Map<String, dynamic> && bPerms is Map<String, dynamic>) {
          if (!_areNestedPermissionsEqual(aPerms, bPerms)) return false;
        } else if (aPerms != bPerms) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  bool _areNestedPermissionsEqual(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    try {
      if (a.length != b.length) return false;

      for (final module in a.keys) {
        if (!b.containsKey(module)) return false;

        final aModulePerms = a[module];
        final bModulePerms = b[module];

        if (aModulePerms is Map<String, dynamic> &&
            bModulePerms is Map<String, dynamic>) {
          if (aModulePerms.length != bModulePerms.length) return false;
          for (final perm in aModulePerms.keys) {
            if (!bModulePerms.containsKey(perm) ||
                aModulePerms[perm] != bModulePerms[perm]) {
              return false;
            }
          }
        } else if (aModulePerms != bModulePerms) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  void _saveChanges() {
    final updatedRole = widget.role.copyWith(
      name: _nameController.text,
      permissions: _permissions,
    );

    Provider.of<AdminRoleProvider>(
      context,
      listen: false,
    ).updateRole(widget.role.id, updatedRole);

    Navigator.pop(context);
  }
}
