import 'package:flutter/material.dart';

import '../../core/config/frappe_config.dart';

class InvoiceServiceLineForm {
  InvoiceServiceLineForm({
    String item = '',
    String description = '',
    String quantity = '1',
    String rate = '',
    String time = '',
  }) : itemController = TextEditingController(text: item),
       descriptionController = TextEditingController(text: description),
       quantityController = TextEditingController(text: quantity),
       rateController = TextEditingController(text: rate),
       timeController = TextEditingController(text: time);

  final TextEditingController itemController;
  final TextEditingController descriptionController;
  final TextEditingController quantityController;
  final TextEditingController rateController;
  final TextEditingController timeController;

  double get quantity => double.tryParse(quantityController.text.trim()) ?? 0;
  double get rate => double.tryParse(rateController.text.trim()) ?? 0;
  double get timeValue {
    final raw = timeController.text.trim();
    final direct = double.tryParse(raw);
    if (direct != null) return direct;

    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(raw);
    if (match == null) return 0;
    return double.tryParse(match.group(1) ?? '') ?? 0;
  }

  double get total => timeValue * rate;

  Map<String, dynamic> toPayload() {
    return {
      FrappeConfig.clientInvoiceServiceItemField: itemController.text.trim(),
      FrappeConfig.clientInvoiceServiceDescriptionField: descriptionController
          .text
          .trim(),
      FrappeConfig.clientInvoiceServiceQuantityField: quantity,
      FrappeConfig.clientInvoiceServiceRateField: rate,
      FrappeConfig.clientInvoiceServiceTimeField: timeController.text.trim(),
      FrappeConfig.clientInvoiceServiceTotalAmountField: total,
    };
  }

  void dispose() {
    itemController.dispose();
    descriptionController.dispose();
    quantityController.dispose();
    rateController.dispose();
    timeController.dispose();
  }
}

class ClientInvoice {
  ClientInvoice({
    required this.id,
    this.creation,
    this.invoiceNumber = '',
    this.invoiceDate = '',
    this.dueDate = '',
    this.billToCompany = '',
    this.billToEmail = '',
    this.billToAddress = '',
    this.billToPhone = '',
    this.services = const [],
    this.subtotal = 0,
    this.vatAmount = 0,
    this.totalAmount = 0,
    this.bankName = '',
    this.bankAccountName = '',
    this.accountNumber = '',
    this.sortCode = '',
    this.paymentMethod = '',
    this.paymentEmail = '',
  });

  final String id;
  final DateTime? creation;
  final String invoiceNumber;
  final String invoiceDate;
  final String dueDate;
  final String billToCompany;
  final String billToEmail;
  final String billToAddress;
  final String billToPhone;
  final List<ServiceLine> services;
  final double subtotal;
  final double vatAmount;
  final double totalAmount;
  final String bankName;
  final String bankAccountName;
  final String accountNumber;
  final String sortCode;
  final String paymentMethod;
  final String paymentEmail;

  factory ClientInvoice.fromListRow(Map<String, dynamic> data) {
    return ClientInvoice(
      id: data['name']?.toString() ?? '',
      creation: _parseDate(data['creation']),
      invoiceNumber: data['invoice_number']?.toString() ?? '',
    );
  }

