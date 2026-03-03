import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/frappe_config.dart';
import '../../../core/services/frappe_client.dart';
import '../../../core/utils/user_friendly_error.dart';
import '../../../data/model/user.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/views/auth_screen.dart';
import '../../employee/view/client_employee_management_screen.dart';
import '../../transaction/view/invoice/invoice_screen.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FrappeClient _client = FrappeClient();
  bool _loading = false;
  String? _error;
  String? _clientName;
  String? _clientEmail;
  String? _clientPhone;
  String? _companyName;
  String? _companyRegistrationNumber;
  String? _vatNumber;

  @override
  void initState() {
    super.initState();
    _loadClientProfile();
  }

  Future<void> _loadClientProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      final user = authState is Authenticated ? authState.user : null;
      final email = user?.email ?? '';

      final response = await _client.get(
        '/api/resource/${FrappeConfig.clientDoctype}',
        queryParameters: {
          'filters': '[["${FrappeConfig.clientUserIdField}","=","$email"]]',
          'fields':
              '["${FrappeConfig.clientFullNameField}","${FrappeConfig.clientEmailField}","${FrappeConfig.clientPhoneField}","${FrappeConfig.clientCompanyNameField}","${FrappeConfig.clientCompanyRegistrationNumberField}","${FrappeConfig.clientVatNumberField}"]',
          'limit_page_length': '1',
        },
      );

      final data = response['data'] ?? response['message'];
      if (data is List && data.isNotEmpty) {
        final first = Map<String, dynamic>.from(data.first as Map);
        _clientName = first[FrappeConfig.clientFullNameField]?.toString() ?? '';
        _clientEmail = first[FrappeConfig.clientEmailField]?.toString() ?? '';
        _clientPhone = first[FrappeConfig.clientPhoneField]?.toString() ?? '';
        _companyName =
            first[FrappeConfig.clientCompanyNameField]?.toString() ?? '';
        _companyRegistrationNumber =
            first[FrappeConfig.clientCompanyRegistrationNumberField]
                ?.toString() ??
            '';
        _vatNumber = first[FrappeConfig.clientVatNumberField]?.toString() ?? '';
      } else {
        throw Exception('Client record not found');
      }
    } catch (e) {
      _error = UserFriendlyError.message(
        e,
        fallback: 'Unable to load profile right now.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _profileInitial(User? user) {
    final name = (_clientName ?? user?.fullName ?? '').trim();
    if (name.isNotEmpty) return name.characters.first.toUpperCase();
    final email = (_clientEmail ?? user?.email ?? '').trim();
    if (email.isNotEmpty) return email.characters.first.toUpperCase();
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is Authenticated ? authState.user : null;

    final List<_ProfileItem> profileItems = const [
      _ProfileItem(
        icon: Icons.people_alt,
        label: 'Employees',
        color: Colors.deepOrange,
        screen: ClientEmployeeManagementScreen(),
      ),
      _ProfileItem(
        icon: Icons.receipt_long,
        label: 'Generate Invoice',
        color: Colors.indigo,
        screen: InvoiceScreen(),
      ),
      _ProfileItem(icon: Icons.logout, label: 'Logout', color: Colors.red),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        leading: const Padding(
          padding: EdgeInsets.all(12),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.transparent,
            backgroundImage: AssetImage("assets/images/logo1.png"),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              );
            },
            icon: const Icon(Icons.edit, color: Colors.black),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 44,
            backgroundColor: const Color(0xFFEAE2FF),
            child: Text(
              _profileInitial(user),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _clientName?.isNotEmpty == true
                ? _clientName!
                : (user?.fullName ?? 'Client'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            _clientEmail?.isNotEmpty == true
                ? _clientEmail!
                : (user?.email ?? ''),
            style: const TextStyle(color: Colors.grey),
          ),
          if (_clientPhone?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _clientPhone!,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          if (_companyName?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Company: ${_companyName!}',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          if (_companyRegistrationNumber?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Company Reg No: ${_companyRegistrationNumber!}',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          if (_vatNumber?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'VAT No: ${_vatNumber!}',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: profileItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final item = profileItems[index];
                return GestureDetector(
                  onTap: () {
                    if (item.label == 'Logout') {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Logout"),
                          content: const Text(
                            "Are you sure you want to logout?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                context.read<AuthBloc>().add(
                                  SignOutRequested(),
                                );
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AuthScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                              child: const Text("Logout"),
                            ),
                          ],
                        ),
                      );
                    } else if (item.screen != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => item.screen!),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(item.icon, color: item.color, size: 32),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            item.label,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ],
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

class _ProfileItem {
  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.color,
    this.screen,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Widget? screen;
}
