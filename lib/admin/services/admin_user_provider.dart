import 'package:flutter/foundation.dart';
import 'package:ecoteam_app/admin/models/user_model.dart';

class AdminUserProvider extends ChangeNotifier {
  List<AdminUser> _users = [];
  List<AdminUser> _filteredUsers = [];
  String _nameFilter = '';
  String _emailFilter = '';
  String _roleFilter = '';

  List<AdminUser> get users => _filteredUsers;
  String get nameFilter => _nameFilter;
  String get emailFilter => _emailFilter;
  String get roleFilter => _roleFilter;

  AdminUserProvider() {
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Sample data
      _users = [
        AdminUser(
          id: '1',
          name: 'John Doe',
          email: 'john@example.com',
          role: 'Admin',
          imageUrl: 'https://via.placeholder.com/150',
        ),
        AdminUser(
          id: '2',
          name: 'Jane Smith',
          email: 'jane@example.com',
          role: 'Manager',
          imageUrl: 'https://via.placeholder.com/150',
        ),
        AdminUser(
          id: '3',
          name: 'Bob Johnson',
          email: 'bob@example.com',
          role: 'User',
          imageUrl: 'https://via.placeholder.com/150',
        ),
      ];
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading users: $e');
    }
  }

  void setNameFilter(String value) {
    _nameFilter = value;
    _applyFilters();
  }

  void setEmailFilter(String value) {
    _emailFilter = value;
    _applyFilters();
  }

  void setRoleFilter(String value) {
    _roleFilter = value;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredUsers = _users.where((user) {
      final nameMatch = _nameFilter.isEmpty ||
          user.name.toLowerCase().contains(_nameFilter.toLowerCase());
      final emailMatch = _emailFilter.isEmpty ||
          user.email.toLowerCase().contains(_emailFilter.toLowerCase());
      final roleMatch = _roleFilter.isEmpty ||
          user.role.toLowerCase().contains(_roleFilter.toLowerCase());
      return nameMatch && emailMatch && roleMatch;
    }).toList();
    notifyListeners();
  }

  void addUser(AdminUser user) {
    _users.add(user);
    _applyFilters();
  }

  void updateUser(String id, AdminUser updatedUser) {
    final index = _users.indexWhere((user) => user.id == id);
    if (index != -1) {
      _users[index] = updatedUser;
      _applyFilters();
    }
  }

  void deleteUser(String id) {
    _users.removeWhere((user) => user.id == id);
    _applyFilters();
  }
}