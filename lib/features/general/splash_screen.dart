import 'package:flutter/material.dart';
import 'package:habesha_tax_app/core/constants/app_color.dart';
import 'dart:async';
import 'onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    });
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
