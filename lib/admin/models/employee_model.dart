class Employee {
  final String id;
  final int? userId;
  String name;
  String? dob;
  String gender;
  String? phone;
  String? address;
  String email;
  String? password;
  String? employeeId;
  String? employeesId;
  int? branchId;
  int? departmentId;
  int? designationId;
  int? roleId; // Added roleId
  String? companyDoj;
  String? documents;
  String? accountHolderName;
  String? accountNumber;
  String? bankName;
  String? bankIdentifierCode;
  String? branchLocation;
  String? taxPayerId;
  String? hoursPerDay;
  String? annualSalary;
  String? daysPerWeek;
  String? fixedSalary;
  String? hoursPerMonth;
  String? ratePerDay;
  String? daysPerMonth;
  String? ratePerHour;
  String? paymentRequiresWorkAdvice;
  String? salary;
  int? isActive;
  int? workspace;
  int? createdBy;
  String? avatar;
  String? organisationSwitch;
  String? providentFundNo;
  String? emergencyContactNo;
  String? emergencyAddress;
  String? accountType;
  String? passportCountry;
  String? passport;
  String? locationType;
  String? country;
  String? state;
  String? city;
  String? zipcode;
  String? salaryType;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? siteId;
  
  // Additional metadata from API
  Map<String, String>? departments;
  Map<String, String>? designations;
  Map<String, String>? branches;
  Map<String, String>? roles;
  Map<String, String>? locationTypes;
  List<Map<String, dynamic>>? documentList;

  // Stored names from nested API objects
  final String? _branchName;
  final String? _departmentName;
  final String? _designationName;

  Employee({
    required this.id,
    this.userId,
    required this.name,
    this.dob,
    required this.gender,
    this.phone,
    this.address,
    required this.email,
    this.password,
    this.employeeId,
    this.employeesId,
    this.branchId,
    this.departmentId,
    this.designationId,
    this.roleId,
    this.companyDoj,
    this.documents,
    this.accountHolderName,
    this.accountNumber,
    this.bankName,
    this.bankIdentifierCode,
    this.branchLocation,
    this.taxPayerId,
    this.hoursPerDay,
    this.annualSalary,
    this.daysPerWeek,
    this.fixedSalary,
    this.hoursPerMonth,
    this.ratePerDay,
    this.daysPerMonth,
    this.ratePerHour,
    this.paymentRequiresWorkAdvice,
    this.salary,
    this.isActive,
    this.workspace,
    this.createdBy,
    this.avatar,
    this.organisationSwitch,
    this.providentFundNo,
    this.emergencyContactNo,
    this.emergencyAddress,
    this.accountType,
    this.passportCountry,
    this.passport,
    this.locationType,
    this.country,
    this.state,
    this.city,
    this.zipcode,
    this.salaryType,
    this.createdAt,
    this.updatedAt,
    this.siteId,
    this.departments,
    this.designations,
    this.branches,
    this.roles,
    this.locationTypes,
    this.documentList,
    String? branchName,
    String? departmentName,
    String? designationName,
  }) : _branchName = branchName,
       _departmentName = departmentName,
       _designationName = designationName;

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id']?.toString() ?? '',
      userId: int.tryParse(json['user_id']?.toString() ?? json['users_id']?.toString() ?? ''),
      name: json['name'] ?? '',
      dob: json['dob']?.toString(),
      gender: json['gender']?.toString().toLowerCase() ?? 'male',
      phone: json['phone']?.toString() ?? json['mobile_no']?.toString(),
      address: json['address']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString(),
      employeeId: json['employee_id']?.toString(),
      employeesId: json['employeesId']?.toString(),
      branchId: int.tryParse(json['branch_id']?.toString() ?? ''),
      departmentId: int.tryParse(json['department_id']?.toString() ?? ''),
      designationId: int.tryParse(json['designation_id']?.toString() ?? ''),
      roleId: int.tryParse(json['role_id']?.toString() ?? json['role']?.toString() ?? ''), // Parsing role_id or role
      companyDoj: json['company_doj']?.toString(),
      documents: json['documents']?.toString(),
      accountHolderName: json['account_holder_name']?.toString(),
      accountNumber: json['account_number']?.toString(),
      bankName: json['bank_name']?.toString(),
      bankIdentifierCode: json['bank_identifier_code']?.toString(),
      branchLocation: json['branch_location']?.toString(),
      taxPayerId: json['tax_payer_id']?.toString(),
      hoursPerDay: json['hours_per_day']?.toString(),
      annualSalary: json['annual_salary']?.toString(),
      daysPerWeek: json['days_per_week']?.toString(),
      fixedSalary: json['fixed_salary']?.toString(),
      hoursPerMonth: json['hours_per_month']?.toString(),
      ratePerDay: json['rate_per_day']?.toString(),
      daysPerMonth: json['days_per_month']?.toString(),
      ratePerHour: json['rate_per_hour']?.toString(),
      paymentRequiresWorkAdvice: json['payment_requires_work_advice']?.toString() ?? 'off',
      salary: json['salary']?.toString(),
      isActive: int.tryParse(json['is_active']?.toString() ?? '') ?? 1,
      workspace: int.tryParse(json['workspace']?.toString() ?? '') ?? 3,
      createdBy: int.tryParse(json['created_by']?.toString() ?? ''),
      avatar: json['avatar']?.toString(),
      organisationSwitch: json['organisation_switch']?.toString(),
      providentFundNo: json['provident_fund_no']?.toString(),
      emergencyContactNo: json['emergency_contact_no']?.toString(),
      emergencyAddress: json['emergency_address']?.toString(),
      accountType: json['account_type']?.toString(),
      passportCountry: json['passport_country']?.toString(),
      passport: json['passport']?.toString(),
      locationType: json['location_type']?.toString() ?? 'residential',
      country: json['country']?.toString(),
      state: json['state']?.toString(),
      city: json['city']?.toString(),
      zipcode: json['zipcode']?.toString(),
      salaryType: json['salary_type']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      siteId: int.tryParse(json['site_id']?.toString() ?? ''),
      
      // Parse nested objects for names
      branchName: json['branch'] is Map ? json['branch']['name']?.toString() : null,
      departmentName: json['department'] is Map ? json['department']['name']?.toString() : null,
      designationName: json['designation'] is Map ? json['designation']['name']?.toString() : null,
    );
  }

  // Factory method for creating from API response with metadata
  factory Employee.fromApiResponse(Map<String, dynamic> response) {
    final employee = Employee(
      id: '',
      name: '',
      gender: 'male',
      email: '',
      workspace: int.tryParse(response['workspace_id']?.toString() ?? '') ?? 3,
      createdBy: int.tryParse(response['created_by']?.toString() ?? '') ?? 9,
    );
    
    // Extract metadata if available
    if (response['departments'] is Map) {
      employee.departments = Map<String, String>.from(
        response['departments'].map((key, value) => MapEntry(key.toString(), value.toString()))
      );
    }
    
    if (response['designations'] is Map) {
      employee.designations = Map<String, String>.from(
        response['designations'].map((key, value) => MapEntry(key.toString(), value.toString()))
      );
    }
    
    if (response['branches'] is Map) {
      employee.branches = Map<String, String>.from(
        response['branches'].map((key, value) => MapEntry(key.toString(), value.toString()))
      );
    }
    
    if (response['role'] is Map) {
      employee.roles = Map<String, String>.from(
        response['role'].map((key, value) => MapEntry(key.toString(), value.toString()))
      );
    }
    
    if (response['location_type'] is Map) {
      employee.locationTypes = Map<String, String>.from(
        response['location_type'].map((key, value) => MapEntry(key.toString(), value.toString()))
      );
    }
    
    if (response['documents'] is List) {
      employee.documentList = List<Map<String, dynamic>>.from(response['documents']);
    }
    
    return employee;
  }

  Map<String, String> toFormData() {
    Map<String, String> data = {
      'name': name,
      'email': email,
      if (dob != null && dob!.isNotEmpty) 'dob': dob!,
      'gender': gender,
      if (phone != null && phone!.isNotEmpty) 'phone': phone!,
      if (address != null && address!.isNotEmpty) 'address': address!,
      if (password != null && password!.isNotEmpty) 'password': password!,
      if (employeeId != null && employeeId!.isNotEmpty) 'employee_id': employeeId!,
      if (employeesId != null && employeesId!.isNotEmpty) 'employeesId': employeesId!,
      if (branchId != null) 'branch_id': branchId.toString(),
      if (departmentId != null) 'department_id': departmentId.toString(),
      if (designationId != null) 'designation_id': designationId.toString(),
      if (roleId != null) 'role_id': roleId.toString(), // Adding role_id to form data
      if (companyDoj != null && companyDoj!.isNotEmpty) 'company_doj': companyDoj!,
      if (locationType != null) 'location_type': locationType!,
      if (accountHolderName != null && accountHolderName!.isNotEmpty) 'account_holder_name': accountHolderName!,
      if (accountNumber != null && accountNumber!.isNotEmpty) 'account_number': accountNumber!,
      if (bankName != null && bankName!.isNotEmpty) 'bank_name': bankName!,
      if (bankIdentifierCode != null && bankIdentifierCode!.isNotEmpty) 'bank_identifier_code': bankIdentifierCode!,
      if (branchLocation != null && branchLocation!.isNotEmpty) 'branch_location': branchLocation!,
      if (taxPayerId != null && taxPayerId!.isNotEmpty) 'tax_payer_id': taxPayerId!,
      if (hoursPerDay != null && hoursPerDay!.isNotEmpty) 'hours_per_day': hoursPerDay!,
      if (annualSalary != null && annualSalary!.isNotEmpty) 'annual_salary': annualSalary!,
      if (daysPerWeek != null && daysPerWeek!.isNotEmpty) 'days_per_week': daysPerWeek!,
      if (fixedSalary != null && fixedSalary!.isNotEmpty) 'fixed_salary': fixedSalary!,
      if (hoursPerMonth != null && hoursPerMonth!.isNotEmpty) 'hours_per_month': hoursPerMonth!,
      if (ratePerDay != null && ratePerDay!.isNotEmpty) 'rate_per_day': ratePerDay!,
      if (daysPerMonth != null && daysPerMonth!.isNotEmpty) 'days_per_month': daysPerMonth!,
      if (ratePerHour != null && ratePerHour!.isNotEmpty) 'rate_per_hour': ratePerHour!,
      'payment_requires_work_advice': paymentRequiresWorkAdvice ?? 'off',
      if (salary != null && salary!.isNotEmpty) 'salary': salary!,
      if (accountType != null && accountType!.isNotEmpty) 'account_type': accountType!,
      if (passportCountry != null && passportCountry!.isNotEmpty) 'passport_country': passportCountry!,
      if (passport != null && passport!.isNotEmpty) 'passport': passport!,
      if (country != null && country!.isNotEmpty) 'country': country!,
      if (state != null && state!.isNotEmpty) 'state': state!,
      if (city != null && city!.isNotEmpty) 'city': city!,
      if (zipcode != null && zipcode!.isNotEmpty) 'zipcode': zipcode!,
      if (salaryType != null && salaryType!.isNotEmpty) 'salary_type': salaryType!,
      'workspace_id': (workspace ?? 3).toString(),
      if (siteId != null) 'site_id': siteId.toString(),
      'created_by': (createdBy ?? 9).toString(),
      if (userId != null) 'user_id': userId.toString(), 
      if (organisationSwitch != null && organisationSwitch!.isNotEmpty) 'organisation_switch': organisationSwitch!,
      if (providentFundNo != null && providentFundNo!.isNotEmpty) 'provident_fund_no': providentFundNo!,
      if (emergencyContactNo != null && emergencyContactNo!.isNotEmpty) 'emergency_contact_no': emergencyContactNo!,
      if (emergencyAddress != null && emergencyAddress!.isNotEmpty) 'emergency_address': emergencyAddress!,
      'is_active': (isActive ?? 1).toString(),
      if (roleId != null) 'role': roleId.toString(),
      if (documents != null && documents!.isNotEmpty) 'documents': documents!,
    };
    
    // Add document fields if they exist
    if (documents != null && documents!.isNotEmpty) {
      final docList = documents!.split(',');
      for (int i = 0; i < docList.length; i++) {
        data['document[${i + 1}]'] = docList[i];
      }
    }
    
    return data;
  }

  Employee copyWith({
    String? id,
    int? userId,
    String? name,
    String? dob,
    String? gender,
    String? phone,
    String? address,
    String? email,
    String? password,
    String? employeeId,
    String? employeesId,
    int? branchId,
    int? departmentId,
    int? designationId,
    int? roleId,
    String? companyDoj,
    String? documents,
    String? accountHolderName,
    String? accountNumber,
    String? bankName,
    String? bankIdentifierCode,
    String? branchLocation,
    String? taxPayerId,
    String? hoursPerDay,
    String? annualSalary,
    String? daysPerWeek,
    String? fixedSalary,
    String? hoursPerMonth,
    String? ratePerDay,
    String? daysPerMonth,
    String? ratePerHour,
    String? paymentRequiresWorkAdvice,
    String? salary,
    int? isActive,
    int? workspace,
    int? createdBy,
    String? avatar,
    String? organisationSwitch,
    String? providentFundNo,
    String? emergencyContactNo,
    String? emergencyAddress,
    String? accountType,
    String? passportCountry,
    String? passport,
    String? locationType,
    String? country,
    String? state,
    String? city,
    String? zipcode,
    String? salaryType,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? siteId,
    Map<String, String>? departments,
    Map<String, String>? designations,
    Map<String, String>? branches,
    Map<String, String>? roles,
    Map<String, String>? locationTypes,
    List<Map<String, dynamic>>? documentList,
    String? branchName,
    String? departmentName,
    String? designationName,
  }) {
    return Employee(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      email: email ?? this.email,
      password: password ?? this.password,
      employeeId: employeeId ?? this.employeeId,
      employeesId: employeesId ?? this.employeesId,
      branchId: branchId ?? this.branchId,
      departmentId: departmentId ?? this.departmentId,
      designationId: designationId ?? this.designationId,
      roleId: roleId ?? this.roleId,
      companyDoj: companyDoj ?? this.companyDoj,
      documents: documents ?? this.documents,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      bankIdentifierCode: bankIdentifierCode ?? this.bankIdentifierCode,
      branchLocation: branchLocation ?? this.branchLocation,
      taxPayerId: taxPayerId ?? this.taxPayerId,
      hoursPerDay: hoursPerDay ?? this.hoursPerDay,
      annualSalary: annualSalary ?? this.annualSalary,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      fixedSalary: fixedSalary ?? this.fixedSalary,
      hoursPerMonth: hoursPerMonth ?? this.hoursPerMonth,
      ratePerDay: ratePerDay ?? this.ratePerDay,
      daysPerMonth: daysPerMonth ?? this.daysPerMonth,
      ratePerHour: ratePerHour ?? this.ratePerHour,
      paymentRequiresWorkAdvice: paymentRequiresWorkAdvice ?? this.paymentRequiresWorkAdvice,
      salary: salary ?? this.salary,
      isActive: isActive ?? this.isActive,
      workspace: workspace ?? this.workspace,
      createdBy: createdBy ?? this.createdBy,
      avatar: avatar ?? this.avatar,
      organisationSwitch: organisationSwitch ?? this.organisationSwitch,
      providentFundNo: providentFundNo ?? this.providentFundNo,
      emergencyContactNo: emergencyContactNo ?? this.emergencyContactNo,
      emergencyAddress: emergencyAddress ?? this.emergencyAddress,
      accountType: accountType ?? this.accountType,
      passportCountry: passportCountry ?? this.passportCountry,
      passport: passport ?? this.passport,
      locationType: locationType ?? this.locationType,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      zipcode: zipcode ?? this.zipcode,
      salaryType: salaryType ?? this.salaryType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      siteId: siteId ?? this.siteId,
      departments: departments ?? this.departments,
      designations: designations ?? this.designations,
      branches: branches ?? this.branches,
      roles: roles ?? this.roles,
      locationTypes: locationTypes ?? this.locationTypes,
      documentList: documentList ?? this.documentList,
      branchName: branchName ?? this._branchName,
      departmentName: departmentName ?? this._departmentName,
      designationName: designationName ?? this._designationName,
    );
  }

  // Helper getters for UI
  String get displayId => employeesId ?? employeeId ?? id;
  String get branchName => _branchName ?? branches?[branchId.toString()] ?? branchId?.toString() ?? 'N/A';
  String get departmentName => _departmentName ?? departments?[departmentId.toString()] ?? departmentId?.toString() ?? 'N/A';
  String get designationName => _designationName ?? designations?[designationId.toString()] ?? designationId?.toString() ?? 'N/A';
  String get roleName => roles?[roleId?.toString() ?? ''] ?? ''; // Updated to use roleId
  String get locationTypeName => locationTypes?[locationType] ?? locationType ?? 'N/A';
  DateTime? get dateOfJoining => companyDoj != null ? DateTime.tryParse(companyDoj!) : null;
}