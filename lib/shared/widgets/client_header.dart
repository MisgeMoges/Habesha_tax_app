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
  static final Map<String, _ClientHeaderCache> _cacheByEmail = {};
  static final Map<String, Future<void>> _inflightByEmail = {};

  bool _loading = false;
  String? _error;
  String? _clientName;
  String? _clientCode;
  String _activeEmail = '';

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final authState = context.read<AuthBloc>().state;
    final user = authState is Authenticated ? authState.user : null;
    final email = user?.email ?? '';

    if (_activeEmail == email) return;
    _activeEmail = email;

    if (email.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
        _clientName = 'Client';
        _clientCode = '';
      });
      return;
    }

    final cached = _cacheByEmail[email];
    if (cached != null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
        _clientName = cached.name;
        _clientCode = cached.code;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _clientName = null;
      _clientCode = null;
    });

    _inflightByEmail[email] ??= _loadClient(email);
    try {
      await _inflightByEmail[email];
    } catch (e) {
      _error = e.toString();
    } finally {
      _inflightByEmail.remove(email);
      if (mounted && _activeEmail == email) {
        final latest = _cacheByEmail[email];
        setState(() {
          _loading = false;
          _clientName = latest?.name ?? 'Client';
          _clientCode = latest?.code ?? '';
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
        _cacheByEmail[email] = _ClientHeaderCache(
          name: first['full_name'] as String? ?? 'Client',
          code: first['client_code'] as String? ?? '',
        );
      } else {
        throw Exception('Client record not found');
      }
    } catch (_) {
      _cacheByEmail[email] ??= const _ClientHeaderCache(
        name: 'Client',
        code: '',
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        final previousEmail = previous is Authenticated
            ? previous.user.email
            : '';
        final currentEmail = current is Authenticated ? current.user.email : '';
        return previousEmail != currentEmail;
      },
      listener: (_, __) => _hydrate(),
      child: () {
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
      }(),
    );
  }
}

class _ClientHeaderCache {
  const _ClientHeaderCache({required this.name, required this.code});

  final String name;
  final String code;
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
