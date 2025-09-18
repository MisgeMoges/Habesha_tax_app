import 'package:flutter/material.dart';
import 'notification_detail_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  final List<Map<String, dynamic>> todayNotifications = const [
    {
      'title': 'You received a payment of \$1500 from Smith Jonson.',
      'time': '02:23 PM',
      'avatar': 'assets/images/profile.webp',
      'message':
          'You received a payment of \$1500 from Smith Jonson via PayPal on your account.',
    },
    {
      'title': 'Your new payment method has been added successfully.',
      'time': '11:05 AM',
      'avatar': 'assets/images/profile.webp',
      'message':
          'Your new Mastercard ending with 1234 has been successfully added.',
    },
    {
      'title': 'William James requested a payment of \$400.',
      'time': '10:16 AM',
      'avatar': 'assets/images/user.png',
      'message':
          'William James has requested a payment of \$400. Please review and process the request.',
    },
    {
      'title': 'You get \$100 discount from your shopping.',
      'time': '09:10 AM',
      'avatar': 'assets/images/profile.webp',
      'message':
          'Congratulations! You received a \$100 discount for your recent shopping.',
    },
  ];

  final List<Map<String, dynamic>> yesterdayNotifications = const [
    {
      'title': 'You received a new payment from Upwork.',
      'time': '12:26 PM',
      'avatar': 'assets/upwork.png',
      'message': 'A payment of \$300 has been transferred from Upwork.',
    },
    {
      'title': 'Your monthly expense almost break the budget.',
      'time': '10:10 AM',
      'avatar': 'assets/warning.png',
      'message':
          'Your monthly expenses are nearing your budget limit. Please review your spending.',
    },
    {
      'title': 'Your electric bill is successfully paid.',
      'time': '09:50 AM',
      'avatar': 'assets/bill.png',
      'message':
          'Your electric bill of \$75.30 has been successfully paid on time.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionTitle(title: 'Today'),
          ...todayNotifications.map((item) => NotificationItem(item: item)),
          const SizedBox(height: 20),
          const SectionTitle(title: 'Yesterday'),
          ...yesterdayNotifications.map((item) => NotificationItem(item: item)),
        ],
      ),
    );
  }
}

class NotificationItem extends StatelessWidget {
  final Map<String, dynamic> item;

  const NotificationItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        leading: CircleAvatar(
          backgroundImage: AssetImage(item['avatar']),
          radius: 24,
        ),
        title: Text(
          item['title'],
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16),
        ),
        subtitle: Text(item['time'], style: const TextStyle(fontSize: 12)),
        trailing: item['action'] != null
            ? ElevatedButton(
                onPressed: () {},
                child: Text(
                  item['action'],
                  style: const TextStyle(fontSize: 13),
                ),
              )
            : const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NotificationDetailScreen(item: item),
            ),
          );
        },
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
