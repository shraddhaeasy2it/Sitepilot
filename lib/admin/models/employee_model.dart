class Employee {
  String id;
  String name;
  String email;
  String branch;
  String department;
  String designation;
  DateTime dateOfJoining;
  String phone;
  String gender;
  String address;
  String state;
  String country;
  String city;
  String passportCountry;
  String passport;
  String zipCode;
  String accountHolderName;
  String accountNumber;
  String bankName;
  String bankIdentifierCode;
  String branchLocation;
  String taxPayerId;
  String hoursPerDay;
  String annualSalary;
  String daysPerWeek;
  String fixedSalary;
  String hoursPerMonth;
  String ratePerDay;
  String daysPerMonth;
  String ratePerHour;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.branch,
    required this.department,
    required this.designation,
    required this.dateOfJoining,
    this.phone = '',
    this.gender = 'Male',
    this.address = '',
    this.state = '',
    this.country = '',
    this.city = '',
    this.passportCountry = '',
    this.passport = '',
    this.zipCode = '',
    this.accountHolderName = '',
    this.accountNumber = '',
    this.bankName = '',
    this.bankIdentifierCode = '',
    this.branchLocation = '',
    this.taxPayerId = '',
    this.hoursPerDay = '',
    this.annualSalary = '',
    this.daysPerWeek = '',
    this.fixedSalary = '',
    this.hoursPerMonth = '',
    this.ratePerDay = '',
    this.daysPerMonth = '',
    this.ratePerHour = '',
  });

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
    String? address,
    String? state,
    String? country,
    String? city,
    String? passportCountry,
    String? passport,
    String? zipCode,
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
      address: address ?? this.address,
      state: state ?? this.state,
      country: country ?? this.country,
      city: city ?? this.city,
      passportCountry: passportCountry ?? this.passportCountry,
      passport: passport ?? this.passport,
      zipCode: zipCode ?? this.zipCode,
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
    );
  }
}