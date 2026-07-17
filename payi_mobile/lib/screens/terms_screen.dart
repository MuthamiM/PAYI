import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  final bool isPrivacyPolicy;

  const TermsScreen({super.key, this.isPrivacyPolicy = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isPrivacyPolicy ? 'Privacy Policy' : 'Terms of Service'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPrivacyPolicy ? 'Privacy Policy' : 'Terms of Service',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Last updated: March 12, 2026',
              style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(153)),
            ),
            const SizedBox(height: 32),
            if (isPrivacyPolicy) ..._buildPrivacyPolicy(context) else ..._buildTermsOfService(context),
            const SizedBox(height: 48),
            Center(
              child: Text(
                '© 2026 PAYI Inc. All rights reserved.',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withAlpha(102),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTermsOfService(BuildContext context) {
    return [
      _buildSection(
        context,
        '1. Acceptance of Terms',
        'By downloading, installing, or using the PAYI mobile application ("App"), you agree to be bound by these Terms of Service. If you do not agree, you must immediately cease all use of the App and uninstall it from your device.',
      ),
      _buildSection(
        context,
        '2. Eligibility',
        'You must be at least 18 years of age or the age of legal majority in your jurisdiction to use PAYI. By using the App, you represent and warrant that you have the legal capacity to enter into a binding agreement.',
      ),
      _buildSection(
        context,
        '3. Wallet and Transactions',
        'PAYI provides a digital wallet interface. You are solely responsible for all transactions initiated through your account. While we implement security measures, we do not guarantee the absolute security of digital assets. Transactions are irreversible once confirmed on the network.',
      ),
      _buildSection(
        context,
        '4. Fees and Charges',
        'We reserve the right to charge fees for certain services, including peer-to-peer transfers or currency conversion. Any applicable fees will be displayed prior to transaction confirmation.',
      ),
      _buildSection(
        context,
        '5. Prohibited Conduct',
        'You agree not to use the App for: (a) any illegal acts or in violation of any local, state, national, or international law; (b) fraudulent activities; (c) money laundering or terrorist financing; (d) unauthorized access to other accounts.',
      ),
      _buildSection(
        context,
        '6. Limitation of Liability',
        'To the maximum extent permitted by law, PAYI Inc. shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of profits or revenues, whether incurred directly or indirectly, or any loss of data, use, goodwill, or other intangible losses.',
      ),
      _buildSection(
        context,
        '7. Termination',
        'We reserve the right to suspend or terminate your account at our sole discretion, without notice, for conduct that we believe violates these Terms or is harmful to other users or our business interests.',
      ),
      _buildSection(
        context,
        '8. Governing Law',
        'These Terms shall be governed and construed in accordance with the laws of the jurisdiction in which PAYI Inc. is registered, without regard to its conflict of law provisions.',
      ),
    ];
  }

  List<Widget> _buildPrivacyPolicy(BuildContext context) {
    return [
      _buildSection(
        context,
        '1. Information Collection',
        'We collect information you provide directly to us when you create an account, including your name, email address, phone number, and financial data required for transactions.',
      ),
      _buildSection(
        context,
        '2. Use of Information',
        'We use the collected information to: (a) facilitate transactions and provide services; (b) verify your identity; (c) prevent fraud; (d) communicate updates; (e) improve our App experience.',
      ),
      _buildSection(
        context,
        '3. Data Sharing',
        'We do not sell your personal data. We may share information with third-party service providers (like Stripe for payments) strictly to perform services on our behalf.',
      ),
      _buildSection(
        context,
        '4. Security',
        'We implement industry-standard administrative, technical, and physical security measures to protect your personal information from unauthorized access and disclosure.',
      ),
      _buildSection(
        context,
        '5. Your Rights',
        'You have the right to access, correct, or delete your personal information stored in our systems. You can manage most data directly through your profile settings.',
      ),
    ];
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: theme.colorScheme.onSurface.withAlpha(204),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
