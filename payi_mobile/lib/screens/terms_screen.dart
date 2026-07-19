import 'package:flutter/material.dart';
import '../theme/colors.dart';

class TermsScreen extends StatefulWidget {
  final bool isPrivacyPolicy;

  const TermsScreen({super.key, this.isPrivacyPolicy = false});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  int _tapCount = 0;
  bool _showSecretRules = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleCopyrightTap() {
    setState(() {
      _tapCount++;
      if (_tapCount >= 5) {
        _showSecretRules = !_showSecretRules;
        _tapCount = 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_showSecretRules ? '🔓 Secret System Rules Unlocked!' : '🔒 Secret System Rules Hidden!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final allSections = widget.isPrivacyPolicy 
        ? _buildDetailedPrivacyPolicy(context) 
        : _buildDetailedTermsOfService(context);

    final filteredSections = allSections.where((section) {
      final query = _searchQuery.toLowerCase();
      return section.title.toLowerCase().contains(query) || 
             section.content.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.isPrivacyPolicy ? 'Privacy Policy' : 'Terms of Service'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search legal clauses...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isPrivacyPolicy ? 'Detailed Privacy Policy' : 'Detailed Terms of Service',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Document Version: 4.12.9 (Last updated: July 20, 2026)',
                    style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(150), fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  
                  // Hidden Rules Section
                  if (_showSecretRules) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: theme.colorScheme.primary.withAlpha(60), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lock_open, color: theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'SYSTEM INTEGRITY & HIDDEN RULES',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1.2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Rule 1: Always check system status via the status dashboard before processing operations.\n'
                            'Rule 2: Do not share your API session JWT keys or store them in plain text.\n'
                            'Rule 3: Any geo-blocking override attempts will result in account review.\n'
                            'Rule 4: Multi-currency balances are calculated dynamically from latest oracle rates.\n'
                            'Rule 5: Antigravity AI assistant remains pair-programmed to maintain system security policies.',
                            style: TextStyle(fontSize: 13, height: 1.5, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (filteredSections.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'No matching legal clauses found.',
                          style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(120)),
                        ),
                      ),
                    )
                  else
                    ...filteredSections.map((sec) => _buildSectionWidget(context, sec.title, sec.content)),
                  
                  const SizedBox(height: 48),
                  Center(
                    child: GestureDetector(
                      onTap: _handleCopyrightTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        color: Colors.transparent, // expand tap target
                        child: Text(
                          '© 2026 PAYI Inc. All rights reserved. (Rev 4.12)',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withAlpha(102),
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                            decorationStyle: TextDecorationStyle.dashed,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionWidget(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withAlpha(200),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  List<LegalSection> _buildDetailedTermsOfService(BuildContext context) {
    return [
      LegalSection('1. ACCEPTANCE AND SCOPE OF TERMS', 
        'Welcome to PAYI. These Terms of Service ("Terms") constitute a legally binding agreement between you ("User" or "you") and PAYI Inc. ("Company," "we," "us," or "our"). By downloading, installing, accessing, or using the PAYI mobile application ("App"), website, platform, APIs, or any associated payment services (collectively, the "Services"), you acknowledge that you have read, understood, and agree to be bound by these Terms, as well as our Privacy Policy, which is incorporated herein by reference. If you do not agree to these Terms, you are not authorized to use the Services and must immediately delete the App and stop accessing our platforms.'),
      
      LegalSection('2. MODIFICATION OF TERMS', 
        'We reserve the right, in our sole discretion, to modify, update, amend, or replace these Terms at any time. Any changes will become effective immediately upon posting the updated Terms in the App or on our website. It is your sole responsibility to check these Terms periodically for updates. Your continued use of the Services following the posting of any changes constitutes your binding acceptance of those changes. If you do not agree to the amended Terms, your only recourse is to terminate your account and cease using the Services.'),
      
      LegalSection('3. ACCOUNT REGISTRATION AND ELIGIBILITY', 
        'To access the full features of the Services, you must register for a PAYI account ("Account"). You represent and warrant that: (a) you are at least 18 years of age or the age of majority in your jurisdiction; (b) you possess the legal capacity and authority to enter into these Terms; (c) all registration and profile information you submit is accurate, current, complete, and truthful; (d) you will maintain the accuracy of such information; and (e) your use of the Services does not violate any applicable law or regulation, including sanction rules. You are responsible for providing all equipment and network connections necessary to access the Services.'),
      
      LegalSection('4. IDENTITY VERIFICATION AND KYC COMPLIANCE', 
        'PAYI operates under strict anti-money laundering (AML) and counter-terrorist financing (CTF) regulations. As part of our Know Your Customer (KYC) requirements, we may require you to verify your identity by submitting copies of government-issued identification cards, passports, biometric face scans, proof of address, and other verified documentation. You authorize us to share this information with third-party verification providers to verify your identity. We reserve the absolute right to suspend, restrict, or terminate your Account if you fail to provide satisfactory verification details or if the provided details are flagged as fraudulent or high-risk.'),
      
      LegalSection('5. ACCOUNT SECURITY AND CREDENTIALS', 
        'You are solely responsible for maintaining the confidentiality of your Account login credentials, including passwords, PINs, biometric data, and any stored session keys or JWT tokens. You agree to take all reasonable steps to prevent unauthorized access to your Account. Any activity conducted through your Account will be deemed to have been authorized by you. You must immediately notify PAYI Support if you suspect or detect any unauthorized access, security breach, or loss of credentials. We shall not be liable for any losses caused by unauthorized use of your Account.'),
      
      LegalSection('6. DIGITAL WALLET SERVICE DESCRIPTION', 
        'PAYI provides a digital wallet system that enables users to store, monitor, and manage multi-currency balances (e.g., USD, KES, NGN, CNY, EUR, GBP, AED, SAR) and perform peer-to-peer (P2P) transfers, bank transfers, bill payments, and other financial actions. The App acts as a client-side interface to our backend ledger system. Balances represented in your Account represent unsecured claims against the Company and do not constitute bank deposits, nor are they insured by the FDIC or any other government agency.'),
      
      LegalSection('7. TRANSACTION INITIATION AND FINALITY', 
        'By initiating a transaction (including Send, Receive, Top-Up, Bank Transfer, or Bill Payment), you authorize PAYI to debit your Account balance and credit the designated recipient or third-party provider. Once a transaction is submitted, it is processed immediately and is completely irreversible. PAYI cannot cancel, recall, or modify a transaction once it has been executed on the ledger. You must double-check all recipient accounts, emails, phone numbers, and amounts before confirming a transaction.'),
      
      LegalSection('8. MULTI-CURRENCY CONVERSION AND ORACLE RATES', 
        'When you execute a transfer involving different currencies (e.g., sending USD to a KES wallet), a currency conversion is performed. The exchange rates applied to these conversions are calculated dynamically based on real-time market feeds from external financial oracles and liquidity providers. These rates fluctuate constantly. The rate displayed at the time of transaction execution is the final rate. PAYI may add a small markup or spread to the base exchange rate as a conversion service fee.'),
      
      LegalSection('9. FEES, PRICING, AND CHARGES', 
        'We reserve the right to charge fees for utilizing specific features of the Services, including but not limited to cross-border transfers, bank withdrawals, instant top-ups, and bill payments. The current fee schedule is available in the App and is displayed prior to transaction confirmation. All fees are non-refundable. We may change our fee structures at any time by updating the fee schedule within the App.'),
      
      LegalSection('10. TRANSACTION AND WALLET LIMITS', 
        'To comply with regulatory requirements and manage risk, PAYI imposes daily, weekly, and monthly limits on the amount of funds you can deposit, transfer, convert, or withdraw. These limits are determined based on your verification tier (KYC level), transaction history, and risk profile. We reserve the right to modify these limits for your Account at our discretion without prior notice.'),
      
      LegalSection('11. STRIPE INTEGRATION AND TOP-UPS', 
        'Top-ups performed via credit or debit card are processed through Stripe, Inc. By using card top-ups, you agree to be bound by Stripe\'s Services Agreement and Privacy Policy. PAYI does not store full credit card numbers or CVVs on its servers. We are not responsible for any issues, declines, or holds placed by Stripe or your card issuer.'),
      
      LegalSection('12. PROHIBITED ACTIVITES AND LEGAL USE', 
        'You agree not to use PAYI for any of the following prohibited activities: (a) purchasing or selling illegal drugs, weapons, or counterfeit goods; (b) gambling, betting, or lottery schemes; (c) money laundering, terrorist financing, or tax evasion; (d) Ponzi schemes, pyramid schemes, or multi-level marketing; (e) accessing accounts without authorization; (f) scraping or reverse engineering the App; or (g) any conduct that violates applicable local or international laws.'),
      
      LegalSection('13. SUSPENSION, RESTRICTION, AND TERMINATION', 
        'We may suspend, restrict, freeze, or terminate your Account and access to the Services, at our sole discretion, without liability, if: (a) we suspect a violation of these Terms; (b) your account is flagged for high risk of fraud, money laundering, or security breaches; (c) we are required to do so by a court order, regulatory body, or law enforcement agency; or (d) you engage in abusive or threatening behavior toward our staff.'),
      
      LegalSection('14. GEOGRAPHIC RESTRICTIONS AND IP BLOCKING', 
        'The Services are not available in all jurisdictions. We reserve the right to implement geo-blocking policies, IP address filters, and other technical restrictions to block access to the Services from sanctioned countries, high-risk regions, or jurisdictions where we do not hold active regulatory licenses. You represent that you are not located in any restricted area.'),
      
      LegalSection('15. NO FINANCIAL OR LEGAL ADVICE', 
        'Any information, market rates, interest calculators (such as the 5.2% APY savings rate), or crypto insights displayed in the App are for informational purposes only. They do not constitute financial, investment, legal, or tax advice. You should consult with qualified professionals before making any financial decisions.'),
      
      LegalSection('16. INTELLECTUAL PROPERTY RIGHTS', 
        'All intellectual property rights in the App, website, logo (SVG/PNG), designs, software, code (Dart, JavaScript, C#), themes, and content belong exclusively to PAYI Inc. and its licensors. You are granted a limited, non-exclusive, non-transferable, revocable license to use the App for personal use in accordance with these Terms.'),
      
      LegalSection('17. DISCLAIMER OF WARRANTIES', 
        'THE SERVICES ARE PROVIDED ON AN "AS IS" AND "AS AVAILABLE" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED. TO THE FULLEST EXTENT PERMITTED BY LAW, WE DISCLAIM ALL WARRANTIES, INCLUDING MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. WE DO NOT GUARANTEE THAT THE SERVICES WILL BE ERROR-FREE, SECURE, OR UNINTERRUPTED.'),
      
      LegalSection('18. LIMITATION OF LIABILITY', 
        'IN NO EVENT SHALL PAYI INC., ITS DIRECTORS, EMPLOYEES, OR AGENTS BE LIABLE FOR ANY INDIRECT, SPECIAL, INCIDENTAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING LOSS OF PROFITS, DATA, OR USE, ARISING OUT OF OR IN CONNECTION WITH THE SERVICES, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.'),
      
      LegalSection('19. INDEMNIFICATION', 
        'You agree to indemnify, defend, and hold harmless PAYI Inc., its affiliates, officers, and employees from and against any claims, liabilities, damages, losses, and expenses (including legal fees) arising out of or related to your use of the Services, violation of these Terms, or infringement of any third-party rights.'),
      
      LegalSection('20. FORCE MAJEURE', 
        'We shall not be liable for any delay or failure in performance resulting from causes beyond our reasonable control, including acts of God, war, terrorism, riots, embargos, acts of civil or military authorities, fire, floods, accidents, network outages, or server hardware failures.'),
      
      LegalSection('21. DISPUTE RESOLUTION AND ARBITRATION', 
        'Any dispute, controversy, or claim arising out of or relating to these Terms or the Services shall be settled by binding arbitration in accordance with the rules of the American Arbitration Association (AAA). The arbitration shall be conducted in English. The decision of the arbitrator shall be final and binding.'),
      
      LegalSection('22. CLASS ACTION WAIVER', 
        'YOU AGREE THAT ANY DISPUTE RESOLUTION PROCEEDINGS WILL BE CONDUCTED ONLY ON AN INDIVIDUAL BASIS AND NOT IN A CLASS, CONSOLIDATED, OR REPRESENTATIVE ACTION. YOU WAIVE THE RIGHT TO PARTICIPATE IN A CLASS ACTION LAWSUIT.'),
      
      LegalSection('23. SEVERABILITY AND WAIVER', 
        'If any provision of these Terms is found to be invalid or unenforceable, that provision shall be limited or eliminated to the minimum extent necessary, and the remaining provisions shall remain in full force and effect. Our failure to enforce any right or provision shall not constitute a waiver.'),
      
      LegalSection('24. ENTIRE AGREEMENT', 
        'These Terms, along with the Privacy Policy and any other legal agreements published by us in the App, constitute the entire agreement between you and PAYI Inc. regarding the use of the Services, superseding any prior verbal or written agreements.'),
      
      LegalSection('25. CONTACT INFORMATION', 
        'If you have any questions, concerns, or feedback regarding these Terms of Service, please contact our Legal Department via email at legal@payi.com or write to us at PAYI Inc., Legal Compliance Division, Suite 500, New York, NY 10001.'),
    ];
  }

  List<LegalSection> _buildDetailedPrivacyPolicy(BuildContext context) {
    return [
      LegalSection('1. SCOPE AND CONSENT', 
        'PAYI Inc. ("we," "us," or "our") is committed to protecting your privacy. This Privacy Policy describes how we collect, use, store, share, and protect your personal information when you use the PAYI mobile application ("App"), website, platform, and associated services. By accessing or using our Services, you consent to the collection and use of your information as outlined in this Policy.'),
      
      LegalSection('2. INFORMATION WE COLLECT DIRECTLY', 
        'We collect information you provide directly to us when registering an Account or completing your profile. This includes: (a) name; (b) email address; (c) phone number; (d) physical address; (e) password hash; and (f) billing details. We also collect any documents you upload for identity verification (KYC), such as copies of ID cards, passports, and selfie photos.'),
      
      LegalSection('3. INFORMATION COLLECTED AUTOMATICALLY', 
        'When you use the App, we automatically collect certain technical data, including: (a) IP address; (b) device model, operating system version, and unique device identifiers; (c) network status and carrier information; (d) App usage statistics, clickstreams, and screens viewed; and (e) crash logs and diagnostic information.'),
      
      LegalSection('4. GEOLOCATION DATA', 
        'To prevent fraudulent transactions and comply with regional licensing restrictions, we may collect your precise geographic coordinates (latitude and longitude) when you initiate transfers, card top-ups, or bill payments. We collect this data only if you grant the App permission to access your location services. You can disable location tracking in your device settings, but doing so may limit your access to certain Services.'),
      
      LegalSection('5. USE OF PERSONAL DATA', 
        'We use your personal data to: (a) authenticate your identity and secure your Account; (b) process currency conversions, transfers, and payments; (c) calculate and apply transaction fees; (d) perform risk assessments and detect fraud, money laundering, or abuse; (e) send transaction receipts and system notifications; and (f) comply with regulatory requirements.'),
      
      LegalSection('6. DATA RETENTION POLICIES', 
        'We retain your personal information, transaction history, and KYC records for as long as your Account remains active, and for a subsequent period as required by applicable tax, financial, and AML laws (typically 5 to 7 years post-account closure). When no longer required, data is deleted or anonymized.'),
      
      LegalSection('7. DATA SHARING WITH THIRD PARTIES', 
        'We do not sell, rent, or trade your personal data. We share information only with: (a) payment processors (like Stripe) to facilitate card top-ups; (b) KYC/AML identity verification agencies; (c) cloud hosting providers; and (d) law enforcement, courts, or regulatory bodies when legally compelled to do so.'),
      
      LegalSection('8. COOKIES AND LOCAL STORAGE', 
        'We use local database storage, shared preferences, and session tokens (JWT) to remember your login state, theme preferences, and security settings on your device. These files do not contain unencrypted passwords and are used solely to improve performance and usability.'),
      
      LegalSection('9. DATA SECURITY MEASURES', 
        'We implement industry-standard technical security controls, including AES-256 database encryption, TLS/HTTPS transit encryption, SSM secure parameter storage, and rate-limiting policies. However, no electronic transmission or storage method is 100% secure, and we cannot guarantee absolute data safety.'),
      
      LegalSection('10. BIOMETRIC DATA PRIVACY', 
        'Biometric authentication (fingerprint/face recognition) is processed locally on your device by the operating system\'s secure enclave. PAYI does not collect, receive, or store your actual fingerprint templates or facial coordinates. We only receive a success/fail response from the system API.'),
      
      LegalSection('11. INTERNATIONAL DATA TRANSFERS', 
        'As a global transfer application, your personal and transaction data may be transferred to, stored, and processed in countries outside of your residence (including the United States), where data protection laws may differ. By using the Services, you consent to these transfers.'),
      
      LegalSection('12. CHILDREN\'S PRIVACY', 
        'PAYI does not knowingly collect or solicit personal information from anyone under the age of 18. If we learn that we have collected personal data from a minor without parental consent, we will delete that information as quickly as possible.'),
      
      LegalSection('13. MARKETING COMMUNICATIONS', 
        'We may occasionally send you email updates or in-app messages about new features, promotions, or services. You can opt out of marketing emails at any time by clicking the "unsubscribe" link at the bottom of the emails.'),
      
      LegalSection('14. DO NOT TRACK SIGNALS', 
        'Because there is no consistent industry standard for responding to browser "Do Not Track" (DNT) signals, our platforms do not currently alter their data collection practices in response to DNT headers.'),
      
      LegalSection('15. YOUR RIGHTS UNDER GDPR', 
        'If you reside in the European Economic Area (EEA) or UK, you have rights under the General Data Protection Regulation (GDPR), including: (a) right of access; (b) right to rectification; (c) right to erasure; (d) right to restrict processing; and (e) right to data portability.'),
      
      LegalSection('16. YOUR RIGHTS UNDER CCPA/CPRA', 
        'If you are a California resident, you have rights under the California Consumer Privacy Act (CCPA), including the right to request disclosure of the categories and specific pieces of personal information we collect, and the right to request deletion of that data.'),
      
      LegalSection('17. POLICY UPDATES AND NOTIFICATIONS', 
        'We may update this Privacy Policy periodically. We will notify you of any material changes by posting the new policy in the App and updating the "last updated" date. Your continued use of the Services constitutes acceptance of the revised policy.'),
      
      LegalSection('18. CONTACT OUR DPO', 
        'If you have questions about this Privacy Policy or wish to exercise your data protection rights, you can contact our Data Protection Officer (DPO) at privacy@payi.com.'),
    ];
  }
}

class LegalSection {
  final String title;
  final String content;

  LegalSection(this.title, this.content);
}
