import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddTransactionFormScreen extends StatefulWidget {
  const AddTransactionFormScreen({super.key});

  @override
  State<AddTransactionFormScreen> createState() =>
      _AddTransactionFormScreenState();
}

class _AddTransactionFormScreenState extends State<AddTransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  String _transactionType = 'Income';
  DateTime _selectedDate = DateTime.now();
  File? _selectedFile;

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
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Picker
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date',
                  suffixIcon: const Icon(Icons.calendar_today),
                  border: const OutlineInputBorder(),
                ),
                onTap: _pickDate,
                controller: TextEditingController(
                  text: formattedDate,
                ), // display date
              ),
              const SizedBox(height: 16),

              // Transaction Type
              DropdownButtonFormField<String>(
                value: _transactionType,
                decoration: const InputDecoration(
                  labelText: 'Transaction Type',
                  border: OutlineInputBorder(),
                ),
                items: ['Income', 'Expense'].map((type) {
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

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter a title' : null,
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
                keyboardType: TextInputType.number,
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

              // Reason
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // File Upload
              GestureDetector(
                onTap: _pickFile,
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
                          _selectedFile != null
                              ? _selectedFile!.path.split('/').last
                              : 'Tap to upload file (PDF or Image)',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _selectedFile != null
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Save logic here
                      Navigator.pop(context);
                    }
                  },
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
