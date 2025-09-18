import 'package:flutter/material.dart';
import '../../auth/views/auth_screen.dart';
import '../home/home_screen.dart';
import 'onboarding_content.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../../core/constants/app_color.dart';
import '../../../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentIndex = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "image": "assets/images/tax-1.png",
      "title": "Welcome to Habesha Tax App",
      "description":
          "Easily manage your income, expenses, and tax records. Your trusted partner for tax, tech, and trade support.",
    },
    {
      "image": "assets/images/tax-2.png",
      "title": "Upload & Track Your Finances",
      "description":
          "Snap and upload your payslips, receipts, and more. Track your income and expenses with simple tools.",
    },
    {
      "image": "assets/images/tax-splash.png",
      "title": "Get Tax Summaries Instantly",
      "description":
          "View monthly and yearly tax summaries at a glance. Always stay prepared for tax season with smart insights.",
    },
  ];

  void goToHome() {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AppWrapper()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _controller,
        itemCount: onboardingData.length,
        onPageChanged: (index) => setState(() => currentIndex = index),
        itemBuilder: (context, index) => OnboardingContent(
          image: onboardingData[index]['image']!,
          title: onboardingData[index]['title']!,
          description: onboardingData[index]['description']!,
        ),
      ),
      bottomSheet: currentIndex == onboardingData.length - 1
          ? Container(
              height: 80,
              margin: const EdgeInsets.only(bottom: 40),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor:
                          AppColor.appColor, // Or any color you want
                    ),
                    onPressed: () => _controller.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    ),
                    child: Text(
                      "Previous",
                      style: TextStyle(color: AppColor.appButtonText),
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          AppColor.appButton, // Use your branded color
                      foregroundColor:
                          AppColor.appContainerColor, // For text color
                    ),
                    onPressed: () => goToHome(),
                    child: Text(
                      "Get Started",
                      style: TextStyle(color: AppColor.appButtonText),
                    ),
                  ),
                ],
              ),
            )
          : Container(
              height: 80,
              margin: const EdgeInsets.only(bottom: 40),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => _controller.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    ),
                    child: Text(
                      "Previous",
                      style: TextStyle(color: AppColor.appButtonText),
                    ),
                  ),
                  FilledButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        AppColor.appButton,
                      ),
                    ),
                    onPressed: () => _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    ),
                    child: Text(
                      "Next",
                      style: TextStyle(color: AppColor.appButtonText),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
