import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  static const String _lastUpdated = 'March 31, 2026';

  static const List<_LegalSection> _sections = [
    _LegalSection(
      title: '1. Acceptance of Terms',
      body:
          'By accessing or using Habesha Tax App, you agree to these Terms and all applicable laws. If you do not agree, do not use the service.',
    ),
    _LegalSection(
      title: '2. Eligibility and Account',
      body:
          'You are responsible for maintaining the confidentiality of your account credentials and for all activities under your account.',
    ),
    _LegalSection(
      title: '3. Service Scope',
      body:
          'The app helps you organize tax-related and financial records. It does not replace legal, tax, or accounting advice from licensed professionals.',
    ),
    _LegalSection(
      title: '4. User Content and Conduct',
      body:
          'You retain ownership of your data. You must not upload unlawful, infringing, malicious, or misleading content. You are responsible for data accuracy.',
    ),
    _LegalSection(
      title: '5. Payments and Billing',
      body:
          'If paid features are offered, pricing and renewal terms are shown before purchase. Taxes and payment processor terms may apply.',
    ),
    _LegalSection(
      title: '6. Availability and Updates',
      body:
          'We may update, suspend, or discontinue features to improve quality, security, and compliance. We aim to provide reliable service but do not guarantee uninterrupted availability.',
    ),
    _LegalSection(
      title: '7. Intellectual Property',
      body:
          'All app content, branding, and software are owned by Habesha Tax or licensors, except user-submitted content.',
    ),
    _LegalSection(
      title: '8. Limitation of Liability',
      body:
          'To the maximum extent permitted by law, we are not liable for indirect or consequential losses arising from your use of the app.',
    ),
    _LegalSection(
      title: '9. Termination',
      body:
          'You may stop using the service at any time. We may suspend or terminate accounts for violations of these Terms or legal requirements.',
    ),
    _LegalSection(
      title: '10. Account Deletion',
      body:
          'You may request permanent deletion directly in the app from Profile > Delete Account. Deletion effects may be immediate or subject to legal retention requirements.',
    ),
    _LegalSection(
      title: '11. Governing Law and Contact',
      body:
          'These Terms are governed by applicable local laws. For legal questions, contact: legal@habeshatax.com.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _LegalHeader(
            title: 'Habesha Tax Terms & Conditions',
            subtitle: 'Last updated: $_lastUpdated',
          ),
          const SizedBox(height: 12),
          ..._sections.map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LegalCard(section: section),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'By creating an account or using this app, you agree to these Terms.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _LegalHeader extends StatelessWidget {
  const _LegalHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _LegalCard extends StatelessWidget {
  const _LegalCard({required this.section});

  final _LegalSection section;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(section.body, style: const TextStyle(height: 1.45)),
          ],
        ),
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection({required this.title, required this.body});

  final String title;
  final String body;
}
