import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/theme.dart';
import 'theme/colors.dart';
import 'providers/wallet_provider.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletProvider()..fetchData()),
      ],
      child: const PayiApp(),
    ),
  );
}

class PayiApp extends StatelessWidget {
  const PayiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PAYI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.saasTheme,
      home: const DashboardSaaSScreen(), // Bypassed Auth Screen for Prototyping
    );
  }
}

class DashboardSaaSScreen extends StatelessWidget {
  const DashboardSaaSScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: walletProvider.fetchData,
          color: AppColors.primaryTeal,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Top Section (App Header + Scan/Balance Pills)
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Search Bar & Profile
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceGrey,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(0xFF2C3544),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.search,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Pay contacts or search...',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProfileScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primaryTeal,
                                    width: 2,
                                  ),
                                ),
                                child: const CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.surfaceGrey,
                                  child: Icon(
                                    Icons.person,
                                    color: AppColors.primaryTeal,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Scan and Balance Pills
                        Row(
                          children: [
                            // Scan Button
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTeal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: AppColors.primaryTeal.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.qr_code_scanner,
                                      color: AppColors.primaryTeal,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Scan',
                                      style: TextStyle(
                                        color: AppColors.primaryTeal,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Balance Button
                            Expanded(
                              flex: 3,
                              child: Container(
                                height: 60,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceGrey,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: const Color(0xFF2C3544),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.account_balance_wallet,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Total Balance',
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                          walletProvider.isLoading
                                              ? const SizedBox(
                                                  height: 12,
                                                  width: 12,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: AppColors
                                                            .primaryTeal,
                                                      ),
                                                )
                                              : Text(
                                                  walletProvider
                                                      .formattedTotalUsd,
                                                  style: const TextStyle(
                                                    color: AppColors.textLight,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Action Grid
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildGridAction(Icons.qr_code, 'Scan any\nQR'),
                          _buildGridAction(Icons.contacts, 'Pay\ncontacts'),
                          _buildGridAction(
                            Icons.phone_android,
                            'Pay to\nphone no.',
                          ),
                          _buildGridAction(
                            Icons.account_balance,
                            'Bank\ntransfer',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildGridAction(Icons.receipt_long, 'Pay\nbills'),
                          _buildGridAction(Icons.add_circle, 'Wallet\nTop-up'),
                          _buildGridAction(
                            Icons.arrow_downward,
                            'Receive\nmoney',
                          ),
                          _buildGridAction(
                            Icons.settings,
                            'Settings',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // People Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(left: 24, top: 16, bottom: 24),
                  decoration: const BoxDecoration(
                    color: AppColors.cardDark,
                    border: Border(
                      top: BorderSide(color: Color(0xFF2C3544)),
                      bottom: BorderSide(color: Color(0xFF2C3544)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'People',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildPersonAvatar(
                              'Alex',
                              Colors.blue.withOpacity(0.2),
                              iconColor: Colors.blueAccent,
                            ),
                            _buildPersonAvatar(
                              'Sarah',
                              Colors.pink.withOpacity(0.2),
                              iconColor: Colors.pinkAccent,
                            ),
                            _buildPersonAvatar(
                              'Mike',
                              Colors.green.withOpacity(0.2),
                              iconColor: Colors.greenAccent,
                            ),
                            _buildPersonAvatar(
                              'Emma',
                              Colors.orange.withOpacity(0.2),
                              iconColor: Colors.orangeAccent,
                            ),
                            _buildPersonAvatar(
                              'Topup',
                              AppColors.primaryTeal.withOpacity(0.1),
                              iconColor: AppColors.primaryTeal,
                              isAction: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Recent Transactions Dynamic List
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent History',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (walletProvider.isLoading)
                        const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryTeal,
                          ),
                        )
                      else if (walletProvider.error != null &&
                          walletProvider.transactions == null)
                        Center(
                          child: Text(
                            'Error loading transactions:\n${walletProvider.error}',
                            style: const TextStyle(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else if (walletProvider.transactions == null ||
                          walletProvider.transactions!.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'No transactions found.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: walletProvider.transactions!
                              .take(5)
                              .length,
                          itemBuilder: (context, index) {
                            final tx = walletProvider.transactions![index];
                            final isSend = tx.direction == 'Send';
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: isSend
                                    ? AppColors.surfaceGrey
                                    : AppColors.primaryTeal.withOpacity(0.1),
                                child: Icon(
                                  isSend
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: isSend
                                      ? AppColors.textLight
                                      : AppColors.primaryTeal,
                                ),
                              ),
                              title: Text(
                                tx.counterpartyName,
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                tx.method,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Text(
                                '${isSend ? '-' : '+'}${tx.amount.toStringAsFixed(2)} ${tx.currency}',
                                style: TextStyle(
                                  color: isSend
                                      ? AppColors.textLight
                                      : AppColors.primaryTeal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridAction(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surfaceGrey,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryTeal, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonAvatar(
    String name,
    Color bgColor, {
    required Color iconColor,
    bool isAction = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: bgColor,
            child: isAction
                ? Icon(Icons.add, color: iconColor, size: 32)
                : Text(
                    name[0],
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
