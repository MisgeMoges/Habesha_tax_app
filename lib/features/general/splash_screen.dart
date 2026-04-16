import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habesha_tax_app/core/constants/app_color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_event.dart';
import '../auth/bloc/auth_state.dart';
import '../auth/views/auth_screen.dart';
import 'onboarding/onboarding_screen.dart';
import '../../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String _onboardingCompletedKey = 'onboarding_completed';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool(_onboardingCompletedKey) ?? false;

    if (!onboardingCompleted) {
      _navigateTo(const OnboardingScreen());
      return;
    }

    final authBloc = context.read<AuthBloc>();
    authBloc.add(AuthCheckRequested());

    AuthState resultState;
    final currentState = authBloc.state;
    if (currentState is Authenticated || currentState is Unauthenticated) {
      resultState = currentState;
    } else {
      resultState = await authBloc.stream
          .firstWhere(
            (state) =>
                state is Authenticated ||
                state is Unauthenticated ||
                state is AuthError,
          )
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => Unauthenticated(),
          );
    }

    if (!mounted) return;

    if (resultState is Authenticated) {
      _navigateTo(const AppWrapper());
      return;
    }

    _navigateTo(const AuthScreen());
  }

  void _navigateTo(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // decoration: const BoxDecoration(
        //   image: DecorationImage(
        //     image: AssetImage('assets/images/tax-splash.webp'),
        //     fit: BoxFit.cover,
        //   ),
        // ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/logo1.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
              // Icon(Icons.church, size: 100, color: Colors.deepPurple),
              const SizedBox(height: 20),
              const Text(
                "Habesha Tax",
                style: TextStyle(color: AppColor.appColor, fontSize: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
