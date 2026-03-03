import 'package:flutter/material.dart';

import '../invoice_models.dart';

class InvoiceDetailView extends StatelessWidget {
  const InvoiceDetailView({
    super.key,
    required this.invoice,
    required this.onDownload,
    required this.onEdit,
  });

  final ClientInvoice invoice;
  final VoidCallback onDownload;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final billToRows = <Widget>[
      if (invoice.billToCompany.trim().isNotEmpty)
        _detailLine('Company', invoice.billToCompany),
      if (invoice.billToEmail.trim().isNotEmpty)
        _detailLine('Email', invoice.billToEmail),
      if (invoice.billToAddress.trim().isNotEmpty)
        _detailLine('Address', invoice.billToAddress),
      if (invoice.billToPhone.trim().isNotEmpty)
        _detailLine('Phone', invoice.billToPhone),
    ];

    final invoiceDateRows = <Widget>[
      if (invoice.invoiceNumber.trim().isNotEmpty)
        _detailLine('Invoice Number', invoice.invoiceNumber),
      if (invoice.invoiceDate.trim().isNotEmpty)
        _detailLine('Invoice Date', invoice.invoiceDate),
      if (invoice.dueDate.trim().isNotEmpty)
        _detailLine('Due Date', invoice.dueDate),
    ];

    final accountRows = <Widget>[
      if (invoice.bankName.trim().isNotEmpty)
        _detailLine('Bank Name', invoice.bankName),
      if (invoice.bankAccountName.trim().isNotEmpty)
        _detailLine('Account Name', invoice.bankAccountName),
      if (invoice.accountNumber.trim().isNotEmpty)
        _detailLine('Account Number', invoice.accountNumber),
      if (invoice.sortCode.trim().isNotEmpty)
        _detailLine('Sort Code', invoice.sortCode),
      if (invoice.paymentMethod.trim().isNotEmpty)
        _detailLine('Payment Method', invoice.paymentMethod),
      if (invoice.paymentEmail.trim().isNotEmpty)
        _detailLine('Payment Email', invoice.paymentEmail),
    ];

    final totalRows = <Widget>[
      if (invoice.subtotal != 0)
        _detailLine('Subtotal', invoice.subtotal.toStringAsFixed(2)),
      if (invoice.vatAmount != 0)
        _detailLine('VAT', invoice.vatAmount.toStringAsFixed(2)),
      if (invoice.totalAmount != 0)
        _detailLine('Total', invoice.totalAmount.toStringAsFixed(2)),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  invoice.invoiceNumber.isEmpty
                      ? 'Invoice ${invoice.id}'
                      : 'Invoice ${invoice.invoiceNumber}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Download PDF',
                onPressed: onDownload,
                icon: const Icon(Icons.picture_as_pdf),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: onEdit,
                icon: const Icon(Icons.edit),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (billToRows.isNotEmpty)
            _sectionCard(
              title: 'Bill To',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: billToRows,
              ),
            ),
          if (billToRows.isNotEmpty) const SizedBox(height: 12),
          if (invoiceDateRows.isNotEmpty)
            _sectionCard(
              title: 'Invoice Dates',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: invoiceDateRows,
              ),
            ),
          if (invoiceDateRows.isNotEmpty) const SizedBox(height: 12),
          if (invoice.services.isNotEmpty)
            _sectionCard(
              title: 'Services Details',
              child: Column(
                children: [
                  for (final service in invoice.services)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (service.item.trim().isNotEmpty)
                            Text(
                              service.item,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (service.description.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(service.description),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            'Qty: ${service.quantity} • Rate: ${service.rate} • Time: ${service.time} • Amount: ${service.totalAmount.toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (invoice.services.isNotEmpty) const SizedBox(height: 12),
          if (accountRows.isNotEmpty)
            _sectionCard(
              title: 'Account Details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: accountRows,
              ),
            ),
          if (accountRows.isNotEmpty) const SizedBox(height: 12),
          if (totalRows.isNotEmpty)
            _sectionCard(
              title: 'Totals',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: totalRows,
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('$label: ${value.trim()}'),
    );
  }
}
