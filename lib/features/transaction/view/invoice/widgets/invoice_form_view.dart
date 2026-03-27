import 'package:flutter/material.dart';

import '../../../../../data/model/transaction_category.dart';
import '../../../../../data/model/invoice_models.dart';

class InvoiceFormView extends StatelessWidget {
  const InvoiceFormView({
    super.key,
    required this.formKey,
    required this.isEditMode,
    required this.saving,
    required this.billToCompanyController,
    required this.billToEmailController,
    required this.billToAddressController,
    required this.billToPhoneController,
    required this.invoiceNumberController,
    required this.invoiceDateController,
    required this.dueDateController,
    required this.bankNameController,
    required this.bankAccountNameController,
    required this.accountNumberController,
    required this.sortCodeController,
    required this.paymentMethodController,
    required this.paymentEmailController,
    required this.vatAmountController,
    required this.serviceForms,
    required this.subtotal,
    required this.total,
    required this.transactionTypes,
    required this.selectedTransactionType,
    required this.onTransactionTypeChanged,
    required this.transactionCategories,
    required this.selectedTransactionCategoryId,
    required this.onTransactionCategoryChanged,
    required this.onPickInvoiceDate,
    required this.onPickDueDate,
    required this.onAddServiceLine,
    required this.onRemoveServiceLine,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final bool isEditMode;
  final bool saving;

  final TextEditingController billToCompanyController;
  final TextEditingController billToEmailController;
  final TextEditingController billToAddressController;
  final TextEditingController billToPhoneController;
  final TextEditingController invoiceNumberController;
  final TextEditingController invoiceDateController;
  final TextEditingController dueDateController;
  final TextEditingController bankNameController;
  final TextEditingController bankAccountNameController;
  final TextEditingController accountNumberController;
  final TextEditingController sortCodeController;
  final TextEditingController paymentMethodController;
  final TextEditingController paymentEmailController;
  final TextEditingController vatAmountController;

  final List<InvoiceServiceLineForm> serviceForms;
  final double subtotal;
  final double total;
  final List<String> transactionTypes;
  final String selectedTransactionType;
  final ValueChanged<String?> onTransactionTypeChanged;
  final List<TransactionCategory> transactionCategories;
  final String? selectedTransactionCategoryId;
  final ValueChanged<String?> onTransactionCategoryChanged;

  final VoidCallback onPickInvoiceDate;
  final VoidCallback onPickDueDate;
  final VoidCallback onAddServiceLine;
  final ValueChanged<int> onRemoveServiceLine;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionCard(
              title: 'Bill To Info',
              child: Column(
                children: [
                  _buildTextField(
                    controller: billToCompanyController,
                    label: 'Client Company *',
                    validator: _requiredValidator('Client company is required'),
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: billToAddressController,
                    label: 'Client Address *',
                    validator: _requiredValidator('Client address is required'),
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: billToEmailController,
                    label: 'Client Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: billToPhoneController,
                    label: 'Client Phone',
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Invoice Date Table',
              child: Column(
                children: [
                  _buildTextField(
                    controller: invoiceNumberController,
                    label: 'Invoice Number *',
                    validator: _requiredValidator('Invoice number is required'),
                  ),
                  const SizedBox(height: 10),
                  _buildDateField(
                    controller: invoiceDateController,
                    label: 'Invoice Date *',
                    onTap: onPickInvoiceDate,
                  ),
                  const SizedBox(height: 10),
                  _buildDateField(
                    controller: dueDateController,
                    label: 'Due Date *',
                    onTap: onPickDueDate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Transaction Mapping',
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedTransactionType,
                    decoration: const InputDecoration(
                      labelText: 'Transaction Type *',
                      border: OutlineInputBorder(),
                    ),
                    items: transactionTypes
                        .map(
                          (type) => DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          ),
                        )
                        .toList(),
                    onChanged: onTransactionTypeChanged,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Select transaction type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: transactionCategories.isEmpty
                        ? null
                        : selectedTransactionCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Transaction Category *',
                      border: OutlineInputBorder(),
                    ),
                    items: transactionCategories
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: transactionCategories.isEmpty
                        ? null
                        : onTransactionCategoryChanged,
                    validator: (_) {
                      if (transactionCategories.isEmpty) {
                        return 'No transaction categories available';
                      }
                      if ((selectedTransactionCategoryId ?? '')
                          .trim()
                          .isEmpty) {
                        return 'Select transaction category';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Services Details',
              trailing: TextButton.icon(
                onPressed: onAddServiceLine,
                icon: const Icon(Icons.add),
                label: const Text('Add Line'),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < serviceForms.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildServiceLineCard(serviceForms[i], i),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Account Details',
              child: Column(
                children: [
                  _buildTextField(
                    controller: bankNameController,
                    label: 'Bank Name',
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: bankAccountNameController,
                    label: 'Bank Account Name',
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: accountNumberController,
                    label: 'Account Number',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: sortCodeController,
                    label: 'Sort Code',
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: paymentMethodController,
                    label: 'Payment Method',
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: paymentEmailController,
                    label: 'Payment Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Totals',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailLine('Subtotal', subtotal.toStringAsFixed(2)),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: vatAmountController,
                    label: 'VAT Amount',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _detailLine('Total', total.toStringAsFixed(2)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: saving ? null : onSubmit,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(isEditMode ? 'Update Invoice' : 'Create Invoice'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceLineCard(InvoiceServiceLineForm line, int index) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Line ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: () => onRemoveServiceLine(index),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          _buildTextField(controller: line.itemController, label: 'Item *'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: line.descriptionController,
            label: 'Description',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: line.quantityController,
                  label: 'Quantity *',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  controller: line.rateController,
                  label: 'Rate *',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: line.timeController,
                  label: 'Time(hrs)',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: line.total.toStringAsFixed(2),
                  ),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Total Amount',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    final shown = value.trim().isEmpty ? '-' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('$label: $shown'),
    );
  }

  String? Function(String?) _requiredValidator(String message) {
    return (value) {
      if (value == null || value.trim().isEmpty) return message;
      return null;
    };
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
      ).copyWith(labelText: label),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      validator: _requiredValidator('$label is required'),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      onTap: onTap,
    );
  }
}
