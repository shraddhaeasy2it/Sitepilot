import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PaymentsDetailScreen extends StatefulWidget {
   final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  
   PaymentsDetailScreen({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
  });

  @override
  State<PaymentsDetailScreen> createState() => _PaymentsDetailScreenState();
}

class _PaymentsDetailScreenState extends State<PaymentsDetailScreen> {
  final List<Map<String, dynamic>> _requests = [];
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _utrController = TextEditingController();
  String _selectedCategory = 'Material';
  final List<String> _categories = ['Material', 'Rental', 'Manpower', 'Misc'];
  File? _selectedFile;
  bool _isUploading = false;
  bool _showUploadError = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _utrController.dispose();
    super.dispose();
  }

  String _getFormattedDate() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isLargeScreen = screenWidth > 600;
    
    // Responsive sizing factors
    final horizontalPadding = screenWidth * 0.04;
    final verticalPadding = screenHeight * 0.02;
    final fieldHeight = screenHeight * 0.06;
    final iconSize = isSmallScreen ? 18.0 : 22.0;
    final titleFontSize = isSmallScreen ? 14.0 : 16.0;
    final contentFontSize = isSmallScreen ? 12.0 : 14.0;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF6f88e2),
          secondary: const Color(0xFF5a73d1),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 80,
          title: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Payments - ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text:_getCurrentSiteName(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4a63c0),
                  Color(0xFF3a53b0),
                  Color(0xFF2a43a0),
                ],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            ),
          ),
        ),
        body: _requests.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.payment,
                      size: screenHeight * 0.08,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: verticalPadding),
                    Text(
                      "No payment requests yet",
                      style: TextStyle(
                        fontSize: titleFontSize,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _requests.length,
                padding: EdgeInsets.all(horizontalPadding),
                itemBuilder: (context, index) {
                  final req = _requests[index];
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: verticalPadding),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: verticalPadding * 0.5,
                      ),
                      leading: Container(
                        padding: EdgeInsets.all(horizontalPadding * 0.5),
                        decoration: BoxDecoration(
                          color: _getStatusColor(req['status']).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.payment,
                          color: _getStatusColor(req['status']),
                          size: iconSize,
                        ),
                      ),
                      title: Text(
                        '₹${req['amount'].toStringAsFixed(2)} - ${req['category']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: titleFontSize,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req['description'],
                            style: TextStyle(fontSize: contentFontSize),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: verticalPadding * 0.25),
                          Text(
                            'Date: ${req['date']}',
                            style: TextStyle(
                              fontSize: contentFontSize * 0.85,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatusTag(req['status'], isSmallScreen),
                          if (req['document'] != null)
                            Icon(
                              Icons.attachment,
                              size: iconSize * 0.8,
                            ),
                        ],
                      ),
                      onTap: () => _showDetailDialog(req, index, screenWidth),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddRequestDialog,
          backgroundColor: const Color(0xFF6f88e2),
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: screenHeight * 0.035,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Paid':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  Widget _buildStatusTag(String status, bool isSmallScreen) {
    final fontSize = isSmallScreen ? 10.0 : 12.0;
    final padding = isSmallScreen ? 4.0 : 6.0;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding * 1.5, vertical: padding),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

