import 'dart:convert';
import 'package:ecoteam_app/admin/models/payment_model.dart';
import 'package:http/http.dart' as http;

class PaymentService {
  static const String baseUrl = 'https://sitepilot.easy2it.in';
  
  // Fetch all payments
  static Future<List<Payment>> getPayments() async {
    try {
      print('Fetching payments from: $baseUrl/api/payments');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/payments'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('Payments API Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        
        if (responseData is List) {
          final List<dynamic> jsonList = responseData;
          print('Found ${jsonList.length} payments');
          
          List<Payment> payments = [];
          for (var json in jsonList) {
            try {
              payments.add(Payment.fromJson(json));
            } catch (e) {
              print('Error parsing payment: $e');
            }
          }
          return payments;
        } else if (responseData is Map && responseData.containsKey('data')) {
          // Handle response with 'data' key
          final List<dynamic> jsonList = responseData['data'] ?? [];
          print('Found ${jsonList.length} payments in data key');
          
          List<Payment> payments = [];
          for (var json in jsonList) {
            try {
              payments.add(Payment.fromJson(json));
            } catch (e) {
              print('Error parsing payment: $e');
            }
          }
          return payments;
        } else {
          print('Unexpected response format: $responseData');
          return [];
        }
      } else {
        print('Failed to load payments: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load payments: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching payments: $e');
      throw Exception('Error fetching payments: $e');
    }
  }

