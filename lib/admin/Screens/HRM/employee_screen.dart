import 'package:ecoteam_app/admin/services/employee_services.dart';
import 'package:flutter/material.dart';
import 'package:ecoteam_app/admin/models/employee_model.dart';

class EmployeePage extends StatefulWidget {
  @override
  _EmployeePageState createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage> {
  List<Employee> employees = [];
  List<Employee> filteredEmployees = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    searchController.addListener(_filterEmployees);
  }

  Future<void> _loadEmployees() async {
    setState(() => isLoading = true);
    try {
      final fetchedEmployees = await ApiService.fetchEmployees();
      setState(() {
        employees = fetchedEmployees;
        filteredEmployees = employees;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load employees: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
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
              (employee.employeeId ?? '').toLowerCase().contains(query) ||
              (employee.department ?? '').toLowerCase().contains(query) ||
              (employee.designation ?? '').toLowerCase().contains(query) ||
              (employee.phone ?? '').toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      searchController.clear();
      isLoading = true;
    });
    
    await _loadEmployees();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data refreshed')),
    );
  }

  Future<void> _addEmployee() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EmployeeBottomSheet(
        onSave: (employee) async {
          try {
            final newEmployee = await ApiService.addEmployee(employee);
            return newEmployee;
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to add employee: $e')),
            );
            return null;
          }
        },
      ),
    );

    if (result != null) {
      setState(() {
        employees.add(result);
        filteredEmployees = employees;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Employee added successfully')),
      );
    }
  }

  Future<void> _editEmployee(Employee employee) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EmployeeBottomSheet(
        employee: employee,
        onSave: (updatedEmployee) async {
          try {
            final savedEmployee = await ApiService.updateEmployee(updatedEmployee);
            return savedEmployee;
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update employee: $e')),
            );
            return null;
          }
        },
      ),
    );

    if (result != null) {
      setState(() {
        final index = employees.indexWhere((e) => e.id == employee.id);
        if (index != -1) {
          employees[index] = result;
          filteredEmployees = employees;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Employee updated successfully')),
      );
    }
  }

  Future<void> _deleteEmployee(Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${employee.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await ApiService.deleteEmployee(employee.id);
        if (success) {
          setState(() {
            employees.removeWhere((e) => e.id == employee.id);
            filteredEmployees = employees;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Employee deleted successfully')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete employee: $e')),
        );
      }
    }
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
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
                      Text(
                        'Active: ${employees.where((e) => e.isActive == 1).length}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green,
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
                            isLoading ? 'Loading...' : 'No employees found',
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
                Row(
                  children: [
                    Text(
                      employee.employeeId ?? employee.id,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (employee.isActive == 1) ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (employee.isActive == 1) ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 10,
                          color: (employee.isActive == 1) ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                    ),
                  ],
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
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (employee.phone != null && employee.phone!.isNotEmpty)
                  _buildInfoChip('Phone', employee.phone!),
                if (employee.branch != null && employee.branch!.isNotEmpty)
                  _buildInfoChip('Branch', employee.branch!),
                if (employee.department != null && employee.department!.isNotEmpty)
                  _buildInfoChip('Dept', employee.department!),
                if (employee.designation != null && employee.designation!.isNotEmpty)
                  _buildInfoChip('Role', employee.designation!),
                if (employee.locationType != null)
                  _buildInfoChip('Location', employee.locationType!),
              ],
            ),
            SizedBox(height: 8),
            if (employee.createdAt != null)
              Text(
                'Created: ${_formatDate(employee.createdAt!)} | Updated: ${_formatDate(employee.updatedAt ?? employee.createdAt!)}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            if (employee.dateOfJoining != null)
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
        '$label: $value',
        style: TextStyle(
          fontSize: 11,
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
  final Future<Employee?> Function(Employee) onSave;

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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _employee = widget.employee ??
        Employee(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: '',
          email: '',
          branch: '',
          department: '',
          designation: '',
          dateOfJoining: DateTime.now(),
          phone: '',
          gender: 'Male',
          isActive: 1,
          workspace: 3,
          createdBy: 1,
          locationType: 'residential',
        );
    _tabController = TabController(length: 4, vsync: this);
  }

  List<Widget> _buildTabs() {
    return [
      Tab(text: 'Personal'),
      Tab(text: 'Company'),
      Tab(text: 'Bank'),
      Tab(text: 'Salary'),
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
      _BankDetailsStep(
        employee: _employee,
        onSaved: (employee) {
          setState(() {
            _employee = employee;
          });
        },
      ),
      _SalaryDetailsStep(
        employee: _employee,
        onSaved: (employee) {
          setState(() {
            _employee = employee;
          });
        },
      ),
    ];
  }

  Future<void> _saveEmployee() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isSaving = true);
      
      try {
        final savedEmployee = await widget.onSave(_employee);
        if (savedEmployee != null && context.mounted) {
          Navigator.pop(context, savedEmployee);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee == null ? 'Add Employee' : 'Edit Employee'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveEmployee,
                  child: _isSaving
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
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

  String _gender = 'Male';
  DateTime? _dateOfBirth;
  String _locationType = 'residential';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee.name);
    _emailController = TextEditingController(text: widget.employee.email);
    _phoneController = TextEditingController(text: widget.employee.phone);
    _addressController = TextEditingController(text: widget.employee.address ?? '');
    _stateController = TextEditingController(text: widget.employee.state ?? '');
    _countryController = TextEditingController(text: widget.employee.country ?? 'India');
    _cityController = TextEditingController(text: widget.employee.city ?? '');
    _passportCountryController = TextEditingController(text: widget.employee.passportCountry ?? '');
    _passportController = TextEditingController(text: widget.employee.passport ?? '');
    _zipCodeController = TextEditingController(text: widget.employee.zipCode ?? '');

    _gender = widget.employee.gender;
    _dateOfBirth = widget.employee.dob;
    _locationType = widget.employee.locationType ?? 'residential';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTextField('Full Name*', _nameController, isRequired: true),
          _buildTextField('Email*', _emailController, isRequired: true, keyboardType: TextInputType.emailAddress),
          _buildDateField('Date of Birth', _dateOfBirth, (date) {
            setState(() => _dateOfBirth = date);
            _updateEmployee();
          }),
          _buildTextField('Phone*', _phoneController,
            hint: '+91 1234567890',
            isRequired: true,
            keyboardType: TextInputType.phone,
          ),
          _buildGenderField(),
          _buildDropdownField('Location Type', ['residential', 'office', 'remote', 'hybrid'], _locationType, (value) {
            setState(() => _locationType = value!);
            _updateEmployee();
          }),
          _buildTextField('Country', _countryController, hint: 'Enter Country'),
          _buildTextField('State', _stateController, hint: 'Enter State'),
          _buildTextField('City', _cityController, hint: 'Enter City'),
          _buildTextField('Zip Code', _zipCodeController, hint: 'Enter Zip Code', keyboardType: TextInputType.number),
          _buildTextField('Address', _addressController, hint: 'Enter complete address', maxLines: 3),
          SizedBox(height: 10),
          _buildSectionHeader('Passport Details'),
          _buildTextField('Passport Country', _passportCountryController, hint: 'Enter Passport Country'),
          _buildTextField('Passport Number', _passportController, hint: 'Enter Passport Number'),
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
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {
    String? hint,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (isRequired ? '*' : ''),
          hintText: hint,
          border: OutlineInputBorder(),
          suffixIcon: isRequired ? Icon(Icons.star, color: Colors.red, size: 10) : null,
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
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

  Widget _buildDateField(String label, DateTime? date, Function(DateTime?) onDateSelected) {
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
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date != null ? '${date.day}/${date.month}/${date.year}' : 'Select date',
                style: TextStyle(
                  color: date != null ? Colors.black : Colors.grey,
                ),
              ),
              Icon(Icons.calendar_today, size: 20),
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
      dob: _dateOfBirth,
      address: _addressController.text,
      state: _stateController.text,
      country: _countryController.text,
      city: _cityController.text,
      passportCountry: _passportCountryController.text,
      passport: _passportController.text,
      zipCode: _zipCodeController.text,
      locationType: _locationType,
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
  late TextEditingController _documentController;

  String _selectedBranch = 'Main Branch';
  String _selectedDesignation = 'Software Developer';
  String _selectedDepartment = 'IT';
  DateTime? _dateOfJoining;

  @override
  void initState() {
    super.initState();
    _employeeIdController = TextEditingController(text: widget.employee.employeeId ?? '');
    _documentController = TextEditingController(text: widget.employee.document ?? '');
    
    _selectedBranch = widget.employee.branch.isNotEmpty ? widget.employee.branch : 'Main Branch';
    _selectedDesignation = widget.employee.designation.isNotEmpty ? widget.employee.designation : 'Software Developer';
    _selectedDepartment = widget.employee.department.isNotEmpty ? widget.employee.department : 'IT';
    _dateOfJoining = widget.employee.companyDof ?? widget.employee.dateOfJoining;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTextField('Employee ID', _employeeIdController, hint: 'EMP001'),
          _buildDropdownField('Branch*', ['Main Branch', 'North Branch', 'South Branch', 'East Branch'], _selectedBranch, (value) {
            setState(() => _selectedBranch = value!);
            _updateEmployee();
          }, isRequired: true),
          _buildDropdownField('Department*', ['IT', 'HR', 'Finance', 'Marketing', 'Operations'], _selectedDepartment, (value) {
            setState(() => _selectedDepartment = value!);
            _updateEmployee();
          }, isRequired: true),
          _buildDropdownField('Designation*', ['Software Developer', 'HR Manager', 'Project Manager', 'Designer', 'QA Engineer'], _selectedDesignation, (value) {
            setState(() => _selectedDesignation = value!);
            _updateEmployee();
          }, isRequired: true),
          _buildDateField('Date of Joining*', _dateOfJoining, (date) {
            setState(() => _dateOfJoining = date);
            _updateEmployee();
          }, isRequired: true),
          _buildTextField('Documents', _documentController, hint: 'Comma separated document IDs'),
          _buildDropdownField('Status', ['Active', 'Inactive'], widget.employee.isActive == 1 ? 'Active' : 'Inactive', (value) {
            _updateEmployee();
          }),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint, bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (isRequired ? '*' : ''),
          hintText: hint,
          border: OutlineInputBorder(),
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
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label + (isRequired ? '*' : ''),
            border: OutlineInputBorder(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date != null ? '${date.day}/${date.month}/${date.year}' : 'Select date',
                style: TextStyle(
                  color: date != null ? Colors.black : Colors.grey,
                ),
              ),
              Icon(Icons.calendar_today, size: 20),
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
          labelText: label + (isRequired ? '*' : ''),
          border: OutlineInputBorder(),
        ),
        value: value,
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: (value) {
          onChanged(value);
          _updateEmployee();
        },
      ),
    );
  }

  void _updateEmployee() {
    widget.onSaved(widget.employee.copyWith(
      employeeId: _employeeIdController.text,
      branch: _selectedBranch,
      department: _selectedDepartment,
      designation: _selectedDesignation,
      companyDof: _dateOfJoining,
      document: _documentController.text,
      isActive: _selectedBranch.contains('Active') ? 1 : 0,
    ));
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _documentController.dispose();
    super.dispose();
  }
}

