class Site {
  final String id;
  final String name;
  final String address;

  Site({
    required this.id,
    required this.name,
    required this.address,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id'],
      name: json['name'],
      address: json['address'],
    );
  }
}
