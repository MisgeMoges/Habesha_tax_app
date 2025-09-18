import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final List<Map<String, dynamic>> settingsItems = const [
    {'icon': Icons.payment, 'label': 'Payment'},
    {'icon': Icons.bar_chart, 'label': 'Activity'},
    {'icon': Icons.message, 'label': 'Message Center'},
    {'icon': Icons.alarm, 'label': 'Reminder'},
    {'icon': Icons.language, 'label': 'Language'},
    {'icon': Icons.info_outline, 'label': 'FAQs'},
    {'icon': Icons.feedback, 'label': 'Send Feedback'},
    {'icon': Icons.report_problem, 'label': 'Report a Problem'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FD),
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: settingsItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final item = settingsItems[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(item['icon'], color: Colors.deepPurple),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item['label'],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
