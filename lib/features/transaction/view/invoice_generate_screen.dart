import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/config/frappe_config.dart';
import '../../../core/services/frappe_client.dart';
import '../../../data/model/transaction_category.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';

class InvoiceGenerateScreen extends StatefulWidget {
  const InvoiceGenerateScreen({super.key});

  @override
  State<InvoiceGenerateScreen> createState() => _InvoiceGenerateScreenState();
}

class _InvoiceGenerateScreenState extends State<InvoiceGenerateScreen> {
  final FrappeClient _client = FrappeClient();
  final _formKey = GlobalKey<FormState>();

  final _customerNameController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _rateController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _noteController = TextEditingController();

  String? _clientId;
  String _transactionType = 'Income';
  TransactionCategory? _selectedCategory;
  List<TransactionCategory> _categories = [];

  bool _loading = false;
  bool _saving = false;
  String? _error;

  static const List<String> _transactionTypes = [
    'Income',
    'Expense',
    'Payment',
    'Receipt',
  ];

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _quantityController.addListener(_recalculateAmount);
    _rateController.addListener(_recalculateAmount);
    _loadClientId();
    _loadCategories();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _customerAddressController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadClientId() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      final user = authState is Authenticated ? authState.user : null;
      final email = user?.email ?? '';

      final response = await _client.get(
        '/api/resource/${FrappeConfig.clientDoctype}',
        queryParameters: {
          'filters': '[["${FrappeConfig.clientUserIdField}","=","$email"]]',
          'fields': '["name"]',
          'limit_page_length': '1',
        },
      );

      final data = response['data'] ?? response['message'];
      if (data is List && data.isNotEmpty) {
        final first = Map<String, dynamic>.from(data.first as Map);
        _clientId = first['name']?.toString();
      } else {
        throw Exception('Client record not found');
      }
    } catch (e) {
      _error = 'Failed to load client: ${e.toString()}';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categoriesResponse = await _client.get(
        '/api/method/habesha_tax.habesha_tax.doctype.transaction_category.transaction_category.get_transaction_categories',
      );

      if (categoriesResponse['success'] == true) {
        final categoriesData = categoriesResponse['data'];

        if (categoriesData is List) {
          final items = categoriesData
              .map(
                (item) => TransactionCategory.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .where(
                (category) =>
                    category.id.isNotEmpty && category.name.isNotEmpty,
              )
              .toList();

          setState(() {
            _categories = items;
            if (_categories.isNotEmpty) {
              _selectedCategory = _categories.first;
            }
          });
        }
      } else {
        throw Exception(
          categoriesResponse['message'] ?? 'Failed to load categories',
        );
      }
    } catch (_) {
      setState(() {
        _categories = [];
        _selectedCategory = null;
      });
    }
  }

  void _recalculateAmount() {
    final qty = double.tryParse(_quantityController.text.trim()) ?? 0;
    final rate = double.tryParse(_rateController.text.trim()) ?? 0;
    final amount = qty * rate;
    _amountController.text = amount.toStringAsFixed(2);
  }

  Future<void> _pickPostingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }
    if (_clientId == null || _clientId!.isEmpty) {
      await _loadClientId();
      if (_clientId == null || _clientId!.isEmpty) return;
    }

    setState(() => _saving = true);

    try {
      final amount = double.tryParse(_amountController.text.trim()) ?? 0;

      final note = StringBuffer()
        ..writeln('Invoice To: ${_customerNameController.text.trim()}')
        ..writeln('Email: ${_customerEmailController.text.trim()}')
        ..writeln('Phone: ${_customerPhoneController.text.trim()}')
        ..writeln('Address: ${_customerAddressController.text.trim()}')
        ..writeln('Description: ${_descriptionController.text.trim()}')
        ..writeln('Qty: ${_quantityController.text.trim()}')
        ..writeln('Rate: ${_rateController.text.trim()}')
        ..writeln('Amount: ${_amountController.text.trim()}')
        ..writeln('Note: ${_noteController.text.trim()}');

      final payload = <String, dynamic>{
        FrappeConfig.transactionClientField: _clientId,
        FrappeConfig.transactionPostingDateField: _dateController.text.trim(),
        FrappeConfig.transactionAmountField: amount,
        FrappeConfig.transactionCategoryField: _selectedCategory!.id,
        FrappeConfig.transactionTypeField: _transactionType,
        FrappeConfig.transactionNoteField: note.toString().trim(),
      };

      final response = await _client.post(
        '/api/resource/${FrappeConfig.transactionDoctype}',
        body: {'data': payload},
      );

      final created = response['data'] ?? response['message'] ?? response;
      final docName = created is Map ? created['name']?.toString() : null;

      if (docName == null || docName.isEmpty) {
        throw Exception('Failed to get invoice document name.');
      }

      await _downloadInvoicePdf(docName);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice generated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate invoice: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _downloadInvoicePdf(String docName) async {
    final baseUrl = FrappeConfig.baseUrl;
    final url = Uri.parse(
      '$baseUrl/api/method/frappe.utils.print_format.download_pdf?doctype=${Uri.encodeComponent(FrappeConfig.transactionDoctype)}&name=${Uri.encodeComponent(docName)}',
    );

    final headers = <String, String>{'Accept': 'application/pdf'};

    if (FrappeConfig.useTokenAuth) {
      headers['Authorization'] =
          'token ${FrappeConfig.apiKey}:${FrappeConfig.apiSecret}';
    }

    final response = await http.get(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to download PDF.');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/invoice_$docName.pdf');
    await file.writeAsBytes(response.bodyBytes, flush: true);
    await OpenFilex.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(title: const Text('Generate Invoice'), centerTitle: true),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _customerNameController,
                      label: 'Customer Name *',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Customer Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _customerEmailController,
                      label: 'Customer Email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _customerPhoneController,
                      label: 'Customer Phone',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _customerAddressController,
                      label: 'Customer Address',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description *',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Description is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _quantityController,
                            label: 'Quantity *',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Quantity is required';
                              }
                              if (double.tryParse(value.trim()) == null) {
                                return 'Invalid quantity';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _rateController,
                            label: 'Rate *',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Rate is required';
                              }
                              if (double.tryParse(value.trim()) == null) {
                                return 'Invalid rate';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _amountController,
                      label: 'Amount',
                      keyboardType: TextInputType.number,
                      readOnly: true,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _transactionType,
                      decoration: const InputDecoration(
                        labelText: 'Transaction Type',
                        border: OutlineInputBorder(),
                      ),
                      items: _transactionTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _transactionType = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TransactionCategory>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategory = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDateField(
                      controller: _dateController,
                      label: 'Posting Date',
                      onTap: _pickPostingDate,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _noteController,
                      label: 'Additional Note',
                      keyboardType: TextInputType.multiline,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _submit,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.picture_as_pdf),
                        label: const Text('Generate & Download PDF'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
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
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      onTap: onTap,
    );
  }
}
