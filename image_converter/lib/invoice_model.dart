import 'dart:convert';

class InvoiceItem {
  String description;
  int quantity;
  double unitPrice;
  // The serial/row number as actually printed on the source receipt
  // (e.g. "10", "S.No 3"). Left empty when the receipt doesn't show one.
  String serialNumber;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.serialNumber = '',
  });

  double get total => quantity * unitPrice;

  InvoiceItem clone() {
    return InvoiceItem(
      description: description,
      quantity: quantity,
      unitPrice: unitPrice,
      serialNumber: serialNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'serialNumber': serialNumber,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      description: map['description'] ?? '',
      quantity: map['quantity']?.toInt() ?? 1,
      unitPrice: map['unitPrice']?.toDouble() ?? 0.0,
      serialNumber: map['serialNumber'] ?? '',
    );
  }
}

class InvoiceModel {
  int? id; // SQLite ID
  String? imagePath; // Path to saved image
  String? createdAt; // ISO8601 string

  String vendorName;
  String vendorAddress;
  String invoiceTitle;
  String invoiceNumber;
  String date;
  String dueDate;
  String clientName;
  String clientAddress;
  List<InvoiceItem> items;
  double taxRate;
  double discount;
  String notes;

  InvoiceModel({
    this.id,
    this.imagePath,
    this.createdAt,
    required this.vendorName,
    required this.vendorAddress,
    this.invoiceTitle = 'INVOICE',
    required this.invoiceNumber,
    required this.date,
    required this.dueDate,
    required this.clientName,
    required this.clientAddress,
    required this.items,
    this.taxRate = 10.0,
    this.discount = 0.0,
    required this.notes,
  });

  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.total);
  }

  double get taxAmount {
    return subtotal * (taxRate / 100);
  }

  double get grandTotal {
    double total = subtotal + taxAmount - discount;
    return total < 0 ? 0.0 : total;
  }

  InvoiceModel clone() {
    return InvoiceModel(
      id: id,
      imagePath: imagePath,
      createdAt: createdAt,
      vendorName: vendorName,
      vendorAddress: vendorAddress,
      invoiceTitle: invoiceTitle,
      invoiceNumber: invoiceNumber,
      date: date,
      dueDate: dueDate,
      clientName: clientName,
      clientAddress: clientAddress,
      items: items.map((item) => item.clone()).toList(),
      taxRate: taxRate,
      discount: discount,
      notes: notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'createdAt': createdAt,
      'vendorName': vendorName,
      'vendorAddress': vendorAddress,
      'invoiceTitle': invoiceTitle,
      'invoiceNumber': invoiceNumber,
      'date': date,
      'dueDate': dueDate,
      'clientName': clientName,
      'clientAddress': clientAddress,
      'items': jsonEncode(items.map((x) => x.toMap()).toList()),
      'taxRate': taxRate,
      'discount': discount,
      'notes': notes,
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'],
      imagePath: map['imagePath'],
      createdAt: map['createdAt'],
      vendorName: map['vendorName'] ?? '',
      vendorAddress: map['vendorAddress'] ?? '',
      invoiceTitle: map['invoiceTitle'] ?? 'INVOICE',
      invoiceNumber: map['invoiceNumber'] ?? '',
      date: map['date'] ?? '',
      dueDate: map['dueDate'] ?? '',
      clientName: map['clientName'] ?? '',
      clientAddress: map['clientAddress'] ?? '',
      items: map['items'] != null
          ? List<InvoiceItem>.from(jsonDecode(map['items'])?.map((x) => InvoiceItem.fromMap(x)) ?? [])
          : [],
      taxRate: map['taxRate']?.toDouble() ?? 10.0,
      discount: map['discount']?.toDouble() ?? 0.0,
      notes: map['notes'] ?? '',
    );
  }
}