  factory ClientInvoice.fromDoc(Map<String, dynamic> data) {
    final invoiceDates = _parseInvoiceDates(
      data[FrappeConfig.clientInvoiceDateTableField],
    );
    final services = _parseServices(
      data[FrappeConfig.clientInvoiceServicesTableField],
    );
    final subtotal = _toDouble(data[FrappeConfig.clientInvoiceSubtotalField]);
    final vatAmount = _toDouble(data[FrappeConfig.clientInvoiceVatAmountField]);
    final computedFromServices = services.fold<double>(
      0,
      (sum, line) => sum + line.totalAmount,
    );
    final resolvedSubtotal = subtotal > 0 ? subtotal : computedFromServices;
    final totalAmount = _toDouble(
      data[FrappeConfig.clientInvoiceTotalAmountField],
    );
    final resolvedTotal = totalAmount > 0
        ? totalAmount
        : resolvedSubtotal + vatAmount;

    String getDateValue(String key, {int? fallbackIndex}) {
      final lower = key.toLowerCase();
      final row = invoiceDates.firstWhere(
        (entry) =>
            entry.name.toLowerCase().contains(lower) &&
            entry.value.trim().isNotEmpty,
        orElse: () => const InvoiceDateEntry('', ''),
      );
      if (row.value.trim().isNotEmpty) return row.value;

      if (fallbackIndex != null &&
          fallbackIndex >= 0 &&
          fallbackIndex < invoiceDates.length) {
        return invoiceDates[fallbackIndex].value;
      }
      return '';
    }

    return ClientInvoice(
      id: data['name']?.toString() ?? '',
      creation: _parseDate(data['creation']),
      invoiceNumber: getDateValue('number', fallbackIndex: 0).isNotEmpty
          ? getDateValue('number', fallbackIndex: 0)
          : data['invoice_number']?.toString() ?? '',
      invoiceDate: getDateValue('invoice date', fallbackIndex: 1).isNotEmpty
          ? getDateValue('invoice date', fallbackIndex: 1)
          : data['invoice_date']?.toString() ?? '',
      dueDate: getDateValue('due date', fallbackIndex: 2).isNotEmpty
          ? getDateValue('due date', fallbackIndex: 2)
          : data['due_date']?.toString() ?? '',
      billToCompany:
          data[FrappeConfig.clientInvoiceBillToCompanyField]?.toString() ?? '',
      billToEmail:
          data[FrappeConfig.clientInvoiceBillToEmailField]?.toString() ?? '',
      billToAddress:
          data[FrappeConfig.clientInvoiceBillToAddressField]?.toString() ?? '',
      billToPhone:
          data[FrappeConfig.clientInvoiceBillToPhoneField]?.toString() ?? '',
      services: services,
      subtotal: resolvedSubtotal,
      vatAmount: vatAmount,
      totalAmount: resolvedTotal,
      bankName: data[FrappeConfig.clientInvoiceBankNameField]?.toString() ?? '',
      bankAccountName:
          data[FrappeConfig.clientInvoiceBankAccountNameField]?.toString() ??
          '',
      accountNumber:
          data[FrappeConfig.clientInvoiceAccountNumberField]?.toString() ?? '',
      sortCode: data[FrappeConfig.clientInvoiceSortCodeField]?.toString() ?? '',
      paymentMethod:
          data[FrappeConfig.clientInvoicePaymentMethodField]?.toString() ?? '',
      paymentEmail:
          data[FrappeConfig.clientInvoicePaymentEmailField]?.toString() ?? '',
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<InvoiceDateEntry> _parseInvoiceDates(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map(
          (row) =>
              InvoiceDateEntry.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  static List<ServiceLine> _parseServices(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map(
          (row) => ServiceLine.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }
}

class InvoiceDateEntry {
  const InvoiceDateEntry(this.name, this.value);

  final String name;
  final String value;

  factory InvoiceDateEntry.fromMap(Map<String, dynamic> data) {
    String resolveName() {
      final direct =
          data[FrappeConfig.clientInvoiceDateEntryNameField]?.toString() ?? '';
      if (direct.trim().isNotEmpty) return direct;

      final label = data['label']?.toString() ?? '';
      if (label.trim().isNotEmpty) return label;

      final excludedKeys = <String>{
        'doctype',
        'name',
        'owner',
        'creation',
        'modified',
        'modified_by',
        'docstatus',
        'idx',
        'parent',
        'parentfield',
        'parenttype',
        FrappeConfig.clientInvoiceDateEntryValueField,
      };

      for (final entry in data.entries) {
        if (excludedKeys.contains(entry.key)) continue;
        final value = entry.value?.toString() ?? '';
        if (value.trim().isNotEmpty) return value;
      }
      return '';
    }

    final name = resolveName();
    final value =
        data[FrappeConfig.clientInvoiceDateEntryValueField]?.toString() ?? '';
    return InvoiceDateEntry(name, value);
  }
}

class ServiceLine {
  const ServiceLine({
    required this.item,
    required this.description,
    required this.quantity,
    required this.rate,
    required this.time,
    required this.totalAmount,
  });

  final String item;
  final String description;
  final double quantity;
  final double rate;
  final String time;
  final double totalAmount;

  factory ServiceLine.fromMap(Map<String, dynamic> data) {
    double toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    double parseTimeValue(dynamic value) {
      final raw = value?.toString().trim() ?? '';
      final direct = double.tryParse(raw);
      if (direct != null) return direct;

      final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(raw);
      if (match == null) return 0;
      return double.tryParse(match.group(1) ?? '') ?? 0;
    }

    final rate = toDouble(data[FrappeConfig.clientInvoiceServiceRateField]);
    final timeRaw =
        data[FrappeConfig.clientInvoiceServiceTimeField]?.toString() ?? '';
    final timeValue = parseTimeValue(timeRaw);

    return ServiceLine(
      item: data[FrappeConfig.clientInvoiceServiceItemField]?.toString() ?? '',
      description:
          data[FrappeConfig.clientInvoiceServiceDescriptionField]?.toString() ??
          '',
      quantity: toDouble(data[FrappeConfig.clientInvoiceServiceQuantityField]),
      rate: rate,
      time: timeRaw,
      totalAmount: rate * timeValue,
    );
  }
}
