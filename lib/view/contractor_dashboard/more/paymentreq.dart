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
          title: Text(
            'Payment Requests - ${widget.siteName}',
            style: TextStyle(color: Colors.white),
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
                    Icon(Icons.payment, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      "No payment requests yet",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _requests.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final req = _requests[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            req['status'],
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.payment,
                          color: _getStatusColor(req['status']),
                        ),
                      ),
                      title: Text(
                        '₹${req['amount'].toStringAsFixed(2)} - ${req['category']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(req['description']),
                          const SizedBox(height: 4),
                          Text(
                            'Date: ${req['date']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatusTag(req['status']),
                          if (req['document'] != null)
                            const Icon(Icons.attachment, size: 18),
                        ],
                      ),
                      onTap: () => _showDetailDialog(req, index),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddRequestDialog,
          backgroundColor: const Color(0xFF6f88e2),
          child: const Icon(Icons.add, color: Colors.white),
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

  Widget _buildStatusTag(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 12,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
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
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.payment,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'New Payment Request',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Form content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Selection
                        _buildSectionTitle('Category'),
                        const SizedBox(height: 12),
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
                                      size: 20,
                                      color: const Color(0xFF6f88e2),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(cat),
                                  ],
                                ),
                              );
                            }).toList(),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => _selectedCategory = val);
                              }
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Amount
                        _buildSectionTitle('Amount'),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            color: Colors.grey.shade50,
                          ),
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(
                                Icons.currency_rupee,
                                color: Color(0xFF6f88e2),
                              ),
                              hintText: 'Enter amount',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Description
                        _buildSectionTitle('Description'),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            color: Colors.grey.shade50,
                          ),
                          child: TextField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(bottom: 40),
                                child: Icon(
                                  Icons.description,
                                  color: Color(0xFF6f88e2),
                                ),
                              ),
                              hintText: 'Enter description...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Document Upload
                        _buildSectionTitle(
                          'Invoice/Payment Proof',
                          isRequired: true,
                        ),
                        const SizedBox(height: 12),
                        _buildEnhancedDocumentUploadField(setModalState),

                        const SizedBox(height: 32),

                        // Submit Button
                        Container(
                          width: double.infinity,
                          height: 56,
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
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text(
                                      'Submit Request',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
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

  Widget _buildSectionTitle(String title, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2d3748),
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

  Widget _buildEnhancedDocumentUploadField(StateSetter setModalState) {
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
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (_selectedFile == null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6f88e2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      size: 32,
                      color: _showUploadError
                          ? Colors.red
                          : const Color(0xFF6f88e2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Upload Document',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _showUploadError
                          ? Colors.red
                          : const Color(0xFF2d3748),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PDF or Image (JPG, PNG)',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6f88e2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.insert_drive_file,
                          color: Color(0xFF6f88e2),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFile!.path.split('/').last,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2d3748),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to change file',
                              style: TextStyle(
                                fontSize: 12,
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
                        icon: Icon(Icons.close, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
                if (_isUploading) ...[
                  const SizedBox(height: 16),
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

  void _showDetailDialog(Map<String, dynamic> req, int index) {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'Payment Request - ₹${req['amount'].toStringAsFixed(2)}',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Category: ${req['category']}'),
                  const SizedBox(height: 8),
                  Text('Description: ${req['description']}'),
                  const SizedBox(height: 8),
                  Text('Date: ${req['date']}'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Status: '),
                      _buildStatusTag(req['status']),
                    ],
                  ),

                  if (req['document'] != null) ...[
                    const SizedBox(height: 8),
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
                            SnackBar(content: Text('File not available')),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.attachment, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            req['document'],
                            style: TextStyle(
                              color: const Color(0xFF6f88e2),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (req['utr'] != null) ...[
                    const SizedBox(height: 8),
                    Text('UTR: ${req['utr']}'),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
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
                  child: const Text(
                    'Reject',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6f88e2),
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
                  child: const Text(
                    'Approve',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
              if (req['status'] == 'Approved') ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6f88e2),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showUploadUTRDialog(req, index);
                  },
                  child: const Text(
                    'Mark as Paid',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showUploadUTRDialog(Map<String, dynamic> req, int index) {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Payment Confirmation'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _utrController,
                    decoration: const InputDecoration(
                      labelText: 'UTR/Reference Number *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Upload Payment Receipt one more time',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDocument,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.upload_file,
                            color: const Color(0xFF6f88e2),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _selectedFile?.path.split('/').last ??
                                  'Tap to upload receipt (PDF/Image)',
                              style: TextStyle(color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_selectedFile != null)
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
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
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6f88e2),
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
                child: const Text(
                  'Confirm Payment',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
