import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String _effectiveDate = '17/04/2026';

  static const List<_LegalSection> _sections = [
    _LegalSection(
      title: '1. Introduction',
      body:
          'Habesha Tax & Support Ltd (“we”, “our”, “us”) respects your privacy and is committed to protecting your personal data. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application and services.',
    ),
    _LegalSection(
      title: '2. Information We Collect',
      body:
          'a) Personal Information\nWe may collect:\n• Full name\n• Email address\n• Phone number\n• Address\n• National Insurance number (if required for tax services)\n• UTR (Unique Taxpayer Reference)\n• Identification documents (passport, BRP, etc.)\n\nb) Financial Information\n• Income details\n• Expense records\n• Payroll information\n• Tax-related documents\n\nc) Technical Data\n• Device type\n• IP address\n• App usage data\n• Login activity',
    ),
    _LegalSection(
      title: '3. How We Use Your Information',
      body:
          'We use your data to:\n• Provide tax, bookkeeping, and financial services\n• Prepare and submit tax returns\n• Communicate with you regarding your account\n• Improve our app and services\n• Comply with legal and regulatory obligations',
    ),
    _LegalSection(
      title: '4. Legal Basis for Processing',
      body:
          'We process your data under:\n• Contractual obligation (providing services)\n• Legal obligation (HMRC compliance)\n• Legitimate interest (service improvement)\n• Consent (where required)',
    ),
    _LegalSection(
      title: '5. Data Sharing',
      body:
          'We may share your data with:\n• HM Revenue & Customs (HMRC)\n• Software providers (e.g., accounting systems)\n• Payment processors\n• Legal authorities when required\n\nWe do not sell your personal data.',
    ),
    _LegalSection(
      title: '6. Data Security',
      body:
          'We implement appropriate security measures including:\n• Encryption\n• Secure cloud storage\n• Access controls\nHowever, no system is 100% secure.',
    ),
    _LegalSection(
      title: '7. Data Retention',
      body:
          'We retain your data for:\n• Up to 6 years (as required by UK tax law)\n• Longer if legally required',
    ),
    _LegalSection(
      title: '8. Your Rights',
      body:
          'Under UK GDPR, you have the right to:\n• Access your data\n• Correct inaccurate data\n• Request deletion\n• Restrict processing\n• Object to processing\n• Data portability\n\nTo exercise these rights, contact us at:\ninfo@habeshatax.co.uk',
    ),
    _LegalSection(
      title: '9. Cookies and Tracking',
      body:
          'We may use cookies or similar technologies to improve app performance and user experience.',
    ),
    _LegalSection(
      title: '10. Third-Party Services',
      body:
          'Our app may integrate with third-party services (e.g., payment gateways, cloud storage). Their privacy policies apply.',
    ),
    _LegalSection(
      title: '11. Children’s Privacy',
      body:
          'Our services are not intended for children under 18. We do not knowingly collect data from minors.',
    ),
    _LegalSection(
      title: '12. Changes to This Policy',
      body:
          'We may update this policy from time to time. Updates will be posted within the app.',
    ),
    _LegalSection(
      title: '13. Contact Us',
      body:
          'Habesha Tax & Support Ltd\nEmail: info@habeshatax.co.uk\nAddress: Allied House 29-39 London Rd, Twickenham TW1 3SZ',
    ),

    _LegalSection(
      title: "Account Deletion",
      body:
          "You may request account deletion by contacting us at info@habeshatax.co.uk. We will delete your data unless legally required to retain it.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy'), centerTitle: true),
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
            'By using this app, you acknowledge that you have read and understood this Privacy Policy.',
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
