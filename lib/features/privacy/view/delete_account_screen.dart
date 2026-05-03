import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/frappe_config.dart';
import '../../../core/services/frappe_client.dart';
import '../../../core/utils/user_friendly_error.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/views/auth_screen.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final FrappeClient _client = FrappeClient();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _agreeToDelete = false;
  bool _isDeleting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _canDelete {
    return _agreeToDelete &&
        _confirmController.text.trim().toUpperCase() == 'DELETE';
  }

  Future<void> _deleteAccount() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No authenticated user found.')),
      );
      return;
    }

    final user = authState.user;
    final email = user.email.trim();
    final userDocName = user.id.trim().isEmpty ? email : user.id.trim();

    setState(() => _isDeleting = true);

    try {
      // Disable related Client record first (if it exists).
      final clientResponse = await _client.get(
        '/api/resource/${FrappeConfig.clientDoctype}',
        queryParameters: {
          'filters': '[["${FrappeConfig.clientUserIdField}","=","$email"]]',
          'fields': '["name"]',
          'limit_page_length': '1',
        },
      );

      final clientData = clientResponse['data'];
      if (clientData is List && clientData.isNotEmpty) {
        final clientName = (clientData.first as Map)['name']?.toString();
        if (clientName != null && clientName.isNotEmpty) {
          await _client.put(
            '/api/resource/${FrappeConfig.clientDoctype}/$clientName',
            body: {
              'data': {FrappeConfig.clientStatusField: 'Inactive'},
            },
          );
        }
      }

      // Disable user account so login is blocked.
      await _client.put(
        '/api/resource/${FrappeConfig.userDoctype}/$userDocName',
        body: {
          'data': {FrappeConfig.userEnabledField: 0},
        },
      );

      // Trigger local sign-out cleanup.
      context.read<AuthBloc>().add(SignOutRequested());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account has been deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final friendly = UserFriendlyError.message(
        e,
        fallback:
            'Unable to delete account automatically. Please contact support.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendly), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete Account'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Before you continue',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• This action is permanent and cannot be undone.'),
                Text(
                  '• You will lose access to this account immediately after deletion.',
                ),
                Text(
                  '• Some records may be retained only where required for legal and compliance reasons.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Reason for deletion (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Type DELETE to confirm',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _agreeToDelete,
            contentPadding: EdgeInsets.zero,
            title: const Text('I understand this action is permanent.'),
            onChanged: (value) =>
                setState(() => _agreeToDelete = value ?? false),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_canDelete && !_isDeleting) ? _deleteAccount : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_forever_outlined),
              label: Text(_isDeleting ? 'Deleting...' : 'Delete My Account'),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'If automated deletion fails, contact support at info@habeshatax.co.uk.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
