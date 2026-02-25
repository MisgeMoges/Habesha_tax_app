import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habesha_tax_app/core/constants/app_color.dart';
import 'package:habesha_tax_app/core/services/frappe_client.dart';
import 'package:habesha_tax_app/core/config/frappe_config.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  int _registerStep = 0;
  final FrappeClient _client = FrappeClient();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _tinController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  String _selectedCountry = '';
  String _selectedBusinessType = '';
  String _selectedBusinessStatus = 'Active';
  String _selectedTaxCategory = '';
  String _selectedUserCategory = 'Business Owner';
  bool _acceptTerms = false;
  bool _resetRequested = false;
  String _resetMessage = 'Password updated successfully. Please log in.';
  bool _loadingLookups = false;
  String? _lookupError;
  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _obscureRegisterConfirmPassword = true;

  List<String> _businessTypes = [];
  final List<String> _businessStatuses = ['Active', 'Inactive', 'Pending'];
  List<String> _taxCategories = [];
  List<String> _countries = [];
  final List<String> _userCategories = ['Employee', 'Business Owner'];

  @override
  void initState() {
    super.initState();
    _loadLookupData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _tinController.dispose();
    _addressLine1Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _loadLookupData() async {
    setState(() {
      _loadingLookups = true;
      _lookupError = null;
    });

    try {
      // OPTION 1: Get all lookups in one call (Recommended)
      final response = await _client.get(
        '/api/method/habesha_tax.api.get_all_lookups',
      );

      if (response['success'] == true) {
        final data = response['data'];

        setState(() {
          _countries = List<String>.from(data['countries'] ?? []);
          _businessTypes = List<String>.from(data['business_types'] ?? []);
          _taxCategories = List<String>.from(data['tax_categories'] ?? []);
          _selectedCountry = _pickDefault(_countries, prefer: 'United Kingdom');
          _selectedBusinessType = _pickDefault(_businessTypes);
          _selectedTaxCategory = _pickDefault(_taxCategories);
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load lookup data');
      }
    } catch (e) {
      setState(() {
        _lookupError = 'Failed to load data: ${e.toString()}';

        // Set default values if API fails
        _countries = ['Ethiopia', 'Kenya', 'Uganda', 'Tanzania'];
        _businessTypes = [
          'Sole Proprietorship',
          'Partnership',
          'LLC',
          'Corporation',
        ];
        _taxCategories = ['VAT Registered', 'Non-VAT', 'Exempt'];
        _selectedCountry = 'Ethiopia';
        _selectedBusinessType = 'Sole Proprietorship';
        _selectedTaxCategory = 'VAT Registered';
      });
    } finally {
      setState(() => _loadingLookups = false);
    }
  }

  String _pickDefault(List<String> list, {String? prefer}) {
    if (list.isEmpty) return '';
    if (prefer != null && list.contains(prefer)) return prefer;
    return list.first;
  }

  void _submit() {
    if (_isLogin && !_formKey.currentState!.validate()) return;
    if (!_isLogin && !_validateAllRegistration()) return;

    if (_isLogin) {
      context.read<AuthBloc>().add(
        SignInRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    } else {
      context.read<AuthBloc>().add(
        SignUpRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          mobileNumber: _mobileController.text.trim(),
          userCategory: _selectedUserCategory,
          businessType: _selectedBusinessType,
          businessStatus: _selectedBusinessStatus,
          tinNumber: _tinController.text.trim(),
          taxCategory: _selectedTaxCategory,
          addressLine1: _addressLine1Controller.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          country: _selectedCountry,
        ),
      );
    }
  }

  bool _validateAllRegistration() {
    for (var i = 0; i < 4; i++) {
      if (!_validateStep(i, showMessage: false)) {
        _validateStep(i, showMessage: true);
        return false;
      }
    }
    return true;
  }

  bool _validateStep(int step, {bool showMessage = true}) {
    String? message;
    if (step == 0) {
      if (_firstNameController.text.trim().isEmpty) {
        message = 'Please enter your first name';
      } else if (_lastNameController.text.trim().isEmpty) {
        message = 'Please enter your last name';
      } else if (_emailController.text.trim().isEmpty ||
          !_emailController.text.contains('@')) {
        message = 'Please enter a valid email';
      } else if (_mobileController.text.trim().isEmpty) {
        message = 'Please enter your mobile number';
      } else if (_passwordController.text.isEmpty) {
        message = 'Please enter your password';
      } else if (_passwordController.text.length < 8) {
        message = 'Password must be at least 8 characters';
      } else if (_confirmPasswordController.text.isEmpty) {
        message = 'Please confirm your password';
      } else if (_confirmPasswordController.text != _passwordController.text) {
        message = 'Passwords do not match';
      }
    } else if (step == 1) {
      if (_selectedBusinessType.isEmpty) {
        message = 'Please select business type';
      } else if (_selectedTaxCategory.isEmpty) {
        message = 'Please select tax category';
      } else if (_tinController.text.trim().isEmpty) {
        message = 'Please enter your TIN';
      }
    } else if (step == 2) {
      if (_addressLine1Controller.text.trim().isEmpty) {
        message = 'Please enter address line 1';
      } else if (_cityController.text.trim().isEmpty) {
        message = 'Please enter your city/town';
      } else if (_stateController.text.trim().isEmpty) {
        message = 'Please enter your state/province';
      } else if (_selectedCountry.isEmpty) {
        message = 'Please enter your country';
      }
    } else if (step == 3) {
      if (!_acceptTerms) {
        message = 'Please accept the terms & conditions';
      }
    }

    if (message != null && showMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
    return message == null;
  }

  void _handleStepContinue() {
    if (_registerStep < 3) {
      if (!_validateStep(_registerStep)) return;
      setState(() => _registerStep += 1);
      return;
    }
    _submit();
  }

  void _handleStepCancel() {
    if (_registerStep == 0) return;
    setState(() => _registerStep -= 1);
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorText;

    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: [
                    Text(
                      'Enter a new password for ${_emailController.text.trim()}',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNewPassword,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNewPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureNewPassword = !obscureNewPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmController,
                      obscureText: obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureConfirmPassword = !obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorText!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newPassword = newPasswordController.text;
                    final confirmPassword = confirmController.text;

                    if (newPassword.isEmpty || newPassword.length < 8) {
                      setDialogState(() {
                        errorText =
                            'Password must be at least 8 characters long';
                      });
                      return;
                    }
                    if (newPassword != confirmPassword) {
                      setDialogState(() {
                        errorText = 'Passwords do not match';
                      });
                      return;
                    }

                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Update Password'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    _resetRequested = true;
    _resetMessage = 'Password updated successfully. Please log in.';
    context.read<AuthBloc>().add(
      UpdatePasswordRequested(
        email: _emailController.text.trim(),
        newPassword: newPasswordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        } else if (state is Authenticated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AppWrapper()),
          );
        } else if (state is Unauthenticated && _resetRequested) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_resetMessage),
              backgroundColor: Colors.green,
            ),
          );
          _emailController.clear();
          _passwordController.clear();
          _resetRequested = false;
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.transparent,
                    backgroundImage: const AssetImage(
                      "assets/images/logo1.png",
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isLogin ? 'Welcome Back' : 'Create Account',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLogin) ...[
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureLoginPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureLoginPassword = !_obscureLoginPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureLoginPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    if (_loadingLookups) const LinearProgressIndicator(),
                    if (_lookupError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: Text(
                          _lookupError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    Stepper(
                      currentStep: _registerStep,
                      onStepContinue: _handleStepContinue,
                      onStepCancel: _handleStepCancel,
                      controlsBuilder: (context, details) {
                        final isLastStep = _registerStep == 3;
                        return Row(
                          children: [
                            if (_registerStep > 0)
                              TextButton(
                                onPressed: details.onStepCancel,
                                child: const Text('Back'),
                              ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: details.onStepContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.appButton,
                              ),
                              child: Text(isLastStep ? 'Register' : 'Next'),
                            ),
                          ],
                        );
                      },
                      steps: [
                        Step(
                          title: const Text('Account'),
                          isActive: _registerStep >= 0,
                          content: Column(
                            children: [
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _firstNameController,
                                decoration: const InputDecoration(
                                  labelText: 'First Name *',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _lastNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Last Name *',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email *',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _mobileController,
                                decoration: const InputDecoration(
                                  labelText: 'Mobile Number *',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password *',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureRegisterPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureRegisterPassword =
                                            !_obscureRegisterPassword;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: _obscureRegisterPassword,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password *',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureRegisterConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureRegisterConfirmPassword =
                                            !_obscureRegisterConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: _obscureRegisterConfirmPassword,
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedUserCategory,
                                decoration: const InputDecoration(
                                  labelText: 'User Category *',
                                  border: OutlineInputBorder(),
                                ),
                                items: _userCategories.map((value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _selectedUserCategory = value);
                                },
                              ),
                            ],
                          ),
                        ),
                        Step(
                          title: const Text('Business'),
                          isActive: _registerStep >= 1,
                          content: Column(
                            children: [
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedBusinessType.isEmpty
                                    ? null
                                    : _selectedBusinessType,
                                decoration: const InputDecoration(
                                  labelText: 'Business Type *',
                                  border: OutlineInputBorder(),
                                ),
                                items: _businessTypes.map((value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _selectedBusinessType = value);
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedBusinessStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Business Status *',
                                  border: OutlineInputBorder(),
                                ),
                                items: _businessStatuses.map((value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(
                                    () => _selectedBusinessStatus = value,
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _tinController,
                                decoration: const InputDecoration(
                                  labelText: 'Tax ID (TIN) *',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedTaxCategory.isEmpty
                                    ? null
                                    : _selectedTaxCategory,
                                decoration: const InputDecoration(
                                  labelText: 'Tax Category *',
                                  border: OutlineInputBorder(),
                                ),
                                items: _taxCategories.map((value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _selectedTaxCategory = value);
                                },
                              ),
                            ],
                          ),
                        ),
                        Step(
                          title: const Text('Address'),
                          isActive: _registerStep >= 2,
                          content: Column(
                            children: [
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _addressLine1Controller,
                                decoration: const InputDecoration(
                                  labelText: 'Address Line 1 *',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _cityController,
                                decoration: const InputDecoration(
                                  labelText: 'City/Town *',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _stateController,
                                decoration: const InputDecoration(
                                  labelText: 'State/Province *',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                isExpanded: true, // ← ADD THIS
                                value: _selectedCountry.isEmpty
                                    ? null
                                    : _selectedCountry,
                                decoration: const InputDecoration(
                                  labelText: 'Country *',
                                  border: OutlineInputBorder(),
                                ),
                                items: _countries.map((value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      overflow: TextOverflow
                                          .ellipsis, // Optional: add ellipsis for long text
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _selectedCountry = value);
                                },
                              ),
                            ],
                          ),
                        ),
                        Step(
                          title: const Text('Terms'),
                          isActive: _registerStep >= 3,
                          content: CheckboxListTile(
                            value: _acceptTerms,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Accept Terms & Conditions *'),
                            onChanged: (value) {
                              setState(() => _acceptTerms = value ?? false);
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ),
                      ],
                    ),
                  ],
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      if (state is AuthLoading) {
                        return const CircularProgressIndicator();
                      }
                      return Column(
                        children: [
                          Column(
                            children: [
                              if (_isLogin)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColor.appButton,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              if (_isLogin)
                                TextButton(
                                  onPressed: _resetPassword,
                                  child: const Text('Forgot Password?'),
                                ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                                _registerStep = 0;
                              });
                            },
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.black),
                                children: [
                                  TextSpan(
                                    text: _isLogin
                                        ? "Don't have account? "
                                        : 'Already have an account? ',
                                  ),
                                  TextSpan(
                                    text: _isLogin
                                        ? 'Create new account'
                                        : 'Login',
                                    style: const TextStyle(
                                      color: Colors.deepPurple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
