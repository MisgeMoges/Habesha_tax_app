import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habesha_tax_app/core/constants/app_color.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../general/home/home_screen.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io' show Platform;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  File? _profileImage;
  String _selectedCategory = 'Member'; // Default category
  bool _resetRequested = false;

  final List<String> _memberCategories = [
    'Clergy',
    'Member',
    'Priest',
    'Deacon',
    'Sunday Students Member',
    'Elder',
    'Youth',
    'Children',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

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
          middleName: _middleNameController.text.trim(),
          memberCategory: _selectedCategory,
          profileImage:
              _profileImage ?? File(''), // Make profile image optional
        ),
      );
    }
  }

  void _resetPassword() {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }
    _resetRequested = true;
    context.read<AuthBloc>().add(
      ResetPasswordRequested(email: _emailController.text.trim()),
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
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else if (state is Unauthenticated && _resetRequested) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset email sent! Check your inbox.'),
              backgroundColor: Colors.green,
            ),
          );
          _resetRequested = false;
        }
      },
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: const AssetImage(
                      "assets/images/logo1.png",
                    ),
                  ),
                  // const Icon(
                  //   Icons.church,
                  //   size: 80,
                  //   color: Colors.deepPurple,
                  // ),
                  const SizedBox(height: 20),
                  Text(
                    _isLogin ? 'Welcome Back' : 'Create Account',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_isLogin) ...[
                    //   GestureDetector(
                    //     onTap: _pickImage,
                    //     child: CircleAvatar(
                    //       radius: 50,
                    //       backgroundColor: Colors.grey[200],
                    //       backgroundImage: _profileImage != null
                    //           ? FileImage(_profileImage!)
                    //           : null,
                    //       child: _profileImage == null
                    //           ? const Icon(Icons.add_a_photo, size: 40)
                    //           : null,
                    //     ),
                    //   ),
                    //   const SizedBox(height: 8),
                    //   const Text(
                    //     'Add Profile Picture (Optional)',
                    //     style: TextStyle(color: Colors.grey, fontSize: 12),
                    //   ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Member Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _memberCategories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (!_isLogin && (value == null || value.isEmpty)) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (!_isLogin && (value == null || value.isEmpty)) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _middleNameController,
                      decoration: const InputDecoration(
                        labelText: 'Middle Name (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
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
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
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
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      if (state is AuthLoading) {
                        return const CircularProgressIndicator();
                      }
                      return Column(
                        children: [
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _submit,
                                  // onPressed: () {
                                  //   Navigator.pushReplacement(
                                  //     context,
                                  //     MaterialPageRoute(
                                  //       builder: (_) => const HomeScreen(),
                                  //     ),
                                  //   );
                                  // },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColor.appButton,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child: Text(
                                    _isLogin ? 'Login' : 'Register',
                                    style: const TextStyle(
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
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  'or sign in with',
                                  style: TextStyle(
                                    color: Colors.deepPurple,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 24),
                          FutureBuilder<bool>(
                            future: SignInWithApple.isAvailable(),
                            builder: (context, snapshot) {
                              final isAppleAvailable = snapshot.data ?? false;

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildSocialButton(
                                    onTap: () {
                                      context.read<AuthBloc>().add(
                                        SignInWithGoogleRequested(),
                                      );
                                    },
                                    icon: Image.asset(
                                      'assets/images/google.png',
                                      height: 60,
                                    ),
                                  ),
                                  if (isAppleAvailable &&
                                      (Platform.isIOS || Platform.isMacOS)) ...[
                                    const SizedBox(width: 20),
                                    _buildSocialButton(
                                      onTap: () {
                                        context.read<AuthBloc>().add(
                                          SignInWithAppleRequested(),
                                        );
                                      },
                                      icon: Image.asset(
                                        'assets/images/apple.png',
                                        height: 60,
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
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

  Widget _buildSocialButton({
    required VoidCallback onTap,
    required Widget icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 50,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: icon,
      ),
    );
  }
}
