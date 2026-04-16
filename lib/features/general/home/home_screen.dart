import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/widgets/client_header.dart';
import 'package:intl/intl.dart';
import 'package:habesha_tax_app/core/config/frappe_config.dart';
import 'package:habesha_tax_app/core/services/frappe_client.dart';
import 'package:habesha_tax_app/data/model/transaction.dart';
import 'package:habesha_tax_app/features/auth/bloc/auth_bloc.dart';
import 'package:habesha_tax_app/features/auth/bloc/auth_state.dart';
import 'package:habesha_tax_app/features/booking/view/booking_screen.dart';
import 'package:habesha_tax_app/features/transaction/view/add_transaction_screen.dart';
import 'package:habesha_tax_app/features/transaction/view/transaction_detail_screen.dart';
import 'package:habesha_tax_app/core/utils/user_friendly_error.dart';
import '../notifications/notification_bell_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FrappeClient _client = FrappeClient();
  bool _loading = false;
  String? _error;
  List<Transaction> _transactions = [];
  final NumberFormat _currency = NumberFormat.currency(symbol: '£');

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
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
            FrappeConfig.transactionNoteField,
          ]),
          'order_by': 'creation desc',
          // Fetch enough rows so income/expense totals are accurate.
          // UI still shows only latest 5 in the list.
          'limit_page_length': '1000',
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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const ClientAppBarTitle(),
        centerTitle: true,
        leading: const Padding(
          padding: EdgeInsets.all(10),
          child: ClientProfileLeading(),
        ),
        actions: [const NotificationBellButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const BookingScreen()));
        },
        icon: const Icon(Icons.calendar_month_outlined),
        label: const Text('Book Meeting'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 24),
            _buildTransactionsHeader(),
            const SizedBox(height: 16),
            _buildTransactionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final incomeTotal = _transactions
        .where((tx) => tx.isIncome)
        .fold<double>(0, (sum, tx) => sum + tx.amount.abs());
    final expenseTotal = _transactions
        .where((tx) => !tx.isIncome)
        .fold<double>(0, (sum, tx) => sum + tx.amount.abs());
    final netBalance = incomeTotal - expenseTotal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(246, 133, 110, 255),
            Color.fromARGB(234, 239, 135, 127),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Net Balance',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currency.format(netBalance),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: Colors.white),
                onSelected: (value) {
                  if (value == 'refresh') {
                    _loadTransactions();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'refresh',
                    child: Text('Refresh'),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBalanceItem(
                'Income',
                _currency.format(incomeTotal),
                Icons.arrow_downward,
                Colors.white,
              ),
              _buildBalanceItem(
                'Expenses',
                _currency.format(expenseTotal),
                Icons.arrow_upward,
                Colors.white70,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(
    String label,
    String amount,
    IconData icon,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1), // light background
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),

        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Transactions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.deepPurple),
              onPressed: _loadTransactions,
              tooltip: 'Refresh',
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddTransactionScreen(),
                  ),
                ).then((updated) {
                  if (updated == true) {
                    _loadTransactions();
                  }
                });
              },
              child: const Text(
                'See All',
                style: TextStyle(color: Colors.deepPurple),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionsList() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Text(_error!, style: const TextStyle(color: Colors.red));
    }

    if (_transactions.isEmpty) {
      return Text(
        'No transactions yet',
        style: TextStyle(color: Colors.grey.shade600),
      );
    }

    final items = _transactions.take(5).toList();
    return Column(children: items.map(_buildTransactionItem).toList());
  }

  Widget _buildTransactionItem(Transaction tx) {
    final isIncome = tx.isIncome;
    final icon = _iconForType(tx.type);
    final timeLabel = _formatPostingDate(tx.postingDateValue, tx.postingDate);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          child: Icon(
            icon,
            color: isIncome ? Colors.lightGreen : Colors.deepPurpleAccent,
          ),
        ),
        title: Text(
          tx.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(timeLabel),
        trailing: Text(
          '${isIncome ? '+' : '-'}£${tx.amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        onTap: () async {
          final updated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TransactionDetailScreen(transaction: tx),
            ),
          );
          if (updated == true) {
            _loadTransactions();
          }
        },
      ),
    );
  }

  String _formatPostingDate(DateTime? date, String fallback) {
    if (date == null) return fallback;
    return DateFormat('MMM dd, yyyy').format(date);
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'income':
        return Icons.arrow_downward;
      case 'expense':
        return Icons.arrow_upward;
      case 'payment':
        return Icons.account_balance_wallet;
      case 'receipt':
        return Icons.receipt_long;
      default:
        return Icons.swap_horiz;
    }
  }
}
