import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../general/notifications/notifications_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String selectedTab = 'Expenses'; // Filter toggle

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header stays the same
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.grid_view_rounded),
                  const Text(
                    'Overview',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Total Income & Expense Cards
              Row(
                children: [
                  Expanded(
                    child: _buildAmountCard(
                      title: 'Total Income',
                      amount: '\$8,500',
                      bgColor: const Color(0xFFF4ECFF),
                      iconColor: const Color(0xFF8A56E8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildAmountCard(
                      title: 'Total Expenses',
                      amount: '\$3,800',
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
                      TransactionBarChart(transactions: _getAllTransactions()),
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
                      Column(
                        children: _getAllTransactions()
                            .where((tx) => tx['type'] == selectedTab)
                            .map((tx) => _buildTransactionRow(tx))
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
                  color: iconColor.withOpacity(
                    1,
                  ), // light background based on icon color
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
              Text(
                amount,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
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

  Widget _buildTransactionRow(Map<String, dynamic> tx) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(tx['icon'], color: Colors.grey[700]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['label'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(tx['date'], style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Text(
            tx['amount'],
            style: TextStyle(
              color: tx['amount'].contains('-')
                  ? Color.fromARGB(234, 239, 135, 127)
                  : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredTransactions() {
    final allTransactions = [
      {
        "icon": Icons.shopping_bag,
        "label": "Shopping",
        "date": "30 Apr 2022",
        "amount": "-\$100,550",
        "type": "Expenses",
      },
      {
        "icon": Icons.laptop,
        "label": "Laptop",
        "date": "28 Apr 2022",
        "amount": "-\$100,200",
        "type": "Expenses",
      },
      {
        "icon": Icons.attach_money,
        "label": "Salary",
        "date": "25 Apr 2022",
        "amount": "\$3,000",
        "type": "Income",
      },
      {
        "icon": Icons.trending_up,
        "label": "Freelance",
        "date": "22 Apr 2022",
        "amount": "\$1,500",
        "type": "Income",
      },
    ];

    return allTransactions.where((tx) => tx['type'] == selectedTab).toList();
  }

  List<Map<String, dynamic>> _getAllTransactions() {
    return [
      {
        "icon": Icons.shopping_bag,
        "label": "Shopping",
        "date": "29 Apr 2022",
        "amount": "\$13,550",
        "type": "Income",
      },
      {
        "icon": Icons.laptop,
        "label": "Laptop",
        "date": "28 Apr 2022",
        "amount": "-\$13,200",
        "type": "Expenses",
      },
      {
        "icon": Icons.attach_money,
        "label": "Salary",
        "date": "2 Apr 2022",
        "amount": "\$100,000",
        "type": "Income",
      },
      {
        "icon": Icons.laptop,
        "label": "Laptop",
        "date": "12 Apr 2022",
        "amount": "-\$80,200",
        "type": "Expenses",
      },
      {
        "icon": Icons.laptop,
        "label": "Laptop",
        "date": "12 Apr 2022",
        "amount": "-\$90,200",
        "type": "Income",
      },

      {
        "icon": Icons.attach_money,
        "label": "Salary",
        "date": "2 Apr 2022",
        "amount": "-\$60,000",
        "type": "Expenses",
      },
      {
        "icon": Icons.trending_up,
        "label": "Freelance",
        "date": "20 Apr 2022",
        "amount": "\$110,500",
        "type": "Income",
      },
      {
        "icon": Icons.trending_up,
        "label": "Freelance",
        "date": "20 Apr 2022",
        "amount": "-\$100,500",
        "type": "Expenses",
      },
    ];
  }
}

class TransactionBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const TransactionBarChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    double parseAmount(String amountStr) {
      final cleaned = amountStr.replaceAll(RegExp(r'[^\d.-]'), '');
      return cleaned.startsWith('-')
          ? double.parse(cleaned.substring(1))
          : double.parse(cleaned);
    }

    String toISO(String dateStr) {
      final parts = dateStr.split(' ');
      final month = {
        'Jan': '01',
        'Feb': '02',
        'Mar': '03',
        'Apr': '04',
        'May': '05',
        'Jun': '06',
        'Jul': '07',
        'Aug': '08',
        'Sep': '09',
        'Oct': '10',
        'Nov': '11',
        'Dec': '12',
      }[parts[1]]!;
      return '${parts[2]}-$month-${parts[0].padLeft(2, '0')}';
    }

    List<double> getWeeklyTotals(String type) {
      final totals = [0.0, 0.0, 0.0, 0.0];
      for (var tx in transactions) {
        if (tx['type'] != type) continue;
        final date = DateTime.parse(toISO(tx['date']));
        final week = ((date.day - 1) ~/ 7).clamp(0, 3);
        totals[week] += parseAmount(tx['amount']);
      }
      return totals;
    }

    final income = getWeeklyTotals('Income');
    final expense = getWeeklyTotals('Expenses');
    final allValues = [...income, ...expense];
    final maxAmount = allValues.isEmpty
        ? 1.0
        : allValues.reduce((a, b) => a > b ? a : b);
    final maxY = (maxAmount / 1000)
        .ceilToDouble()
        .clamp(1, double.infinity)
        .toDouble();

    double interval;
    if (maxY <= 5) {
      interval = 1;
    } else if (maxY <= 10) {
      interval = 2;
    } else if (maxY <= 20) {
      interval = 5;
    } else {
      interval = 10;
    }

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
                  toY: income[i] / 1000,
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
                  toY: expense[i] / 1000,
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
                reservedSize: 40,
                interval: interval,
                getTitlesWidget: (value, _) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '\$${value.toInt()}k',
                    style: const TextStyle(fontSize: 12),
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
