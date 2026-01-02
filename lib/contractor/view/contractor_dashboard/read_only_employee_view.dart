
import 'dart:io';
import 'package:ecoteam_app/admin/models/employee_model.dart';
import 'package:flutter/material.dart';

class ReadOnlyEmployeeBottomSheet extends StatefulWidget {
  final Employee? employee;

  const ReadOnlyEmployeeBottomSheet({
    Key? key,
    this.employee,
  }) : super(key: key);

  @override
  _ReadOnlyEmployeeBottomSheetState createState() => _ReadOnlyEmployeeBottomSheetState();
}

class _ReadOnlyEmployeeBottomSheetState extends State<ReadOnlyEmployeeBottomSheet>
    with TickerProviderStateMixin {
  late Employee _employee;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _employee = widget.employee ??
        Employee(
          id: '',
          name: '',
          email: '',
          gender: 'male',
          workspace: 3,
          createdBy: 9,
          employeesId: '#EMP00000001',
        );

    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Scaffold(
        appBar: AppBar(
          title: Text('View Details'),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: [
              Tab(text: 'Personal'),
              Tab(text: 'Company'),
              Tab(text: 'Bank'),
              Tab(text: 'Additional'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _ReadOnlyPersonalDetailsTab(employee: _employee),
            _ReadOnlyCompanyDetailsTab(employee: _employee),
            _ReadOnlyBankDetailsTab(employee: _employee),
            _ReadOnlyAdditionalDetailsTab(employee: _employee),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper Mixin for ReadOnly Fields
mixin ReadOnlyFieldsMixin {
  Widget _buildReadOnlyField(String label, String value, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 5),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Text(
            value.isNotEmpty ? value : '-',
            style: TextStyle(
              fontSize: 14, // Slightly smaller for dense view
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRow(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.map((child) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: child,
        ))).toList(),
      ),
    );
  }
  
  Widget _buildSingle(Widget child) {
      return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: child,
        ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
}

// Personal Details Tab
class _ReadOnlyPersonalDetailsTab extends StatelessWidget with ReadOnlyFieldsMixin {
  final Employee employee;

  _ReadOnlyPersonalDetailsTab({
    Key? key,
    required this.employee,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 80, // Smaller avatar
              height: 80,
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: employee.avatar != null && employee.avatar!.isNotEmpty
                    ? Image.network(
                        'https://sitepilot.easy2it.in/${employee.avatar}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.person, size: 40, color: Colors.grey[400]),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.person, size: 40, color: Colors.grey[400]),
                      ),
              ),
            ),
          ),
          
          _buildRow([
              _buildReadOnlyField('Name', employee.name),
              _buildReadOnlyField('Gender', employee.gender),
          ]),
          
          _buildSingle(_buildReadOnlyField('Email', employee.email)),
          
          _buildRow([
              _buildReadOnlyField('Phone', employee.phone ?? ''),
              _buildReadOnlyField('Date of Birth', employee.dob ?? ''),
          ]),

          _buildSingle(_buildReadOnlyField('Address', employee.address ?? '', maxLines: 2)),
          
          SizedBox(height: 10),
          _buildSectionHeader('Passport Details'),
          _buildRow([
              _buildReadOnlyField('Passport Number', employee.passport ?? ''),
              _buildReadOnlyField('Country', employee.passportCountry ?? ''),
          ]),
        ],
      ),
    );
  }
}

// Company Details Tab
class _ReadOnlyCompanyDetailsTab extends StatelessWidget with ReadOnlyFieldsMixin {
  final Employee employee;

  _ReadOnlyCompanyDetailsTab({
    Key? key,
    required this.employee,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow([
               _buildReadOnlyField('Employee ID', employee.employeeId ?? ''),
               _buildReadOnlyField('Employees ID', employee.employeesId ?? ''),
          ]),

          _buildRow([
             _buildReadOnlyField('Branch', employee.branchName.isNotEmpty ? employee.branchName : (employee.branchId?.toString() ?? '')),
             _buildReadOnlyField('Department', employee.departmentName.isNotEmpty ? employee.departmentName : (employee.departmentId?.toString() ?? '')),
          ]),

          _buildRow([
            _buildReadOnlyField('Designation', employee.designationName.isNotEmpty ? employee.designationName : (employee.designationId?.toString() ?? '')),
            _buildReadOnlyField('Role', employee.roles != null && employee.roleId != null ? 
              (employee.roles![employee.roleId.toString()] ?? employee.roleId.toString()) : ''),
          ]),

          _buildRow([
             _buildReadOnlyField('Date of Joining', employee.companyDoj ?? ''),
             _buildReadOnlyField('Status', (employee.isActive ?? 1) == 1 ? 'Active' : 'Inactive'),
          ]),

          if (employee.documentList != null && employee.documentList!.isNotEmpty)
            _buildDocumentsList(),

          _buildSingle(_buildReadOnlyField('Documents', employee.documents ?? '')),
        ],
      ),
    );
  }

   Widget _buildDocumentsList() {
    final documents = employee.documentList ?? [];
    final selectedDocs =
        employee.documents?.split(',').map((e) => e.trim()).toList() ??
        [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ExpansionTile(
        title: Text('Documents (${selectedDocs.length} selected)', style: TextStyle(fontSize: 14)),
        children: documents.map((doc) {
          final docId = doc['id'].toString();
          final docName = doc['name']?.toString() ?? 'Document $docId';
          final isSelected = selectedDocs.contains(docId);

          return ListTile(
            dense: true,
            title: Text(docName, style: TextStyle(fontSize: 13)),
            trailing: isSelected ? Icon(Icons.check, color: Colors.green, size: 20) : null,
          );
        }).toList(),
      ),
    );
  }
}

