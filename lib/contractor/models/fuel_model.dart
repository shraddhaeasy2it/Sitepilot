class FuelEntry {
  final String id;
  final String machineId;
  String fuelType;
  double cost;
  double litre;
  double total;
  String site;
  DateTime date;
  
  FuelEntry({
    required this.id,
    required this.machineId,
    required this.fuelType,
    required this.cost,
    required this.litre,
    required this.total,
    required this.site,
    required this.date,
  });
  
  factory FuelEntry.fromJson(Map<String, dynamic> json) {
    return FuelEntry(
      id: json['id'],
      machineId: json['machineId'],
      fuelType: json['fuelType'],
      cost: json['cost']?.toDouble() ?? 0.0,
      litre: json['litre']?.toDouble() ?? 0.0,
      total: json['total']?.toDouble() ?? 0.0,
      site: json['site'],
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'machineId': machineId,
      'fuelType': fuelType,
      'cost': cost,
      'litre': litre,
      'total': total,
      'site': site,
      'date': date.toIso8601String(),
    };
  }
  
  // CopyWith method for updating
  FuelEntry copyWith({
    String? id,
    String? machineId,
    String? fuelType,
    double? cost,
    double? litre,
    double? total,
    String? site,
    DateTime? date,
  }) {
    return FuelEntry(
      id: id ?? this.id,
      machineId: machineId ?? this.machineId,
      fuelType: fuelType ?? this.fuelType,
      cost: cost ?? this.cost,
      litre: litre ?? this.litre,
      total: total ?? this.total,
      site: site ?? this.site,
      date: date ?? this.date,
    );
  }
}