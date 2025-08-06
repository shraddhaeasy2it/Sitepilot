class PickingItem {
  final int? id;
  final String name;
  final String materialName;
  final String materialUnit;
  final double quantity;
  final String supplierName;
  final String deliveryDate;
  final String status;

  PickingItem({
    this.id,
    required this.name,
    required this.materialName,
    required this.materialUnit,
    required this.quantity,
    required this.supplierName,
    required this.deliveryDate,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'materialName': materialName,
      'materialUnit': materialUnit,
      'quantity': quantity,
      'supplierName': supplierName,
      'deliveryDate': deliveryDate,
      'status': status,
    };
  }

  factory PickingItem.fromMap(Map<String, dynamic> map) {
    return PickingItem(
      id: map['id'],
      name: map['name'],
      materialName: map['materialName'],
      materialUnit: map['materialUnit'],
      quantity: map['quantity'],
      supplierName: map['supplierName'],
      deliveryDate: map['deliveryDate'],
      status: map['status'],
    );
  }
}