// Bank Details Tab
class _ReadOnlyBankDetailsTab extends StatelessWidget with ReadOnlyFieldsMixin {
  final Employee employee;

  _ReadOnlyBankDetailsTab({
    Key? key,
    required this.employee,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow([
             _buildReadOnlyField('Account Holder', employee.accountHolderName ?? ''),
             _buildReadOnlyField('Account Type', employee.accountType ?? ''),
          ]),
          
          _buildSingle(_buildReadOnlyField('Account Number', employee.accountNumber ?? '')),
          
          _buildRow([
             _buildReadOnlyField('Bank Name', employee.bankName ?? ''),
             _buildReadOnlyField('BIC/SWIFT', employee.bankIdentifierCode ?? ''),
          ]),

          _buildRow([
             _buildReadOnlyField('Branch Location', employee.branchLocation ?? ''),
             _buildReadOnlyField('Tax Payer ID', employee.taxPayerId ?? ''),
          ]),
        ],
      ),
    );
  }
}

// Additional Details Tab
class _ReadOnlyAdditionalDetailsTab extends StatelessWidget with ReadOnlyFieldsMixin {
  final Employee employee;

  _ReadOnlyAdditionalDetailsTab({
    Key? key,
    required this.employee,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Location'),
          _buildRow([
            _buildReadOnlyField('Type', employee.locationTypeName.isNotEmpty ? employee.locationTypeName : (employee.locationType ?? '')),
            _buildReadOnlyField('Country', employee.country ?? ''),
          ]),
          _buildRow([
             _buildReadOnlyField('State', employee.state ?? ''),
             _buildReadOnlyField('City', employee.city ?? ''),
          ]),
           _buildSingle(_buildReadOnlyField('Zipcode', employee.zipcode ?? '')),
          
          SizedBox(height: 10),
          _buildSectionHeader('Organization'),
          _buildRow([
             _buildReadOnlyField('Org Switch', employee.organisationSwitch ?? ''),
             _buildReadOnlyField('PF No.', employee.providentFundNo ?? ''),
          ]),

          SizedBox(height: 10),
          _buildSectionHeader('Emergency Contact'),
          _buildSingle(_buildReadOnlyField('Mobile', employee.emergencyContactNo ?? '')),
          _buildSingle(_buildReadOnlyField('Address', employee.emergencyAddress ?? '', maxLines: 2)),

          SizedBox(height: 10),
          _buildSectionHeader('Salary & Hours'),
          _buildRow([
              _buildReadOnlyField('Salary Type', employee.salaryType ?? ''),
              _buildReadOnlyField('Amount', employee.salary ?? ''),
          ]),
          
          _buildRow([
               _buildReadOnlyField('Hours/Day', employee.hoursPerDay ?? ''),
               _buildReadOnlyField('Days/Week', employee.daysPerWeek ?? ''),
          ]),
           _buildRow([
               _buildReadOnlyField('Hours/Month', employee.hoursPerMonth ?? ''),
               _buildReadOnlyField('Days/Month', employee.daysPerMonth ?? ''),
          ]),

          SizedBox(height: 10),
          _buildSectionHeader('Rates'),
          _buildRow([
              _buildReadOnlyField('Rate/Hour', employee.ratePerHour ?? ''),
              _buildReadOnlyField('Rate/Day', employee.ratePerDay ?? ''),
          ]),

          _buildRow([
              _buildReadOnlyField('Annual Salary', employee.annualSalary ?? ''),
              _buildReadOnlyField('Fixed Salary', employee.fixedSalary ?? ''),
          ]),
        ],
      ),
    );
  }
}
