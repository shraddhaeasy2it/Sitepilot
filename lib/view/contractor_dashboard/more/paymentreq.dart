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
          primary: Colors.lightBlue.shade600,
          secondary: Colors.lightBlue.shade400,
        ),
      ),
      child: Scaffold(
         appBar: AppBar(
          toolbarHeight: 90,
          title: Text('Payment Requests - ${widget.siteName}',style: TextStyle(color: Colors.white),),
           iconTheme: const IconThemeData(
          color: Colors.white, // Back arrow white
        ),
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF6f88e2),
                  Color(0xFF5a73d1),
                  Color(0xFF4a63c0),
                ],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
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
          backgroundColor: const Color.fromARGB(255, 54, 134, 238),
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
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'New Payment Request',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹) *',
                    prefixIcon: Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _buildDocumentUploadField(),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 102, 135, 245),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _validateAndSubmitRequest,
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text(
                    'Submit Request',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentUploadField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Invoice/Payment Proof ',
            style: const TextStyle(fontSize: 16, color: Colors.black),
            children: const [
              TextSpan(
                text: '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDocument,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: _showUploadError ? Colors.red : Colors.grey,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.upload_file, color: Colors.lightBlue.shade600),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _selectedFile?.path.split('/').last ??
                        'Tap to upload document (PDF/Image)',
                    style: TextStyle(
                      color: _selectedFile == null ? Colors.grey : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isUploading)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                if (_selectedFile != null && !_isUploading)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() {
                        _showUploadError = true;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
        if (_showUploadError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Document proof is required',
              style: TextStyle(color: Colors.red.shade600, fontSize: 12),
            ),
          ),
      ],
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
                              color: Colors.lightBlue.shade600,
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
                    backgroundColor: Colors.lightBlue.shade600,
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
                    backgroundColor: Colors.lightBlue.shade600,
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
                            color: Colors.lightBlue.shade600,
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
                  backgroundColor: Colors.lightBlue.shade600,
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