class AdminRole {
  final String id;
  String name;
  final Map<String, Map<String, dynamic>> permissions;

  AdminRole({
    required this.id,
    required this.name,
    required this.permissions,
  });

  // Factory constructor for creating default roles
  factory AdminRole.defaultRole(String id, String name) {
    return AdminRole(
      id: id,
      name: name,
      permissions: {
        'general': {
          'user': {
            'manage': false,
            'profile': false,
            'logs_history': false,
            'create': false,
            'reset_password': false,
            'chat_manage': false,
            'edit': false,
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
    );
  }

  // Copy with method for updating
  AdminRole copyWith({
    String? id,
    String? name,
    Map<String, Map<String, dynamic>>? permissions,
  }) {
    return AdminRole(
      id: id ?? this.id,
      name: name ?? this.name,
      permissions: permissions ?? this.permissions,
    );
  }

  // Get key permissions for display
  List<String> getKeyPermissions() {
    List<String> keyPerms = [];
    try {
      permissions.forEach((category, categoryPerms) {
        if (categoryPerms is Map<String, dynamic>) {
          categoryPerms.forEach((module, modulePerms) {
            if (modulePerms is Map<String, dynamic>) {
              // Handle nested permissions (like in 'general' category)
              modulePerms.forEach((perm, enabled) {
                if (enabled is bool && enabled == true) {
                  keyPerms.add(_formatPermissionName(perm));
                }
              });
            } else if (modulePerms is bool && modulePerms == true) {
              // Handle simple boolean permissions (like in other categories)
              keyPerms.add(_formatPermissionName(module));
            }
          });
        }
      });
    } catch (e) {
      // Return empty list if there's any error parsing permissions
      return [];
    }
    return keyPerms.take(3).toList(); // Show only first 3 permissions
  }

  String _formatPermissionName(String perm) {
    return perm.replaceAll('_', ' ').split(' ').map((word) =>
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word
    ).join(' ');
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'permissions': permissions,
    };
  }

  // Create from JSON
  factory AdminRole.fromJson(Map<String, dynamic> json) {
    return AdminRole(
      id: json['id'],
      name: json['name'],
      permissions: Map<String, Map<String, bool>>.from(json['permissions']),
    );
  }
}