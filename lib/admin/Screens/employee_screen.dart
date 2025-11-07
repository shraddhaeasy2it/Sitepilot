import 'package:ecoteam_app/admin/models/employee_model.dart';
import 'package:flutter/material.dart';

class EmployeePage extends StatefulWidget {
  @override
  _EmployeePageState createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage> {
  List<Employee> employees = [];
  List<Employee> filteredEmployees = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSampleData();
    searchController.addListener(_filterEmployees);
  }

  void _loadSampleData() {
    setState(() {
      employees = [
        Employee(
          id: 'EMPO001',
          name: 'Ninad1',
          email: 'ninad1@company.com',
          branch: 'Main Branch',
          department: 'IT',
          designation: 'Software Developer',
          dateOfJoining: DateTime(2023, 1, 15),
          phone: '+911234567890',
          gender: 'Female',
        ),
        Employee(
          id: 'EMPO002',
          name: 'John Doe',
          email: 'john.doe@company.com',
          branch: 'North Branch',
          department: 'HR',
          designation: 'HR Manager',
          dateOfJoining: DateTime(2023, 3, 20),
          phone: '+911234567891',
          gender: 'Male',
        ),
      ];
      filteredEmployees = employees;
    });
  }

  void _filterEmployees() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredEmployees = employees;
      } else {
        filteredEmployees = employees.where((employee) {
          return employee.name.toLowerCase().contains(query) ||
              employee.email.toLowerCase().contains(query) ||
              employee.id.toLowerCase().contains(query) ||
              employee.department.toLowerCase().contains(query) ||
              employee.designation.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _refreshData() {
    setState(() {
      searchController.clear();
      filteredEmployees = employees;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data refreshed')),
    );
  }

  void _addEmployee() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EmployeeBottomSheet(
        onSave: (employee) {
          setState(() {
            employees.add(employee);
            filteredEmployees = employees;
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Employee added successfully')),
          );
        },
      ),
    );
  }

  void _editEmployee(Employee employee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EmployeeBottomSheet(
        employee: employee,
        onSave: (updatedEmployee) {
          setState(() {
            final index = employees.indexWhere((e) => e.id == employee.id);
            if (index != -1) {
              employees[index] = updatedEmployee;
              filteredEmployees = employees;
            }
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Employee updated successfully')),
          );
        },
      ),
    );
  }

  void _deleteEmployee(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${employee.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                employees.removeWhere((e) => e.id == employee.id);
                filteredEmployees = employees;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Employee deleted successfully')),
              );
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addEmployee,
            tooltip: 'Add Employee',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search employees...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Employees: ${filteredEmployees.length}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: filteredEmployees.isEmpty
                ? Center(
                    child: Text(
                      'No employees found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredEmployees.length,
                    itemBuilder: (context, index) {
                      final employee = filteredEmployees[index];
                      return EmployeeCard(
                        employee: employee,
                        onEdit: () => _editEmployee(employee),
                        onDelete: () => _deleteEmployee(employee),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

class EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EmployeeCard({
    Key? key,
    required this.employee,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  employee.id,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, size: 20),
                      onPressed: onEdit,
                      color: Colors.blue,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.delete, size: 20),
                      onPressed: onDelete,
                      color: Colors.red,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              employee.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              employee.email,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip('Branch', employee.branch),
                SizedBox(width: 8),
                _buildInfoChip('Department', employee.department),
                SizedBox(width: 8),
                _buildInfoChip('Designation', employee.designation),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Joined: ${_formatDate(employee.dateOfJoining)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class EmployeeBottomSheet extends StatefulWidget {
  final Employee? employee;
  final Function(Employee) onSave;

  const EmployeeBottomSheet({
    Key? key,
    this.employee,
    required this.onSave,
  }) : super(key: key);

  @override
  _EmployeeBottomSheetState createState() => _EmployeeBottomSheetState();
}

class _EmployeeBottomSheetState extends State<EmployeeBottomSheet> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late Employee _employee;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _employee = widget.employee ??
        Employee(
          id: 'EMPO${DateTime.now().millisecondsSinceEpoch}',
          name: '',
          email: '',
          branch: '',
          department: '',
          designation: '',
          dateOfJoining: DateTime.now(),
        );
    _tabController = TabController(length: 2, vsync: this);
  }

  List<Widget> _buildTabs() {
    return [
      Tab(text: 'Personal Details'),
      Tab(text: 'Company Details'),
    ];
  }

  List<Widget> _buildTabViews() {
    return [
      _PersonalDetailsStep(
        employee: _employee,
        onSaved: (employee) {
          setState(() {
            _employee = employee;
          });
        },
      ),
      _CompanyDetailsStep(
        employee: _employee,
        onSaved: (employee) {
          setState(() {
            _employee = employee;
          });
        },
      ),
    ];
  }

  void _saveEmployee() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.onSave(_employee);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee == null ? 'Add Employee' : 'Edit Employee'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _buildTabs(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: _buildTabViews(),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
              ),
            ),
            ElevatedButton(
              onPressed: _saveEmployee,
              child: Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalDetailsStep extends StatefulWidget {
  final Employee employee;
  final Function(Employee) onSaved;

  const _PersonalDetailsStep({
    Key? key,
    required this.employee,
    required this.onSaved,
  }) : super(key: key);

  @override
  __PersonalDetailsStepState createState() => __PersonalDetailsStepState();
}

class __PersonalDetailsStepState extends State<_PersonalDetailsStep> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _cityController;
  late TextEditingController _passportCountryController;
  late TextEditingController _passportController;
  late TextEditingController _zipCodeController;
  late TextEditingController _accountHolderNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _bankNameController;
  late TextEditingController _bankIdentifierCodeController;
  late TextEditingController _branchLocationController;
  late TextEditingController _taxPayerIdController;

  String _gender = 'Male';
  DateTime? _dateOfBirth;
  String _locationType = 'Select Location Type';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee.name);
    _emailController = TextEditingController(text: widget.employee.email);
    _phoneController = TextEditingController(text: widget.employee.phone);
    _addressController = TextEditingController(text: widget.employee.address);
    _stateController = TextEditingController(text: widget.employee.state);
    _countryController = TextEditingController(text: widget.employee.country);
    _cityController = TextEditingController(text: widget.employee.city);
    _passportCountryController = TextEditingController(text: widget.employee.passportCountry);
    _passportController = TextEditingController(text: widget.employee.passport);
    _zipCodeController = TextEditingController(text: widget.employee.zipCode);
    _accountHolderNameController = TextEditingController(text: widget.employee.accountHolderName);
    _accountNumberController = TextEditingController(text: widget.employee.accountNumber);
    _bankNameController = TextEditingController(text: widget.employee.bankName);
    _bankIdentifierCodeController = TextEditingController(text: widget.employee.bankIdentifierCode);
    _branchLocationController = TextEditingController(text: widget.employee.branchLocation);
    _taxPayerIdController = TextEditingController(text: widget.employee.taxPayerId);

    _gender = widget.employee.gender;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSectionHeader('Personal Details'),
          _buildTextField('Name*', _nameController, isRequired: true),
          _buildTextField('Email*', _emailController, isRequired: true),
          _buildDateField('Date of Birth*', _dateOfBirth, (date) {
            setState(() => _dateOfBirth = date);
          }, isRequired: true),
          _buildTextField('Phone*', _phoneController,
            hint: 'Enter employee phone with Country code (+91)',
            isRequired: true
          ),
          _buildGenderField(),
          _buildSectionHeader('Location Details'),
          _buildDropdownField('Location Type', ['Select Location Type', 'Office', 'Remote', 'Hybrid'], _locationType, (value) {
            setState(() => _locationType = value!);
          }),
          _buildTextField('State', _stateController, hint: 'Enter State'),
          _buildTextField('Country', _countryController, hint: 'Enter Country'),
          _buildTextField('City', _cityController, hint: 'Enter City'),
          _buildTextField('Passport country', _passportCountryController, hint: 'Enter Passport Country'),
          _buildTextField('Passport', _passportController, hint: 'Enter Passport'),
          _buildTextField('Zip code', _zipCodeController, hint: 'Enter Zip code'),
          _buildTextField('Address*', _addressController, 
            hint: 'Enter employee address',
            isRequired: true
          ),
          _buildSectionHeader('Bank Account Detail'),
          _buildTextField('Account Holder Name', _accountHolderNameController, hint: 'Enter Account Holder Name'),
          _buildTextField('Account Number', _accountNumberController, hint: 'Enter Account Number'),
          _buildTextField('Bank Name', _bankNameController, hint: 'Enter Bank Name'),
          _buildTextField('Bank Identifier Code', _bankIdentifierCodeController, hint: 'Enter Bank Identifier Code'),
          _buildTextField('Branch Location', _branchLocationController, hint: 'Enter Branch Location'),
          _buildTextField('Tax Payer Id', _taxPayerIdController, hint: 'Enter Tax Payer Id'),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint, bool isRequired = false, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint ?? label,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          
        ),
        validator: isRequired ? (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          return null;
        } : null,
        onChanged: (value) => _updateEmployee(),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, Function(DateTime?) onDateSelected, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () async {
          final selectedDate = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (selectedDate != null) {
            onDateSelected(selectedDate);
            _updateEmployee();
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
           
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date != null ? '${date.month}/${date.day}/${date.year}' : 'mm/dd/yyyy',
                style: TextStyle(
                  color: date != null ? Colors.black : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gender*', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text('Male'),
                  value: 'Male',
                  groupValue: _gender,
                  onChanged: (value) {
                    setState(() => _gender = value!);
                    _updateEmployee();
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text('Female'),
                  value: 'Female',
                  groupValue: _gender,
                  onChanged: (value) {
                    setState(() => _gender = value!);
                    _updateEmployee();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> options, String value, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        value: value,
        items: options.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _updateEmployee() {
    widget.onSaved(widget.employee.copyWith(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      gender: _gender,
      address: _addressController.text,
      state: _stateController.text,
      country: _countryController.text,
      city: _cityController.text,
      passportCountry: _passportCountryController.text,
      passport: _passportController.text,
      zipCode: _zipCodeController.text,
      accountHolderName: _accountHolderNameController.text,
      accountNumber: _accountNumberController.text,
      bankName: _bankNameController.text,
      bankIdentifierCode: _bankIdentifierCodeController.text,
      branchLocation: _branchLocationController.text,
      taxPayerId: _taxPayerIdController.text,
    ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _passportCountryController.dispose();
    _passportController.dispose();
    _zipCodeController.dispose();
    _accountHolderNameController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _bankIdentifierCodeController.dispose();
    _branchLocationController.dispose();
    _taxPayerIdController.dispose();
    super.dispose();
  }
}

class _CompanyDetailsStep extends StatefulWidget {
  final Employee employee;
  final Function(Employee) onSaved;

  const _CompanyDetailsStep({
    Key? key,
    required this.employee,
    required this.onSaved,
  }) : super(key: key);

  @override
  __CompanyDetailsStepState createState() => __CompanyDetailsStepState();
}

class __CompanyDetailsStepState extends State<_CompanyDetailsStep> {
  late TextEditingController _employeeIdController;
  late TextEditingController _hoursPerDayController;
  late TextEditingController _annualSalaryController;
  late TextEditingController _daysPerWeekController;
  late TextEditingController _fixedSalaryController;
  late TextEditingController _hoursPerMonthController;
  late TextEditingController _ratePerDayController;
  late TextEditingController _daysPerMonthController;
  late TextEditingController _ratePerHourController;

  String _selectedBranch = 'Select Branch';
  String _selectedDesignation = 'Select Designation';
  String _selectedDepartment = 'Select Department';
  DateTime? _dateOfJoining;

  @override
  void initState() {
    super.initState();
    _employeeIdController = TextEditingController(text: widget.employee.id);
    _hoursPerDayController = TextEditingController(text: widget.employee.hoursPerDay);
    _annualSalaryController = TextEditingController(text: widget.employee.annualSalary);
    _daysPerWeekController = TextEditingController(text: widget.employee.daysPerWeek);
    _fixedSalaryController = TextEditingController(text: widget.employee.fixedSalary);
    _hoursPerMonthController = TextEditingController(text: widget.employee.hoursPerMonth);
    _ratePerDayController = TextEditingController(text: widget.employee.ratePerDay);
    _daysPerMonthController = TextEditingController(text: widget.employee.daysPerMonth);
    _ratePerHourController = TextEditingController(text: widget.employee.ratePerHour);
    
    _selectedBranch = widget.employee.branch.isEmpty ? 'Select Branch' : widget.employee.branch;
    _selectedDesignation = widget.employee.designation.isEmpty ? 'Select Designation' : widget.employee.designation;
    _selectedDepartment = widget.employee.department.isEmpty ? 'Select Department' : widget.employee.department;
    _dateOfJoining = widget.employee.dateOfJoining;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSectionHeader('Company Detail'),
          _buildTextField('Employee ID', _employeeIdController, readOnly: true),
          _buildDropdownField('Branch*', ['Select Branch', 'Main Branch', 'North Branch', 'South Branch', 'East Branch', 'West Branch'], _selectedBranch, (value) {
            setState(() => _selectedBranch = value!);
            _updateEmployee();
          }, isRequired: true),
          _buildDropdownField('Designation*', ['Select Designation', 'Software Developer', 'HR Manager', 'Project Manager', 'Designer', 'QA Engineer'], _selectedDesignation, (value) {
            setState(() => _selectedDesignation = value!);
            _updateEmployee();
          }, isRequired: true),
          _buildDropdownField('Department*', ['Select Department', 'IT', 'HR', 'Finance', 'Marketing', 'Operations'], _selectedDepartment, (value) {
            setState(() => _selectedDepartment = value!);
            _updateEmployee();
          }, isRequired: true),
          _buildDateField('Company Date Of joining*', _dateOfJoining, (date) {
            setState(() => _dateOfJoining = date);
            _updateEmployee();
          }, isRequired: true),
          SizedBox(height: 20),
          _buildSectionHeader('Hours and Rates Detail'),
          _buildHoursRatesTable(),
          SizedBox(height: 20),
          _buildCheckboxField(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool readOnly = false, bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
         
        ),
        onChanged: (value) => _updateEmployee(),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, Function(DateTime?) onDateSelected, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () async {
          final selectedDate = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (selectedDate != null) {
            onDateSelected(selectedDate);
            _updateEmployee();
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            suffixIcon: isRequired ? Icon(Icons.star, color: Colors.red, size: 12) : Icon(Icons.calendar_today, size: 20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date != null ? '${date.month}/${date.day}/${date.year}' : 'mm/dd/yyyy',
                style: TextStyle(
                  color: date != null ? Colors.black : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> options, String value, Function(String?) onChanged, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffixIcon: isRequired ? Icon(Icons.star, color: Colors.red, size: 12) : null,
        ),
        value: value,
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged,
        validator: isRequired ? (value) {
          if (value == null || value == 'Select Branch' || value == 'Select Designation' || value == 'Select Department') {
            return 'This field is required';
          }
          return null;
        } : null,
      ),
    );
  }

  Widget _buildHoursRatesTable() {
    return Table(
      columnWidths: {
        0: FlexColumnWidth(1.5),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          children: [
            _buildTableHeader('Hours'),
            _buildTableHeader(''),
            _buildTableHeader('Rates'),
            _buildTableHeader(''),
          ],
        ),
        _buildTableRow('Hours Per day', _hoursPerDayController, 'Annual salary', _annualSalaryController),
        _buildTableRow('Days Per week', _daysPerWeekController, 'Fixed Salary', _fixedSalaryController),
        _buildTableRow('Hours Per month', _hoursPerMonthController, 'Rate per day', _ratePerDayController),
        _buildTableRow('Days per month', _daysPerMonthController, 'Rate per hour', _ratePerHourController),
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  TableRow _buildTableRow(String leftLabel, TextEditingController leftController, String rightLabel, TextEditingController rightController) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Text(leftLabel),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: TextFormField(
            controller: leftController,
            decoration: InputDecoration(
              hintText: 'Enter $leftLabel',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            onChanged: (value) => _updateEmployee(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Text(rightLabel),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: TextFormField(
            controller: rightController,
            decoration: InputDecoration(
              hintText: 'Enter $rightLabel',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            onChanged: (value) => _updateEmployee(),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxField() {
    return Row(
      children: [
        Checkbox(value: false, onChanged: (value) {}),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'This employee must not be paid unless hours or days worked are advised',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  void _updateEmployee() {
    widget.onSaved(widget.employee.copyWith(
      id: _employeeIdController.text,
      branch: _selectedBranch == 'Select Branch' ? '' : _selectedBranch,
      designation: _selectedDesignation == 'Select Designation' ? '' : _selectedDesignation,
      department: _selectedDepartment == 'Select Department' ? '' : _selectedDepartment,
      dateOfJoining: _dateOfJoining ?? widget.employee.dateOfJoining,
      hoursPerDay: _hoursPerDayController.text,
      annualSalary: _annualSalaryController.text,
      daysPerWeek: _daysPerWeekController.text,
      fixedSalary: _fixedSalaryController.text,
      hoursPerMonth: _hoursPerMonthController.text,
      ratePerDay: _ratePerDayController.text,
      daysPerMonth: _daysPerMonthController.text,
      ratePerHour: _ratePerHourController.text,
    ));
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _hoursPerDayController.dispose();
    _annualSalaryController.dispose();
    _daysPerWeekController.dispose();
    _fixedSalaryController.dispose();
    _hoursPerMonthController.dispose();
    _ratePerDayController.dispose();
    _daysPerMonthController.dispose();
    _ratePerHourController.dispose();
    super.dispose();
  }
}