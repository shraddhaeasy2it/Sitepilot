class StockReportItem {
  final int materialId;
  final String materialName;
  final String materialPrice;
  final String reorderLevel;
  final String unitName;
  final String unitSymbol;
  final int categoryId;
  final String categoryName;
  final num totalQty;

  StockReportItem({
    required this.materialId,
    required this.materialName,
    required this.materialPrice,
    required this.reorderLevel,
    required this.unitName,
    required this.unitSymbol,
    required this.categoryId,
    required this.categoryName,
    required this.totalQty,
  });

  factory StockReportItem.fromJson(Map<String, dynamic> json) {
    return StockReportItem(
      materialId: int.tryParse(json['material_id']?.toString() ?? '0') ?? 0,
      materialName: json['material_name'] ?? '',
      materialPrice: json['material_price']?.toString() ?? '0.00',
      reorderLevel: json['reorder_level']?.toString() ?? '0',
      unitName: json['unit_name'] ?? '',
      unitSymbol: json['unit_symbol'] ?? '',
      categoryId: int.tryParse(json['category_id']?.toString() ?? '0') ?? 0,
      categoryName: json['category_name'] ?? '',
      totalQty: num.tryParse(json['total_qty']?.toString() ?? '0') ?? 0,
    );
  }
}
