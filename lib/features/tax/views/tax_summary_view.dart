import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/tax_bloc.dart';
import '../bloc/tax_event.dart';
import '../bloc/tax_state.dart';

class TaxSummaryView extends StatefulWidget {
  const TaxSummaryView({super.key});

  @override
  State<TaxSummaryView> createState() => _TaxSummaryViewState();
}

class _TaxSummaryViewState extends State<TaxSummaryView> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _fetchSummary();
  }

  void _fetchSummary() {
    context.read<TaxBloc>().add(FetchTaxSummaryRequested(_selectedMonth));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tax Summary')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Month: ', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedMonth,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDatePickerMode: DatePickerMode.year,
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedMonth = DateTime(picked.year, picked.month);
                      });
                      _fetchSummary();
                    }
                  },
                  child: Text(DateFormat.yMMM().format(_selectedMonth)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            BlocBuilder<TaxBloc, TaxState>(
              builder: (context, state) {
                if (state is TaxLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is TaxSummaryLoaded) {
                  final summary = state.summary;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Income:   \\${summary['income']?.toStringAsFixed(2) ?? '0.00'}',
                      ),
                      Text(
                        'Total Expenses: \\${summary['expenses']?.toStringAsFixed(2) ?? '0.00'}',
                      ),
                      Text(
                        'Taxable Income: \\${summary['taxableIncome']?.toStringAsFixed(2) ?? '0.00'}',
                      ),
                    ],
                  );
                } else if (state is TaxError) {
                  return Text(
                    'Error: ${state.message}',
                    style: const TextStyle(color: Colors.red),
                  );
                } else {
                  return const Text('No data available.');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
