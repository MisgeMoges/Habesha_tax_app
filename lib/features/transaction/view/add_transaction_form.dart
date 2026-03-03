import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:habesha_tax_app/core/config/frappe_config.dart';
import 'package:habesha_tax_app/core/services/frappe_client.dart';
import 'package:habesha_tax_app/core/utils/user_friendly_error.dart';
import 'package:habesha_tax_app/data/model/transaction_category.dart';
import 'package:habesha_tax_app/data/model/transaction.dart';
import 'package:habesha_tax_app/features/auth/bloc/auth_bloc.dart';
import 'package:habesha_tax_app/features/auth/bloc/auth_state.dart';

class AddTransactionFormScreen extends StatefulWidget {
  final String? initialTransactionType;
  final Transaction? initialTransaction;

  const AddTransactionFormScreen({
    super.key,
    this.initialTransactionType,
    this.initialTransaction,
  });

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
  final ImagePicker _imagePicker = ImagePicker();

  String _transactionType = 'Income';
  DateTime _selectedDate = DateTime.now();

  File? _mainFile;
  final List<File> _attachments = [];
  bool _isSingleAttachmentMode = false;
  bool _isSubmitting = false;
  bool _loadingLookups = false;
  bool _loadingClient = false;
  String? _lookupError;
  String? _clientError;
  List<TransactionCategory> _categories = [];
  TransactionCategory? _selectedCategory;
  Map<String, dynamic>? _clientRecord;
  late final String? _initialCategoryId;

  static const List<String> _transactionTypes = ['Income', 'Expense'];

  @override
  void initState() {
    super.initState();
    _transactionType = widget.initialTransactionType ?? _transactionType;
    _initialCategoryId = widget.initialTransaction?.category;
    if (widget.initialTransaction != null) {
      final tx = widget.initialTransaction!;
      _transactionType = tx.type.isNotEmpty ? tx.type : _transactionType;
      _amountController.text = tx.amount.toString();
      _noteController.text = tx.note;
      final parsedDate = tx.postingDateValue ?? _selectedDate;
      _selectedDate = parsedDate;
    }
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
      final authState = context.read<AuthBloc>().state;
      final user = authState is Authenticated ? authState.user : null;
      final userEmail = user?.email ?? '';
      if (userEmail.isEmpty) {
        throw Exception('User not authenticated');
      }
      final response = await _client.get(
        '/api/resource/${FrappeConfig.clientDoctype}',
        queryParameters: {
          'filters': '[["user_id","=","$userEmail"]]',
          'limit_page_length': '1',
        },
      );
      final data = response['data'] ?? response['message'];
      if (data is List && data.isNotEmpty) {
        _clientRecord = Map<String, dynamic>.from(data.first as Map);
      } else {
        throw Exception('Client record not found');
      }
    } catch (e) {
      _clientError = UserFriendlyError.message(
        e,
        fallback: 'Unable to load your account details right now.',
      );
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
              _selectedCategory = _categories.firstWhere(
                (category) => category.id == _initialCategoryId,
                orElse: () => _categories.first,
              );
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
        _lookupError = UserFriendlyError.message(
          e,
          fallback:
              'Some form options could not be loaded. You can still continue.',
        );
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
        if (_isSingleAttachmentMode) {
          _mainFile = File(result.files.single.path!);
        } else {
          _attachments.add(File(result.files.single.path!));
        }
      });
    }
  }

  Future<void> _takeAttachmentPhoto() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo == null) return;

      setState(() {
        if (_isSingleAttachmentMode) {
          _mainFile = File(photo.path);
        } else {
          _attachments.add(File(photo.path));
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserFriendlyError.message(
              e,
              fallback: 'Unable to open camera right now.',
            ),
          ),
        ),
      );
    }
  }

  Future<String?> _uploadFile(File file) async {
    final response = await _client.uploadFile(file: file);
    final fileUrl =
        response['message']?['file_url']?.toString() ??
        response['file_url']?.toString();
    return fileUrl;
  }

  void _setAttachmentMode(bool singleMode) {
    setState(() {
      _isSingleAttachmentMode = singleMode;
      if (singleMode) {
        _attachments.clear();
      }
    });
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
            _clientRecord?['name']?.toString() ?? '',
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

      if (widget.initialTransaction != null &&
          widget.initialTransaction!.id.isNotEmpty) {
        await _client.put(
          '/api/resource/${FrappeConfig.transactionDoctype}/${widget.initialTransaction!.id}',
          body: payload,
        );
      } else {
        await _client.post(
          '/api/resource/${FrappeConfig.transactionDoctype}',
          body: payload,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserFriendlyError.message(
              e,
              fallback:
                  'Unable to save transaction right now. Please try again.',
            ),
          ),
        ),
      );
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
    final isEditing = widget.initialTransaction != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
        centerTitle: true,
      ),
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
              DropdownButtonFormField<TransactionCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<TransactionCategory>(
                    value: category,
                    child: Text(category.name),
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
                      if (_mainFile != null)
                        IconButton(
                          tooltip: 'Remove main attachment',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() {
                              _mainFile = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Attachment Mode Selector
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attachment Mode',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _setAttachmentMode(true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _isSingleAttachmentMode
                                      ? const Color(0xFF8A56E8)
                                      : Colors.deepPurple.withOpacity(0.25),
                                  width: _isSingleAttachmentMode ? 1.8 : 1,
                                ),
                              ),
                              child: Text(
                                'Single',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.deepPurple,
                                  fontWeight: _isSingleAttachmentMode
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _setAttachmentMode(false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: !_isSingleAttachmentMode
                                      ? const Color(0xFF8A56E8)
                                      : Colors.deepPurple.withOpacity(0.25),
                                  width: !_isSingleAttachmentMode ? 1.8 : 1,
                                ),
                              ),
                              child: Text(
                                'Multiple',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.deepPurple,
                                  fontWeight: !_isSingleAttachmentMode
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Camera Capture (between main and multiple)
              Center(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _takeAttachmentPhoto,
                  child: Ink(
                    width: 230,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8A56E8), Color(0xFF6D3BD2)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x338A56E8),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_rounded, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Take Picture',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Conditional section between main and multiple
              if (_isSingleAttachmentMode)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.deepPurple.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _mainFile == null
                              ? 'Single mode: choose a main attachment from camera or select file.'
                              : 'Single mode selected. Main attachment is ready.',
                          style: const TextStyle(color: Colors.deepPurple),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _pickAttachment,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF8A56E8)),
                          foregroundColor: const Color(0xFF8A56E8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Select File',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox.shrink(),

              const SizedBox(height: 8),

              // Attachments
              if (!_isSingleAttachmentMode) ...[
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Multiple Attachments',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickAttachment,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF8A56E8)),
                        foregroundColor: const Color(0xFF8A56E8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.attach_file),
                      label: const Text(
                        'Add File',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),

                if (_attachments.isEmpty)
                  Text(
                    'No attachments added',
                    style: TextStyle(color: Colors.grey.shade600),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 16,
                      horizontalMargin: 20,
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
                                constraints: const BoxConstraints(
                                  maxWidth: 260,
                                ),
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
              ],

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFF8A56E8),
                      width: 1.8,
                    ),
                    foregroundColor: const Color(0xFF8A56E8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: Text(
                    isEditing ? 'Update Transaction' : 'Add Transaction',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
