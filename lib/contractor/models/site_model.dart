class Site {
  final String id;
  final String name;
  final String address;
  final String companyId;
  double balance; // Added balance field
  
  Site({
    required this.id,
    required this.name,
    required this.address,
    this.companyId = '',
    this.balance = 1000.0, // Default balance
  });
  
  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      companyId: json['companyId'] ?? '',
      balance: json['balance']?.toDouble() ?? 1000.0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'companyId': companyId,
      'balance': balance,
    };
  }
  
  // CopyWith method for updating
  Site copyWith({
    String? id,
    String? name,
    String? address,
    String? companyId,
    double? balance,
  }) {
    return Site(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      companyId: companyId ?? this.companyId,
      balance: balance ?? this.balance,
    );
  }
}