void _showAddRequestDialog() {
  setState(() {
    _selectedFile = null;
    _showUploadError = false;
  });

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isSmallScreen = screenWidth < 360;
        final isLargeScreen = screenWidth > 600;

        final horizontalPadding = screenWidth * 0.04;
        final verticalPadding = screenHeight * 0.015;
        final fieldHeight = screenHeight * 0.055;
        final iconSize = isSmallScreen ? 18.0 : 20.0;
        final titleFontSize = isSmallScreen ? 18.0 : 20.0;
        final contentFontSize = isSmallScreen ? 12.0 : 14.0;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: Scrollbar(
                  controller: scrollController,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6f88e2).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.payment,
                                color: Color(0xFF6f88e2),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'New Payment Request',
                                    style: TextStyle(
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Text(
                                    'Fill in the details below',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Category Field
                        _buildSectionTitle('Category', titleFontSize),
                        const SizedBox(height: 10),
                       _buildFormField(
  height: fieldHeight,
  child: DropdownButtonFormField<String>(
    value: _selectedCategory,
    items: _categories.map((cat) {
      return DropdownMenuItem(
        value: cat,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center, // ✅ Keep icon + text centered
          children: [
            Icon(
              _getCategoryIcon(cat),
              size: iconSize * 0.9,
              color: const Color(0xFF6f88e2),
            ),
            const SizedBox(width: 8),
            Text(
              cat,
              style: TextStyle(fontSize: contentFontSize),
            ),
          ],
        ),
      );
    }).toList(),
    decoration: const InputDecoration(
      border: InputBorder.none,
      isDense: true, // ✅ removes extra vertical padding
      contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 8), 
    ),
    isDense: true, // ✅ makes dropdown more compact
    alignment: Alignment.center, // ✅ centers selected item & arrow vertically
    icon: const Icon( // ✅ custom icon perfectly centered
      Icons.arrow_drop_down,
      size: 28,
      color: Colors.black54,
    ),
    onChanged: (val) {
      if (val != null) {
        setModalState(() => _selectedCategory = val);
      }
    },
  ),
),


                        const SizedBox(height: 20),

                        // Amount Field
                        _buildSectionTitle('Amount', titleFontSize),
                        const SizedBox(height: 8),
                        _buildFormField(
                          height: fieldHeight,
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter amount',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: contentFontSize,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Description Field
                        _buildSectionTitle('Description', titleFontSize),
                        const SizedBox(height: 8),
                        _buildFormField(
                          height: fieldHeight * 1.5,
                          child: TextField(
                            controller: _descriptionController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter description...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: contentFontSize,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Upload
                        _buildSectionTitle(
                          'Invoice/Payment Proof',
                          titleFontSize,
                          isRequired: true,
                        ),
                        const SizedBox(height: 8),
                        _buildEnhancedDocumentUploadField(
                          setModalState,
                          isSmallScreen,
                          horizontalPadding,
                          verticalPadding,
                          iconSize,
                          contentFontSize,
                        ),

                        const SizedBox(height: 32),

                        // Submit Button
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6f88e2), Color(0xFF5a73d1)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6f88e2).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.send, color: Colors.white),
                            label: const Text(
                              'Submit Request',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: _validateAndSubmitRequest,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}


  // Helper widget for consistent form fields
  Widget _buildFormField({required Widget child, double? height}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.grey.shade50,
      ),
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: child,
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Material':
        return Icons.construction;
      case 'Rental':
        return Icons.car_rental;
      case 'Manpower':
        return Icons.people;
      case 'Misc':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }

  Widget _buildSectionTitle(
    String title,
    double fontSize, {
    bool isRequired = false,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2d3748),
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
      ],
    );
  }

  Widget _buildEnhancedDocumentUploadField(
    StateSetter setModalState,
    bool isSmallScreen,
    double horizontalPadding,
    double verticalPadding,
    double iconSize,
    double contentFontSize,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _showUploadError ? Colors.red : Colors.grey.shade300,
          width: _showUploadError ? 2 : 1,
        ),
        color: _selectedFile != null
            ? const Color(0xFF6f88e2).withOpacity(0.05)
            : Colors.grey.shade50,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await _pickDocument();
            setModalState(() {});
          },
          child: Padding(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              children: [
                if (_selectedFile == null) ...[
                  Container(
                    padding: EdgeInsets.all(horizontalPadding * 0.75),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6f88e2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      size: iconSize * 1.3,
                      color: _showUploadError
                          ? Colors.red
                          : const Color(0xFF6f88e2),
                    ),
                  ),
                  SizedBox(height: verticalPadding),
                  Text(
                    'Upload Document',
                    style: TextStyle(
                      fontSize: contentFontSize,
                      fontWeight: FontWeight.w600,
                      color: _showUploadError
                          ? Colors.red
                          : const Color(0xFF2d3748),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: verticalPadding * 0.5),
                  Text(
                    'PDF or Image (JPG, PNG)',
                    style: TextStyle(
                      fontSize: contentFontSize * 0.85,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(horizontalPadding * 0.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6f88e2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.insert_drive_file,
                          color: const Color(0xFF6f88e2),
                          size: iconSize * 0.9,
                        ),
                      ),
                      SizedBox(width: horizontalPadding * 0.75),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFile!.path.split('/').last,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2d3748),
                                fontSize: contentFontSize * 0.9,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: verticalPadding * 0.5),
                            Text(
                              'Tap to change file',
                              style: TextStyle(
                                fontSize: contentFontSize * 0.8,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedFile = null;
                            _showUploadError = true;
                          });
                        },
                        icon: Icon(
                          Icons.close,
                          color: Colors.grey.shade600,
                          size: iconSize * 0.8,
                        ),
                      ),
                    ],
                  ),
                ],
                if (_isUploading) ...[
                  SizedBox(height: verticalPadding),
                  const LinearProgressIndicator(
                    backgroundColor: Colors.grey,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF6f88e2),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDocument() async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Storage permission is required to pick files'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _isUploading = true;
      _showUploadError = false;
    });
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _showUploadError = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _validateAndSubmitRequest() {
    final amount = double.tryParse(_amountController.text);
    final description = _descriptionController.text.trim();
    if (amount == null || description.isEmpty || _selectedFile == null) {
      setState(() => _showUploadError = _selectedFile == null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields and upload document'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _requests.add({
        'category': _selectedCategory,
        'amount': amount,
        'description': description,
        'date': _getFormattedDate(),
        'status': 'Pending',
        'document': _selectedFile?.path.split('/').last ?? 'document',
        'file': _selectedFile,
        'utr': null,
      });
      _amountController.clear();
      _descriptionController.clear();
      _selectedFile = null;
      _showUploadError = false;
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment request submitted successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showDetailDialog(
    Map<String, dynamic> req,
    int index,
    double screenWidth,
  ) {
    final isSmallScreen = screenWidth < 360;
    final fontSize = isSmallScreen ? 14.0 : 16.0;
    final padding = screenWidth * 0.03;
    
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding: EdgeInsets.all(screenWidth * 0.05),
            child: Container(
              constraints: BoxConstraints(maxWidth: 500),
              child: AlertDialog(
                title: Text(
                  'Payment Request - ₹${req['amount'].toStringAsFixed(2)}',
                  style: TextStyle(fontSize: fontSize),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category: ${req['category']}',
                        style: TextStyle(fontSize: fontSize),
                      ),
                      SizedBox(height: padding),
                      Text(
                        'Description: ${req['description']}',
                        style: TextStyle(fontSize: fontSize),
                      ),
                      SizedBox(height: padding),
                      Text(
                        'Date: ${req['date']}',
                        style: TextStyle(fontSize: fontSize),
                      ),
                      SizedBox(height: padding),
                      Row(
                        children: [
                          Text(
                            'Status: ',
                            style: TextStyle(fontSize: fontSize),
                          ),
                          _buildStatusTag(req['status'], isSmallScreen),
                        ],
                      ),
                      if (req['document'] != null) ...[
                        SizedBox(height: padding),
                        InkWell(
                          onTap: () {
                            if (req['file'] != null) {
                              showDialog(
                                context: context,
                                builder: (_) => Dialog(child: Image.file(req['file'])),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('File not available'),
                                ),
                              );
                            }
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.attachment,
                                size: fontSize * 0.9,
                              ),
                              SizedBox(width: padding * 0.7),
                              Expanded(
                                child: Text(
                                  req['document'],
                                  style: TextStyle(
                                    color: const Color(0xFF6f88e2),
                                    decoration: TextDecoration.underline,
                                    fontSize: fontSize * 0.85,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (req['utr'] != null) ...[
                        SizedBox(height: padding),
                        Text(
                          'UTR: ${req['utr']}',
                          style: TextStyle(fontSize: fontSize),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Close',
                      style: TextStyle(fontSize: fontSize),
                    ),
                  ),
                  if (req['status'] == 'Pending') ...[
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _requests[index]['status'] = 'Rejected';
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payment request rejected'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                      child: Text(
                        'Reject',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6f88e2),
                        padding: EdgeInsets.symmetric(
                          horizontal: padding,
                          vertical: padding * 0.8,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _requests[index]['status'] = 'Approved';
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payment request approved'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: Text(
                        'Approve',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                  ],
                  if (req['status'] == 'Approved') ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6f88e2),
                        padding: EdgeInsets.symmetric(
                          horizontal: padding,
                          vertical: padding * 0.8,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showUploadUTRDialog(req, index, screenWidth);
                      },
                      child: Text(
                        'Mark as Paid',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSize * 0.9,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showUploadUTRDialog(
    Map<String, dynamic> req,
    int index,
    double screenWidth,
  ) {
    final isSmallScreen = screenWidth < 360;
    final fontSize = isSmallScreen ? 14.0 : 16.0;
    final padding = screenWidth * 0.03;
    
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding: EdgeInsets.all(screenWidth * 0.05),
            child: Container(
              constraints: BoxConstraints(maxWidth: 500),
              child: AlertDialog(
                title: Text(
                  'Payment Confirmation',
                  style: TextStyle(fontSize: fontSize),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _utrController,
                        decoration: InputDecoration(
                          labelText: 'UTR/Reference Number *',
                          border: const OutlineInputBorder(),
                          labelStyle: TextStyle(
                            fontSize: fontSize,
                          ),
                        ),
                        style: TextStyle(fontSize: fontSize),
                      ),
                      SizedBox(height: padding),
                      Text(
                        'Upload Payment Receipt',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: fontSize,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: padding * 0.8),
                      InkWell(
                        onTap: _pickDocument,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(padding),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey, width: 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.upload_file,
                                color: const Color(0xFF6f88e2),
                                size: fontSize * 1.2,
                              ),
                              SizedBox(width: padding),
                              Expanded(
                                child: Text(
                                  _selectedFile?.path.split('/').last ??
                                      'Tap to upload receipt (PDF/Image)',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: fontSize * 0.85,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_selectedFile != null)
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: fontSize * 0.9,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedFile = null;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(fontSize: fontSize),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6f88e2),
                      padding: EdgeInsets.symmetric(
                        horizontal: padding,
                        vertical: padding * 0.8,
                      ),
                    ),
                    onPressed: () {
                      if (_utrController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter Payment ID'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      setState(() {
                        _requests[index]['utr'] = _utrController.text;
                        _requests[index]['status'] = 'Paid';
                        if (_selectedFile != null) {
                          _requests[index]['document'] =
                              _selectedFile!.path.split('/').last;
                          _requests[index]['file'] = _selectedFile;
                        }
                      });
                      _utrController.clear();
                      _selectedFile = null;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payment marked as paid'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: Text(
                      'Confirm Payment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize * 0.85,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
   String _getCurrentSiteName() {
    if (widget.selectedSiteId == null) {
      return 'All Sites';
    }
    final site = widget.sites.firstWhere(
      (site) => site.id == widget.selectedSiteId,
      orElse: () =>
          Site(id: '', name: 'Unknown Site', companyId: ''),
    );
    return site.name;
  }
}