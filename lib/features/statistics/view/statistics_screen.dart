import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:habesha_tax_app/core/config/frappe_config.dart';
import 'package:habesha_tax_app/core/services/frappe_client.dart';
import 'package:habesha_tax_app/data/model/transaction.dart';
import '../../general/notifications/notification_bell_button.dart';
import '../../../shared/widgets/client_header.dart';
import 'package:habesha_tax_app/features/auth/bloc/auth_bloc.dart';
import 'package:habesha_tax_app/features/auth/bloc/auth_state.dart';
import 'package:habesha_tax_app/features/transaction/view/transaction_detail_screen.dart';
import 'package:habesha_tax_app/core/utils/user_friendly_error.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String selectedTab = 'Expenses'; // Filter toggle
  final FrappeClient _client = FrappeClient();
  bool _loading = false;
  String? _error;
  List<Transaction> _transactions = [];
  final NumberFormat _currency = NumberFormat.currency(symbol: r'$');

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
          fallback: 'Unable to load statistics right now.',
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final incomeTotal = _transactions
        .where((tx) => tx.isIncome)
        .fold<double>(0, (sum, tx) => sum + tx.amount.abs());
    final expenseTotal = _transactions
        .where((tx) => !tx.isIncome)
        .fold<double>(0, (sum, tx) => sum + tx.amount.abs());

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const ClientProfileLeading(),
                  const Expanded(child: Center(child: ClientAppBarTitle())),
                  const NotificationBellButton(),
                ],
              ),
              const SizedBox(height: 24),

              // Total Income & Expense Cards
              Row(
                children: [
                  Expanded(
                    child: _buildAmountCard(
                      title: 'Total Income',
                      amount: _currency.format(incomeTotal),
                      bgColor: const Color(0xFFF4ECFF),
                      iconColor: const Color(0xFF8A56E8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildAmountCard(
                      title: 'Total Expenses',
                      amount: _currency.format(expenseTotal),
                      bgColor: const Color(0xFFFFF0ED),
                      iconColor: const Color.fromARGB(234, 239, 135, 127),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Now wrap everything below in SingleChildScrollView
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statistics Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Statistics',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('Jul 01 - Jul 30'),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Color(0xFFF4ECFF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: 'Monthly',
                                dropdownColor: Color(0xFFF4ECFF),
                                icon: const Icon(Icons.arrow_drop_down),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Monthly',
                                    child: Text('Monthly'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Weekly',
                                    child: Text('Weekly'),
                                  ),
                                ],
                                onChanged: (_) {},
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Chart
                      TransactionBarChart(transactions: _transactions),
                      const SizedBox(height: 24),

                      // Filter Tabs
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTab('Income'),
                          const SizedBox(width: 8),
                          _buildTab('Expenses'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Filtered Transactions List
                      if (_loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_error != null)
                        Text(_error!, style: const TextStyle(color: Colors.red))
                      else if (_transactions.isEmpty)
                        Text(
                          'No transactions yet',
                          style: TextStyle(color: Colors.grey.shade600),
                        )
                      else
                        Column(
                          children: _transactions
                              .where(
                                (tx) => selectedTab == 'Income'
                                    ? tx.isIncome
                                    : !tx.isIncome,
                              )
                              .map(_buildTransactionRow)
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountCard({
    required String title,
    required String amount,
    required Color bgColor,
    required Color iconColor,
  }) {
    final bool isExpense = title.toLowerCase().contains('expense');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isExpense
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    amount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String tabName) {
    final isSelected = selectedTab == tabName;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = tabName;
          });
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isSelected
                ? (tabName == 'Income'
                      ? const Color(0xFF8A56E8)
                      : const Color.fromARGB(234, 239, 135, 127))
                : const Color(0xFFF4ECFF),
          ),
          child: Text(
            tabName,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionRow(Transaction tx) {
    final amountText =
        '${tx.isIncome ? '+' : '-'}${_currency.format(tx.amount.abs())}';
    final dateText = tx.postingDateValue != null
        ? DateFormat('MMM dd, yyyy').format(tx.postingDateValue!)
        : tx.postingDate;

    return InkWell(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(_iconForType(tx.type), color: Colors.grey[700]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(dateText, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Text(
              amountText,
              style: TextStyle(
                color: tx.isIncome
                    ? Colors.green
                    : const Color.fromARGB(234, 239, 135, 127),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
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

class TransactionBarChart extends StatelessWidget {
  final List<Transaction> transactions;
  final NumberFormat _compactCurrency = NumberFormat.compactCurrency(
    symbol: r'$',
  );

  TransactionBarChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    List<double> getWeeklyTotals(bool income) {
      final totals = [0.0, 0.0, 0.0, 0.0];
      for (var tx in transactions) {
        if (tx.isIncome != income) continue;
        final date = tx.postingDateValue;
        if (date == null) continue;
        final week = ((date.day - 1) ~/ 7).clamp(0, 3);
        totals[week] += tx.amount.abs();
      }
      return totals;
    }

    final income = getWeeklyTotals(true);
    final expense = getWeeklyTotals(false);
    final allValues = [...income, ...expense];
    final maxAmount = allValues.isEmpty
        ? 1.0
        : allValues.reduce((a, b) => a > b ? a : b);
    final maxY = maxAmount <= 0 ? 1.0 : maxAmount;
    final interval = (maxY / 4)
        .ceilToDouble()
        .clamp(1, double.infinity)
        .toDouble();

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: List.generate(4, (i) {
            return BarChartGroupData(
              x: i,
              barsSpace: 6,
              barRods: [
                BarChartRodData(
                  toY: income[i],
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(197, 118, 61, 230),
                      Color.fromARGB(246, 133, 110, 255),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                BarChartRodData(
                  toY: expense[i],
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                  color: const Color(0xFFEF877F),
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56,
                interval: interval,
                getTitlesWidget: (value, _) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    _compactCurrency.format(value),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) =>
                    Text('Week ${value.toInt() + 1}'),
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: false),
        ),
      ),
    );
  }
}
