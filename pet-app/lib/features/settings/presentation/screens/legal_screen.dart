import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class LegalScreen extends StatelessWidget {
  final String type;

  const LegalScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isTerms = type == 'terms';
    return Scaffold(
      appBar: AppBar(
        title: Text(isTerms ? 'Terms of Service' : 'Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTerms ? 'Terms of Service' : 'Privacy Policy',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: July 6, 2026',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            if (isTerms) ..._termsSections(context) else ..._privacySections(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _termsSections(BuildContext context) => [
        _section(
          context,
          '1. Acceptance of Terms',
          'By accessing or using the Pet Health Assistant application ("the App"), you agree to be bound by these Terms of Service. If you do not agree, do not use the App.',
        ),
        _section(
          context,
          '2. Description of Service',
          'The App provides AI-powered pet health information, symptom analysis, emergency guidance, and health tracking tools. The App is for informational purposes only and does not constitute veterinary medical advice.',
        ),
        _section(
          context,
          '3. User Accounts',
          'You are responsible for maintaining the confidentiality of your account credentials. You must provide accurate and complete information when creating an account. You are solely responsible for all activities under your account.',
        ),
        _section(
          context,
          '4. Acceptable Use',
          'You agree not to use the App for any unlawful purpose or in violation of any applicable laws. You may not attempt to reverse engineer, modify, or distribute the App without authorization.',
        ),
        _section(
          context,
          '5. Disclaimers',
          'The App provides AI-generated suggestions that are not a substitute for professional veterinary consultation. Always consult a licensed veterinarian for medical advice. The AI analysis may not be accurate for all conditions.',
        ),
        _section(
          context,
          '6. Limitation of Liability',
          'We shall not be liable for any damages arising from your use of the App. In no event shall our liability exceed the amount paid by you for access to the App.',
        ),
        _section(
          context,
          '7. Termination',
          'We reserve the right to suspend or terminate your access to the App at any time for violation of these terms. Upon termination, your right to use the App ceases immediately.',
        ),
        _section(
          context,
          '8. Changes to Terms',
          'We may update these terms at any time. Continued use of the App after changes constitutes acceptance of the new terms. We will notify users of material changes via the App or email.',
        ),
        _section(
          context,
          '9. Contact',
          'For questions about these terms, contact us at support@pethealthassistant.com.',
        ),
      ];

  List<Widget> _privacySections(BuildContext context) => [
        _section(
          context,
          '1. Information We Collect',
          'We collect information you provide when creating an account and using the App, including: name, email address, pet information (name, species, breed, age, weight, medical history), symptom descriptions, and usage data.',
        ),
        _section(
          context,
          '2. How We Use Information',
          'We use your information to: provide and improve the App\'s features, analyze symptoms using AI, send notifications you have opted into, communicate with you about your account, and comply with legal obligations.',
        ),
        _section(
          context,
          '3. Data Sharing',
          'We do not sell your personal information. We may share anonymized data for research purposes. We may share data with service providers who help operate the App. We may disclose data if required by law.',
        ),
        _section(
          context,
          '4. Data Security',
          'We implement reasonable security measures to protect your data. However, no method of electronic storage is 100% secure. You are responsible for keeping your account credentials secure.',
        ),
        _section(
          context,
          '5. Data Retention',
          'We retain your data for as long as your account is active. You may request deletion of your data by contacting us. Some data may be retained for legal compliance purposes.',
        ),
        _section(
          context,
          '6. Your Rights',
          'You have the right to access, correct, or delete your personal data. You may export your data upon request. You may opt out of marketing communications at any time.',
        ),
        _section(
          context,
          '7. Third-Party Services',
          'The App may use third-party services for AI processing, analytics, and push notifications. These services have their own privacy policies. We recommend reviewing them.',
        ),
        _section(
          context,
          '8. Children\'s Privacy',
          'The App is not intended for children under 13. We do not knowingly collect data from children under 13. If we discover such data, we will delete it promptly.',
        ),
        _section(
          context,
          '9. Changes to Policy',
          'We may update this policy. Material changes will be notified via the App or email. Continued use after changes constitutes acceptance of the updated policy.',
        ),
        _section(
          context,
          '10. Contact',
          'For privacy inquiries, contact us at privacy@pethealthassistant.com.',
        ),
      ];

  Widget _section(BuildContext context, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
