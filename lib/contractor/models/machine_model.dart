class Machine {
  final String id;
  String name;
  String type; // 'own' or 'rental'
  String currentSite; // Track current site
  
  Machine({
    required this.id,
    required this.name,
    required this.type,
    required this.currentSite,
  });
  
  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      currentSite: json['currentSite'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'currentSite': currentSite,
    };
  }
  
  // CopyWith method for updating
  Machine copyWith({
    String? id,
    String? name,
    String? type,
    String? currentSite,
  }) {
    return Machine(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      currentSite: currentSite ?? this.currentSite,
    );
  }
}