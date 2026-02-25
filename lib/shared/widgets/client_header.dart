import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/frappe_client.dart';
import '../../data/model/user.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';

class ClientAppBarTitle extends StatefulWidget {
  const ClientAppBarTitle({super.key});

  @override
  State<ClientAppBarTitle> createState() => _ClientAppBarTitleState();
}

class _ClientAppBarTitleState extends State<ClientAppBarTitle> {
  static String? _cachedName;
  static String? _cachedCode;
  static Future<void>? _inflight;

  bool _loading = false;
  String? _error;
  String? _clientName;
  String? _clientCode;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final authState = context.read<AuthBloc>().state;
    final user = authState is Authenticated ? authState.user : null;
    final email = user?.email ?? '';

    if (_cachedName != null || _cachedCode != null) {
      setState(() {
        _clientName = _cachedName;
        _clientCode = _cachedCode;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    _inflight ??= _loadClient(email);
    try {
      await _inflight;
    } finally {
      _inflight = null;
      if (mounted) {
        setState(() {
          _loading = false;
          _clientName = _cachedName;
          _clientCode = _cachedCode;
        });
      }
    }
  }

  Future<void> _loadClient(String email) async {
    try {
      final response = await FrappeClient().get(
        '/api/resource/Client',
        queryParameters: {
          'filters': '[["user_id","=","${email.isNotEmpty ? email : ''}"]]',
          'fields': '["full_name", "client_code"]',
          'limit_page_length': '1',
        },
      );

      final data = response['data'] ?? response['message'];
      if (data is List && data.isNotEmpty) {
        final first = Map<String, dynamic>.from(data.first as Map);
        _cachedName = first['full_name'] as String? ?? 'Client';
        _cachedCode = first['client_code'] as String? ?? '';
      } else {
        throw Exception('Client record not found');
      }
    } catch (e) {
      _error = e.toString();
      _cachedName ??= 'Client';
      _cachedCode ??= '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Text(
        'Loading client...',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      );
    }

    if (_error != null && (_clientName == null || _clientName!.isEmpty)) {
      return const Text(
        'Client',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _clientName ?? 'Client',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        if ((_clientCode ?? '').isNotEmpty)
          Text(
            'Client Code: $_clientCode',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

class ClientProfileLeading extends StatelessWidget {
  const ClientProfileLeading({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is Authenticated ? authState.user : null;
    final label = _profileLabel(user);

    return CircleAvatar(
      backgroundColor: const Color(0xFFEAE2FF),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _profileLabel(User? user) {
    final name = user?.fullName.trim() ?? '';
    if (name.isNotEmpty) return name.characters.first.toUpperCase();
    final email = user?.email ?? '';
    if (email.isNotEmpty) return email.characters.first.toUpperCase();
    return 'U';
  }
}
