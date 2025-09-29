class RentalEntry {
  final String id;
  final String machineId;
  double cost;
  double advance;
  double total;
  String site;
  DateTime date;
  
  RentalEntry({
    required this.id,
    required this.machineId,
    required this.cost,
    required this.advance,
    required this.total,
    required this.site,
    required this.date,
  });
  
  factory RentalEntry.fromJson(Map<String, dynamic> json) {
    return RentalEntry(
      id: json['id'],
      machineId: json['machineId'],
      cost: json['cost']?.toDouble() ?? 0.0,
      advance: json['advance']?.toDouble() ?? 0.0,
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
      'cost': cost,
      'advance': advance,
      'total': total,
      'site': site,
      'date': date.toIso8601String(),
    };
  }
  
  // CopyWith method for updating
  RentalEntry copyWith({
    String? id,
    String? machineId,
    double? cost,
    double? advance,
    double? total,
    String? site,
    DateTime? date,
  }) {
    return RentalEntry(
      id: id ?? this.id,
      machineId: machineId ?? this.machineId,
      cost: cost ?? this.cost,
      advance: advance ?? this.advance,
      total: total ?? this.total,
      site: site ?? this.site,
      date: date ?? this.date,
    );
  }
}