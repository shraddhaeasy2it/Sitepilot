class Supplier {
  int? id;
  String name;
  int categoryId;
  String type;
  String contactPerson;
  String phone;
  String? email;
  String? address;
  String? city;
  String? state;
  String? pincode;
  String? country;
  String? upiScreenshot1;
  String? upiScreenshot2;
  String? gstNumber;
  String? panNumber;
  String? registrationNumber;
  String? bankName;
  String? accountNumber;
  String? ifscCode;
  String? paymentTerms;
  int siteId;
  int workspaceId;
  int createdBy;
  int isActive;
  String status;
  String? createdAt;
  String? updatedAt;

  Supplier({
    this.id,
    required this.name,
    required this.categoryId,
    required this.type,
    required this.contactPerson,
    required this.phone,
    this.email,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.country,
    this.upiScreenshot1,
    this.upiScreenshot2,
    this.gstNumber,
    this.panNumber,
    this.registrationNumber,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.paymentTerms,
    required this.siteId,
    required this.workspaceId,
    required this.createdBy,
    required this.isActive,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'],
      name: json['name'] ?? '',
      categoryId: json['category_id'] ?? 0,
      type: json['type'] ?? '',
      contactPerson: json['contact_person'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      country: json['country'],
      upiScreenshot1: json['upi_screenshot_1'],
      upiScreenshot2: json['upi_screenshot_2'],
      gstNumber: json['gst_number'],
      panNumber: json['pan_number'],
      registrationNumber: json['registration_number'],
      bankName: json['bank_name'],
      accountNumber: json['account_number'],
      ifscCode: json['ifsc_code'],
      paymentTerms: json['payment_terms'],
      siteId: json['site_id'] ?? 0,
      workspaceId: json['workspace_id'] ?? 0,
      createdBy: json['created_by'] ?? 0,
      isActive: json['is_active'] ?? 1,
      status: json['status']?.toString() ?? '0',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category_id': categoryId,
      'type': type,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'country': country,
      'upi_screenshot_1': upiScreenshot1,
      'upi_screenshot_2': upiScreenshot2,
      'gst_number': gstNumber,
      'pan_number': panNumber,
      'registration_number': registrationNumber,
      'bank_name': bankName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'payment_terms': paymentTerms,
      'site_id': siteId,
      'workspace_id': workspaceId,
      'created_by': createdBy,
      'is_active': isActive,
      'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  // Helper getters for UI compatibility
  String get category {
    // Map category_id to actual category names
    switch (categoryId) {
      case 1:
        return 'Material';
      case 2:
        return 'Equipment';
      case 3:
        return 'Service';
      case 4:
        return 'Other';
      default:
        return 'Other';
    }
  }

  // Helper method to get category ID from name
  static int getCategoryId(String categoryName) {
    switch (categoryName) {
      case 'Material':
        return 1;
      case 'Equipment':
        return 2;
      case 'Service':
        return 3;
      case 'Other':
        return 4;
      default:
        return 4;
    }
  }
}