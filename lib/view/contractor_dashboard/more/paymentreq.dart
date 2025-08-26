import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PaymentsDetailScreen extends StatefulWidget {
  final String siteId;
  final String siteName;
  const PaymentsDetailScreen({
    super.key,
    required this.siteId,
    required this.siteName,
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
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF6f88e2),
          secondary: const Color(0xFF5a73d1),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: screenHeight * 0.1, // Responsive toolbar height
          title: RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'Payments - ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20, // keep title size bigger
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: widget.siteName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16, // smaller font size only for siteName
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
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
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
                      size: screenHeight * 0.08, // Responsive icon size
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      "No payment requests yet",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _requests.length,
                padding: EdgeInsets.all(
                  screenWidth * 0.04,
                ), // Responsive padding
                itemBuilder: (context, index) {
                  final req = _requests[index];
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: screenHeight * 0.015),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.01,
                      ),
                      leading: Container(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            req['status'],
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.payment,
                          color: _getStatusColor(req['status']),
                          size: isSmallScreen ? 20 : 24,
                        ),
                      ),
                      title: Text(
                        '₹${req['amount'].toStringAsFixed(2)} - ${req['category']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req['description'],
                            style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: screenHeight * 0.005),
                          Text(
                            'Date: ${req['date']}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 12,
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
                              size: isSmallScreen ? 16 : 18,
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
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: isSmallScreen ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: isSmallScreen ? 10 : 12,
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
      isDismissible: false,
      enableDrag: false,
      builder: (_) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isSmallScreen = screenWidth < 360;
        return StatefulBuilder(
          builder: (context, setModalState) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 0,
              left: 0,
              right: 0,
            ),
            height: screenHeight * 0.5, // Set to half screen height
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6f88e2), Color(0xFF5a73d1)],
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        width: screenWidth * 0.1,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(screenWidth * 0.03),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.payment,
                              color: Colors.white,
                              size: isSmallScreen ? 20 : 24,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.04),
                          Expanded(
                            child: Text(
                              'New Payment Request',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 18 : 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: isSmallScreen ? 20 : 24,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Form content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(screenWidth * 0.06),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Selection
                        _buildSectionTitle('Category', isSmallScreen),
                        SizedBox(height: screenHeight * 0.012),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            color: Colors.grey.shade50,
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            items: _categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Row(
                                  children: [
                                    Icon(
                                      _getCategoryIcon(cat),
                                      size: isSmallScreen ? 18 : 20,
                                      color: const Color(0xFF6f88e2),
                                    ),
                                    SizedBox(width: screenWidth * 0.03),
                                    Text(
                                      cat,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14 : 16,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04,
                                vertical: screenHeight * 0.02,
                              ),
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => _selectedCategory = val);
                              }
                            },
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.024),
                        // Amount
                        _buildSectionTitle('Amount', isSmallScreen),
                        SizedBox(height: screenHeight * 0.012),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            color: Colors.grey.shade50,
                          ),
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.currency_rupee,
                                color: const Color(0xFF6f88e2),
                                size: isSmallScreen ? 20 : 24,
                              ),
                              hintText: 'Enter amount',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04,
                                vertical: screenHeight * 0.02,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.024),
                        // Description
                        _buildSectionTitle('Description', isSmallScreen),
                        SizedBox(height: screenHeight * 0.012),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            color: Colors.grey.shade50,
                          ),
                          child: TextField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(bottom: 40),
                                child: Icon(
                                  Icons.description,
                                  color: const Color(0xFF6f88e2),
                                  size: isSmallScreen ? 20 : 24,
                                ),
                              ),
                              hintText: 'Enter description...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04,
                                vertical: screenHeight * 0.02,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.024),
                        // Document Upload
                        _buildSectionTitle(
                          'Invoice/Payment Proof',
                          isSmallScreen,
                          isRequired: true,
                        ),
                        SizedBox(height: screenHeight * 0.012),
                        _buildEnhancedDocumentUploadField(
                          setModalState,
                          isSmallScreen,
                        ),
                        SizedBox(height: screenHeight * 0.032),
                        // Submit Button
                        Container(
                          width: double.infinity,
                          height: screenHeight * 0.065,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF6f88e2), Color(0xFF5a73d1)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6f88e2).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _validateAndSubmitRequest,
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.send,
                                      color: Colors.white,
                                      size: isSmallScreen ? 20 : 24,
                                    ),
                                    SizedBox(width: screenWidth * 0.03),
                                    Text(
                                      'Submit Request',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isSmallScreen ? 14 : 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.016),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    bool isSmallScreen, {
    bool isRequired = false,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
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
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
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
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Column(
              children: [
                if (_selectedFile == null) ...[
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6f88e2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      size: isSmallScreen ? 28 : 32,
                      color: _showUploadError
                          ? Colors.red
                          : const Color(0xFF6f88e2),
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.04),
                  Text(
                    'Upload Document',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: _showUploadError
                          ? Colors.red
                          : const Color(0xFF2d3748),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  Text(
                    'PDF or Image (JPG, PNG)',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6f88e2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.insert_drive_file,
                          color: const Color(0xFF6f88e2),
                          size: isSmallScreen ? 20 : 24,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFile!.path.split('/').last,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2d3748),
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: screenWidth * 0.01),
                            Text(
                              'Tap to change file',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 12,
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
                          size: isSmallScreen ? 18 : 24,
                        ),
                      ),
                    ],
                  ),
                ],
                if (_isUploading) ...[
                  SizedBox(height: screenWidth * 0.04),
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
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding: EdgeInsets.all(
              screenWidth * 0.05,
            ), // Responsive margin
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 500, // Limit maximum width on large screens
              ),
              child: AlertDialog(
                title: Text(
                  'Payment Request - ₹${req['amount'].toStringAsFixed(2)}',
                  style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category: ${req['category']}',
                        style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                      ),
                      SizedBox(height: screenWidth * 0.03),
                      Text(
                        'Description: ${req['description']}',
                        style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                      ),
                      SizedBox(height: screenWidth * 0.03),
                      Text(
                        'Date: ${req['date']}',
                        style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                      ),
                      SizedBox(height: screenWidth * 0.03),
                      Row(
                        children: [
                          Text(
                            'Status: ',
                            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                          ),
                          _buildStatusTag(req['status'], isSmallScreen),
                        ],
                      ),
                      if (req['document'] != null) ...[
                        SizedBox(height: screenWidth * 0.03),
                        InkWell(
                          onTap: () {
                            if (req['file'] != null) {
                              showDialog(
                                context: context,
                                builder: (_) =>
                                    Dialog(child: Image.file(req['file'])),
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
                                size: isSmallScreen ? 14 : 16,
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Expanded(
                                child: Text(
                                  req['document'],
                                  style: TextStyle(
                                    color: const Color(0xFF6f88e2),
                                    decoration: TextDecoration.underline,
                                    fontSize: isSmallScreen ? 12 : 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (req['utr'] != null) ...[
                        SizedBox(height: screenWidth * 0.03),
                        Text(
                          'UTR: ${req['utr']}',
                          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
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
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
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
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6f88e2),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 8 : 12,
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
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                    ),
                  ],
                  if (req['status'] == 'Approved') ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6f88e2),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 8 : 12,
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
                          fontSize: isSmallScreen ? 12 : 14,
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
                  style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
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
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        ),
                        style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                      ),
                      SizedBox(height: screenWidth * 0.04),
                      Text(
                        'Upload Payment Receipt one more time',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenWidth * 0.03),
                      InkWell(
                        onTap: _pickDocument,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey, width: 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.upload_file,
                                color: const Color(0xFF6f88e2),
                                size: isSmallScreen ? 20 : 24,
                              ),
                              SizedBox(width: screenWidth * 0.04),
                              Expanded(
                                child: Text(
                                  _selectedFile?.path.split('/').last ??
                                      'Tap to upload receipt (PDF/Image)',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: isSmallScreen ? 12 : 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_selectedFile != null)
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: isSmallScreen ? 16 : 18,
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
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6f88e2),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 8 : 12,
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
                          _requests[index]['document'] = _selectedFile!.path
                              .split('/')
                              .last;
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
                        fontSize: isSmallScreen ? 11 : 12,
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
}