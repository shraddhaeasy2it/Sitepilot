// project_site_provider.dart
import 'package:ecoteam_app/admin/models/project_site_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ecoteam_app/contractor/services/api_service_login.dart';

class ProjectSiteProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _companies = [];
  List<Project> _projects = [];
  String? _selectedCompanyId;
  String? _selectedCompanyName;
  bool _isLoading = false;
  final String _baseUrl = 'http://sitepilot.easy2it.in';

  List<Map<String, dynamic>> get companies => _companies;
  List<Project> get projects => _projects;
  String? get selectedCompanyId => _selectedCompanyId;
  String? get selectedCompanyName => _selectedCompanyName;
  bool get isLoading => _isLoading;

  // Get filtered projects based on selected company
  List<Project> get filteredProjects {
    if (_selectedCompanyId == null || _selectedCompanyId!.isEmpty) {
      return _projects;
    }
    return _projects.where((project) => project.companyId == _selectedCompanyId).toList();
  }

  Future<void> loadCompanies() async {
    try {
      _setLoading(true);
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/workspaces'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final workspaces = data['workspaces'] as List;
        
        _companies.clear();
        
        for (var workspace in workspaces) {
          if (workspace['status'] == 'active') {
            _companies.add({
              'id': workspace['id'].toString(),
              'name': workspace['name'],
              'created_by': workspace['created_by'],
            });
          }
        }
        
        // Select first company if available
        if (_companies.isNotEmpty) {
          _selectedCompanyId = _companies.first['id'].toString();
          _selectedCompanyName = _companies.first['name'];
        }
        
        await loadProjects();
        notifyListeners();
      } else {
        throw Exception('Failed to load workspaces: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading companies: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadProjects() async {
    try {
      _setLoading(true);
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/projects'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final projectsData = data['projects'] as List? ?? [];
        
        _projects.clear();
        
        for (var projectData in projectsData) {
          try {
            final project = _parseProjectFromJson(projectData);
            if (project != null) {
              _projects.add(project);
            }
          } catch (e) {
            print('Error parsing project data: $e');
            print('Problematic project data: $projectData');
          }
        }
        
        print('Successfully loaded ${_projects.length} projects');
        notifyListeners();
      } else {
        throw Exception('Failed to load projects: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading projects: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Load projects by specific workspace ID
  Future<void> loadProjectsByWorkspace(String workspaceId) async {
    try {
      _setLoading(true);
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/projects?workspace=$workspaceId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final projectsData = data['projects'] as List? ?? [];
        
        _projects.clear();
        
        for (var projectData in projectsData) {
          try {
            final project = _parseProjectFromJson(projectData);
            if (project != null) {
              _projects.add(project);
            }
          } catch (e) {
            print('Error parsing project data: $e');
            print('Problematic project data: $projectData');
          }
        }
        
        print('Successfully loaded ${_projects.length} projects for workspace $workspaceId');
        notifyListeners();
      } else {
        throw Exception('Failed to load projects by workspace: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading projects by workspace: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Project? _parseProjectFromJson(Map<String, dynamic> projectData) {
    try {
      print('Parsing project: ${projectData['name']}');
      
      final companyId = projectData['workspace']?.toString() ?? '';
      
      // Find company name
      String companyName = 'Unknown Company';
      try {
        if (_companies.isNotEmpty) {
          final company = _companies.firstWhere(
            (c) => c['id'] == companyId,
            orElse: () => {'name': 'Unknown Company'},
          );
          companyName = company['name'];
        }
      } catch (e) {
        print('Company not found for ID: $companyId');
      }

      // Parse status
      ProjectStatus status;
      final statusString = projectData['status']?.toString().toLowerCase() ?? 'ongoing';
      switch (statusString) {
        case 'completed':
          status = ProjectStatus.completed;
          break;
        case 'on hold':
          status = ProjectStatus.onHold;
          break;
        default:
          status = ProjectStatus.ongoing;
      }

      // Parse budget safely
      double budget;
      try {
        final budgetValue = projectData['budget'];
        if (budgetValue == null) {
          budget = 0.0;
        } else if (budgetValue is String) {
          budget = double.tryParse(budgetValue) ?? 0.0;
        } else if (budgetValue is int) {
          budget = budgetValue.toDouble();
        } else if (budgetValue is double) {
          budget = budgetValue;
        } else {
          budget = 0.0;
        }
      } catch (e) {
        print('Error parsing budget: $e');
        budget = 0.0;
      }

      // Parse progress safely
      double progress;
      try {
        final progressValue = projectData['progress'];
        if (progressValue == null) {
          progress = 0.0;
        } else if (progressValue is String) {
          progress = double.tryParse(progressValue) ?? 0.0;
        } else if (progressValue is int) {
          progress = progressValue.toDouble();
        } else if (progressValue is double) {
          progress = progressValue;
        } else {
          progress = 0.0;
        }
      } catch (e) {
        print('Error parsing progress: $e');
        progress = 0.0;
      }

      // Parse dates
      DateTime startDate;
      try {
        final startDateStr = projectData['start_date']?.toString() ?? '';
        if (startDateStr.isNotEmpty) {
          startDate = DateTime.parse(startDateStr);
        } else {
          startDate = DateTime.now();
        }
      } catch (e) {
        print('Error parsing start date: $e');
        startDate = DateTime.now();
      }

      DateTime endDate;
      try {
        final endDateStr = projectData['end_date']?.toString() ?? '';
        if (endDateStr.isNotEmpty) {
          endDate = DateTime.parse(endDateStr);
        } else {
          endDate = DateTime.now().add(const Duration(days: 365));
        }
      } catch (e) {
        print('Error parsing end date: $e');
        endDate = DateTime.now().add(const Duration(days: 365));
      }

      final project = Project(
        id: projectData['id']?.toString() ?? '',
        name: projectData['name']?.toString() ?? 'Unnamed Project',
        status: status,
        budget: budget,
        startDate: startDate,
        endDate: endDate,
        description: projectData['description']?.toString() ?? '',
        members: _parseMembers(projectData),
        companyId: companyId,
        companyName: companyName,
        progress: progress,
      );

      print('Successfully parsed project: ${project.name}');
      return project;
    } catch (e) {
      print('Error parsing project: $e');
      print('Project data that caused error: $projectData');
      return null;
    }
  }

  List<String> _parseMembers(Map<String, dynamic> projectData) {
    try {
      // You can modify this based on how members are structured in your API
      // For now, return empty list
      return [];
    } catch (e) {
      return [];
    }
  }

  void selectCompany(String companyId) {
    if (companyId.isEmpty) {
      _selectedCompanyId = null;
      _selectedCompanyName = null;
      // Load all projects when "All Companies" is selected
      loadProjects();
    } else {
      try {
        final company = _companies.firstWhere(
          (c) => c['id'] == companyId,
        );
        _selectedCompanyId = companyId;
        _selectedCompanyName = company['name'];
        // Load projects for specific workspace
        loadProjectsByWorkspace(companyId);
      } catch (e) {
        _selectedCompanyId = null;
        _selectedCompanyName = null;
        loadProjects();
      }
    }
    notifyListeners();
  }

  Future<bool> addProject(Project project) async {
    try {
      _setLoading(true);
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/projects'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': project.name,
          'description': project.description,
          'budget': project.budget.toInt(),
          'workspace': int.parse(project.companyId),
          'start_date': project.startDate.toIso8601String().split('T')[0],
          'end_date': project.endDate.toIso8601String().split('T')[0],
          'status': project.statusString.toLowerCase(),
          'created_by': await ApiService.getCurrentUserId(),
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Reload projects based on current selection
        if (_selectedCompanyId == null || _selectedCompanyId!.isEmpty) {
          await loadProjects();
        } else {
          await loadProjectsByWorkspace(_selectedCompanyId!);
        }
        return true;
      } else {
        throw Exception('Failed to add project: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error adding project: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProject(Project project) async {
    try {
      _setLoading(true);
      
      final response = await http.put(
        Uri.parse('$_baseUrl/api/projects/${project.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': project.name,
          'description': project.description,
          'budget': project.budget.toInt(),
          'workspace': int.parse(project.companyId),
          'start_date': project.startDate.toIso8601String().split('T')[0],
          'end_date': project.endDate.toIso8601String().split('T')[0],
          'status': project.statusString.toLowerCase(),
          'created_by': await ApiService.getCurrentUserId(),
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // Reload projects based on current selection
        if (_selectedCompanyId == null || _selectedCompanyId!.isEmpty) {
          await loadProjects();
        } else {
          await loadProjectsByWorkspace(_selectedCompanyId!);
        }
        return true;
      } else {
        throw Exception('Failed to update project: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error updating project: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteProject(String projectId) async {
    try {
      _setLoading(true);
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/projects/$projectId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 204) {
        _projects.removeWhere((project) => project.id == projectId);
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to delete project: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting project: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}