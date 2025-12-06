class Employee {
  final String id;
  String name;
  String email;
  String branch;
  String department;
  String designation;
  DateTime dateOfJoining;
  String phone;
  String gender;
  
  // Additional fields from API and UI
  String? employeeId;
  int? userId;
  DateTime? dob;
  String? address;
  String? password;
  int? branchId;
  int? departmentId;
  int? designationId;
  DateTime? companyDof;
  String? document;
  String? accountHolderName;
  String? accountNumber;
  String? bankName;
  String? bankIdentifierCode;
  String? branchLocation;
  String? taxPayerId;
  String? salaryType;
  String? accountType;
  String? passportCountry;
  String? passport;
  String? locationType;
  String? country;
  String? state;
  String? city;
  String? zipCode;
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
  DateTime? createdAt;
  DateTime? updatedAt;
  String? age;
  String? role;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.branch,
    required this.department,
    required this.designation,
    required this.dateOfJoining,
    required this.phone,
    required this.gender,
    
    // Additional fields
    this.employeeId,
    this.userId,
    this.dob,
    this.address,
    this.password,
    this.branchId,
    this.departmentId,
    this.designationId,
    this.companyDof,
    this.document,
    this.accountHolderName,
    this.accountNumber,
    this.bankName,
    this.bankIdentifierCode,
    this.branchLocation,
    this.taxPayerId,
    this.salaryType,
    this.accountType,
    this.passportCountry,
    this.passport,
    this.locationType,
    this.country,
    this.state,
    this.city,
    this.zipCode,
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
    this.createdAt,
    this.updatedAt,
    this.age,
    this.role,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      branch: json['branch'] ?? 'Select Branch',
      department: json['department'] ?? 'Select Department',
      designation: json['designation'] ?? 'Select Designation',
      dateOfJoining: DateTime.tryParse(json['company_dof'] ?? json['date_of_joining'] ?? '') ?? DateTime.now(),
      phone: json['phone'] ?? '',
      gender: json['gender'] ?? 'Male',
      
      // Additional fields
      employeeId: json['employee_id']?.toString() ?? 'EMP${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 5)}',
      userId: json['user_id'],
      dob: DateTime.tryParse(json['dob'] ?? ''),
      address: json['address'],
      password: json['password'],
      branchId: json['branch_id'],
      departmentId: json['department_id'],
      designationId: json['designation_id'],
      companyDof: DateTime.tryParse(json['company_dof'] ?? ''),
      document: json['document'],
      accountHolderName: json['account_holder_name'],
      accountNumber: json['account_number'],
      bankName: json['bank_name'],
      bankIdentifierCode: json['bank_identifier_code'],
      branchLocation: json['branch_location'],
      taxPayerId: json['tax_payer_id'],
      salaryType: json['salary_type'],
      accountType: json['account_type'],
      passportCountry: json['passport_country'],
      passport: json['passport'],
      locationType: json['location_type'] ?? 'Select Location Type',
      country: json['country'] ?? 'India',
      state: json['state'],
      city: json['city'],
      zipCode: json['zipcode'],
      hoursPerDay: json['hours_per_day']?.toString(),
      annualSalary: json['annual_salary']?.toString(),
      daysPerWeek: json['days_per_week']?.toString(),
      fixedSalary: json['fixed_salary']?.toString(),
      hoursPerMonth: json['hours_per_month']?.toString(),
      ratePerDay: json['rate_per_day']?.toString(),
      daysPerMonth: json['days_per_month']?.toString(),
      ratePerHour: json['rate_per_hour']?.toString(),
      paymentRequiresWorkAdvice: json['payment_requires_work_advice'],
      salary: json['salary']?.toString(),
      isActive: json['is_active'] ?? 1,
      workspace: json['workspace'] ?? 3,
      createdBy: json['created_by'],
      avatar: json['avatar'],
      organisationSwitch: json['organisation_switch'],
      providentFundNo: json['provident_fund_no'],
      createdAt: DateTime.tryParse(json['created_at'] ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? ''),
      age: json['age']?.toString(),
      role: json['role'] ?? 'Select Role',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'gender': gender,
      'address': address,
      'dob': dob?.toIso8601String(),
      'employee_id': employeeId,
      'branch': branch,
      'department': department,
      'designation': designation,
      'branch_id': branchId,
      'department_id': departmentId,
      'designation_id': designationId,
      'company_dof': companyDof?.toIso8601String(),
      'date_of_joining': dateOfJoining.toIso8601String(),
      'document': document,
      'account_holder_name': accountHolderName,
      'account_number': accountNumber,
      'bank_name': bankName,
      'bank_identifier_code': bankIdentifierCode,
      'branch_location': branchLocation,
      'tax_payer_id': taxPayerId,
      'salary_type': salaryType,
      'account_type': accountType,
      'passport_country': passportCountry,
      'passport': passport,
      'location_type': locationType,
      'country': country,
      'state': state,
      'city': city,
      'zipcode': zipCode,
      'hours_per_day': hoursPerDay,
      'annual_salary': annualSalary,
      'days_per_week': daysPerWeek,
      'fixed_salary': fixedSalary,
      'hours_per_month': hoursPerMonth,
      'rate_per_day': ratePerDay,
      'days_per_month': daysPerMonth,
      'rate_per_hour': ratePerHour,
      'payment_requires_work_advice': paymentRequiresWorkAdvice,
      'salary': salary,
      'is_active': isActive,
      'workspace': workspace,
      'created_by': createdBy,
      'organisation_switch': organisationSwitch,
      'provident_fund_no': providentFundNo,
      'role': role,
    };
  }

  Employee copyWith({
    String? id,
    String? name,
    String? email,
    String? branch,
    String? department,
    String? designation,
    DateTime? dateOfJoining,
    String? phone,
    String? gender,
    String? employeeId,
    int? userId,
    DateTime? dob,
    String? address,
    String? password,
    int? branchId,
    int? departmentId,
    int? designationId,
    DateTime? companyDof,
    String? document,
    String? accountHolderName,
    String? accountNumber,
    String? bankName,
    String? bankIdentifierCode,
    String? branchLocation,
    String? taxPayerId,
    String? salaryType,
    String? accountType,
    String? passportCountry,
    String? passport,
    String? locationType,
    String? country,
    String? state,
    String? city,
    String? zipCode,
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
    DateTime? createdAt,
    DateTime? updatedAt,
    String? age,
    String? role,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      branch: branch ?? this.branch,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      dateOfJoining: dateOfJoining ?? this.dateOfJoining,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      employeeId: employeeId ?? this.employeeId,
      userId: userId ?? this.userId,
      dob: dob ?? this.dob,
      address: address ?? this.address,
      password: password ?? this.password,
      branchId: branchId ?? this.branchId,
      departmentId: departmentId ?? this.departmentId,
      designationId: designationId ?? this.designationId,
      companyDof: companyDof ?? this.companyDof,
      document: document ?? this.document,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      bankIdentifierCode: bankIdentifierCode ?? this.bankIdentifierCode,
      branchLocation: branchLocation ?? this.branchLocation,
      taxPayerId: taxPayerId ?? this.taxPayerId,
      salaryType: salaryType ?? this.salaryType,
      accountType: accountType ?? this.accountType,
      passportCountry: passportCountry ?? this.passportCountry,
      passport: passport ?? this.passport,
      locationType: locationType ?? this.locationType,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      zipCode: zipCode ?? this.zipCode,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      age: age ?? this.age,
      role: role ?? this.role,
    );
  }
}