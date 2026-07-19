import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';


import 'theme/theme.dart';
import 'theme/colors.dart';
import 'theme/widgets.dart';
import 'providers/wallet_provider.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/search_contacts_screen.dart';
import 'screens/balance_details_screen.dart';
import 'screens/transfer_screen.dart';
import 'screens/bank_transfer_screen.dart';
import 'screens/pay_bills_screen.dart';
import 'screens/scan_qr_screen.dart';
import 'screens/topup_screen.dart';
import 'screens/receive_money_screen.dart';
import 'screens/transaction_details_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/international_transfer_screen.dart';
import 'screens/savings_screen.dart';
import 'screens/crypto_screen.dart';
import 'screens/loans_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    final isDark = context.watch<WalletProvider>().isDarkMode;
    return MaterialApp(
      title: 'PAYI',
      debugShowCheckedModeBanner: false,
      theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: const AuthScreen(),
    );
  }
}

class DashboardSaaSScreen extends StatefulWidget {
  const DashboardSaaSScreen({super.key});

  @override
  State<DashboardSaaSScreen> createState() => _DashboardSaaSScreenState();
}

class _DashboardSaaSScreenState extends State<DashboardSaaSScreen> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);
    final primaryColor = theme.colorScheme.primary;

    // Resolve numerical balance value for animated counter
    double balanceValue = 0.0;
    String currencySymbol = '\$';
    String currencyCode = 'USD';
    
    if (walletProvider.wallet != null && walletProvider.wallet!.balances.isNotEmpty) {
      if (walletProvider.wallet!.balances.containsKey('USD') && walletProvider.wallet!.balances['USD']! > 0) {
        balanceValue = walletProvider.wallet!.balances['USD']!;
      } else {
        final entry = walletProvider.wallet!.balances.entries.first;
        balanceValue = entry.value;
        currencyCode = entry.key;
        currencySymbol = '';
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScanQrScreen()),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withAlpha(100),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.qr_code_scanner,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: walletProvider.fetchData,
            color: primaryColor,
            backgroundColor: theme.colorScheme.surface,
            edgeOffset: 10,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    // --- App Header & Search ---
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SearchContactsScreen(),
                                ),
                              );
                            },
                            child: GlassContainer(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              borderRadius: 20,
                              child: Row(
                                children: [
                                  Icon(Icons.search, color: mutedColor, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Pay contacts or search...',
                                      style: TextStyle(color: mutedColor, fontSize: 15),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProfileScreen()),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primaryColor.withAlpha(100),
                                width: 2,
                              ),
                            ),
                            child: PulsingGlow(
                              glowColor: primaryColor,
                              maxRadius: 10,
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor: theme.colorScheme.surface,
                                child: Icon(Icons.person, color: primaryColor, size: 24),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- Hero Balance Card ---
                    StaggeredSlideIn(
                      index: 0,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: isDark ? AppColors.heroCardGradient : AppColors.heroCardLightGradient,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: isDark ? Colors.white.withAlpha(15) : AppColors.surfaceLightBorder,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(isDark ? 40 : 10),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Stack(
                            children: [
                              // Decorative Background Shape
                              Positioned(
                                right: -50,
                                top: -50,
                                child: Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        primaryColor.withAlpha(isDark ? 30 : 15),
                                        primaryColor.withAlpha(0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'TOTAL BALANCE',
                                          style: TextStyle(
                                            color: mutedColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withAlpha(26),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            'Active',
                                            style: TextStyle(
                                              color: primaryColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    walletProvider.isLoading
                                        ? const SizedBox(
                                            height: 48,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: SizedBox(
                                                height: 24,
                                                width: 24,
                                                child: CircularProgressIndicator(strokeWidth: 2.5),
                                              ),
                                            ),
                                          )
                                        : Row(
                                            crossAxisAlignment: CrossAxisAlignment.baseline,
                                            textBaseline: TextBaseline.alphabetic,
                                            children: [
                                              AnimatedCounter(
                                                targetValue: balanceValue,
                                                prefix: currencySymbol,
                                                suffix: currencySymbol.isEmpty ? ' $currencyCode' : '',
                                                style: TextStyle(
                                                  color: theme.colorScheme.onSurface,
                                                  fontSize: 42,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: -1.0,
                                                ),
                                              ),
                                            ],
                                          ),
                                    const SizedBox(height: 20),
                                    Divider(color: isDark ? Colors.white.withAlpha(15) : AppColors.surfaceLightBorder),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const BalanceDetailsScreen()),
                                            );
                                          },
                                          child: Row(
                                            children: [
                                              Text(
                                                'View Multi-Currency Balances',
                                                style: TextStyle(
                                                  color: primaryColor,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(Icons.arrow_forward_ios, size: 12, color: primaryColor),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          walletProvider.wallet != null 
                                            ? 'Updated: just now'
                                            : 'Connecting...',
                                          style: TextStyle(color: mutedColor, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- Grid Actions ---
                    StaggeredSlideIn(
                      index: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'QUICK ACTIONS',
                                style: TextStyle(
                                  color: mutedColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isExpanded = !_isExpanded;
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  _isExpanded ? 'SHOW LESS' : 'SHOW MORE',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildActionItem(
                                context,
                                Icons.people_outline,
                                'Pay Friends',
                                const TransferScreen(),
                                AppColors.primaryGradient,
                              ),
                              _buildActionItem(
                                context,
                                Icons.public_outlined,
                                'Global Pay',
                                const InternationalTransferScreen(),
                                AppColors.premiumGradient,
                              ),
                              _buildActionItem(
                                context,
                                Icons.account_balance_outlined,
                                'Bank Send',
                                const BankTransferScreen(),
                                AppColors.goldGradient,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildActionItem(
                                context,
                                Icons.receipt_long_outlined,
                                'Pay Bills',
                                const PayBillsScreen(),
                                const LinearGradient(colors: [Colors.purple, Colors.pink]),
                              ),
                              _buildActionItem(
                                context,
                                Icons.add_circle_outline,
                                'Top-up',
                                const TopupScreen(),
                                AppColors.receiveGradient,
                              ),
                              _buildActionItem(
                                context,
                                Icons.arrow_downward_outlined,
                                'Receive',
                                const ReceiveMoneyScreen(),
                                AppColors.sendGradient,
                              ),
                            ],
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: _isExpanded
                                ? Column(
                                    children: [
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildActionItem(
                                            context,
                                            Icons.savings_outlined,
                                            'Savings',
                                            const SavingsScreen(),
                                            const LinearGradient(colors: [Color(0xFF00C9A7), Color(0xFF059669)]),
                                          ),
                                          _buildActionItem(
                                            context,
                                            Icons.currency_bitcoin_outlined,
                                            'Crypto',
                                            const CryptoScreen(),
                                            const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                                          ),
                                          _buildActionItem(
                                            context,
                                            Icons.credit_card_outlined,
                                            'Loans',
                                            const LoansScreen(),
                                            const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Promotional Card
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const SavingsScreen()),
                                          );
                                        },
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            gradient: AppColors.heroCardGradient,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isDark ? Colors.white.withAlpha(15) : AppColors.surfaceLightBorder,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: primaryColor.withAlpha(26),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(Icons.percent, color: primaryColor, size: 20),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Earn up to 5.2% APY',
                                                      style: TextStyle(
                                                        color: theme.colorScheme.onSurface,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Grow your wealth with high-yield savings.',
                                                      style: TextStyle(
                                                        color: mutedColor,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(Icons.arrow_forward_ios, size: 12, color: mutedColor),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- People Section ---
                    StaggeredSlideIn(
                      index: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'QUICK SEND',
                                style: TextStyle(
                                  color: mutedColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SearchContactsScreen()),
                                  );
                                },
                                child: Text(
                                  'View All',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _buildPersonAvatar(context, 'Alex', Colors.blue.withAlpha(40), Colors.blueAccent),
                                _buildPersonAvatar(context, 'Sarah', Colors.pink.withAlpha(40), Colors.pinkAccent),
                                _buildPersonAvatar(context, 'Mike', Colors.green.withAlpha(40), Colors.greenAccent),
                                _buildPersonAvatar(context, 'Emma', Colors.orange.withAlpha(40), Colors.orangeAccent),
                                _buildPersonAvatar(context, 'Add', primaryColor.withAlpha(20), primaryColor, isAction: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- Recent History ---
                    StaggeredSlideIn(
                      index: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'RECENT HISTORY',
                                style: TextStyle(
                                  color: mutedColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 14, color: mutedColor),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (walletProvider.isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (walletProvider.error != null && walletProvider.transactions == null)
                            _buildHistoryErrorCard(theme, walletProvider.error!)
                          else if (walletProvider.transactions == null || walletProvider.transactions!.isEmpty)
                            _buildEmptyHistoryCard(mutedColor)
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: walletProvider.transactions!.take(5).length,
                              itemBuilder: (context, index) {
                                final tx = walletProvider.transactions![index];
                                final isSend = tx.direction == 'Send';
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: GlassContainer(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    borderRadius: 18,
                                    child: ListTile(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TransactionDetailsScreen(transaction: tx),
                                          ),
                                        );
                                      },
                                      contentPadding: EdgeInsets.zero,
                                      leading: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: isSend ? AppColors.sendGradient : AppColors.receiveGradient,
                                        ),
                                        child: Icon(
                                          isSend ? Icons.arrow_upward : Icons.arrow_downward,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        tx.counterpartyName,
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      subtitle: Text(
                                        tx.method,
                                        style: TextStyle(color: mutedColor, fontSize: 12),
                                      ),
                                      trailing: Text(
                                        '${isSend ? '-' : '+'}${tx.amount.toStringAsFixed(2)} ${tx.currency}',
                                        style: TextStyle(
                                          color: isSend ? theme.colorScheme.onSurface : primaryColor,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 80), // Space for floating button
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    IconData icon,
    String label,
    Widget targetScreen,
    Gradient gradient,
  ) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen));
      },
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        borderRadius: 22,
        child: SizedBox(
          width: (MediaQuery.of(context).size.width - 72) / 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: gradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withAlpha(60),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonAvatar(
    BuildContext context,
    String name,
    Color bgColor,
    Color iconColor, {
    bool isAction = false,
  }) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);

    return GestureDetector(
      onTap: () {
        if (isAction) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchContactsScreen()));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (context) => TransferScreen(initialRecipient: name)));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: bgColor,
              child: isAction
                  ? Icon(Icons.add, color: iconColor, size: 26)
                  : Text(
                      name[0],
                      style: TextStyle(
                        color: iconColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryCard(Color mutedColor) {
    return GlassContainer(
      padding: const EdgeInsets.all(32.0),
      borderRadius: 24,
      child: Center(
        child: Column(
          children: [
            Icon(Icons.history_toggle_off, size: 40, color: mutedColor),
            const SizedBox(height: 12),
            Text(
              'No transactions found.',
              style: TextStyle(color: mutedColor, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryErrorCard(ThemeData theme, String error) {
    return GlassContainer(
      padding: const EdgeInsets.all(24.0),
      borderRadius: 24,
      borderColor: theme.colorScheme.error.withAlpha(100),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 36),
          const SizedBox(height: 12),
          Text(
            'Failed to load transactions',
            style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(153), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
