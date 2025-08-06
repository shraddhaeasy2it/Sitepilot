import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Requests - ${widget.siteName}'),
      ),
      body: _requests.isEmpty
          ? const Center(child: Text("No payment requests yet."))
          : ListView.builder(
              itemCount: _requests.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final req = _requests[index];
                return Card(
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(Icons.payment,
                        color: _getStatusColor(req['status'])),
                    title: Text('₹${req['amount']} - ${req['category']}'),
                    subtitle: Text('${req['description']}\nDate: ${req['date']}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatusTag(req['status']),
                        if (req['utr'] != null)
                          const Icon(Icons.attach_file, size: 18),
                      ],
                    ),
                    onTap: () => _showDetailDialog(req),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRequestDialog,
        child: const Icon(Icons.add),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('New Payment Request',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                decoration: const InputDecoration(labelText: 'Category'),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (₹)'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  final amount = double.tryParse(_amountController.text);
                  final description = _descriptionController.text.trim();

                  if (amount != null && description.isNotEmpty) {
                    setState(() {
                      _requests.add({
                        'category': _selectedCategory,
                        'amount': amount,
                        'description': description,
                        'date': _getFormattedDate(),
                        'status': 'Pending',
                        'utr': null,
                      });
                    });

                    _amountController.clear();
                    _descriptionController.clear();
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.send),
                label: const Text('Submit Request'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showDetailDialog(Map<String, dynamic> req) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Payment Request - ₹${req['amount']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Category: ${req['category']}'),
            Text('Description: ${req['description']}'),
            Text('Status: ${req['status']}'),
            if (req['utr'] != null) Text('UTR: ${req['utr']}'),
          ],
        ),
        actions: [
          if (req['status'] == 'Pending') ...[
            TextButton(
              onPressed: () {
                setState(() => req['status'] = 'Rejected');
                Navigator.pop(context);
              },
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => req['status'] = 'Approved');
                Navigator.pop(context);
              },
              child: const Text('Approve'),
            ),
          ],
          if (req['status'] == 'Approved') ...[
            TextButton(
              onPressed: () {
                _showUploadUTRDialog(req);
              },
              child: const Text('Upload UTR'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showUploadUTRDialog(Map<String, dynamic> req) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Upload UTR & Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _utrController,
              decoration: const InputDecoration(labelText: 'UTR Number'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Mock document picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Document uploaded successfully!')),
                );
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload PDF/IMG'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_utrController.text.isNotEmpty) {
                setState(() {
                  req['utr'] = _utrController.text;
                  req['status'] = 'Paid';
                });
                _utrController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
