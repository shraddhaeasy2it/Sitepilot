// // providers/material_provider.dart
// import 'package:ecoteam_app/admin/Screens/all_material_page.dart';
// import 'package:ecoteam_app/admin/service/material_services.dart';
// import 'package:flutter/material.dart';


// class MaterialProvider with ChangeNotifier {
//   List<MaterialItem> _materials = [];
//   List<MaterialItem> _filteredMaterials = [];
//   bool _isLoading = false;
//   String _errorMessage = '';

//   // Getters
//   List<MaterialItem> get materials => _materials;
//   List<MaterialItem> get filteredMaterials => _filteredMaterials;
//   bool get isLoading => _isLoading;
//   String get errorMessage => _errorMessage;

//   // Load all materials
//   Future<void> loadMaterials() async {
//     _setLoading(true);
//     _setErrorMessage('');

//     try {
//       final materials = await MaterialApiService.getMaterials();
//       _materials = materials;
//       _filteredMaterials = materials;
//       notifyListeners();
//     } catch (e) {
//       _setErrorMessage(e.toString());
//       notifyListeners();
//       rethrow;
//     } finally {
//       _setLoading(false);
//     }
//   }

//   // Add new material
//   Future<void> addMaterial(MaterialItem material) async {
//     _setLoading(true);
    
//     try {
//       final newMaterial = await MaterialApiService.addMaterial(material);
//       _materials.add(newMaterial);
//       _filteredMaterials = List.from(_materials);
//       notifyListeners();
//     } catch (e) {
//       _setErrorMessage(e.toString());
//       notifyListeners();
//       rethrow;
//     } finally {
//       _setLoading(false);
//     }
//   }

//   // Update existing material
//   Future<void> updateMaterial(MaterialItem material) async {
//     _setLoading(true);
    
//     try {
//       final updatedMaterial = await MaterialApiService.updateMaterial(material);
//       final index = _materials.indexWhere((m) => m.id == material.id);
//       if (index != -1) {
//         _materials[index] = updatedMaterial;
//         _filteredMaterials = List.from(_materials);
//         notifyListeners();
//       }
//     } catch (e) {
//       _setErrorMessage(e.toString());
//       notifyListeners();
//       rethrow;
//     } finally {
//       _setLoading(false);
//     }
//   }

//   // Delete material
//   Future<void> deleteMaterial(int materialId) async {
//     _setLoading(true);
    
//     try {
//       final success = await MaterialApiService.deleteMaterial(materialId);
//       if (success) {
//         _materials.removeWhere((m) => m.id == materialId);
//         _filteredMaterials = List.from(_materials);
//         notifyListeners();
//       }
//     } catch (e) {
//       _setErrorMessage(e.toString());
//       notifyListeners();
//       rethrow;
//     } finally {
//       _setLoading(false);
//     }
//   }

//   // Filter materials by search query
//   void filterMaterials(String query) {
//     if (query.isEmpty) {
//       _filteredMaterials = List.from(_materials);
//     } else {
//       _filteredMaterials = _materials.where((material) {
//         return material.name.toLowerCase().contains(query.toLowerCase()) ||
//                (material.category?.name.toLowerCase().contains(query.toLowerCase()) ?? false) ||
//                material.sku.toLowerCase().contains(query.toLowerCase());
//       }).toList();
//     }
//     notifyListeners();
//   }

//   // Clear filters
//   void clearFilters() {
//     _filteredMaterials = List.from(_materials);
//     notifyListeners();
//   }

//   // Get material by ID
//   MaterialItem? getMaterialById(int id) {
//     try {
//       return _materials.firstWhere((material) => material.id == id);
//     } catch (e) {
//       return null;
//     }
//   }

//   // Private methods
//   void _setLoading(bool loading) {
//     _isLoading = loading;
//     notifyListeners();
//   }

//   void _setErrorMessage(String message) {
//     _errorMessage = message;
//   }

//   // Clear error message
//   void clearError() {
//     _errorMessage = '';
//     notifyListeners();
//   }
// }