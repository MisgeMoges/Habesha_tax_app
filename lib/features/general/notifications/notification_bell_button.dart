import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import 'notifications_screen.dart';

class NotificationBellButton extends StatefulWidget {
  const NotificationBellButton({super.key, this.iconColor = Colors.black});

  final Color iconColor;

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton> {
  Timer? _timer;

  String get _userEmail {
    final authState = context.read<AuthBloc>().state;
    final user = authState is Authenticated ? authState.user : null;
    return user?.email ?? '';
  }

  @override
  void initState() {
    super.initState();
    NotificationCenter.refreshUnreadCount(userEmail: _userEmail);
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      NotificationCenter.refreshUnreadCount(userEmail: _userEmail);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationCenter.unreadCountNotifier,
      builder: (context, unreadCount, _) {
        final icon = Icon(Icons.notifications_none, color: widget.iconColor);
        final iconWithBadge = unreadCount <= 0
            ? icon
            : Stack(
                clipBehavior: Clip.none,
                children: [
                  icon,
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );

        return IconButton(
          icon: iconWithBadge,
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            );
            await NotificationCenter.refreshUnreadCount(userEmail: _userEmail);
          },
        );
      },
    );
  }
}
