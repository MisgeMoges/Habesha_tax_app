import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/client_header.dart';
import 'package:habesha_tax_app/core/config/frappe_config.dart';
import 'package:habesha_tax_app/core/services/frappe_client.dart';
import 'add_transaction_form.dart';
import '../../general/notifications/notifications_screen.dart';
import 'package:habesha_tax_app/data/model/transaction_category.dart';
import 'package:habesha_tax_app/data/model/transaction.dart';
import 'package:habesha_tax_app/features/auth/bloc/auth_bloc.dart';
import 'package:habesha_tax_app/features/auth/bloc/auth_state.dart';
import 'package:habesha_tax_app/features/transaction/view/transaction_detail_screen.dart';
import 'package:habesha_tax_app/core/utils/user_friendly_error.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final FrappeClient _client = FrappeClient();
  bool _loading = false;
  String? _error;
  bool _hasChanges = false;
  List<Transaction> _transactions = [];
  List<TransactionCategory> _categories = [];
  String _selectedCategory = 'All';
  String _selectedType = 'All';
  DateTime? _selectedPostingDate;
  final TextEditingController _dateController = TextEditingController();
  _RangeFilter _rangeFilter = _RangeFilter.all;

  static const List<String> _transactionTypes = [
    'Income',
    'Expense',
    'Payment',
    'Receipt',
  ];

  @override
  void initState() {
    super.initState();
    _loadLookups();
    _loadLastTransactions();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
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
            _selectedCategory = 'All';
          });
        }
      } else {
        throw Exception(
          categoriesResponse['message'] ?? 'Failed to load categories',
        );
      }
    } catch (e) {
      setState(() {
        _categories = [];
        _selectedCategory = 'All';
      });
    }
  }

  Future<void> _loadLastTransactions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      final user = authState is Authenticated ? authState.user : null;
      final userEmail = user?.email ?? '';
      if (userEmail.isEmpty) {
        throw Exception('User not authenticated');
      }

      final clientResponse = await _client.get(
        '/api/resource/${FrappeConfig.clientDoctype}',
        queryParameters: {
          'filters': jsonEncode([
            ['user_id', '=', userEmail],
          ]),
          'fields': jsonEncode(['name']),
          'limit_page_length': '1',
        },
      );
      final clientData = clientResponse['data'] ?? clientResponse['message'];
      if (clientData is! List || clientData.isEmpty) {
        throw Exception('Client record not found');
      }
      final clientName = (clientData.first as Map)['name']?.toString() ?? '';
      if (clientName.isEmpty) {
        throw Exception('Client record not found');
      }

      final response = await _client.get(
        '/api/resource/${FrappeConfig.transactionDoctype}',
        queryParameters: {
          'filters': jsonEncode([
            [FrappeConfig.transactionClientField, '=', clientName],
          ]),
          'fields': jsonEncode([
            'name',
            FrappeConfig.transactionPostingDateField,
            FrappeConfig.transactionAmountField,
            FrappeConfig.transactionTypeField,
            FrappeConfig.transactionCategoryField,
            'category_name',
          ]),
          'order_by': 'creation desc',
          'limit_page_length': '200',
        },
      );

      final data = response['data'];
      if (data is List) {
        final items = data.map<Transaction>((item) {
          final map = item as Map<String, dynamic>;
          final amountRaw = map[FrappeConfig.transactionAmountField];
          final amount = amountRaw is num
              ? amountRaw.toDouble()
              : double.tryParse(amountRaw?.toString() ?? '0') ?? 0;
          final type = map[FrappeConfig.transactionTypeField]?.toString() ?? '';
          final category =
              map[FrappeConfig.transactionCategoryField]?.toString() ?? '';
          final categoryName = map['category_name']?.toString() ?? '';
          final date =
              map[FrappeConfig.transactionPostingDateField]?.toString() ?? '';
          final note = map[FrappeConfig.transactionNoteField]?.toString() ?? '';

          return Transaction.fromJson({
            'id': map['name']?.toString() ?? '',
            'postingDate': date,
            'amount': amount,
            'type': type,
            'category': category,
            'category_name': categoryName,
            'note': note,
          });
        }).toList();

        setState(() => _transactions = items);
      }
    } catch (e) {
      setState(
        () => _error = UserFriendlyError.message(
          e,
          fallback: 'Unable to load transactions right now.',
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Transaction> get _filteredTransactions {
    Iterable<Transaction> items = _transactions;

    if (_selectedCategory != 'All' && _selectedCategory.isNotEmpty) {
      items = items.where(
        (tx) => tx.category.toLowerCase() == _selectedCategory.toLowerCase(),
      );
    }

    if (_selectedType != 'All' && _selectedType.isNotEmpty) {
      items = items.where(
        (tx) => tx.type.toLowerCase() == _selectedType.toLowerCase(),
      );
    }

    if (_selectedPostingDate != null) {
      items = items.where((tx) {
        final date = tx.postingDateValue;
        if (date == null) return false;
        return _isSameDay(date, _selectedPostingDate!);
      });
    }

    final now = DateTime.now();
    if (_rangeFilter != _RangeFilter.all) {
      items = items.where((tx) {
        final date = tx.postingDateValue;
        if (date == null) return false;
        switch (_rangeFilter) {
          case _RangeFilter.week:
            final start = _startOfWeek(now);
            final end = start.add(const Duration(days: 7));
            return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
                date.isBefore(end);
          case _RangeFilter.month:
            return date.year == now.year && date.month == now.month;
          case _RangeFilter.year:
            return date.year == now.year;
          case _RangeFilter.all:
            return true;
        }
      });
    }

    return items.toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _startOfWeek(DateTime date) {
    final dayOfWeek = date.weekday;
    final start = date.subtract(Duration(days: dayOfWeek - 1));
    return DateTime(start.year, start.month, start.day);
  }

  Future<void> _pickPostingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedPostingDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedPostingDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = 'All';
      _selectedType = 'All';
      _selectedPostingDate = null;
      _dateController.clear();
      _rangeFilter = _RangeFilter.all;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          Navigator.pop(context, true);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const ClientAppBarTitle(),
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    if (_hasChanges) {
                      Navigator.pop(context, true);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                )
              : const Padding(
                  padding: EdgeInsets.all(10),
                  child: ClientProfileLeading(),
                ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NotificationScreen()),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8A56E8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Add Transaction',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddTransactionFormScreen(),
                      ),
                    ).then((updated) {
                      if (updated == true) {
                        _hasChanges = true;
                        _loadLastTransactions();
                      }
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filters',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ), // Reduce padding
                            ),
                            items:
                                _categories
                                    .map(
                                      (category) => DropdownMenuItem<String>(
                                        value: category.id,
                                        child: Text(
                                          category.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList()
                                  ..insert(
                                    0,
                                    const DropdownMenuItem<String>(
                                      value: 'All',
                                      child: Text('All'),
                                    ),
                                  ),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _selectedCategory = value);
                            },
                            isExpanded: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedType,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                              border: OutlineInputBorder(),
                            ),
                            items: ['All', ..._transactionTypes]
                                .map(
                                  (value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _selectedType = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      readOnly: true,
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: 'Posting Date',
                        border: const OutlineInputBorder(),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_selectedPostingDate != null)
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _selectedPostingDate = null;
                                    _dateController.clear();
                                  });
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: _pickPostingDate,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<_RangeFilter>(
                      value: _rangeFilter,
                      decoration: const InputDecoration(
                        labelText: 'Period',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: _RangeFilter.all,
                          child: Text('All'),
                        ),
                        DropdownMenuItem(
                          value: _RangeFilter.week,
                          child: Text('This Week'),
                        ),
                        DropdownMenuItem(
                          value: _RangeFilter.month,
                          child: Text('This Month'),
                        ),
                        DropdownMenuItem(
                          value: _RangeFilter.year,
                          child: Text('This Year'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _rangeFilter = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Transactions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    )
                  : _filteredTransactions.isEmpty
                  ? const Center(child: Text('No transactions yet'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _filteredTransactions[index];
                        final sign = transaction.isIncome ? '+' : '-';
                        return Card(
                          elevation: 0,
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepPurple.withOpacity(
                                0.1,
                              ),
                              child: Icon(
                                transaction.isIncome
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: Colors.deepPurple,
                              ),
                            ),
                            title: Text(
                              transaction.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(transaction.postingDate),
                            trailing: Text(
                              '$sign\$${transaction.amount.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                color: transaction.isIncome
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            onTap: () async {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TransactionDetailScreen(
                                    transaction: transaction,
                                  ),
                                ),
                              );
                              if (updated == true) {
                                _hasChanges = true;
                                _loadLastTransactions();
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _RangeFilter { all, week, month, year }
