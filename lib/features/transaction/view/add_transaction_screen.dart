import 'package:flutter/material.dart';
import 'add_transaction_form.dart';
import '../../general/notifications/notifications_screen.dart';

class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = [
      _Transaction('Sallary', '30 Apr 2022', 1500, true, Icons.money),
      _Transaction(
        'Paypal',
        '28 Apr 2022',
        3500,
        true,
        Icons.account_balance_wallet,
      ),
      _Transaction('Food', '25 Apr 2022', -300, false, Icons.fastfood),
      _Transaction('Upwork', '23 Apr 2022', 800, true, Icons.work),
      _Transaction('Bill', '22 Apr 2022', -600, false, Icons.receipt_long),
      _Transaction('Discount', '20 Apr 2022', 200, true, Icons.percent),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        title: const Text(
          'Add Transaction',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddTransactionFormScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4ECFF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: const [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Color(0xFF8A56E8),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add Income',
                            style: TextStyle(color: Color(0xFF8A56E8)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddTransactionFormScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0ED),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: const [
                          Icon(Icons.wallet_outlined, color: Color(0xFFFF6A55)),
                          SizedBox(height: 8),
                          Text(
                            'Add Expense',
                            style: TextStyle(color: Color(0xFFFF6A55)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Last Added',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  // shape: RoundedRectangleBorder(
                  //   borderRadius: BorderRadius.circular(16),
                  // ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple.withOpacity(0.1),
                      child: Icon(transaction.icon, color: Colors.deepPurple),
                    ),
                    title: Text(
                      transaction.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(transaction.date),
                    trailing: Text(
                      '${transaction.amount > 0 ? '+' : '-'}\$${transaction.amount.abs()}',
                      style: TextStyle(
                        color: transaction.amount > 0
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Transaction {
  final String title;
  final String date;
  final int amount;
  final bool isIncome;
  final IconData icon;

  _Transaction(this.title, this.date, this.amount, this.isIncome, this.icon);
}
