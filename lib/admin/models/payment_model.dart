// payment_model.dart
class Payment {
  int? id;
  String? paymentNumber;
  int? supplierId;
  int? purchaseInvoiceId;
  int? siteId;
  String? paymentDate;
  String? amount;
  String? paymentType;
  String? mode;
  String? referenceNumber;
  int? createdBy;
  int? workspaceId;
  String? notes;
  String? paymentProofFile;
  String? createdAt;
  String? updatedAt;
  Supplier? supplier;
  Invoice? invoice;
  Site? site;
  double? remainingAmount;
  Creator? creator;

  Payment({
    this.id,
    this.paymentNumber,
    this.supplierId,
    this.purchaseInvoiceId,
    this.siteId,
    this.paymentDate,
    this.amount,
    this.paymentType,
    this.mode,
    this.referenceNumber,
    this.createdBy,
    this.workspaceId,
    this.notes,
    this.paymentProofFile,
    this.createdAt,
    this.updatedAt,
    this.supplier,
    this.invoice,
    this.site,
    this.remainingAmount,
    this.creator,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return Payment(
      id: _parseInt(json['id']),
      paymentNumber: json['payment_number'],
      supplierId: _parseInt(json['supplier_id']),
      purchaseInvoiceId: _parseInt(json['purchase_invoice_id']),
      siteId: _parseInt(json['site_id']),
      paymentDate: json['payment_date'],
      amount: json['amount'],
      paymentType: json['payment_type'],
      mode: json['mode'],
      referenceNumber: json['reference_number'],
      createdBy: _parseInt(json['created_by']),
      workspaceId: _parseInt(json['workspace_id']),
      notes: json['notes'],
      paymentProofFile: json['payment_proff_file'] ?? json['payment_proof_file'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      supplier: json['supplier'] != null ? Supplier.fromJson(json['supplier']) : null,
      invoice: json['invoice'] != null ? Invoice.fromJson(json['invoice']) : null,
      site: json['site'] != null ? Site.fromJson(json['site']) : null,
      remainingAmount: json['remaining_amount'] != null 
          ? double.tryParse(json['remaining_amount'].toString()) 
          : 0.0,
      creator: json['creator'] != null ? Creator.fromJson(json['creator']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_number': paymentNumber,
      'supplier_id': supplierId,
      'purchase_invoice_id': purchaseInvoiceId,
      'site_id': siteId,
      'payment_date': paymentDate,
      'amount': amount,
      'payment_type': paymentType,
      'mode': mode,
      'reference_number': referenceNumber,
      'created_by': createdBy,
      'workspace_id': workspaceId,
      'notes': notes,
      'payment_proof_file': paymentProofFile,
    };
  }
}

class Supplier {
  int? id;
  String? name;

  Supplier({
    this.id,
    this.name,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: int.tryParse(json['id']?.toString() ?? ''),
      name: json['name']?.toString(),
    );
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: int.tryParse(map['id'].toString()),
      name: map['name'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Invoice {
  int? id;
  String? invoiceNumber;
  double? remainingAmount;
  Creator? creator;

  Invoice({
    this.id,
    this.invoiceNumber,
    this.remainingAmount,
    this.creator,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: int.tryParse(json['id']?.toString() ?? ''),
      invoiceNumber: json['invoice_number']?.toString(),
      remainingAmount: json['remaining_amount'] != null 
          ? double.tryParse(json['remaining_amount'].toString()) 
          : 0.0,
      creator: json['creator'] != null ? Creator.fromJson(json['creator']) : null,
    );
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: int.tryParse(map['id'].toString()),
      invoiceNumber: map['invoice_number']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
    };
  }
}

class Site {
  int? id;
  String? name;

  Site({
    this.id,
    this.name,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: int.tryParse(json['id']?.toString() ?? ''),
      name: json['name']?.toString(),
    );
  }

  factory Site.fromMap(Map<String, dynamic> map) {
    return Site(
      id: int.tryParse(map['id'].toString()),
      name: map['name'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

// Updated DropdownData class
class DropdownData {
  Map<String, Supplier>? suppliers;
  Map<String, Invoice>? invoices;
  List<Site>? sites;
  String? nextPaymentNumber;
  dynamic customFields;

  DropdownData({
    this.suppliers,
    this.invoices,
    this.sites,
    this.nextPaymentNumber,
    this.customFields,
  });

  factory DropdownData.fromJson(Map<String, dynamic> json) {
    print('Parsing dropdown JSON: ${json.keys}');
    
    // Parse suppliers - Handle map format from API
    Map<String, Supplier> suppliers = {};
    if (json['suppliers'] != null) {
      print('Suppliers data type: ${json['suppliers'].runtimeType}');
      print('Suppliers data: ${json['suppliers']}');
      
      if (json['suppliers'] is Map) {
        json['suppliers'].forEach((key, value) {
          try {
            // Key is ID, value is name (e.g., "2": "Big Materials 2")
            if (value is String) {
              suppliers[key.toString()] = Supplier(
                id: int.tryParse(key.toString()),
                name: value.toString(),
              );
            } else if (value is Map) {
              // If value is a map with id and name
              suppliers[key.toString()] = Supplier(
                id: value['id'] != null ? int.tryParse(value['id'].toString()) : int.tryParse(key.toString()),
                name: value['name']?.toString() ?? value.toString(),
              );
            }
          } catch (e) {
            print('Error parsing supplier $key: $e');
            suppliers[key.toString()] = Supplier(
              id: int.tryParse(key.toString()),
              name: value.toString(),
            );
          }
        });
      } else if (json['suppliers'] is List) {
        // Handle list format
        List<dynamic> supplierList = json['suppliers'];
        for (int i = 0; i < supplierList.length; i++) {
          dynamic item = supplierList[i];
          if (item is Map<String, dynamic>) {
            String key = item['id']?.toString() ?? i.toString();
            suppliers[key] = Supplier.fromJson(item);
          }
        }
      }
    }
    
    // Parse invoices - Handle map format from API
    Map<String, Invoice> invoices = {};
    if (json['invoices'] != null) {
      print('Invoices data type: ${json['invoices'].runtimeType}');
      print('Invoices data: ${json['invoices']}');
      
      if (json['invoices'] is Map) {
        json['invoices'].forEach((key, value) {
          try {
            // Key is ID, value is invoice number (e.g., "3": "INV-G608")
            invoices[key.toString()] = Invoice(
              id: int.tryParse(key.toString()),
              invoiceNumber: value.toString(),
            );
          } catch (e) {
            print('Error parsing invoice $key: $e');
          }
        });
      } else if (json['invoices'] is List) {
        List<dynamic> invoiceList = json['invoices'];
        for (int i = 0; i < invoiceList.length; i++) {
          dynamic item = invoiceList[i];
          if (item is Map<String, dynamic>) {
            String key = item['id']?.toString() ?? i.toString();
            invoices[key] = Invoice.fromJson(item);
          }
        }
      }
    }
    
    // Parse sites - Based on your API response: array of objects with id and name
    List<Site> sites = [];
    if (json['sites'] != null) {
      print('Sites data type: ${json['sites'].runtimeType}');
      print('Sites data: ${json['sites']}');
      
      if (json['sites'] is List) {
        List<dynamic> siteList = json['sites'];
        for (var item in siteList) {
          if (item is Map<String, dynamic>) {
            sites.add(Site.fromJson(item));
          } else {
            print('Unexpected site item type: ${item.runtimeType}');
          }
        }
      } else if (json['sites'] is Map) {
        // Handle if sites is a map instead of array
        json['sites'].forEach((key, value) {
          try {
            if (value is Map<String, dynamic>) {
              sites.add(Site.fromJson(value));
            } else {
              sites.add(Site(
                id: int.tryParse(key.toString()),
                name: value.toString(),
              ));
            }
          } catch (e) {
            print('Error parsing site $key: $e');
          }
        });
      }
    }
    
    print('Parsed ${suppliers.length} suppliers, ${invoices.length} invoices, ${sites.length} sites');
    
    return DropdownData(
      suppliers: suppliers.isNotEmpty ? suppliers : null,
      invoices: invoices.isNotEmpty ? invoices : null,
      sites: sites.isNotEmpty ? sites : null,
      nextPaymentNumber: json['nextPaymentNumber']?.toString(),
      customFields: json['customfields'] ?? json['customFields'],
    );
  }
}

class PaymentFormData {
  String? paymentNumber;
  int? createdBy;
  int? workspaceId;
  int? supplierId;
  int? purchaseInvoiceId;
  int? siteId;
  String? paymentDate;
  String? amount;
  String? paymentType;
  String? mode;
  String? referenceNumber;
  String? notes;
  String? paymentProofFile;

  PaymentFormData({
    this.paymentNumber,
    this.createdBy,
    this.workspaceId,
    this.supplierId,
    this.purchaseInvoiceId,
    this.siteId,
    this.paymentDate,
    this.amount,
    this.paymentType,
    this.mode,
    this.referenceNumber,
    this.notes,
    this.paymentProofFile,
  });

  Map<String, dynamic> toJson() {
    return {
      if (paymentNumber != null) 'payment_number': paymentNumber,
      'created_by': createdBy,
      'workspace_id': workspaceId,
      'supplier_id': supplierId,
      'purchase_invoice_id': purchaseInvoiceId,
      'site_id': siteId,
      'payment_date': paymentDate,
      'amount': amount,
      'payment_type': paymentType,
      'mode': mode,
      'reference_number': referenceNumber,
      'notes': notes,
      'payment_proof_file': paymentProofFile,
      'payment_proff_file': paymentProofFile, // Backend expects this typo
    };
  }
}

class Creator {
  int? id;
  String? name;

  Creator({
    this.id,
    this.name,
  });

  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator(
      id: int.tryParse(json['id']?.toString() ?? ''),
      name: json['name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}