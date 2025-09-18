import 'package:flutter/material.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Home',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        leading: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.grid_view_rounded, color: Colors.black),
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
                  children: const [
                    Text(
                      'Total Balance',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '\$3,257.00',
                      style: TextStyle(
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
                    // 🔄 Refresh logic here
                    debugPrint('Refresh clicked');
                    // setState or fetch new data if needed
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
                '\$2,350.00',
                Icons.arrow_downward,
                Colors.white,
              ),
              _buildBalanceItem(
                'Expenses',
                '\$950.00',
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
            color: iconColor.withOpacity(0.1), // light background
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
        TextButton(
          onPressed: () {},
          child: const Text(
            'See All',
            style: TextStyle(color: Colors.deepPurple),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList() {
    final transactions = [
      _Transaction('Money Transfer', '12:35 PM', -450, Icons.money),
      _Transaction('Paypal', '10:20 AM', 1200, Icons.payment),
      _Transaction('Uber', '08:40 AM', -150, Icons.directions_car),
      _Transaction('Bata Store', 'Yesterday', -200, Icons.store),
      _Transaction('Bank Transfer', 'Yesterday', -600, Icons.account_balance),
    ];

    return Column(children: transactions.map(_buildTransactionItem).toList());
  }

  Widget _buildTransactionItem(_Transaction tx) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          child: Icon(
            tx.icon,
            color: tx.amount > 0 ? Colors.lightGreen : Colors.deepPurpleAccent,
          ),
        ),
        title: Text(
          tx.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(tx.time),
        trailing: Text(
          '${tx.amount > 0 ? '+' : '-'}\$${tx.amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: tx.amount > 0 ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}

class _Transaction {
  final String title;
  final String time;
  final double amount;
  final IconData icon;

  _Transaction(this.title, this.time, this.amount, this.icon);
}
