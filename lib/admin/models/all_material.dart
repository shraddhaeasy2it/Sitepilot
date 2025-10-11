// // models/material_model.dart
// class MaterialItem {
//   final int id;
//   final String name;
//   final String sku;
//   final int categoryId;
//   final int unitId;
//   final String description;
//   final double price;
//   final int reorderLevel;
//   final String status;
//   final String? image;
//   final int? siteId;
//   final int createdBy;
//   final int workspaceId;
//   final String createdAt;
//   final String updatedAt;
//   final Unit? unit;
//   final Category? category;

//   MaterialItem({
//     required this.id,
//     required this.name,
//     required this.sku,
//     required this.categoryId,
//     required this.unitId,
//     required this.description,
//     required this.price,
//     required this.reorderLevel,
//     required this.status,
//     this.image,
//     this.siteId,
//     required this.createdBy,
//     required this.workspaceId,
//     required this.createdAt,
//     required this.updatedAt,
//     this.unit,
//     this.category,
//   });

//   factory MaterialItem.fromJson(Map<String, dynamic> json) {
//     return MaterialItem(
//       id: json['id'] ?? 0,
//       name: json['name'] ?? '',
//       sku: json['sku'] ?? '',
//       categoryId: json['category_id'] ?? 0,
//       unitId: json['unit_id'] ?? 0,
//       description: json['description'] ?? '',
//       price: double.tryParse(json['price']?.toString().replaceAll(',', '') ?? '0') ?? 0.0,
//       reorderLevel: json['reorder_level'] ?? 0,
//       status: json['status'] ?? 'inactive',
//       image: json['image'],
//       siteId: json['site_id'],
//       createdBy: json['created_by'] ?? 0,
//       workspaceId: json['workspace_id'] ?? 0,
//       createdAt: json['created_at'] ?? '',
//       updatedAt: json['updated_at'] ?? '',
//       unit: json['unit'] != null ? Unit.fromJson(json['unit']) : null,
//       category: json['category'] != null ? Category.fromJson(json['category']) : null,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'name': name,
//       'sku': sku,
//       'category_id': categoryId,
//       'unit_id': unitId,
//       'description': description,
//       'price': price,
//       'reorder_level': reorderLevel,
//       'status': status,
//       'image': image,
//     };
//   }

//   MaterialItem copyWith({
//     int? id,
//     String? name,
//     String? sku,
//     int? categoryId,
//     int? unitId,
//     String? description,
//     double? price,
//     int? reorderLevel,
//     String? status,
//     String? image,
//     int? siteId,
//     int? createdBy,
//     int? workspaceId,
//     String? createdAt,
//     String? updatedAt,
//     Unit? unit,
//     Category? category,
//   }) {
//     return MaterialItem(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       sku: sku ?? this.sku,
//       categoryId: categoryId ?? this.categoryId,
//       unitId: unitId ?? this.unitId,
//       description: description ?? this.description,
//       price: price ?? this.price,
//       reorderLevel: reorderLevel ?? this.reorderLevel,
//       status: status ?? this.status,
//       image: image ?? this.image,
//       siteId: siteId ?? this.siteId,
//       createdBy: createdBy ?? this.createdBy,
//       workspaceId: workspaceId ?? this.workspaceId,
//       createdAt: createdAt ?? this.createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//       unit: unit ?? this.unit,
//       category: category ?? this.category,
//     );
//   }
// }

// class Unit {
//   final int id;
//   final String name;
//   final String symbol;
//   final String? description;
//   final int isActive;

//   Unit({
//     required this.id,
//     required this.name,
//     required this.symbol,
//     this.description,
//     required this.isActive,
//   });

//   factory Unit.fromJson(Map<String, dynamic> json) {
//     return Unit(
//       id: json['id'] ?? 0,
//       name: json['name'] ?? '',
//       symbol: json['symbol'] ?? '',
//       description: json['description'],
//       isActive: json['is_active'] ?? 0,
//     );
//   }
// }

// class Category {
//   final int id;
//   final String name;

//   Category({
//     required this.id,
//     required this.name,
//   });

//   factory Category.fromJson(Map<String, dynamic> json) {
//     return Category(
//       id: json['id'] ?? 0,
//       name: json['name'] ?? '',
//     );
//   }
// }