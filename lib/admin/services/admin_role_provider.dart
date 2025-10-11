import 'package:flutter/foundation.dart';
import 'package:ecoteam_app/admin/models/role_model.dart';

class AdminRoleProvider extends ChangeNotifier {
  List<AdminRole> _roles = [];
  bool _isLoading = false;

  List<AdminRole> get roles => _roles;
  bool get isLoading => _isLoading;

  AdminRoleProvider() {
    loadRoles();
  }

  Future<void> loadRoles() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Sample data with different roles
      _roles = [
        AdminRole.defaultRole('1', 'Client').copyWith(
          permissions: {
            'general': {
              'user': {
                'manage': true,
                'profile': true,
                'logs_history': false,
                'create': true,
                'reset_password': false,
                'chat_manage': true,
                'edit': true,
                'login_manage': false,
                'delete': false,
                'import': false,
              },
              'setting': {
                'manage': false,
              },
              'plan': {
                'manage': false,
                'order': false,
                'purchase': false,
                'subscribe': false,
              },
              'helpdesk': {
                'ticket_manage': false,
                'create': false,
                'edit': false,
                'show': false,
                'reply': false,
                'delete': false,
              },
              'referral': {
                'program_manage': false,
              },
              'workspace': {
                'manage': false,
                'create': false,
                'edit': false,
                'delete': false,
              },
              'roles': {
                'manage': false,
                'create': false,
                'edit': false,
                'delete': false,
              },
            },
            'product_services': {
              'manage': false,
              'create': false,
              'edit': false,
              'delete': false,
            },
            'project': {
              'manage': false,
              'create': false,
              'edit': false,
              'delete': false,
            },
            'hrm': {
              'manage': false,
              'create': false,
              'edit': false,
              'delete': false,
            },
          },
        ),
        AdminRole.defaultRole('2', 'Staff').copyWith(
          permissions: {
            'general': {
              'user': {
                'manage': true,
                'profile': true,
                'logs_history': true,
                'create': true,
                'reset_password': false,
                'chat_manage': true,
                'edit': true,
                'login_manage': false,
                'delete': false,
                'import': false,
              },
              'setting': {
                'manage': false,
              },
              'plan': {
                'manage': false,
                'order': false,
                'purchase': false,
                'subscribe': false,
              },
              'helpdesk': {
                'ticket_manage': true,
                'create': true,
                'edit': true,
                'show': true,
                'reply': true,
                'delete': false,
              },
              'referral': {
                'program_manage': false,
              },
              'workspace': {
                'manage': true,
                'create': true,
                'edit': true,
                'delete': false,
              },
              'roles': {
                'manage': false,
                'create': false,
                'edit': false,
                'delete': false,
              },
            },
            'product_services': {
              'manage': true,
              'create': true,
              'edit': true,
              'delete': false,
            },
            'project': {
              'manage': true,
              'create': true,
              'edit': true,
              'delete': false,
            },
            'hrm': {
              'manage': true,
              'create': true,
              'edit': true,
              'delete': false,
            },
          },
        ),
        AdminRole.defaultRole('3', 'Site/Project Manager').copyWith(
          permissions: {
            'general': {
              'user': {
                'manage': true,
                'profile': true,
                'logs_history': true,
                'create': true,
                'reset_password': true,
                'chat_manage': true,
                'edit': true,
                'login_manage': true,
                'delete': true,
                'import': true,
              },
              'setting': {
                'manage': true,
              },
              'plan': {
                'manage': true,
                'order': true,
                'purchase': true,
                'subscribe': true,
              },
              'helpdesk': {
                'ticket_manage': true,
                'create': true,
                'edit': true,
                'show': true,
                'reply': true,
                'delete': true,
              },
              'referral': {
                'program_manage': true,
              },
              'workspace': {
                'manage': true,
                'create': true,
                'edit': true,
                'delete': true,
              },
              'roles': {
                'manage': true,
                'create': true,
                'edit': true,
                'delete': true,
              },
            },
            'product_services': {
              'manage': true,
              'create': true,
              'edit': true,
              'delete': true,
            },
            'project': {
              'manage': true,
              'create': true,
              'edit': true,
              'delete': true,
            },
            'hrm': {
              'manage': true,
              'create': true,
              'edit': true,
              'delete': true,
            },
          },
        ),
        AdminRole.defaultRole('4', 'Vendor').copyWith(
          permissions: {
            'general': {
              'user': {
                'manage': false,
                'profile': true,
                'logs_history': false,
                'create': true,
                'reset_password': false,
                'chat_manage': false,
                'edit': true,
                'login_manage': false,
                'delete': false,
                'import': false,
              },
              'setting': {
                'manage': false,
              },
              'plan': {
                'manage': false,
                'order': false,
                'purchase': false,
                'subscribe': false,
              },
              'helpdesk': {
                'ticket_manage': true,
                'create': true,
                'edit': true,
                'show': true,
                'reply': true,
                'delete': false,
              },
              'referral': {
                'program_manage': false,
              },
              'workspace': {
                'manage': false,
                'create': false,
                'edit': false,
                'delete': false,
              },
              'roles': {
                'manage': false,
                'create': false,
                'edit': false,
                'delete': false,
              },
            },
            'product_services': {
              'manage': false,
              'create': true,
              'edit': true,
              'delete': false,
            },
            'project': {
              'manage': false,
              'create': true,
              'edit': true,
              'delete': false,
            },
            'hrm': {
              'manage': false,
              'create': false,
              'edit': false,
              'delete': false,
            },
          },
        ),
      ];
    } catch (e) {
      debugPrint('Error loading roles: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateRole(String id, AdminRole updatedRole) {
    final index = _roles.indexWhere((role) => role.id == id);
    if (index != -1) {
      _roles[index] = updatedRole;
      notifyListeners();
    }
  }

  AdminRole? getRoleById(String id) {
    return _roles.firstWhere((role) => role.id == id);
  }

  void addRole(AdminRole role) {
    _roles.add(role);
    notifyListeners();
  }

  void deleteRole(String id) {
    _roles.removeWhere((role) => role.id == id);
    notifyListeners();
  }
}