class _BankDetailsStep extends StatefulWidget {
  final Employee employee;
  final Function(Employee) onSaved;

  const _BankDetailsStep({
    Key? key,
    required this.employee,
    required this.onSaved,
  }) : super(key: key);

  @override
  __BankDetailsStepState createState() => __BankDetailsStepState();
}

class __BankDetailsStepState extends State<_BankDetailsStep> {
  late TextEditingController _accountHolderNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _bankNameController;
  late TextEditingController _bankIdentifierCodeController;
  late TextEditingController _branchLocationController;
  late TextEditingController _taxPayerIdController;

  String _accountType = 'Savings';

  @override
  void initState() {
    super.initState();
    _accountHolderNameController = TextEditingController(text: widget.employee.accountHolderName ?? '');
    _accountNumberController = TextEditingController(text: widget.employee.accountNumber ?? '');
    _bankNameController = TextEditingController(text: widget.employee.bankName ?? '');
    _bankIdentifierCodeController = TextEditingController(text: widget.employee.bankIdentifierCode ?? '');
    _branchLocationController = TextEditingController(text: widget.employee.branchLocation ?? '');
    _taxPayerIdController = TextEditingController(text: widget.employee.taxPayerId ?? '');
    
    _accountType = widget.employee.accountType ?? 'Savings';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTextField('Account Holder Name*', _accountHolderNameController, isRequired: true),
          _buildTextField('Account Number*', _accountNumberController, isRequired: true, keyboardType: TextInputType.number),
          _buildTextField('Bank Name*', _bankNameController, isRequired: true),
          _buildDropdownField('Account Type', ['Savings', 'Current', 'Salary'], _accountType, (value) {
            setState(() => _accountType = value!);
            _updateEmployee();
          }),
          _buildTextField('Bank Identifier Code (BIC)', _bankIdentifierCodeController),
          _buildTextField('Branch Location', _branchLocationController),
          _buildTextField('Tax Payer ID', _taxPayerIdController),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (isRequired ? '*' : ''),
          border: OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        onChanged: (value) => _updateEmployee(),
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
      accountHolderName: _accountHolderNameController.text,
      accountNumber: _accountNumberController.text,
      bankName: _bankNameController.text,
      accountType: _accountType,
      bankIdentifierCode: _bankIdentifierCodeController.text,
      branchLocation: _branchLocationController.text,
      taxPayerId: _taxPayerIdController.text,
    ));
  }

  @override
  void dispose() {
    _accountHolderNameController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _bankIdentifierCodeController.dispose();
    _branchLocationController.dispose();
    _taxPayerIdController.dispose();
    super.dispose();
  }
}

