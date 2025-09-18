import 'package:flutter/material.dart';

class OnboardingContent extends StatelessWidget {
  final String image, title, description;

  const OnboardingContent({
    super.key,
    required this.image,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Image.asset(image, width: double.infinity, fit: BoxFit.cover),
        ),
        Container(
          height: MediaQuery.of(context).size.height * 0.45,
          padding: const EdgeInsets.only(top: 25),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
