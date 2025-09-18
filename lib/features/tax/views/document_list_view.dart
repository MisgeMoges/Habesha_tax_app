import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/tax_bloc.dart';
import '../bloc/tax_event.dart';
import '../bloc/tax_state.dart';
import '../../../data/model/tax_document.dart';

class DocumentListView extends StatefulWidget {
  const DocumentListView({super.key});

  @override
  State<DocumentListView> createState() => _DocumentListViewState();
}

class _DocumentListViewState extends State<DocumentListView> {
  @override
  void initState() {
    super.initState();
    context.read<TaxBloc>().add(const FetchTaxDocumentsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Documents')),
      body: BlocBuilder<TaxBloc, TaxState>(
        builder: (context, state) {
          if (state is TaxLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TaxDocumentsLoaded) {
            final docs = state.documents;
            if (docs.isEmpty) {
              return const Center(child: Text('No documents uploaded yet.'));
            }
            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final doc = docs[index];
                return ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(doc.documentType.toUpperCase()),
                  subtitle: Text(
                    'Amount: \\${doc.amount.toStringAsFixed(2)}\nCategory: ${doc.category}\nDate: ${doc.uploadDate.toLocal().toString().split(' ')[0]}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () {
                      // Optionally open the file URL
                    },
                  ),
                );
              },
            );
          } else if (state is TaxError) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else {
            return const Center(child: Text('No data available.'));
          }
        },
      ),
    );
  }
}