class _SalaryDetailsStep extends StatefulWidget {
  final Employee employee;
  final Function(Employee) onSaved;

  const _SalaryDetailsStep({
    Key? key,
    required this.employee,
    required this.onSaved,
  }) : super(key: key);

  @override
  __SalaryDetailsStepState createState() => __SalaryDetailsStepState();
}

class __SalaryDetailsStepState extends State<_SalaryDetailsStep> {
  late TextEditingController _hoursPerDayController;
  late TextEditingController _annualSalaryController;
  late TextEditingController _daysPerWeekController;
  late TextEditingController _fixedSalaryController;
  late TextEditingController _hoursPerMonthController;
  late TextEditingController _ratePerDayController;
  late TextEditingController _daysPerMonthController;
  late TextEditingController _ratePerHourController;
  late TextEditingController _salaryController;
  late TextEditingController _providentFundNoController;

  String _salaryType = 'Monthly';
  bool _paymentRequiresWorkAdvice = false;

  @override
  void initState() {
    super.initState();
    _hoursPerDayController = TextEditingController(text: widget.employee.hoursPerDay ?? '');
    _annualSalaryController = TextEditingController(text: widget.employee.annualSalary ?? '');
    _daysPerWeekController = TextEditingController(text: widget.employee.daysPerWeek ?? '');
    _fixedSalaryController = TextEditingController(text: widget.employee.fixedSalary ?? '');
    _hoursPerMonthController = TextEditingController(text: widget.employee.hoursPerMonth ?? '');
    _ratePerDayController = TextEditingController(text: widget.employee.ratePerDay ?? '');
    _daysPerMonthController = TextEditingController(text: widget.employee.daysPerMonth ?? '');
    _ratePerHourController = TextEditingController(text: widget.employee.ratePerHour ?? '');
    _salaryController = TextEditingController(text: widget.employee.salary ?? '');
    _providentFundNoController = TextEditingController(text: widget.employee.providentFundNo ?? '');
    
    _salaryType = widget.employee.salaryType ?? 'Monthly';
    _paymentRequiresWorkAdvice = widget.employee.paymentRequiresWorkAdvice == 'on';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDropdownField('Salary Type', ['Monthly', 'Hourly', 'Weekly', 'Bi-weekly', 'Annual'], _salaryType, (value) {
            setState(() => _salaryType = value!);
            _updateEmployee();
          }),
          SizedBox(height: 20),
          
          _buildSectionHeader('Working Hours'),
          _buildNumberField('Hours Per Day', _hoursPerDayController),
          _buildNumberField('Days Per Week', _daysPerWeekController),
          _buildNumberField('Hours Per Month', _hoursPerMonthController),
          _buildNumberField('Days Per Month', _daysPerMonthController),
          
          SizedBox(height: 20),
          _buildSectionHeader('Salary Details'),
          _buildNumberField('Salary', _salaryController, prefix: '₹'),
          _buildNumberField('Annual Salary', _annualSalaryController, prefix: '₹'),
          _buildNumberField('Fixed Salary', _fixedSalaryController, prefix: '₹'),
          
          SizedBox(height: 20),
          _buildSectionHeader('Rate Details'),
          _buildNumberField('Rate Per Hour', _ratePerHourController, prefix: '₹'),
          _buildNumberField('Rate Per Day', _ratePerDayController, prefix: '₹'),
          
          SizedBox(height: 20),
          _buildSectionHeader('Additional Details'),
          _buildTextField('Provident Fund No.', _providentFundNoController),
          
          CheckboxListTile(
            title: Text('Payment requires work advice'),
            value: _paymentRequiresWorkAdvice,
            onChanged: (value) {
              setState(() => _paymentRequiresWorkAdvice = value!);
              _updateEmployee();
            },
          ),
          
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
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        onChanged: (value) => _updateEmployee(),
      ),
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller, {String? prefix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          prefixText: prefix,
        ),
        keyboardType: TextInputType.number,
        onChanged: (value) => _updateEmployee(),
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
      hoursPerDay: _hoursPerDayController.text,
      annualSalary: _annualSalaryController.text,
      daysPerWeek: _daysPerWeekController.text,
      fixedSalary: _fixedSalaryController.text,
      hoursPerMonth: _hoursPerMonthController.text,
      ratePerDay: _ratePerDayController.text,
      daysPerMonth: _daysPerMonthController.text,
      ratePerHour: _ratePerHourController.text,
      salary: _salaryController.text,
      salaryType: _salaryType,
      providentFundNo: _providentFundNoController.text,
      paymentRequiresWorkAdvice: _paymentRequiresWorkAdvice ? 'on' : 'off',
    ));
  }

  @override
  void dispose() {
    _hoursPerDayController.dispose();
    _annualSalaryController.dispose();
    _daysPerWeekController.dispose();
    _fixedSalaryController.dispose();
    _hoursPerMonthController.dispose();
    _ratePerDayController.dispose();
    _daysPerMonthController.dispose();
    _ratePerHourController.dispose();
    _salaryController.dispose();
    _providentFundNoController.dispose();
    super.dispose();
  }
}