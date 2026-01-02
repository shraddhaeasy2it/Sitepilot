// activity_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// API Service for Activities
class ActivityApiService {
  static const String baseUrl =
      'https://sitepilot.easy2it.in'; // Replace with your base URL

  // Fetch all activities
  static Future<List<Activity>> fetchActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/activities'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          List<Activity> allActivities = [];

          // Parse Pending Activities
          if (data['pending'] != null) {
            final pendingList = (data['pending'] as List)
                .map((json) => Activity.fromApiJson(json)..status = 0)
                .toList();
            allActivities.addAll(pendingList);
          }

          // Parse Completed Activities
          if (data['completed'] != null) {
            final completedList = (data['completed'] as List)
                .map((json) => Activity.fromApiJson(json)..status = 1)
                .toList();
            allActivities.addAll(completedList);
          }

          return allActivities;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching activities: $e');
      return [];
    }
  }

  // Fetch single activity by ID
  static Future<Activity?> fetchActivityById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/activities/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          return Activity.fromApiJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching activity: $e');
      return null;
    }
  }

  // Create new activity
  static Future<Map<String, dynamic>> createActivity(
    Map<String, dynamic> activityData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse('$baseUrl/api/activities'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(activityData),
      );

      return {
        'success': response.statusCode == 201,
        'data': json.decode(response.body),
        'statusCode': response.statusCode,
      };
    } catch (e) {
      print('Error creating activity: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Update activity
  static Future<Map<String, dynamic>> updateActivity(
    int id,
    Map<String, dynamic> activityData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.put(
        Uri.parse('$baseUrl/api/activities/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(activityData),
      );

      return {
        'success': response.statusCode == 200,
        'data': json.decode(response.body),
        'statusCode': response.statusCode,
      };
    } catch (e) {
      print('Error updating activity: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Delete activity
  static Future<bool> deleteActivity(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.delete(
        Uri.parse('$baseUrl/api/activities/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting activity: $e');
      return false;
    }
  }

  // Fetch create form data (workspaces, sites, priorities)
  static Future<Map<String, dynamic>> fetchCreateData(
    Map<String, dynamic> params,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse('$baseUrl/api/activities/create-data'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(params),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          return {
            'success': true,
            'workspaces': data['workspaces'] ?? [],
            'sites': data['sites'] ?? [],
            'priorities': data['priorities'] ?? [],
          };
        }
      }
      return {
        'success': false,
        'workspaces': [],
        'sites': [],
        'priorities': [],
      };
    } catch (e) {
      print('Error fetching create data: $e');
      return {
        'success': false,
        'workspaces': [],
        'sites': [],
        'priorities': [],
      };
    }
  }

  // Fetch progress data
  static Future<Map<String, dynamic>> fetchProgressData(
    Map<String, dynamic> params,
  ) async {
    try {
      final queryParams = Uri(queryParameters: params).query;
      final response = await http.get(
        Uri.parse('$baseUrl/api/activities/progress/create?$queryParams'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          return {
            'success': true,
            'workspaces': data['workspaces'] ?? [],
            'sites': data['sites'] ?? [],
            'priorities': data['priorities'] ?? [],
            'activities': data['activities'] ?? [],
            'alreadyCompleted': data['alreadyCompleted'] ?? 0,
          };
        }
      }
      return {
        'success': false,
        'workspaces': [],
        'sites': [],
        'priorities': [],
        'activities': [],
        'alreadyCompleted': 0,
      };
    } catch (e) {
      print('Error fetching progress data: $e');
      return {
        'success': false,
        'workspaces': [],
        'sites': [],
        'priorities': [],
        'activities': [],
        'alreadyCompleted': 0,
      };
    }
  }
}

// Activity Update Model
class ActivityUpdate {
  final int id;
  final int activityId;
  final int completedQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  ActivityUpdate({
    required this.id,
    required this.activityId,
    required this.completedQuantity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ActivityUpdate.fromApiJson(Map<String, dynamic> json) {
    return ActivityUpdate(
      id: json['id'] ?? 0,
      activityId: json['activity_id'] ?? 0,
      completedQuantity: json['completed_quantity'] ?? 0,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toString(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toString(),
      ),
    );
  }
}

// Activity Model
class Activity {
  final int id;
  String title;
  String scope;
  int quantity;
  String unit;
  int completedQuantity;
  String priority;
  int status; // 0 = pending, 1 = completed
  int createdBy;
  int workspaceId;
  int siteId;
  DateTime createdAt;
  DateTime updatedAt;
  List<ActivityUpdate> completions;

  int get balanceQuantity => quantity - completedQuantity;
  bool get isCompleted => status == 1 || completedQuantity >= quantity;
  double get progressPercentage =>
      quantity > 0 ? (completedQuantity / quantity) : 0.0;

  Activity({
    required this.id,
    required this.title,
    required this.scope,
    required this.quantity,
    required this.unit,
    required this.completedQuantity,
    required this.priority,
    required this.status,
    required this.createdBy,
    required this.workspaceId,
    required this.siteId,
    required this.createdAt,
    required this.updatedAt,
    List<ActivityUpdate>? completions,
  }) : completions = completions ?? [];

  factory Activity.fromApiJson(Map<String, dynamic> json) {
    List<ActivityUpdate> completions = [];
    if (json['completions'] != null && json['completions'] is List) {
      completions = (json['completions'] as List)
          .map((comp) => ActivityUpdate.fromApiJson(comp))
          .toList();
    }

    // Handle nested workspace/site ID extraction
    int workspaceId = 0;
    if (json['workspace'] is Map) {
      workspaceId = json['workspace']['id'] ?? 0;
    } else {
      workspaceId = json['workspace_id'] ?? 0;
    }

    int siteId = 0;
    if (json['site'] is Map) {
      siteId = json['site']['id'] ?? 0;
    } else {
      siteId = json['site_id'] ?? 0;
    }

    // Handle name/title mapping
    String title = json['title'] ?? json['name'] ?? 'Activity #${json['id'] ?? 'Unknown'}';

    // Handle qty mapping
    int quantity = json['quantity'] ?? json['qty'] ?? 0;

    // Handle completed_qty mapping
    int completedQty = 0;
    if (json['completed_quantity'] != null) {
      completedQty = json['completed_quantity'];
    } else if (json['completed_qty'] != null) {
      completedQty = json['completed_qty'];
    } else {
       completedQty = completions.fold(
          0,
          (sum, comp) => sum + comp.completedQuantity,
       );
    }

    return Activity(
      id: json['id'] ?? 0,
      title: title,
      scope: json['scope'] ?? '',
      quantity: quantity,
      unit: json['unit'] ?? '',
      completedQuantity: completedQty,
      priority: json['priority'] ?? 'medium',
      status: json['status'] is int ? json['status'] : 0,
      createdBy: json['created_by'] ?? 0,
      workspaceId: workspaceId,
      siteId: siteId,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      completions: completions,
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'title': title,
      'scope': scope,
      'quantity': quantity,
      'unit': unit,
      'priority': priority,
      'completed_quantity': completedQuantity,
      'created_by': createdBy,
      'workspace_id': workspaceId,
      'site_id': siteId,
      if (id != 0) 'activity_id': id,
    };
  }

  Activity copyWith({
    int? id,
    String? title,
    String? scope,
    int? quantity,
    String? unit,
    int? completedQuantity,
    String? priority,
    int? status,
    int? createdBy,
    int? workspaceId,
    int? siteId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ActivityUpdate>? completions,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      scope: scope ?? this.scope,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      completedQuantity: completedQuantity ?? this.completedQuantity,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      workspaceId: workspaceId ?? this.workspaceId,
      siteId: siteId ?? this.siteId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completions: completions ?? this.completions,
    );
  }
}

// Workspace Model
class Workspace {
  final int id;
  final String name;

  Workspace({required this.id, required this.name});

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(id: json['id'] ?? 0, name: json['name'] ?? '');
  }
}

// Site Model for API
class ApiSite {
  final int id;
  final String name;

  ApiSite({required this.id, required this.name});

  factory ApiSite.fromJson(Map<String, dynamic> json) {
    return ApiSite(id: json['id'] ?? 0, name: json['name'] ?? '');
  }
}

// Activity Provider
class ActivityProvider with ChangeNotifier {
  List<Activity> _activities = [];
  bool _isLoading = false;
  String? _error;

  List<Activity> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Activity> get pendingActivities =>
      _activities.where((activity) => !activity.isCompleted).toList();

  List<Activity> get completedActivities =>
      _activities.where((activity) => activity.isCompleted).toList();

  // Fetch all activities
  Future<void> fetchActivities() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final activities = await ActivityApiService.fetchActivities();
      _activities = activities;
    } catch (e) {
      _error = 'Failed to fetch activities: ${e.toString()}';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add activity
  Future<Map<String, dynamic>> addActivity(Activity activity) async {
    try {
      final result = await ActivityApiService.createActivity(
        activity.toApiJson(),
      );

      if (result['success'] == true) {
        if (result['data']['status'] == true) {
          // Add the new activity to the list
          final newActivity = Activity.fromApiJson(result['data']['data']);
          _activities.insert(0, newActivity);
          notifyListeners();
          return {'success': true, 'message': 'Activity created successfully'};
        }
      }
      return {'success': false, 'message': 'Failed to create activity'};
    } catch (e) {
      print('Error adding activity: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Update activity
  Future<Map<String, dynamic>> updateActivity(Activity updatedActivity) async {
    try {
      final result = await ActivityApiService.updateActivity(
        updatedActivity.id,
        updatedActivity.toApiJson(),
      );

      if (result['success'] == true) {
        if (result['data']['status'] == true) {
          // Update the activity in the list
          // Update the activity in the list with server data
          final updatedServerActivity = Activity.fromApiJson(result['data']['data']);
          final index = _activities.indexWhere(
            (activity) => activity.id == updatedActivity.id,
          );
          if (index != -1) {
            _activities[index] = updatedServerActivity;
            notifyListeners();
          }
           return {
              'success': true,
              'message': 'Activity updated successfully',
            };
        }
      }
      return {'success': false, 'message': 'Failed to update activity'};
    } catch (e) {
      print('Error updating activity: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Mark as complete
  Future<Map<String, dynamic>> markComplete(
    int id,
    int completedQuantity,
  ) async {
    try {
      final activity = _activities.firstWhere((activity) => activity.id == id);
      final updatedActivity = activity.copyWith(
        completedQuantity: activity.completedQuantity + completedQuantity,
        status:
            (activity.completedQuantity + completedQuantity) >=
                activity.quantity
            ? 1
            : 0,
      );

      return await updateActivity(updatedActivity);
    } catch (e) {
      print('Error marking complete: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Delete activity
  Future<Map<String, dynamic>> deleteActivity(int id) async {
    try {
      final success = await ActivityApiService.deleteActivity(id);

      if (success) {
        _activities.removeWhere((activity) => activity.id == id);
        notifyListeners();
        return {'success': true, 'message': 'Activity deleted successfully'};
      }
      return {'success': false, 'message': 'Failed to delete activity'};
    } catch (e) {
      print('Error deleting activity: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}