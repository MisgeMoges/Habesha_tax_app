import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/frappe_config.dart';
import '../../../core/services/frappe_client.dart';
import '../../../core/utils/user_friendly_error.dart';
import '../../../data/model/user.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final FrappeClient _client = FrappeClient();
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _tinController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyRegistrationNumberController = TextEditingController();
  final _vatNumberController = TextEditingController();
  final _taxCategoryController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  bool _loading = false;
  bool _saving = false;
  String? _error;
  String? _clientDocName;

  @override
  void initState() {
    super.initState();
    _loadClientProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _tinController.dispose();
    _companyNameController.dispose();
    _companyRegistrationNumberController.dispose();
    _vatNumberController.dispose();
    _taxCategoryController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
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
      print('Loading profile for user email: $email');

      final response = await _client.get(
        '/api/resource/${FrappeConfig.clientDoctype}',
        queryParameters: {
          'filters': '[["${FrappeConfig.clientUserIdField}","=","$email"]]',
          'fields':
              '["name","${FrappeConfig.clientFullNameField}","${FrappeConfig.clientEmailField}","${FrappeConfig.clientPhoneField}","${FrappeConfig.clientTinNumberField}","${FrappeConfig.clientCompanyNameField}","${FrappeConfig.clientCompanyRegistrationNumberField}","${FrappeConfig.clientVatNumberField}","${FrappeConfig.clientTaxCategoryField}","${FrappeConfig.clientAddressLine1Field}","${FrappeConfig.clientAddressLine2Field}","${FrappeConfig.clientPostalCodeField}","${FrappeConfig.clientCityField}","${FrappeConfig.clientStateField}"]',
          'limit_page_length': '1',
        },
      );

      final data = response['data'] ?? response['message'];
      if (data is List && data.isNotEmpty) {
        final first = Map<String, dynamic>.from(data.first as Map);
        _clientDocName = first['name']?.toString();
        _fullNameController.text =
            first[FrappeConfig.clientFullNameField]?.toString() ?? '';
        _emailController.text =
            first[FrappeConfig.clientEmailField]?.toString() ?? '';
        _phoneController.text =
            first[FrappeConfig.clientPhoneField]?.toString() ?? '';
        _tinController.text =
            first[FrappeConfig.clientTinNumberField]?.toString() ?? '';
        _companyNameController.text =
            first[FrappeConfig.clientCompanyNameField]?.toString() ?? '';
        _companyRegistrationNumberController.text =
            first[FrappeConfig.clientCompanyRegistrationNumberField]
                ?.toString() ??
            '';
        _vatNumberController.text =
            first[FrappeConfig.clientVatNumberField]?.toString() ?? '';
        _taxCategoryController.text =
            first[FrappeConfig.clientTaxCategoryField]?.toString() ?? '';
        _addressLine1Controller.text =
            first[FrappeConfig.clientAddressLine1Field]?.toString() ?? '';
        _addressLine2Controller.text =
            first[FrappeConfig.clientAddressLine2Field]?.toString() ?? '';
        _postalCodeController.text =
            first[FrappeConfig.clientPostalCodeField]?.toString() ?? '';
        _cityController.text =
            first[FrappeConfig.clientCityField]?.toString() ?? '';
        _stateController.text =
            first[FrappeConfig.clientStateField]?.toString() ?? '';
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

  Future<void> _saveClientProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_clientDocName == null || _clientDocName!.isEmpty) {
      await _loadClientProfile();
      if (_clientDocName == null || _clientDocName!.isEmpty) return;
    }

    setState(() => _saving = true);

    try {
      final payload = <String, dynamic>{
        FrappeConfig.clientFullNameField: _fullNameController.text.trim(),
        FrappeConfig.clientPhoneField: _phoneController.text.trim(),
        FrappeConfig.clientTinNumberField: _tinController.text.trim(),
        FrappeConfig.clientCompanyNameField: _companyNameController.text.trim(),
        FrappeConfig.clientCompanyRegistrationNumberField:
            _companyRegistrationNumberController.text.trim(),
        FrappeConfig.clientVatNumberField: _vatNumberController.text.trim(),
        FrappeConfig.clientTaxCategoryField: _taxCategoryController.text.trim(),
        FrappeConfig.clientAddressLine1Field: _addressLine1Controller.text
            .trim(),
        FrappeConfig.clientAddressLine2Field: _addressLine2Controller.text
            .trim(),
        FrappeConfig.clientPostalCodeField: _postalCodeController.text.trim(),
        FrappeConfig.clientCityField: _cityController.text.trim(),
        FrappeConfig.clientStateField: _stateController.text.trim(),
      };

      await _client.put(
        '/api/resource/${FrappeConfig.clientDoctype}/${_clientDocName!}',
        body: {'data': payload},
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserFriendlyError.message(
              e,
              fallback: 'Unable to update profile right now. Please try again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _profileInitial(User? user) {
    final name = user?.fullName.trim() ?? '';
    if (name.isNotEmpty) return name.characters.first.toUpperCase();
    final email = user?.email ?? '';
    if (email.isNotEmpty) return email.characters.first.toUpperCase();
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is Authenticated ? authState.user : null;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(title: const Text('Edit Profile'), centerTitle: true),
      body: Column(
        children: [
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFEAE2FF),
            child: Text(
              _profileInitial(user),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
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
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Full Name *',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email *',
                      keyboardType: TextInputType.emailAddress,
                      readOnly: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _tinController,
                      label: 'TIN Number',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _companyNameController,
                      label: 'Company Name (Optional)',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _companyRegistrationNumberController,
                      label: 'Company Registration Number (Optional)',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _vatNumberController,
                      label: 'VAT Number (Optional)',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _taxCategoryController,
                      label: 'Tax Category',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _addressLine1Controller,
                      label: 'Address Line 1',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _addressLine2Controller,
                      label: 'Address Line 2 (Optional)',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(controller: _cityController, label: 'City'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _stateController,
                      label: 'State',
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _postalCodeController,
                      label: 'Postal Code (Optional)',
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _saveClientProfile,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Update Profile'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
      ).copyWith(labelText: label),
    );
  }
}
