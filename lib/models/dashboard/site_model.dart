class Site {
  final String id;
  final String name;
  final String address;
  final String companyId; // Added company identifier

  Site({
    required this.id,
    required this.name,
    required this.address,
    this.companyId = '', // Default empty string for backward compatibility
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      companyId: json['companyId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'companyId': companyId,
    };
  }
}