  // Fetch dropdown data for forms - including sites, suppliers, invoices
  static Future<DropdownData> getDropdownData({int? siteId, int? workspaceId}) async {
    try {
      print('Fetching dropdown data for workspace: $workspaceId, site: $siteId');
      
      final Map<String, dynamic> requestBody = {};
      
      // Add site_id if provided
      if (siteId != null && siteId > 0) {
        requestBody['site_id'] = siteId;
      }
      
      // Add workspace_id if provided
      if (workspaceId != null && workspaceId > 0) {
        requestBody['workspace_id'] = workspaceId;
      }
      
      print('Request body for dropdown: $requestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/payments/create-data'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Dropdown API Status: ${response.statusCode}');
      print('Dropdown API Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        print('Dropdown API Response keys: ${jsonData.keys}');
        
        // Debug log the structure
        if (jsonData.containsKey('suppliers')) {
          print('Suppliers data type: ${jsonData['suppliers'].runtimeType}');
          print('Suppliers data: ${jsonData['suppliers']}');
        }
        
        if (jsonData.containsKey('sites')) {
          print('Sites data type: ${jsonData['sites'].runtimeType}');
          print('Sites data: ${jsonData['sites']}');
        }
        
        if (jsonData.containsKey('invoices')) {
          print('Invoices data type: ${jsonData['invoices'].runtimeType}');
          print('Invoices data: ${jsonData['invoices']}');
        }
        
        if (jsonData.containsKey('nextPaymentNumber')) {
          print('Next Payment Number: ${jsonData['nextPaymentNumber']}');
        }
        
        // Parse using our DropdownData.fromJson method
        final dropdownData = DropdownData.fromJson(jsonData);
        print('Parsed dropdown data:');
        print('- Sites: ${dropdownData.sites?.length ?? 0}');
        print('- Suppliers: ${dropdownData.suppliers?.length ?? 0}');
        print('- Invoices: ${dropdownData.invoices?.length ?? 0}');
        
        return dropdownData;
      } else {
        print('Dropdown API Error Response: ${response.body}');
        throw Exception('Failed to load dropdown data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in getDropdownData: $e');
      throw Exception('Error fetching dropdown data: $e');
    }
  }

  // Fetch suppliers for specific site
  static Future<Map<String, Supplier>> getSuppliersBySite(int siteId, int workspaceId) async {
    try {
      print('Fetching suppliers for site ID: $siteId, workspace ID: $workspaceId');
      
      final dropdownData = await getDropdownData(
        siteId: siteId,
        workspaceId: workspaceId,
      );
      
      return dropdownData.suppliers ?? {};
    } catch (e) {
      print('Error in getSuppliersBySite: $e');
      return {};
    }
  }

  // Fetch invoices for specific supplier
  static Future<Map<String, String>> getSupplierInvoices(int supplierId) async {
    try {
      print('Fetching invoices for supplier ID: $supplierId');
      
      final url = '$baseUrl/api/ajax/get-purchase-invoice-by-supplier-id-edit?supplier_id=$supplierId';
      print('URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('Supplier invoices API Status: ${response.statusCode}');
      print('Supplier invoices API Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        Map<String, String> invoices = {};
        
        if (responseData is Map) {
          responseData.forEach((key, value) {
            if (value is String) {
              invoices[key] = value;
            } else if (value is Map && value.containsKey('invoice_number')) {
              // Handle object format
              invoices[key] = value['invoice_number'].toString();
            } else {
              invoices[key] = value.toString();
            }
          });
        } else if (responseData is List) {
          // Handle array format
          for (int i = 0; i < responseData.length; i++) {
            final item = responseData[i];
            if (item is Map && item.containsKey('id') && item.containsKey('invoice_number')) {
              invoices[item['id'].toString()] = item['invoice_number'].toString();
            }
          }
        }
        
        print('Found ${invoices.length} invoices for supplier $supplierId');
        return invoices;
      } else if (response.statusCode == 404) {
        // Handle 404 - no invoices found
        print('No invoices found for supplier $supplierId');
        return {};
      } else {
        print('Supplier invoices API Error: ${response.statusCode} - ${response.body}');
        return {};
      }
    } catch (e) {
      print('Error in getSupplierInvoices: $e');
      return {};
    }
  }

  // Get invoice details (for remaining amount)
  static Future<Invoice?> getInvoiceDetails(int invoiceId) async {
    try {
      print('Fetching invoice details for invoice ID: $invoiceId');
      
      final url = '$baseUrl/api/ajax/get-purchase-invoice-remaining-amount-by-purchase-invoice-id?purchase_invoice_id=$invoiceId';
      print('URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('Invoice details API Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        print('Invoice details: $jsonData');

        return Invoice(
          id: invoiceId,
          remainingAmount: jsonData['remaining_amount'] != null
              ? double.tryParse(jsonData['remaining_amount'].toString())
              : 0.0,
          invoiceNumber: jsonData['invoice_number']?.toString(),
        );
      } else {
        print('Invoice details API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error in getInvoiceDetails: $e');
      return null;
    }
  }

  // Create a new payment
  static Future<Payment> createPayment(PaymentFormData formData) async {
    try {
      print('Creating payment with data: ${formData.toJson()}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/payments'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(formData.toJson()),
      );

      print('Create payment API Status: ${response.statusCode}');
      print('Create payment API Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        
        // Check if response has 'data' key
        if (jsonData['data'] != null) {
          return Payment.fromJson(jsonData['data']);
        } else if (jsonData['payment'] != null) {
          return Payment.fromJson(jsonData['payment']);
        }
        return Payment.fromJson(jsonData);
      } else {
        print('Failed to create payment: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create payment: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error creating payment: $e');
      throw Exception('Error creating payment: $e');
    }
  }

  // Update existing payment
  static Future<Payment> updatePayment(int paymentId, PaymentFormData formData) async {
    try {
      print('Updating payment $paymentId with data: ${formData.toJson()}');
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/payments/$paymentId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(formData.toJson()),
      );
    
      print('Update payment API Status: ${response.statusCode}');
      print('Update payment API Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        
        if (jsonData['data'] != null) {
          return Payment.fromJson(jsonData['data']);
        }
        return Payment.fromJson(jsonData);
      } else {
        print('Failed to update payment: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to update payment: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating payment: $e');
      throw Exception('Error updating payment: $e');
    }
  }

  // Delete payment
  static Future<bool> deletePayment(int paymentId) async {
    try {
      print('Deleting payment $paymentId');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/api/payments/$paymentId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('Delete payment API Status: ${response.statusCode}');
      print('Delete payment API Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        return jsonData['success'] == true || 
               jsonData['deleted'] == true || 
               jsonData['message']?.toString().toLowerCase().contains('success') == true;
      } else {
        print('Failed to delete payment: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting payment: $e');
      return false;
    }
  }

  // Search payments
  static Future<List<Payment>> searchPayments(String query) async {
    try {
      print('Searching payments for: "$query"');
      
      final allPayments = await getPayments();
      final filtered = allPayments.where((payment) {
        final paymentNumber = payment.paymentNumber?.toLowerCase() ?? '';
        final supplierName = payment.supplier?.name?.toLowerCase() ?? '';
        final referenceNumber = payment.referenceNumber?.toLowerCase() ?? '';
        final invoiceNumber = payment.invoice?.invoiceNumber?.toLowerCase() ?? '';
        final siteName = payment.site?.name?.toLowerCase() ?? '';
        final searchLower = query.toLowerCase();
        
        return paymentNumber.contains(searchLower) ||
            supplierName.contains(searchLower) ||
            referenceNumber.contains(searchLower) ||  
            invoiceNumber.contains(searchLower) ||
            siteName.contains(searchLower);
      }).toList();
      
      print('Found ${filtered.length} payments matching "$query"');
      return filtered;
    } catch (e) {
      print('Error searching payments: $e');
      return [];
    }
  }

  // Helper method to test API connection
  static Future<bool> testConnection() async {
    try {
      print('Testing API connection to: $baseUrl');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/payments'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      print('Connection test status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}