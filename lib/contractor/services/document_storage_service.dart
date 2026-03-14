import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ecoteam_app/contractor/models/document_model.dart';
import 'package:ecoteam_app/contractor/services/api_ser.dart';
import 'package:ecoteam_app/contractor/services/dio_service.dart';

class DocumentStorageService {
  
  // 1. Get List of Documents (Root)
  Future<List<Document>> getDocuments(String projectId) async {
    try {
      final response = await ApiService.getRequest('/projects/$projectId/documents');
      if (response['success'] == true && response['data'] is List) {
        return (response['data'] as List)
            .map((e) => Document.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching documents: $e');
      throw e;
    }
  }

  // 2. Get Structure (Root Files & Folders)
  Future<Map<String, dynamic>> getStructure(String projectId) async {
    try {
      final response = await ApiService.getRequest('/projects/$projectId/documents/structure');
      if (response['success'] == true && response['data'] != null) {
        return response['data'];
      }
      return {};
    } catch (e) {
      print('Error fetching document structure: $e');
      throw e;
    }
  }

  // 3. Get Nested Structure
  Future<Map<String, dynamic>> getNestedStructure(String projectId) async {
    try {
      final response = await ApiService.getRequest('/projects/$projectId/documents/structure-nested');
      // The API returns { "files": [], "folders": {...} } directly or in data. 
      // Based on previous image it looked like root object. 
      // Use helper to handle both cases if unsure, or assume root based on previous.
      return response;
    } catch (e) {
      print('Error fetching nested structure: $e');
      throw e;
    }
  }

  // 4. Get Stats
  Future<Map<String, dynamic>> getStats(String projectId) async {
    try {
      final response = await ApiService.getRequest('/projects/$projectId/documents/stats');
      if (response['success'] == true && response['data'] != null) {
        return response['data'];
      }
      return {};
    } catch (e) {
      print('Error fetching document stats: $e');
      throw e;
    }
  }

  // 5. Create Folder
  Future<bool> createFolder({
    required String projectId,
    required String folderName,
  }) async {
    try {
      final response = await DioService.instance.dio.post(
        '/projects/$projectId/documents/folders',
        data: FormData.fromMap({'folder_name': folderName}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) return true;
      return false;
    } catch (e) {
      print('Error creating folder: $e');
      throw e;
    }
  }

  // 6. Upload Document
  Future<bool> addDocument({
    required String projectId, // Corresponds to siteId/projectId in API path
    required File file,
    required String description,
    String? folderPath,
  }) async {
    try {
      String fileName = file.path.split('/').last;
      
      Map<String, dynamic> data = {
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'description': description,
      };
      
      if (folderPath != null && folderPath.isNotEmpty) {
        data['folder_path'] = folderPath;
      }

      FormData formData = FormData.fromMap(data);

      final response = await DioService.instance.dio.post(
        '/projects/$projectId/documents/upload',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error uploading document: $e');
      throw e;
    }
  }
  
  // 7. Update Document
  Future<bool> updateDocument({
    required String projectId,
    required int documentId,
    String? fileName, 
    String? description,
  }) async {
    try {
        // PUT request. DioService doesn't have putRequest helper exposed usually, we use dio directly.
        // API Image says PUT /api/projects/{projectId}/documents/{documentId}
        // It might be x-www-form-urlencoded or JSON. Image shows JSON body response, but request body type isn't fully clear (likely JSON or form).
        // Standard Laravel PUT often prefers _method=PUT with POST if using FormData, but specific PUT method works with JSON.
        // Only description/file_name usually updated.
        
        final response = await DioService.instance.dio.put(
          '/projects/$projectId/documents/$documentId',
          data: {
             if(fileName != null) 'file_name': fileName,
             if(description != null) 'description': description,
          }
        );
         if (response.statusCode == 200) return true;
         return false;
    } catch (e) {
      print('Error updating document: $e');
      throw e;
    }
  }
  // 8. Delete Document
  Future<bool> deleteDocument({
    required String projectId,
    required int documentId,
  }) async {
    try {
      final response = await DioService.instance.dio.delete(
        '/projects/$projectId/documents/$documentId',
      );
      if (response.statusCode == 200) return true;
      return false;
    } catch (e) {
      print('Error deleting document: $e');
      throw e;
    }
  }

  // 9. Download Document
  Future<bool> downloadDocument({
    required String projectId,
    required int documentId,
    required String savePath,
  }) async {
    try {
       // GET /api/projects/{projectId}/documents/{documentId}/download
       final response = await DioService.instance.dio.download(
          '/projects/$projectId/documents/$documentId/download',
          savePath,
       );
       if (response.statusCode == 200) {
          return true;
       }
       return false;
    } catch (e) {
       print('Error downloading document: $e');
       throw e;
    }
  }
}
