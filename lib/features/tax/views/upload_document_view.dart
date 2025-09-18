import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../bloc/tax_bloc.dart';
import '../bloc/tax_event.dart';
import '../bloc/tax_state.dart';

class UploadDocumentView extends StatefulWidget {
  const UploadDocumentView({super.key});

  @override
  State<UploadDocumentView> createState() => _UploadDocumentViewState();
}

class _UploadDocumentViewState extends State<UploadDocumentView> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  String? _filePath;
  String? _type;
  String? _category;
  double? _amount;
  final _descriptionController = TextEditingController();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _filePath = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Document')),
      body: BlocListener<TaxBloc, TaxState>(
        listener: (context, state) {
          if (state is TaxError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is TaxDocumentsLoaded) {
            Navigator.pop(context);
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (_filePath != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Selected: ${_filePath!.split('/').last}'),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload_file),
                label: const Text('Select Document'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Document Type',
                  border: OutlineInputBorder(),
                ),
                items: ['payslip', 'expense', 'revenue']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _type = value),
                validator: (value) =>
                    value == null ? 'Please select a document type' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _amount = double.tryParse(value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _category = value,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a category' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              BlocBuilder<TaxBloc, TaxState>(
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state is TaxLoading
                        ? null
                        : () {
                            if (_formKey.currentState?.validate() ?? false) {
                              if (_filePath == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select a document'),
                                  ),
                                );
                                return;
                              }
                              context.read<TaxBloc>().add(
                                UploadTaxDocumentRequested(
                                  filePath: _filePath!,
                                  documentType: _type!,
                                  amount: _amount!,
                                  category: _category!,
                                  description: _descriptionController.text,
                                ),
                              );
                            }
                          },
                    child: state is TaxLoading
                        ? const CircularProgressIndicator()
                        : const Text('Upload'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}
