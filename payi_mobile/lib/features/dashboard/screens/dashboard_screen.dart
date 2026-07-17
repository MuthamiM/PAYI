import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:payi_mobile/core/providers/wallet_provider.dart';
import 'package:payi_mobile/core/models/models.dart';
import 'package:payi_mobile/features/profile/screens/profile_screen.dart';
import 'package:payi_mobile/features/profile/screens/settings_screen.dart';
import 'package:payi_mobile/features/dashboard/screens/search_contacts_screen.dart';
import 'package:payi_mobile/features/dashboard/screens/balance_details_screen.dart';
import 'package:payi_mobile/features/dashboard/screens/transaction_details_screen.dart';
import 'package:payi_mobile/features/payments/screens/transfer_screen.dart';
import 'package:payi_mobile/features/payments/screens/bank_transfer_screen.dart';
import 'package:payi_mobile/features/payments/screens/international_transfer_screen.dart';
import 'package:payi_mobile/features/payments/screens/pay_bills_screen.dart';
import 'package:payi_mobile/features/payments/screens/scan_qr_screen.dart';
import 'package:payi_mobile/features/payments/screens/topup_screen.dart';
import 'package:payi_mobile/features/payments/screens/receive_money_screen.dart';

class DashboardSaaSScreen extends StatelessWidget {
  const DashboardSaaSScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: walletProvider.fetchData,
          color: theme.colorScheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Top Section (App Header + Scan/Balance Pills)
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.only(
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
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SearchContactsScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.brightness == Brightness.dark 
                                        ? const Color(0xFF1E2633) 
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: theme.brightness == Brightness.dark 
                                        ? const Color(0xFF2C3544)
                                        : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.search,
                                        color: mutedColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Pay contacts or search...',
                                          style: TextStyle(
                                            color: mutedColor,
                                            fontSize: 16,
                                            ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
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
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: theme.brightness == Brightness.dark 
                                      ? const Color(0xFF1E2633) 
                                      : const Color(0xFFF1F5F9),
                                  child: Icon(
                                    Icons.person,
                                    color: theme.colorScheme.primary,
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
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ScanQrScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withAlpha(26),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: theme.colorScheme.primary.withAlpha(128),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.qr_code_scanner,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Scan',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Balance Button
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const BalanceDetailsScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 60,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.brightness == Brightness.dark 
                                        ? const Color(0xFF1E2633) 
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: theme.brightness == Brightness.dark 
                                        ? const Color(0xFF2C3544)
                                        : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet,
                                        color: mutedColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Total Balance',
                                              style: TextStyle(
                                                color: mutedColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                            walletProvider.isLoading
                                                ? SizedBox(
                                                    height: 12,
                                                    width: 12,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: theme.colorScheme.primary,
                                                        ),
                                                  )
                                                : Text(
                                                    walletProvider
                                                        .formattedTotalBalance,
                                                    style: TextStyle(
                                                      color:
                                                          theme.colorScheme.onSurface,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                          _buildGridAction(
                            context,
                            Icons.qr_code,
                            'Scan any\nQR',
                            onTap: () {
                              Navigator.push(
                                context,
                                  MaterialPageRoute(
                                    builder: (context) => const ScanQrScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildGridAction(
                              context,
                              Icons.people,
                              'Pay\nFriends',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TransferScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildGridAction(
                              context,
                              Icons.public,
                              'Global\nTransfer',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const InternationalTransferScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildGridAction(
                              context,
                              Icons.account_balance,
                              'Bank\ntransfer',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const BankTransferScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildGridAction(
                              context,
                              Icons.receipt_long,
                              'Pay\nbills',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PayBillsScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildGridAction(
                              context,
                              Icons.add_circle,
                              'Wallet\nTop-up',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TopupScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildGridAction(
                              context,
                              Icons.arrow_downward,
                              'Receive\nmoney',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ReceiveMoneyScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildGridAction(
                              context,
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
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: theme.brightness == Brightness.dark 
                          ? const Color(0xFF2C3544)
                          : const Color(0xFFE2E8F0),
                      ),
                      bottom: BorderSide(
                        color: theme.brightness == Brightness.dark 
                          ? const Color(0xFF2C3544)
                          : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'People',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: mutedColor,
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
                              context,
                              'Alex',
                              Colors.blue.withAlpha(51),
                              iconColor: Colors.blueAccent,
                            ),
                            _buildPersonAvatar(
                              context,
                              'Sarah',
                              Colors.pink.withAlpha(51),
                              iconColor: Colors.pinkAccent,
                            ),
                            _buildPersonAvatar(
                              context,
                              'Mike',
                              Colors.green.withAlpha(51),
                              iconColor: Colors.greenAccent,
                            ),
                            _buildPersonAvatar(
                              context,
                              'Emma',
                              Colors.orange.withAlpha(51),
                              iconColor: Colors.orangeAccent,
                            ),
                            _buildPersonAvatar(
                              context,
                              'Topup',
                              theme.colorScheme.primary.withAlpha(26),
                              iconColor: theme.colorScheme.primary,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent History',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: mutedColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (walletProvider.isLoading)
                        Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                        )
                      else if (walletProvider.error != null &&
                          walletProvider.transactions == null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error.withAlpha(26),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.error_outline,
                                    color: theme.colorScheme.error,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Error',
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (walletProvider.transactions == null ||
                          walletProvider.transactions!.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              'No transactions found.',
                              style: TextStyle(color: mutedColor),
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
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TransactionDetailsScreen(
                                          transaction: tx,
                                        ),
                                  ),
                                );
                              },
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: isSend
                                    ? (theme.brightness == Brightness.dark ? const Color(0xFF1E2633) : const Color(0xFFF1F5F9))
                                    : theme.colorScheme.primary.withAlpha(26),
                                child: Icon(
                                  isSend
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: isSend
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                tx.counterpartyName,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                tx.method,
                                style: TextStyle(
                                  color: mutedColor,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Text(
                                '${isSend ? '-' : '+'}${tx.amount.toStringAsFixed(2)} ${tx.currency}',
                                style: TextStyle(
                                  color: isSend
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.primary,
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

  Widget _buildGridAction(
    BuildContext context,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap:
          onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${label.replaceAll('\n', ' ')} tapped'),
              ),
            );
          },
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark 
                    ? const Color(0xFF1E2633) 
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
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
    BuildContext context,
    String name,
    Color bgColor, {
    required Color iconColor,
    bool isAction = false,
  }) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);
    
    return GestureDetector(
      onTap: () {
        if (isAction) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TopupScreen()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransferScreen(initialRecipient: name),
            ),
          );
        }
      },
      child: Padding(
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
              style: TextStyle(
                fontSize: 14,
                color: mutedColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
