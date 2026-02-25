import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:habesha_tax_app/core/config/frappe_config.dart';
import 'package:habesha_tax_app/core/services/frappe_client.dart';
import 'package:habesha_tax_app/data/model/transaction_category.dart';

class AddTransactionFormScreen extends StatefulWidget {
  final String? initialTransactionType;

  const AddTransactionFormScreen({super.key, this.initialTransactionType});

  @override
  State<AddTransactionFormScreen> createState() =>
      _AddTransactionFormScreenState();
}

class _AddTransactionFormScreenState extends State<AddTransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _dateController = TextEditingController();

  final FrappeClient _client = FrappeClient();

  String _transactionType = 'Income';
  DateTime _selectedDate = DateTime.now();

  File? _mainFile;
  final List<File> _attachments = [];
  bool _isSubmitting = false;
  bool _loadingLookups = false;
  bool _loadingClient = false;
  String? _lookupError;
  String? _clientError;
  List<TransactionCategory> _categories = [];
  TransactionCategory? _selectedCategory;
  Map<String, dynamic>? _clientRecord;

  static const List<String> _transactionTypes = [
    'Income',
    'Expense',
    'Payment',
    'Receipt',
  ];

  @override
  void initState() {
    super.initState();
    _transactionType = widget.initialTransactionType ?? _transactionType;
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _loadLookups();
    _loadClientData();
  }

  Future<void> _loadClientData() async {
    setState(() {
      _loadingClient = true;
      _clientError = null;
    });

    try {
      // final loggedUserResponse = await _client.get(
      //   '/api/method/fhabesha_tax.habesha_tax.doctype.client.client.get_logged_in_user',
      // );
      // final userEmail = loggedUserResponse['message']?.toString() ?? '';
      // if (userEmail.isEmpty) {
      //   throw Exception('User not authenticated');
      // }

      final response = await _client.get(
        '/api/method/habesha_tax.habesha_tax.doctype.client.client.get_clients',
      );
      print('Loaded client record: $response');
      if (response['success'] == true) {
        final data = response['data'];
        if (data is List && data.isNotEmpty) {
          _clientRecord = Map<String, dynamic>.from(data.first as Map);
        } else {
          throw Exception('Client record not found');
        }
      } else {
        throw Exception(
          response['message']?.toString() ?? 'Failed to fetch clients',
        );
      }
    } catch (e) {
      _clientError = 'Failed to load client data: ${e.toString()}';
    } finally {
      if (mounted) {
        setState(() => _loadingClient = false);
      }
    }
  }

  Future<void> _loadLookups() async {
    setState(() {
      _loadingLookups = true;
      _lookupError = null;
    });

    try {
      final categoriesResponse = await _client.get(
        '/api/method/habesha_tax.habesha_tax.doctype.transaction_category.transaction_category.get_transaction_categories',
      );

      print('Categories response: $categoriesResponse');

      if (categoriesResponse['success'] == true) {
        final categoriesData = categoriesResponse['data'];

        if (categoriesData is List) {
          _categories = categoriesData
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
    } catch (e) {
      setState(() {
        _lookupError = 'Failed to load options: ${e.toString()}';
        // Set default categories for fallback
        _categories = [
          TransactionCategory(id: 'sales', name: 'Sales'),
          TransactionCategory(id: 'purchase', name: 'Purchase'),
          TransactionCategory(id: 'service', name: 'Service'),
        ];
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
        }
      });
    } finally {
      setState(() => _loadingLookups = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
    }
  }

  Future<void> _pickMainFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null && result.files.single.path != null) {
      setState(() {
        _mainFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null && result.files.single.path != null) {
      setState(() {
        _attachments.add(File(result.files.single.path!));
      });
    }
  }

  Future<String?> _uploadFile(File file) async {
    final response = await _client.uploadFile(file: file);
    final fileUrl =
        response['message']?['file_url']?.toString() ??
        response['file_url']?.toString();
    return fileUrl;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    if (_clientRecord == null) {
      await _loadClientData();
    }

    if (_clientRecord == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client data is required to submit.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final mainFileUrl = _mainFile == null
          ? null
          : await _uploadFile(_mainFile!);

      final attachmentUrls = <String>[];
      for (final attachment in _attachments) {
        final url = await _uploadFile(attachment);
        if (url != null && url.isNotEmpty) {
          attachmentUrls.add(url);
        }
      }

      final payload = <String, dynamic>{
        FrappeConfig.transactionClientField:
            _clientRecord?['id']?.toString() ?? '',
        FrappeConfig.transactionPostingDateField: DateFormat(
          'yyyy-MM-dd',
        ).format(_selectedDate),
        FrappeConfig.transactionAmountField:
            double.tryParse(_amountController.text.trim()) ?? 0,
        FrappeConfig.transactionCategoryField: _selectedCategory!.id,
        FrappeConfig.transactionTypeField: _transactionType,
        FrappeConfig.transactionNoteField: _noteController.text.trim(),
      };

      if (mainFileUrl != null && mainFileUrl.isNotEmpty) {
        payload[FrappeConfig.transactionMainFileField] = mainFileUrl;
      }

      if (attachmentUrls.isNotEmpty) {
        payload[FrappeConfig.transactionAttachmentsField] = attachmentUrls
            .map((url) => {FrappeConfig.transactionAttachmentFileField: url})
            .toList();
      }

      await _client.post(
        '/api/resource/${FrappeConfig.transactionDoctype}',
        body: {'data': payload},
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add transaction: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loadingLookups) const LinearProgressIndicator(),
              if (_loadingClient) const LinearProgressIndicator(),
              if (_lookupError != null) ...[
                const SizedBox(height: 12),
                Text(_lookupError!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],
              if (_clientError != null) ...[
                const SizedBox(height: 12),
                Text(_clientError!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],
              // Date Picker
              TextFormField(
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Posting Date',
                  suffixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                onTap: _pickDate,
                controller: _dateController,
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              //Category Dropdown
              DropdownButtonFormField<TransactionCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<TransactionCategory>(
                    value: category,
                    child: Text(category.name), // Display category_name
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
                validator: (value) =>
                    value == null ? 'Select a category' : null,
              ),
              const SizedBox(height: 16),

              // Transaction Type
              DropdownButtonFormField<String>(
                value: _transactionType,
                decoration: const InputDecoration(
                  labelText: 'Transaction Type',
                  border: OutlineInputBorder(),
                ),
                items: _transactionTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _transactionType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Main File Upload
              GestureDetector(
                onTap: _pickMainFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, color: Colors.grey),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _mainFile != null
                              ? _mainFile!.path.split('/').last
                              : 'Tap to upload main file',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _mainFile != null
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Multiple Attachments
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Multiple Attachments',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickAttachment,
                    icon: const Icon(Icons.add),
                    label: const Text('Add File'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_attachments.isEmpty)
                Text(
                  'No attachments added',
                  style: TextStyle(color: Colors.grey.shade600),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('No.')),
                      DataColumn(label: Text('File')),
                      DataColumn(label: Text('')),
                    ],
                    rows: List.generate(_attachments.length, (index) {
                      final file = _attachments[index];
                      return DataRow(
                        cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: Text(
                                file.path.split('/').last,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() {
                                  _attachments.removeAt(index);
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(
                      0xFF8A56E8,
                    ), // Button background color
                    foregroundColor: Colors.white, // Text (and icon) color
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        20,
                      ), // Optional: rounded corners
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: const Text(
                    'Add Transaction',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
