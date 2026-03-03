import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../invoice_models.dart';

class InvoiceListView extends StatelessWidget {
  const InvoiceListView({
    super.key,
    required this.invoices,
    required this.loading,
    required this.onCreate,
    required this.onOpen,
    required this.onEdit,
    required this.onDownload,
  });

  final List<ClientInvoice> invoices;
  final bool loading;
  final VoidCallback onCreate;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onEdit;
  final ValueChanged<String> onDownload;

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty && !loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No invoices found.'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Create Invoice'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: invoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final invoice = invoices[index];
        return Card(
          child: ListTile(
            onTap: () => onOpen(invoice.id),
            title: Text(
              invoice.invoiceNumber.isEmpty
                  ? 'Invoice ${invoice.id}'
                  : 'Invoice ${invoice.invoiceNumber}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              [
                if (invoice.creation != null)
                  DateFormat('dd MMM, yyyy').format(invoice.creation!),
                'Tap to view details',
              ].join(' • '),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () => onEdit(invoice.id),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Download PDF',
                  onPressed: () => onDownload(invoice.id),
                  icon: const Icon(Icons.download),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
