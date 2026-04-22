import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  static const String _effectiveDate = '17/04/2026';

  static const List<_LegalSection> _sections = [
    _LegalSection(
      title: '1. Acceptance of Terms',
      body:
          'By using our mobile application, you agree to these Terms and Conditions. If you do not agree, please do not use the app.',
    ),
    _LegalSection(
      title: '2. Services Provided',
      body:
          'We provide:\n• Self-Assessment tax return services\n• Bookkeeping and payroll support\n• Business financial management\n• Home office application-related assistance (non-legal advice)',
    ),
    _LegalSection(
      title: '3. User Responsibilities',
      body:
          'You agree to:\n• Provide accurate and complete information\n• Keep your login details secure\n• Update your information when necessary\n• Use the app lawfully',
    ),
    _LegalSection(
      title: '4. Account Registration',
      body:
          'You must:\n• Be at least 18 years old\n• Provide valid contact details\n• Maintain confidentiality of your account\n\nWe reserve the right to suspend accounts for misuse.',
    ),
    _LegalSection(
      title: '5. Fees and Payments',
      body:
          '• Some services may be paid\n• Fees will be clearly communicated\n• Payments are non-refundable unless stated otherwise',
    ),
    _LegalSection(
      title: '6. Tax Responsibility Disclaimer',
      body:
          'While we assist with tax preparation:\n• You remain responsible for the accuracy of your information\n• We rely on data you provide\n• HMRC decisions are final',
    ),
    _LegalSection(
      title: '7. Limitation of Liability',
      body:
          'We are not liable for:\n• Errors caused by incorrect information you provide\n• Delays from third parties (e.g., HMRC)\n• Indirect or consequential losses',
    ),
    _LegalSection(
      title: '8. Data Protection',
      body: 'Your data is handled according to our Privacy Policy.',
    ),
    _LegalSection(
      title: '9. Intellectual Property',
      body:
          'All content in the app belongs to Habesha Tax & Support Ltd. You may not copy or distribute without permission.',
    ),
    _LegalSection(
      title: '10. Termination',
      body:
          'We may suspend or terminate access if:\n• You breach these terms\n• Fraudulent activity is suspected\n• Required by law',
    ),
    _LegalSection(
      title: '11. Changes to Terms',
      body:
          'We may update these terms at any time. Continued use means acceptance of changes.',
    ),
    _LegalSection(
      title: '12. Governing Law',
      body: 'These terms are governed by the laws of England and Wales.',
    ),
    _LegalSection(
      title: '13. Contact Information',
      body:
          'Habesha Tax & Support Ltd\nEmail: info@habeshatax.co.uk\nAddress: Allied House 29-39 London Rd, Twickenham TW1 3SZ',
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
            title: 'Habesha Tax & Support Ltd',
            subtitle: 'Effective Date: $_effectiveDate',
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
            'By creating an account or using this app, you agree to these Terms and Conditions.',
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
