
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ecoteam_app/admin/models/employee_model.dart';
import 'package:ecoteam_app/admin/services/employee_services.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isLoading = false;

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

    _loadEmployeeDetails();
  }

  Future<void> _loadEmployeeDetails() async {
    final String idToUse = _employee.id;
    if (idToUse.isEmpty) {
      print('DEBUG BottomSheet: Cannot load details - Employee ID is empty');
      return;
    }

    setState(() => _isLoading = true);
    try {
      print('DEBUG BottomSheet: Loading details for ID: $idToUse, Workspace: ${_employee.workspace}');
      
      final updatedEmployee = await ApiService.getEmployeeById(
        idToUse,
        workspaceId: _employee.workspace,
      );

      if (mounted) {
        setState(() {
          _employee = updatedEmployee;
          _isLoading = false;
        });
        print('DEBUG BottomSheet: Successfully updated employee details from API');
      }
    } catch (e) {
      print('DEBUG BottomSheet: Error fetching employee details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Loads the full employee record from SharedPreferences (saved at login).
  /// This avoids an extra API call — the login response already contains all
  /// fields: branch, department, designation (nested), documents, bank, salary, etc.
  Future<void> _loadFromLoginCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final employeeDataString = prefs.getString('employee_data');
      if (employeeDataString == null) return;

      final employeeJson = jsonDecode(employeeDataString);
      final cachedEmployee = Employee.fromJson(employeeJson);

      if (mounted) {
        setState(() {
          _employee = cachedEmployee;
        });
      }
      print('DEBUG BottomSheet: Employee loaded from login cache — ${cachedEmployee.name}');
    } catch (e) {
      print('DEBUG BottomSheet: Could not load employee from cache: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: const Text('View Details'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                bottom: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Personal'),
                    Tab(text: 'Company'),
                    Tab(text: 'Bank'),
                    Tab(text: 'Additional'),
                  ],
                ),
              ),
              body: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _employee.name.isEmpty && _employee.email.isEmpty
                      ? const Center(
                          child: Text(
                            'No details found for this employee',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _ReadOnlyPersonalDetailsTab(employee: _employee),
                            _ReadOnlyCompanyDetailsTab(employee: _employee),
                            _ReadOnlyBankDetailsTab(employee: _employee),
                            _ReadOnlyAdditionalDetailsTab(employee: _employee),
                          ],
                        ),
              bottomNavigationBar: BottomAppBar(
                color: Colors.transparent,
                elevation: 0,
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
          ),
        ],
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
                        'https://app.ecoteamsolar.com/${employee.avatar}',
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

  static const String _baseUrl = 'https://app.ecoteamsolar.com/';

  @override
  Widget build(BuildContext context) {
    // Build documents list from documentList (raw JSON from login response)
    final List<Map<String, dynamic>> rawDocs =
        employee.documentList ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow([
            _buildReadOnlyField('Employee ID', employee.employeeId ?? ''),
            _buildReadOnlyField('Date of Joining', employee.companyDoj ?? ''),
          ]),

          _buildRow([
            _buildReadOnlyField(
                'Branch',
                employee.branchName.isNotEmpty
                    ? employee.branchName
                    : (employee.branchId?.toString() ?? '')),
            _buildReadOnlyField(
                'Department',
                employee.departmentName.isNotEmpty
                    ? employee.departmentName
                    : (employee.departmentId?.toString() ?? '')),
          ]),

          _buildRow([
            _buildReadOnlyField(
                'Designation',
                employee.designationName.isNotEmpty
                    ? employee.designationName
                    : (employee.designationId?.toString() ?? '')),
            _buildReadOnlyField(
                'Status',
                (employee.isActive ?? 1) == 1 ? 'Active' : 'Inactive'),
          ]),

          const SizedBox(height: 16),

          // Documents Section
          if (rawDocs.isNotEmpty) ..._buildDocumentCards(context, rawDocs)
          else
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: Text(
                'No documents uploaded',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildDocumentCards(
      BuildContext context, List<Map<String, dynamic>> docs) {
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          'Documents (${docs.length})',
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent),
        ),
      ),
      ...docs.map((doc) {
        final docPath = doc['document_value']?.toString() ?? '';
        final fullUrl = _baseUrl + docPath;
        final fileName = docPath.split('/').last;
        final typeName = doc['document_type'] is Map
            ? doc['document_type']['name']?.toString() ?? 'Document'
            : 'Document';

        final bool isPdf = fileName.toLowerCase().endsWith('.pdf');
        final bool isImage = fileName.toLowerCase().endsWith('.jpg') ||
            fileName.toLowerCase().endsWith('.jpeg') ||
            fileName.toLowerCase().endsWith('.png') ||
            fileName.toLowerCase().endsWith('.webp');

        return _DocumentCard(
          fileName: fileName,
          typeName: typeName,
          fullUrl: fullUrl,
          isPdf: isPdf,
          isImage: isImage,
        );
      }).toList(),
    ];
  }
}

