class Consumption {
  final int id;
  final String consumptionNo;
  final DateTime consumptionDate;
  final String consumptionType;
  final String site;
  final String consumptionFile;
  final String? remarks;
  final List<ConsumptionItem>? items;
  final String? machineryType;
  final String? machinery;

  Consumption({
    required this.id,
    required this.consumptionNo,
    required this.consumptionDate,
    required this.consumptionType,
    required this.site,
    required this.consumptionFile,
    this.remarks,
    this.items,
    this.machineryType,
    this.machinery,
  });

  Consumption copyWith({
    int? id,
    String? consumptionNo,
    DateTime? consumptionDate,
    String? consumptionType,
    String? site,
    String? consumptionFile,
    String? remarks,
    List<ConsumptionItem>? items,
    String? machineryType,
    String? machinery,
  }) {
    return Consumption(
      id: id ?? this.id,
      consumptionNo: consumptionNo ?? this.consumptionNo,
      consumptionDate: consumptionDate ?? this.consumptionDate,
      consumptionType: consumptionType ?? this.consumptionType,
      site: site ?? this.site,
      consumptionFile: consumptionFile ?? this.consumptionFile,
      remarks: remarks ?? this.remarks,
      items: items ?? this.items,
      machineryType: machineryType ?? this.machineryType,
      machinery: machinery ?? this.machinery,
    );
  }
}

class ConsumptionItem {
  final String material;
  final double quantity;
  final String unit;
  final double? price;

  ConsumptionItem({
    required this.material,
    required this.quantity,
    required this.unit,
    this.price,
  });
}