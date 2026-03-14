import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:ecoteam_app/contractor/services/dio_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

// API Service for Activities
class ActivityApiService {
  static const String baseUrl =
      'https://app.ecoteamsolar.com/api'; // Replace with your base URL

  // Fetch all activities
  static Future<List<Activity>> fetchActivities({Map<String, dynamic>? queryParams}) async {
    try {
      final response = await DioService.instance.dio.get(
        '/activities',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == true) {
          final payload = data['data'] ?? data;
          List<Activity> allActivities = [];

          // Parse Pending Activities
          if (payload['pending'] != null) {
            final pendingList = (payload['pending'] as List)
                .map((json) => Activity.fromApiJson(json)..status = 0)
                .toList();
            allActivities.addAll(pendingList);
          }

          // Parse Completed Activities
          if (payload['completed'] != null) {
            final completedList = (payload['completed'] as List)
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
      final response = await DioService.instance.dio.get('/activities/$id');

      if (response.statusCode == 200) {
        final data = response.data;
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
    Map<String, dynamic> activityData, {
    File? file,
  }) async {
    try {
      dynamic data = activityData;
      if (file != null) {
        final Map<String, dynamic> modifiedData = Map.from(activityData);
        if (modifiedData.containsKey('assign_to')) {
          modifiedData['assign_to[]'] = modifiedData.remove('assign_to');
        }
        data = FormData.fromMap({
          ...modifiedData,
          'reference_file': await MultipartFile.fromFile(
            file.path,
            filename: file.path.split(Platform.pathSeparator).last,
          ),
        });
      }
      print('Creating activity with data: $activityData');
      final response = await DioService.instance.dio.post(
        '/activities',
        data: data,
      );

      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': response.data,
        'statusCode': response.statusCode,
      };
    } on DioException catch (e) {
      print('DioError creating activity:');
      print('  Type: ${e.type}');
      print('  Message: ${e.message}');
      if (e.response != null) {
        print('  Status Code: ${e.response?.statusCode}');
        print('  Data: ${e.response?.data}');
      }
      return {
        'success': false,
        'error': e.message,
        'data': e.response?.data,
        'statusCode': e.response?.statusCode,
      };
    } catch (e) {
      print('Error creating activity: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Update activity
  static Future<Map<String, dynamic>> updateActivity(
    int id,
    Map<String, dynamic> activityData, {
    File? file,
  }) async {
    try {
      dynamic data = activityData;
      if (file != null) {
        final Map<String, dynamic> modifiedData = Map.from(activityData);
        if (modifiedData.containsKey('assign_to')) {
          modifiedData['assign_to[]'] = modifiedData.remove('assign_to');
        }
        data = FormData.fromMap({
          ...modifiedData,
          'reference_file': await MultipartFile.fromFile(
            file.path,
            filename: file.path.split(Platform.pathSeparator).last,
          ),
          '_method': 'PUT', // Often needed when sending FormData for PUT requests
        });
      }

      final response = await DioService.instance.dio.post(
        '/activities/$id',
        data: data,
      );

      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': response.data,
        'statusCode': response.statusCode,
      };
    } on DioException catch (e) {
      print('DioError updating activity $id:');
      print('  Type: ${e.type}');
      print('  Message: ${e.message}');
      if (e.response != null) {
        print('  Status Code: ${e.response?.statusCode}');
        print('  Data: ${e.response?.data}');
      }
      return {
        'success': false,
        'error': e.message,
        'data': e.response?.data,
        'statusCode': e.response?.statusCode,
      };
    } catch (e) {
      print('Error updating activity: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Delete activity
  static Future<bool> deleteActivity(int id) async {
    try {
      final response = await DioService.instance.dio.delete('/activities/$id');

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
      final response = await DioService.instance.dio.post(
        '/activities/create-data',
        data: params,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == true) {
          return {
            'success': true,
            'workspaces': data['workspaces'] ?? [],
            'sites': data['sites'] ?? [],
            'priorities': data['priorities'] ?? [],
            'users': data['users'] ?? {},
          };
        }
      }
      return {
        'success': false,
        'workspaces': [],
        'sites': [],
        'priorities': [],
        'users': {},
      };
    } catch (e) {
      print('Error fetching create data: $e');
      return {
        'success': false,
        'workspaces': [],
        'sites': [],
        'priorities': [],
        'users': {},
      };
    }
  }

  // Fetch progress data
  static Future<Map<String, dynamic>> fetchProgressData(
    Map<String, dynamic> params,
  ) async {
    try {
      final response = await DioService.instance.dio.get(
        '/activities/progress/create',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        final data = response.data;
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

  // Store progress
  static Future<Map<String, dynamic>> storeProgress(
    Map<String, dynamic> progressData, {
    File? image,
  }) async {
    try {
      dynamic data;
      
      if (image != null) {
        final formData = FormData();
        
        // Add all text fields as strings
        progressData.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
        
        // Ensure completed_date and completed_quantity aliases are explicit
        if (!progressData.containsKey('completed_date')) {
          formData.fields.add(MapEntry('completed_date', progressData['date'].toString()));
        }
        
        final String fileName = image.path.split('/').last.split('\\').last;
        final String extension = fileName.split('.').last.toLowerCase();
        final String mimeType = (extension == 'png') ? 'image/png' : 'image/jpeg';

        // Add file with multiple aliases to find which one the backend expects
        final multipartFile = await MultipartFile.fromFile(
          image.path,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        );

        formData.files.add(MapEntry('completed_reference_file', multipartFile));
        
        // Add another copy for 'reference_file' key which is common in this app
        formData.files.add(MapEntry(
          'reference_file',
          await MultipartFile.fromFile(
            image.path,
            filename: fileName,
            contentType: MediaType.parse(mimeType),
          ),
        ));
        
        data = formData;
        print('DIAGNOSTIC: Sending Multipart Request');
        print('DIAGNOSTIC: Fields: ${formData.fields.map((e) => "${e.key}: ${e.value}").toList()}');
        print('DIAGNOSTIC: Files: ${formData.files.map((e) => "${e.key}: ${e.value.filename}").toList()}');
      } else {
        data = {
          ...progressData,
          'completed_date': progressData['date'],
        };
        print('DIAGNOSTIC: Storing progress with JSON: $data');
      }

      final response = await DioService.instance.dio.post(
        '/activities/progress/store',
        data: data,
      );

      print('DIAGNOSTIC: ADD PROGRESS RESPONSE: ${response.data}');

      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': response.data,
        'statusCode': response.statusCode,
      };
    } catch (e) {
      print('Error storing progress: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}

// Consumption Models
class MaterialItem {
  final int id;
  final String name;
  final String unit;

  MaterialItem({required this.id, required this.name, required this.unit});

  factory MaterialItem.fromApiJson(Map<String, dynamic> json) {
    return MaterialItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      unit: json['unit_id']?.toString() ?? '',
    );
  }
}

class ConsumptionDetail {
  final int id;
  final double quantity;
  final String unit;
  final MaterialItem? material;

  ConsumptionDetail({
    required this.id,
    required this.quantity,
    required this.unit,
    this.material,
  });

  factory ConsumptionDetail.fromApiJson(Map<String, dynamic> json) {
    return ConsumptionDetail(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0.0,
      unit: json['unit'] ?? '',
      material: json['material'] != null ? MaterialItem.fromApiJson(json['material']) : null,
    );
  }
}

class Consumption {
  final int id;
  final String consumptionDate;
  final List<ConsumptionDetail> details;

  Consumption({
    required this.id,
    required this.consumptionDate,
    required this.details,
  });

  factory Consumption.fromApiJson(Map<String, dynamic> json) {
    List<ConsumptionDetail> details = [];
    if (json['details'] != null && json['details'] is List) {
      details = (json['details'] as List)
          .map((detail) => ConsumptionDetail.fromApiJson(detail))
          .toList();
    }
    return Consumption(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      consumptionDate: json['consumption_date'] ?? '',
      details: details,
    );
  }
}

// Manpower Models
class ManpowerType {
  final int id;
  final String name;

  ManpowerType({required this.id, required this.name});

  factory ManpowerType.fromApiJson(Map<String, dynamic> json) {
    return ManpowerType(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class ManpowerDetail {
  final int id;
  final int count;
  final ManpowerType? type;

  ManpowerDetail({required this.id, required this.count, this.type});

  factory ManpowerDetail.fromApiJson(Map<String, dynamic> json) {
    return ManpowerDetail(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      type: json['type'] != null ? ManpowerType.fromApiJson(json['type']) : null,
    );
  }
}

class Manpower {
  final int id;
  final String workDate;
  final List<ManpowerDetail> details;

  Manpower({required this.id, required this.workDate, required this.details});

  factory Manpower.fromApiJson(Map<String, dynamic> json) {
    List<ManpowerDetail> details = [];
    if (json['details'] != null && json['details'] is List) {
      details = (json['details'] as List)
          .map((detail) => ManpowerDetail.fromApiJson(detail))
          .toList();
    }
    return Manpower(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      workDate: json['work_date'] ?? '',
      details: details,
    );
  }
}

// Daily Progress Models (Machinery)
class MachineryItem {
  final int id;
  final String name;

  MachineryItem({required this.id, required this.name});

  factory MachineryItem.fromApiJson(Map<String, dynamic> json) {
    return MachineryItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class ActivityDailyProgress {
  final int id;
  final String date;
  final double dieselConsumption;
  final MachineryItem? machinery;

  ActivityDailyProgress({
    required this.id,
    required this.date,
    required this.dieselConsumption,
    this.machinery,
  });

  factory ActivityDailyProgress.fromApiJson(Map<String, dynamic> json) {
    return ActivityDailyProgress(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      date: json['date'] ?? '',
      dieselConsumption: double.tryParse(json['diesel_consumption']?.toString() ?? '0') ?? 0.0,
      machinery: json['machinery'] != null ? MachineryItem.fromApiJson(json['machinery']) : null,
    );
  }
}

// Activity Update Model
class ActivityUpdate {
  final int id;
  final int activityId;
  final int completedQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? completedReferenceFile;
  final Map<String, dynamic>? creator;

  /// Nested data directly from this completed entry
  final List<dynamic> manpowers;
  final List<dynamic> dailyConsumptions;
  final List<dynamic> dailyProgressReports;

  ActivityUpdate({
    required this.id,
    required this.activityId,
    required this.completedQuantity,
    required this.createdAt,
    required this.updatedAt,
    this.completedReferenceFile,
    this.creator,
    this.manpowers = const [],
    this.dailyConsumptions = const [],
    this.dailyProgressReports = const [],
  });

  factory ActivityUpdate.fromApiJson(Map<String, dynamic> json) {
    final dateStr = json['completed_date'] ??
        json['created_at'] ??
        DateTime.now().toString();
    return ActivityUpdate(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      activityId:
          int.tryParse(json['activity_id']?.toString() ?? '0') ?? 0,
      completedQuantity:
          int.tryParse(json['completed_quantity']?.toString() ?? '0') ??
              0,
      createdAt: DateTime.tryParse(dateStr) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(
                json['updated_at'] ?? DateTime.now().toString(),
              ) ??
          DateTime.now(),
      completedReferenceFile: json['completed_reference_file']?.toString(),
      creator: json['creator'] is Map<String, dynamic> ? json['creator'] : null,
      manpowers: (json['manpowers'] as List<dynamic>?) ?? [],
      dailyConsumptions:
          (json['daily_consumptions'] as List<dynamic>?) ?? [],
      dailyProgressReports:
          (json['daily_progress_reports'] as List<dynamic>?) ?? [],
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
  List<String>? assignTo;
  DateTime date; // Executed/Planned date
  DateTime createdAt;
  DateTime updatedAt;
  String? referenceFile;
  Map<String, dynamic>? creator;
  List<ActivityUpdate> completions;
  List<Consumption> consumptions;
  List<Manpower> manpowers;
  List<ActivityDailyProgress> dailyProgress;

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
    this.assignTo,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.referenceFile,
    this.creator,
    List<ActivityUpdate>? completions,
    List<Consumption>? consumptions,
    List<Manpower>? manpowers,
    List<ActivityDailyProgress>? dailyProgress,
  }) : completions = completions ?? [], 
       consumptions = consumptions ?? [],
       manpowers = manpowers ?? [],
       dailyProgress = dailyProgress ?? [];

  factory Activity.fromApiJson(Map<String, dynamic> json) {
    List<ActivityUpdate> completions = [];
    if (json['completions'] != null && json['completions'] is List) {
      completions = (json['completions'] as List)
          .map((comp) => ActivityUpdate.fromApiJson(comp))
          .toList();
    } else if (json['completeds'] != null && json['completeds'] is List) {
       completions = (json['completeds'] as List)
          .map((comp) => ActivityUpdate.fromApiJson(comp))
          .toList();
    }

    List<Consumption> consumptions = [];
    if (json['consumptions'] != null && json['consumptions'] is List) {
      consumptions = (json['consumptions'] as List)
          .map((comp) => Consumption.fromApiJson(comp))
          .toList();
    }

    List<Manpower> manpowers = [];
    if (json['manpowers'] != null && json['manpowers'] is List) {
      manpowers = (json['manpowers'] as List)
          .map((mp) => Manpower.fromApiJson(mp))
          .toList();
    }

    List<ActivityDailyProgress> dailyProgress = [];
    if (json['daily_progress'] != null && json['daily_progress'] is List) {
      dailyProgress = (json['daily_progress'] as List)
          .map((dp) => ActivityDailyProgress.fromApiJson(dp))
          .toList();
    }

    // Handle nested workspace/site ID extraction
    int workspaceId = 0;
    if (json['workspace'] is Map) {
      workspaceId = json['workspace']['id'] ?? 0;
    } else {
      workspaceId = int.tryParse(json['workspace_id']?.toString() ?? '0') ?? 0;
    }

    int siteId = 0;
    if (json['site'] is Map) {
      siteId = json['site']['id'] ?? 0;
    } else {
      siteId = int.tryParse(json['site_id']?.toString() ?? '0') ?? 0;
    }

    // Handle name/title mapping
    String title = json['title'] ?? json['name'] ?? 'Activity #${json['id'] ?? 'Unknown'}';

    // Handle qty mapping (safely parse String to int)
    int quantity = 0;
    if (json['quantity'] != null) {
       quantity = int.tryParse(json['quantity'].toString()) ?? 0;
    } else if (json['qty'] != null) {
       quantity = int.tryParse(json['qty'].toString()) ?? 0;
    }

    // Handle completed_qty mapping
    int completedQty = 0;
    if (json['completed_quantity'] != null) {
      completedQty = int.tryParse(json['completed_quantity'].toString()) ?? 0;
    } else if (json['completed_qty'] != null) {
      completedQty = int.tryParse(json['completed_qty'].toString()) ?? 0;
    } else {
       completedQty = completions.fold(
          0,
          (sum, comp) => sum + comp.completedQuantity,
       );
    }

    return Activity(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: title,
      scope: json['scope'] ?? '',
      quantity: quantity,
      unit: json['unit'] ?? '',
      completedQuantity: completedQty,
      priority: json['priority'] ?? 'medium',
      status: int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      createdBy: int.tryParse(json['created_by']?.toString() ?? '0') ?? 0,
      workspaceId: workspaceId,
      siteId: siteId,
      assignTo: json['assign_to'] is List
          ? (json['assign_to'] as List).map((e) => e.toString()).toList()
          : (json['assign_to'] != null ? [json['assign_to'].toString()] : null),
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      createdAt:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      referenceFile: json['reference_file']?.toString(),
      creator: json['creator'] is Map<String, dynamic> ? json['creator'] : null,
      completions: completions,
      consumptions: consumptions,
      manpowers: manpowers,
      dailyProgress: dailyProgress,
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'title': title,
      'scope': scope,
      'quantity': quantity,
      'unit': unit,
      'priority': priority,
      if (completedQuantity > 0 || id != 0)
        'completed_quantity': completedQuantity,
      'created_by': createdBy,
      'workspace_id': workspaceId,
      'site_id': siteId,
      if (assignTo != null && assignTo!.isNotEmpty) 'assign_to': assignTo,
      'start_date': DateFormat('yyyy-MM-dd').format(date),
      'due_date': DateFormat('yyyy-MM-dd').format(date),
      if (referenceFile != null) 'reference_file': referenceFile,
      if (creator != null) 'creator': creator,
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
    List<String>? assignTo,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? referenceFile,
    Map<String, dynamic>? creator,
    List<ActivityUpdate>? completions,
    List<Consumption>? consumptions,
    List<Manpower>? manpowers,
    List<ActivityDailyProgress>? dailyProgress,
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
      assignTo: assignTo ?? this.assignTo,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      referenceFile: referenceFile ?? this.referenceFile,
      creator: creator ?? this.creator,
      completions: completions ?? this.completions,
      consumptions: consumptions ?? this.consumptions,
      manpowers: manpowers ?? this.manpowers,
      dailyProgress: dailyProgress ?? this.dailyProgress,
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
  Future<void> fetchActivities({int? siteId, int? workspaceId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (workspaceId != null) queryParams['workspace_id'] = workspaceId;
      if (siteId != null) queryParams['site_id'] = siteId;

      final activities = await ActivityApiService.fetchActivities(
        queryParams: queryParams,
      );
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
  Future<Map<String, dynamic>> addActivity(Activity activity, {File? file}) async {
    try {
      final result = await ActivityApiService.createActivity(
        activity.toApiJson(),
        file: file,
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
  Future<Map<String, dynamic>> updateActivity(Activity updatedActivity, {File? file}) async {
    try {
      final result = await ActivityApiService.updateActivity(
        updatedActivity.id,
        updatedActivity.toApiJson(),
        file: file,
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

  // Add progress
  Future<Map<String, dynamic>> addProgress(
    int activityId,
    int workspaceId,
    int siteId,
    int completedQuantity,
    String date,
    int userId, {
    File? image,
  }) async {
    try {
      final result = await ActivityApiService.storeProgress({
        'workspace_id': workspaceId,
        'site_id': siteId,
        'activity_id': activityId,
        'completed_quantity': completedQuantity,
        'date': date,
        'created_by': userId,
      }, image: image);

      if (result['success'] == true) {
        if (result['data']['status'] == true) {
          final updatedServerActivity =
              Activity.fromApiJson(result['data']['data']);
          final index = _activities.indexWhere(
            (activity) => activity.id == activityId,
          );
          if (index != -1) {
            _activities[index] = updatedServerActivity;
            notifyListeners();
          }

          // Print full response for debugging
          print('=== ADD PROGRESS RESPONSE ===');
          print('Full response: ${result["data"]}');

          // Extract the id of the latest completed entry from the response
          int? completedId;
          final completeds = result['data']['data']['completeds'];
          print('completeds array: $completeds');
          if (completeds != null && completeds is List && completeds.isNotEmpty) {
            completedId = int.tryParse(
              completeds.last['id']?.toString() ?? '',
            );
          }
          print('Extracted activityCompletedId: $completedId');
          print('=============================');

          return {
            'success': true,
            'message': 'Progress added successfully',
            'completedId': completedId,
          };
        }
      }
      return {'success': false, 'message': 'Failed to add progress'};
    } catch (e) {
      print('Error adding progress: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}