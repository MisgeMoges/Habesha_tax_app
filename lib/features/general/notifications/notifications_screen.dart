import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/config/frappe_config.dart';
import '../../../core/services/frappe_client.dart';
import '../../../core/utils/user_friendly_error.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import 'notification_detail_screen.dart';

class NotificationCenter {
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  static Future<void> refreshUnreadCount({required String userEmail}) async {
    final client = FrappeClient();
    if (userEmail.trim().isEmpty) {
      unreadCountNotifier.value = 0;
      return;
    }

    try {
      try {
        final unreadResponse = await client.get(
          '/api/resource/${FrappeConfig.notificationDoctype}',
          queryParameters: {
            'filters': jsonEncode([
              [FrappeConfig.notificationRecipientField, '=', userEmail],
              [FrappeConfig.notificationReadField, '=', 0],
            ]),
            'fields': jsonEncode(['name']),
            'limit_page_length': '500',
          },
        );
        final unreadData = unreadResponse['data'];
        unreadCountNotifier.value = unreadData is List ? unreadData.length : 0;
      } catch (_) {
        final response = await client.get(
          '/api/resource/${FrappeConfig.notificationDoctype}',
          queryParameters: {
            'filters': jsonEncode([
              [FrappeConfig.notificationRecipientField, '=', userEmail],
            ]),
            'fields': jsonEncode(['name']),
            'limit_page_length': '500',
          },
        );
        final data = response['data'];
        unreadCountNotifier.value = data is List ? data.length : 0;
      }
    } catch (_) {
      unreadCountNotifier.value = 0;
    }
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FrappeClient _client = FrappeClient();
  bool _loading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final authState = context.read<AuthBloc>().state;
      final user = authState is Authenticated ? authState.user : null;
      final userEmail = user?.email ?? '';
      if (userEmail.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await _client.get(
        '/api/resource/${FrappeConfig.notificationDoctype}',
        queryParameters: {
          'filters': jsonEncode([
            // [FrappeConfig.notificationRecipientField, '=', userEmail],
          ]),
          'fields': jsonEncode([
            'name',
            FrappeConfig.notificationTitleField,
            FrappeConfig.notificationBodyField,
            FrappeConfig.notificationTimestampField,
            FrappeConfig.notificationReadField,
            FrappeConfig.notificationTypeField,
          ]),
          'order_by': '${FrappeConfig.notificationTimestampField} desc',
          'limit_page_length': '100',
        },
      );

      final data = response['data'];
      if (data is List) {
        _notifications = data.map((item) {
          final timestamp =
              DateTime.tryParse(
                item[FrappeConfig.notificationTimestampField]?.toString() ?? '',
              ) ??
              DateTime.now();
          return {
            'id': item['name']?.toString() ?? '',
            'title':
                item[FrappeConfig.notificationTitleField]?.toString() ??
                'Notification',
            'message':
                item[FrappeConfig.notificationBodyField]?.toString() ?? '',
            'timestamp': timestamp,
            'read': item[FrappeConfig.notificationReadField],
            'type': item[FrappeConfig.notificationTypeField]?.toString(),
          };
        }).toList();
      }
      await NotificationCenter.refreshUnreadCount(userEmail: userEmail);
    } catch (e) {
      _errorMessage = UserFriendlyError.message(
        e,
        fallback: 'Unable to load notifications right now.',
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _filterByDate(DateTime date) {
    return _notifications.where((item) {
      final ts = item['timestamp'] as DateTime;
      return ts.year == date.year &&
          ts.month == date.month &&
          ts.day == date.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayNotifications = _filterByDate(now);
    final yesterdayNotifications = _filterByDate(
      now.subtract(const Duration(days: 1)),
    );

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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SectionTitle(title: 'Today'),
                ...todayNotifications.map(
                  (item) => NotificationItem(item: item),
                ),
                const SizedBox(height: 20),
                const SectionTitle(title: 'Yesterday'),
                ...yesterdayNotifications.map(
                  (item) => NotificationItem(item: item),
                ),
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
          backgroundColor: Colors.deepPurple[50],
          child: Icon(Icons.notifications, color: Colors.deepPurple),
          radius: 24,
        ),
        title: Text(
          item['title'],
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16),
        ),
        subtitle: Text(
          DateFormat('hh:mm a').format(item['timestamp'] as DateTime),
          style: const TextStyle(fontSize: 12),
        ),
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