/// Stateful card that handles download progress per document.
class _DocumentCard extends StatefulWidget {
  final String fileName;
  final String typeName;
  final String fullUrl;
  final bool isPdf;
  final bool isImage;

  const _DocumentCard({
    required this.fileName,
    required this.typeName,
    required this.fullUrl,
    required this.isPdf,
    required this.isImage,
  });

  @override
  State<_DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<_DocumentCard> {
  bool _downloading = false;
  double _downloadProgress = 0;

  Future<void> _download() async {
    if (_downloading) return;
    setState(() {
      _downloading = true;
      _downloadProgress = 0;
    });
    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/${widget.fileName}';
      final dio = Dio();
      await dio.download(
        widget.fullUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _downloadProgress = received / total);
          }
        },
      );
      if (mounted) {
        setState(() => _downloading = false);
        await OpenFile.open(savePath);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _downloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _view() async {
    if (widget.isImage) {
      // Full-screen image viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _FullScreenImageViewer(
            url: widget.fullUrl,
            fileName: widget.fileName,
          ),
        ),
      );
    } else {
      // Open PDF or other type in browser
      final uri = Uri.parse(widget.fullUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot open this file')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thumbnail or icon
            GestureDetector(
              onTap: _view,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.isImage
                    ? Image.network(
                        widget.fullUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fileIcon(widget.isPdf),
                      )
                    : _fileIcon(widget.isPdf),
              ),
            ),
            const SizedBox(width: 12),
            // File name + progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.typeName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.fileName,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_downloading) ...
                  [
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: _downloadProgress > 0 ? _downloadProgress : null,
                      backgroundColor: Colors.grey[200],
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _downloadProgress > 0
                          ? '${(_downloadProgress * 100).toStringAsFixed(0)}%'
                          : 'Downloading...',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.blue),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Action buttons
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(
                  icon: Icons.visibility_rounded,
                  label: 'View',
                  color: Colors.blue,
                  onTap: _view,
                ),
                const SizedBox(height: 6),
                _downloading
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _ActionButton(
                        icon: Icons.download_rounded,
                        label: 'Download',
                        color: Colors.green,
                        onTap: _download,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fileIcon(bool isPdf) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: isPdf ? Colors.red[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded,
        size: 36,
        color: isPdf ? Colors.red : Colors.blueGrey,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 3),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Full-screen image viewer with pinch-to-zoom.
class _FullScreenImageViewer extends StatelessWidget {
  final String url;
  final String fileName;

  const _FullScreenImageViewer({required this.url, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          fileName,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: Colors.white),
            tooltip: 'Open in browser',
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 5.0,
        child: Center(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(child: CircularProgressIndicator()),
            errorBuilder: (_, __, ___) => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image, color: Colors.grey, size: 64),
                  SizedBox(height: 8),
                  Text('Could not load image',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
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
          
          
        ],
      ),
    );
  }
}
