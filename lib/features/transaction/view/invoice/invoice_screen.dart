import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../../core/config/frappe_config.dart';
import '../../../../core/utils/user_friendly_error.dart';
import '../../../../data/model/transaction_category.dart';
import 'invoice_models.dart';
import 'invoice_service.dart';
import 'widgets/invoice_detail_view.dart';
import 'widgets/invoice_form_view.dart';
import 'widgets/invoice_list_view.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

enum InvoiceViewMode { list, form, detail }

class _InvoiceScreenState extends State<InvoiceScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  final _formKey = GlobalKey<FormState>();

  final _billToCompanyController = TextEditingController();
  final _billToEmailController = TextEditingController();
  final _billToAddressController = TextEditingController();
  final _billToPhoneController = TextEditingController();

  final _invoiceNumberController = TextEditingController();
  final _invoiceDateController = TextEditingController();
  final _dueDateController = TextEditingController();

  final _bankNameController = TextEditingController();
  final _bankAccountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _sortCodeController = TextEditingController();
  final _paymentMethodController = TextEditingController();
  final _paymentEmailController = TextEditingController();

  final _vatAmountController = TextEditingController(text: '0');
  final List<InvoiceServiceLineForm> _serviceForms = [];
  static const List<String> _transactionTypes = [
    'Income',
    'Expense',
    'Payment',
    'Receipt',
  ];

  String? _clientId;
  String _invoiceDateNameFieldKey =
      FrappeConfig.clientInvoiceDateEntryNameField;
  List<TransactionCategory> _transactionCategories = [];
  String _selectedTransactionType = 'Income';
  String? _selectedTransactionCategoryId;
  bool _loadingClient = false;
  bool _loadingList = false;
  bool _loadingInvoice = false;
  bool _saving = false;
  String? _error;

  InvoiceViewMode _mode = InvoiceViewMode.list;
  bool _isEditMode = false;
  String? _editingDocName;
  ClientInvoice? _selectedInvoice;
  List<ClientInvoice> _invoices = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _invoiceDateController.text = DateFormat('yyyy-MM-dd').format(now);
    _dueDateController.text = DateFormat(
      'yyyy-MM-dd',
    ).format(now.add(const Duration(days: 7)));
    _vatAmountController.addListener(_recalculateTotals);
    _addServiceRow();
    _loadClientAndInvoices();
  }

  @override
  void dispose() {
    _billToCompanyController.dispose();
    _billToEmailController.dispose();
    _billToAddressController.dispose();
    _billToPhoneController.dispose();
    _invoiceNumberController.dispose();
    _invoiceDateController.dispose();
    _dueDateController.dispose();
    _bankNameController.dispose();
    _bankAccountNameController.dispose();
    _accountNumberController.dispose();
    _sortCodeController.dispose();
    _paymentMethodController.dispose();
    _paymentEmailController.dispose();
    _vatAmountController.dispose();
    for (final line in _serviceForms) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _loadClientAndInvoices() async {
    setState(() {
      _loadingClient = true;
      _error = null;
    });

    try {
      _invoiceDateNameFieldKey = await _invoiceService
          .resolveInvoiceDateNameFieldKey();
      _transactionCategories = await _invoiceService
          .loadTransactionCategories();
      if (_transactionCategories.isNotEmpty &&
          (_selectedTransactionCategoryId == null ||
              _selectedTransactionCategoryId!.isEmpty)) {
        _selectedTransactionCategoryId = _transactionCategories.first.id;
      }
      final authState = context.read<AuthBloc>().state;
      final user = authState is Authenticated ? authState.user : null;
      final email = user?.email ?? '';
      _clientId = await _invoiceService.resolveClientIdFromEmail(email);
      await _loadInvoices();
    } catch (e) {
      _error = UserFriendlyError.message(
        e,
        fallback: 'Unable to load invoice account details right now.',
      );
    } finally {
      if (mounted) setState(() => _loadingClient = false);
    }
  }

  Future<void> _loadInvoices() async {
    if (_clientId == null || _clientId!.isEmpty) return;
    setState(() {
      _loadingList = true;
      _error = null;
    });

    try {
      _invoices = await _invoiceService.loadInvoices(_clientId!);
    } catch (e) {
      _error = UserFriendlyError.message(
        e,
        fallback: 'Unable to load invoices right now.',
      );
    } finally {
      if (mounted) setState(() => _loadingList = false);
    }
  }

  Future<void> _openDetail(String docName) async {
    setState(() {
      _loadingInvoice = true;
      _error = null;
    });
    try {
      final invoice = await _invoiceService.loadInvoiceByName(docName);
      _selectedInvoice = invoice;
      _mode = InvoiceViewMode.detail;
    } catch (e) {
      _error = UserFriendlyError.message(
        e,
        fallback: 'Unable to open this invoice right now.',
      );
    } finally {
      if (mounted) setState(() => _loadingInvoice = false);
    }
  }

  Future<void> _openEdit(String docName) async {
    setState(() {
      _loadingInvoice = true;
      _error = null;
    });
    try {
      final invoice = await _invoiceService.loadInvoiceByName(docName);
      _fillForm(invoice);
      _isEditMode = true;
      _editingDocName = invoice.id;
      _mode = InvoiceViewMode.form;
    } catch (e) {
      _error = UserFriendlyError.message(
        e,
        fallback: 'Unable to open invoice for editing right now.',
      );
    } finally {
      if (mounted) setState(() => _loadingInvoice = false);
    }
  }

  void _openCreate() {
    _resetForm();
    _isEditMode = false;
    _editingDocName = null;
    setState(() => _mode = InvoiceViewMode.form);
  }

  void _backToList() {
    setState(() {
      _mode = InvoiceViewMode.list;
      _selectedInvoice = null;
      _loadingInvoice = false;
    });
  }

  void _resetForm() {
    _billToCompanyController.clear();
    _billToEmailController.clear();
    _billToAddressController.clear();
    _billToPhoneController.clear();
    _invoiceNumberController.clear();

    final now = DateTime.now();
    _invoiceDateController.text = DateFormat('yyyy-MM-dd').format(now);
    _dueDateController.text = DateFormat(
      'yyyy-MM-dd',
    ).format(now.add(const Duration(days: 7)));

    _bankNameController.clear();
    _bankAccountNameController.clear();
    _accountNumberController.clear();
    _sortCodeController.clear();
    _paymentMethodController.clear();
    _paymentEmailController.clear();
    _vatAmountController.text = '0';
    _selectedTransactionType = 'Income';
    _selectedTransactionCategoryId = _transactionCategories.isNotEmpty
        ? _transactionCategories.first.id
        : null;

    for (final line in _serviceForms) {
      line.dispose();
    }
    _serviceForms
      ..clear()
      ..add(_createServiceLineForm());
  }

  void _fillForm(ClientInvoice invoice) {
    _billToCompanyController.text = invoice.billToCompany;
    _billToEmailController.text = invoice.billToEmail;
    _billToAddressController.text = invoice.billToAddress;
    _billToPhoneController.text = invoice.billToPhone;
    _invoiceNumberController.text = invoice.invoiceNumber;
    _invoiceDateController.text = invoice.invoiceDate;
    _dueDateController.text = invoice.dueDate;

    _bankNameController.text = invoice.bankName;
    _bankAccountNameController.text = invoice.bankAccountName;
    _accountNumberController.text = invoice.accountNumber;
    _sortCodeController.text = invoice.sortCode;
    _paymentMethodController.text = invoice.paymentMethod;
    _paymentEmailController.text = invoice.paymentEmail;
    _vatAmountController.text = invoice.vatAmount.toStringAsFixed(2);

    for (final line in _serviceForms) {
      line.dispose();
    }
    _serviceForms
      ..clear()
      ..addAll(
        invoice.services.isEmpty
            ? [_createServiceLineForm()]
            : invoice.services
                  .map((line) => _createServiceLineForm(serviceLine: line))
                  .toList(),
      );
  }

  InvoiceServiceLineForm _createServiceLineForm({ServiceLine? serviceLine}) {
    final form = InvoiceServiceLineForm(
      item: serviceLine?.item ?? '',
      description: serviceLine?.description ?? '',
      quantity: serviceLine == null ? '1' : serviceLine.quantity.toString(),
      rate: serviceLine == null ? '' : serviceLine.rate.toString(),
      time: serviceLine?.time ?? '',
    );
    form.quantityController.addListener(_recalculateTotals);
    form.rateController.addListener(_recalculateTotals);
    form.timeController.addListener(_recalculateTotals);
    return form;
  }

  void _addServiceRow() {
    setState(() => _serviceForms.add(_createServiceLineForm()));
  }

  void _removeServiceRow(int index) {
    if (_serviceForms.length == 1) return;
    setState(() {
      _serviceForms[index].dispose();
      _serviceForms.removeAt(index);
    });
  }

  double get _subtotal =>
      _serviceForms.fold<double>(0, (sum, line) => sum + line.total);
  double get _vatAmount =>
      double.tryParse(_vatAmountController.text.trim()) ?? 0;
  double get _grandTotal => _subtotal + _vatAmount;

  void _recalculateTotals() {
    if (mounted) setState(() {});
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final initialDate = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  bool _validateServiceLines() {
    for (final line in _serviceForms) {
      if (line.itemController.text.trim().isEmpty) {
        _showSnack('Service item is required.');
        return false;
      }
      final qty = double.tryParse(line.quantityController.text.trim()) ?? -1;
      final rate = double.tryParse(line.rateController.text.trim()) ?? -1;
      if (qty <= 0) {
        _showSnack('Quantity must be greater than 0.');
        return false;
      }
      if (rate < 0) {
        _showSnack('Rate must be a valid number.');
        return false;
      }
    }
    return true;
  }

  Future<void> _submitInvoice() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_validateServiceLines()) return;

    if (_clientId == null || _clientId!.isEmpty) {
      await _loadClientAndInvoices();
      if (_clientId == null || _clientId!.isEmpty) return;
    }

    if (_transactionCategories.isNotEmpty &&
        (_selectedTransactionCategoryId == null ||
            _selectedTransactionCategoryId!.isEmpty)) {
      _showSnack('Please select transaction category.');
      return;
    }

    setState(() => _saving = true);

    try {
      final payload = <String, dynamic>{
        FrappeConfig.clientInvoiceClientField: _clientId,
        FrappeConfig.clientInvoiceBillToCompanyField: _billToCompanyController
            .text
            .trim(),
        FrappeConfig.clientInvoiceBillToEmailField: _billToEmailController.text
            .trim(),
        FrappeConfig.clientInvoiceBillToAddressField: _billToAddressController
            .text
            .trim(),
        FrappeConfig.clientInvoiceBillToPhoneField: _billToPhoneController.text
            .trim(),
        FrappeConfig.clientInvoiceSubtotalField: _subtotal,
        FrappeConfig.clientInvoiceVatAmountField: _vatAmount,
        FrappeConfig.clientInvoiceBankNameField: _bankNameController.text
            .trim(),
        FrappeConfig.clientInvoiceBankAccountNameField:
            _bankAccountNameController.text.trim(),
        FrappeConfig.clientInvoiceAccountNumberField: _accountNumberController
            .text
            .trim(),
        FrappeConfig.clientInvoiceSortCodeField: _sortCodeController.text
            .trim(),
        FrappeConfig.clientInvoicePaymentMethodField: _paymentMethodController
            .text
            .trim(),
        FrappeConfig.clientInvoicePaymentEmailField: _paymentEmailController
            .text
            .trim(),
        FrappeConfig.clientInvoiceDateTableField: [
          _buildInvoiceDateRow(
            label: 'Invoice Number',
            value: _invoiceNumberController.text.trim(),
          ),
          _buildInvoiceDateRow(
            label: 'Invoice Date',
            value: _invoiceDateController.text.trim(),
          ),
          _buildInvoiceDateRow(
            label: 'Due Date',
            value: _dueDateController.text.trim(),
          ),
        ],
        FrappeConfig.clientInvoiceServicesTableField: _serviceForms
            .map((line) => line.toPayload())
            .toList(),
      };

      if (_isEditMode && _editingDocName != null) {
        await _invoiceService.updateInvoice(_editingDocName!, payload);
      } else {
        Object? invoiceError;
        Object? transactionError;

        await Future.wait([
          _invoiceService
              .createInvoice(payload)
              .catchError((error) => invoiceError = error),
          _invoiceService
              .createTransactionForInvoice(
                clientId: _clientId!,
                amount: _grandTotal,
                postingDate: _invoiceDateController.text.trim(),
                invoiceNumber: _invoiceNumberController.text.trim(),
                transactionType: _selectedTransactionType,
                transactionCategoryId: _selectedTransactionCategoryId,
              )
              .catchError((error) => transactionError = error),
        ]);

        if (invoiceError != null) {
          throw Exception(invoiceError.toString());
        }

        if (transactionError != null) {
          _showSnack(
            'Invoice created, but client transaction was not created.',
          );
        }
      }

      await _loadInvoices();
      if (!mounted) return;

      _showSnack(_isEditMode ? 'Invoice updated.' : 'Invoice created.');
      _backToList();
    } catch (e) {
      _showSnack(
        UserFriendlyError.message(
          e,
          fallback: 'Unable to save invoice right now. Please try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Map<String, dynamic> _buildInvoiceDateRow({
    required String label,
    required String value,
  }) {
    return {
      _invoiceDateNameFieldKey: label,
      // Common alternatives used in child doctypes for the label/name column.
      // Unknown keys are ignored by Frappe, known ones will populate.
      'field_name': label,
      'name1': label,
      'title': label,
      'label': label,
      FrappeConfig.clientInvoiceDateEntryValueField: value,
    };
  }

  Future<void> _downloadInvoicePdf(String docName) async {
    try {
      await _invoiceService.downloadInvoicePdf(docName);
    } catch (e) {
      _showSnack(
        UserFriendlyError.message(
          e,
          fallback: 'Unable to download invoice PDF right now.',
        ),
      );
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: Text(
          _mode == InvoiceViewMode.list
              ? 'Invoices'
              : _mode == InvoiceViewMode.form
              ? (_isEditMode ? 'Edit Invoice' : 'Create Invoice')
              : 'Invoice Details',
        ),
        centerTitle: true,
        leading: _mode == InvoiceViewMode.list
            ? null
            : IconButton(
                onPressed: _backToList,
                tooltip: "Add",
                icon: const Icon(Icons.arrow_back),
              ),
        actions: [
          if (_mode == InvoiceViewMode.list)
            IconButton(
              tooltip: 'Create Invoice',
              onPressed: _openCreate,
              icon: const Icon(Icons.add),
            ),
          if (_mode == InvoiceViewMode.list)
            IconButton(
              tooltip: 'Refresh',
              onPressed: _loadInvoices,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_loadingClient || _loadingList || _loadingInvoice)
            const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: switch (_mode) {
              InvoiceViewMode.list => InvoiceListView(
                invoices: _invoices,
                loading: _loadingList,
                onCreate: _openCreate,
                onOpen: _openDetail,
                onEdit: _openEdit,
                onDownload: _downloadInvoicePdf,
              ),
              InvoiceViewMode.form => InvoiceFormView(
                formKey: _formKey,
                isEditMode: _isEditMode,
                saving: _saving,
                billToCompanyController: _billToCompanyController,
                billToEmailController: _billToEmailController,
                billToAddressController: _billToAddressController,
                billToPhoneController: _billToPhoneController,
                invoiceNumberController: _invoiceNumberController,
                invoiceDateController: _invoiceDateController,
                dueDateController: _dueDateController,
                bankNameController: _bankNameController,
                bankAccountNameController: _bankAccountNameController,
                accountNumberController: _accountNumberController,
                sortCodeController: _sortCodeController,
                paymentMethodController: _paymentMethodController,
                paymentEmailController: _paymentEmailController,
                vatAmountController: _vatAmountController,
                serviceForms: _serviceForms,
                subtotal: _subtotal,
                total: _grandTotal,
                transactionTypes: _transactionTypes,
                selectedTransactionType: _selectedTransactionType,
                onTransactionTypeChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedTransactionType = value);
                },
                transactionCategories: _transactionCategories,
                selectedTransactionCategoryId: _selectedTransactionCategoryId,
                onTransactionCategoryChanged: (value) {
                  setState(() => _selectedTransactionCategoryId = value);
                },
                onPickInvoiceDate: () => _pickDate(_invoiceDateController),
                onPickDueDate: () => _pickDate(_dueDateController),
                onAddServiceLine: _addServiceRow,
                onRemoveServiceLine: _removeServiceRow,
                onSubmit: _submitInvoice,
              ),
              InvoiceViewMode.detail =>
                _selectedInvoice == null
                    ? const Center(child: Text('Invoice not loaded.'))
                    : InvoiceDetailView(
                        invoice: _selectedInvoice!,
                        onDownload: () =>
                            _downloadInvoicePdf(_selectedInvoice!.id),
                        onEdit: () => _openEdit(_selectedInvoice!.id),
                      ),
            },
          ),
        ],
      ),
    );
  }
}
