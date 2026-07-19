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

class _DashboardSaaSScreenState extends State<DashboardSaaSScreen>
    with TickerProviderStateMixin {
  final PageController _balancePageController = PageController(viewportFraction: 0.92);
  int _currentBalancePage = 0;
  late AnimationController _greetingFadeController;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _greetingFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _balancePageController.dispose();
    _greetingFadeController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);
    final primaryColor = theme.colorScheme.primary;

    // Build balance entries list
    final balanceEntries = <MapEntry<String, double>>[];
    if (walletProvider.wallet != null && walletProvider.wallet!.balances.isNotEmpty) {
      balanceEntries.addAll(walletProvider.wallet!.balances.entries);
    }
    if (balanceEntries.isEmpty) {
      balanceEntries.add(const MapEntry('USD', 0.0));
    }

    // Calculate insights
    double totalSent = 0;
    double totalReceived = 0;
    int pendingCount = 0;
    if (walletProvider.transactions != null) {
      for (final tx in walletProvider.transactions!) {
        if (tx.direction == 'Send') {
          totalSent += tx.amount;
        } else {
          totalReceived += tx.amount;
        }
        if (tx.status.toLowerCase() == 'pending') {
          pendingCount++;
        }
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                    const SizedBox(height: 12),

                    // ═══════════════════════════════════════
                    // GREETING HEADER
                    // ═══════════════════════════════════════
                    FadeTransition(
                      opacity: _greetingFadeController,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const ProfileScreen())),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: primaryColor.withAlpha(80), width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withAlpha(30),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: isDark
                                    ? primaryColor.withAlpha(20)
                                    : primaryColor.withAlpha(15),
                                child: Icon(Icons.person, color: primaryColor, size: 26),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_getGreeting()} ${_getGreetingEmoji()}',
                                  style: TextStyle(
                                    color: mutedColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  walletProvider.wallet?.userEmail.split('@')[0] ?? 'Welcome Back',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          _buildHeaderIcon(context, Icons.search, () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const SearchContactsScreen()));
                          }),
                          const SizedBox(width: 8),
                          _buildHeaderIcon(context, Icons.qr_code_scanner, () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const ScanQrScreen()));
                          }),
                          const SizedBox(width: 8),
                          _buildHeaderIcon(context, Icons.settings_outlined, () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const SettingsScreen()));
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ═══════════════════════════════════════
                    // BALANCE CAROUSEL
                    // ═══════════════════════════════════════
                    StaggeredSlideIn(
                      index: 0,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 195,
                            child: walletProvider.isLoading
                                ? Center(
                                    child: GlassContainer(
                                      padding: const EdgeInsets.all(40),
                                      borderRadius: 28,
                                      child: const CircularProgressIndicator(strokeWidth: 2.5),
                                    ),
                                  )
                                : PageView.builder(
                                    controller: _balancePageController,
                                    itemCount: balanceEntries.length,
                                    onPageChanged: (i) => setState(() => _currentBalancePage = i),
                                    itemBuilder: (context, index) {
                                      final entry = balanceEntries[index];
                                      final currencyIcons = {
                                        'USD': '🇺🇸', 'KES': '🇰🇪', 'NGN': '🇳🇬',
                                        'CNY': '🇨🇳', 'AED': '🇦🇪', 'SAR': '🇸🇦',
                                        'GBP': '🇬🇧', 'EUR': '🇪🇺',
                                      };
                                      final flag = currencyIcons[entry.key] ?? '💰';
                                      final gradients = [
                                        AppColors.heroCardGradient,
                                        AppColors.premiumGradient,
                                        AppColors.goldGradient,
                                        const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
                                      ];
                                      final grad = isDark
                                          ? gradients[index % gradients.length]
                                          : AppColors.heroCardLightGradient;

                                      return GestureDetector(
                                        onTap: () => Navigator.push(context,
                                            MaterialPageRoute(builder: (_) => const BalanceDetailsScreen())),
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 4),
                                          decoration: BoxDecoration(
                                            gradient: grad,
                                            borderRadius: BorderRadius.circular(28),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.white.withAlpha(15)
                                                  : AppColors.surfaceLightBorder,
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withAlpha(isDark ? 50 : 10),
                                                blurRadius: 30,
                                                offset: const Offset(0, 12),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(28),
                                            child: Stack(
                                              children: [
                                                Positioned(
                                                  right: -40, top: -40,
                                                  child: Container(
                                                    width: 160, height: 160,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      gradient: RadialGradient(colors: [
                                                        primaryColor.withAlpha(isDark ? 25 : 12),
                                                        primaryColor.withAlpha(0),
                                                      ]),
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  left: -30, bottom: -30,
                                                  child: Container(
                                                    width: 100, height: 100,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      gradient: RadialGradient(colors: [
                                                        primaryColor.withAlpha(isDark ? 15 : 8),
                                                        primaryColor.withAlpha(0),
                                                      ]),
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(24),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(flag, style: const TextStyle(fontSize: 22)),
                                                          const SizedBox(width: 10),
                                                          Text(
                                                            entry.key,
                                                            style: TextStyle(
                                                              color: mutedColor,
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.w700,
                                                              letterSpacing: 1.2,
                                                            ),
                                                          ),
                                                          const Spacer(),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                            decoration: BoxDecoration(
                                                              color: primaryColor.withAlpha(26),
                                                              borderRadius: BorderRadius.circular(10),
                                                            ),
                                                            child: Text(
                                                              'Active',
                                                              style: TextStyle(
                                                                color: primaryColor,
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.w700,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 16),
                                                      AnimatedCounter(
                                                        targetValue: entry.value,
                                                        prefix: entry.key == 'USD' ? '\$' : '',
                                                        suffix: entry.key != 'USD' ? ' ${entry.key}' : '',
                                                        style: TextStyle(
                                                          color: theme.colorScheme.onSurface,
                                                          fontSize: 38,
                                                          fontWeight: FontWeight.w800,
                                                          letterSpacing: -1.0,
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            'Tap to view details',
                                                            style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Icon(Icons.arrow_forward_ios, size: 10, color: primaryColor),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          if (balanceEntries.length > 1) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(balanceEntries.length, (i) {
                                final isActive = i == _currentBalancePage;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: isActive ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isActive ? primaryColor : mutedColor.withAlpha(60),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ═══════════════════════════════════════
                    // INSIGHTS STRIP
                    // ═══════════════════════════════════════
                    StaggeredSlideIn(
                      index: 1,
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
                        borderRadius: 20,
                        child: Row(
                          children: [
                            _buildInsightChip(context, Icons.arrow_upward, 'Sent',
                                '\$${totalSent.toStringAsFixed(0)}', AppColors.sendGradient),
                            _buildInsightDivider(isDark),
                            _buildInsightChip(context, Icons.arrow_downward, 'Received',
                                '\$${totalReceived.toStringAsFixed(0)}', AppColors.receiveGradient),
                            _buildInsightDivider(isDark),
                            _buildInsightChip(context, Icons.schedule, 'Pending',
                                '$pendingCount', AppColors.goldGradient),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ═══════════════════════════════════════
                    // ACTION CHIPS (Horizontal Scrollable)
                    // ═══════════════════════════════════════
                    StaggeredSlideIn(
                      index: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'QUICK ACTIONS',
                            style: TextStyle(
                              color: mutedColor, fontSize: 11,
                              fontWeight: FontWeight.w800, letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _buildActionChip(context, Icons.send_rounded, 'Send', const TransferScreen(), AppColors.primaryGradient),
                                _buildActionChip(context, Icons.call_received_rounded, 'Receive', const ReceiveMoneyScreen(), AppColors.receiveGradient),
                                _buildActionChip(context, Icons.add_card, 'Top-up', const TopupScreen(), AppColors.goldGradient),
                                _buildActionChip(context, Icons.receipt_long, 'Bills', const PayBillsScreen(), const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)])),
                                _buildActionChip(context, Icons.public, 'Global', const InternationalTransferScreen(), AppColors.premiumGradient),
                                _buildActionChip(context, Icons.account_balance, 'Bank', const BankTransferScreen(), const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ═══════════════════════════════════════
                    // SERVICES DISCOVERY CAROUSEL
                    // ═══════════════════════════════════════
                    StaggeredSlideIn(
                      index: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EXPLORE SERVICES',
                            style: TextStyle(
                              color: mutedColor, fontSize: 11,
                              fontWeight: FontWeight.w800, letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 130,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              children: [
                                _buildServiceCard(
                                  context,
                                  icon: Icons.savings_rounded,
                                  title: 'Savings',
                                  subtitle: 'Earn 5.2% APY',
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                                  ),
                                  screen: const SavingsScreen(),
                                ),
                                _buildServiceCard(
                                  context,
                                  icon: Icons.currency_bitcoin,
                                  title: 'Crypto',
                                  subtitle: 'Buy & Sell',
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                                  ),
                                  screen: const CryptoScreen(),
                                ),
                                _buildServiceCard(
                                  context,
                                  icon: Icons.credit_score_rounded,
                                  title: 'Loans',
                                  subtitle: 'Quick Credit',
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                                  ),
                                  screen: const LoansScreen(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ═══════════════════════════════════════
                    // QUICK SEND
                    // ═══════════════════════════════════════
                    StaggeredSlideIn(
                      index: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'QUICK SEND',
                                style: TextStyle(
                                  color: mutedColor, fontSize: 11,
                                  fontWeight: FontWeight.w800, letterSpacing: 1.5,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const SearchContactsScreen())),
                                child: Text(
                                  'View All',
                                  style: TextStyle(
                                    color: primaryColor, fontSize: 12, fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _buildQuickSendAvatar(context, 'Add', primaryColor.withAlpha(20), primaryColor, isAdd: true),
                                _buildQuickSendAvatar(context, 'Alex', const Color(0xFF3B82F6).withAlpha(30), const Color(0xFF3B82F6)),
                                _buildQuickSendAvatar(context, 'Sarah', const Color(0xFFEC4899).withAlpha(30), const Color(0xFFEC4899)),
                                _buildQuickSendAvatar(context, 'Mike', const Color(0xFF10B981).withAlpha(30), const Color(0xFF10B981)),
                                _buildQuickSendAvatar(context, 'Emma', const Color(0xFFF59E0B).withAlpha(30), const Color(0xFFF59E0B)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ═══════════════════════════════════════
                    // TRANSACTION TIMELINE
                    // ═══════════════════════════════════════
                    StaggeredSlideIn(
                      index: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'RECENT ACTIVITY',
                                style: TextStyle(
                                  color: mutedColor, fontSize: 11,
                                  fontWeight: FontWeight.w800, letterSpacing: 1.5,
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 14, color: mutedColor),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (walletProvider.isLoading)
                            const Center(child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            ))
                          else if (walletProvider.error != null && walletProvider.transactions == null)
                            _buildHistoryErrorCard(theme, walletProvider.error!)
                          else if (walletProvider.transactions == null || walletProvider.transactions!.isEmpty)
                            _buildEmptyHistoryCard(mutedColor)
                          else
                            ...walletProvider.transactions!.take(5).toList().asMap().entries.map((entry) {
                              final index = entry.key;
                              final tx = entry.value;
                              final isSend = tx.direction == 'Send';
                              final isLast = index == (walletProvider.transactions!.take(5).length - 1);

                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Timeline indicator
                                    SizedBox(
                                      width: 32,
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 12, height: 12,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSend
                                                  ? const Color(0xFFEF4444).withAlpha(200)
                                                  : primaryColor.withAlpha(200),
                                              border: Border.all(
                                                color: isDark ? Colors.white.withAlpha(20) : Colors.grey.withAlpha(40),
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          if (!isLast)
                                            Expanded(
                                              child: Container(
                                                width: 2,
                                                color: isDark ? Colors.white.withAlpha(12) : Colors.grey.withAlpha(30),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Transaction card
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => Navigator.push(context,
                                            MaterialPageRoute(builder: (_) => TransactionDetailsScreen(transaction: tx))),
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          child: GlassContainer(
                                            padding: const EdgeInsets.all(14),
                                            borderRadius: 18,
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 42, height: 42,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: isSend ? AppColors.sendGradient : AppColors.receiveGradient,
                                                  ),
                                                  child: Icon(
                                                    isSend ? Icons.arrow_upward : Icons.arrow_downward,
                                                    color: Colors.white, size: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        tx.counterpartyName,
                                                        style: TextStyle(
                                                          color: theme.colorScheme.onSurface,
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        tx.method,
                                                        style: TextStyle(color: mutedColor, fontSize: 11),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      '${isSend ? '-' : '+'}${tx.amount.toStringAsFixed(2)} ${tx.currency}',
                                                      style: TextStyle(
                                                        color: isSend ? theme.colorScheme.onSurface : primaryColor,
                                                        fontWeight: FontWeight.w800,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: tx.status.toLowerCase() == 'completed'
                                                            ? primaryColor.withAlpha(20)
                                                            : const Color(0xFFF59E0B).withAlpha(20),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        tx.status,
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w700,
                                                          color: tx.status.toLowerCase() == 'completed'
                                                              ? primaryColor
                                                              : const Color(0xFFF59E0B),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          const SizedBox(height: 80),
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
      // ═══════════════════════════════════════
      // BOTTOM NAVIGATION BAR
      // ═══════════════════════════════════════
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0A0F1A) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white.withAlpha(10) : Colors.grey.withAlpha(30),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 40 : 10),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, Icons.home_rounded, 'Home', 0),
                _buildNavItem(context, Icons.swap_horiz_rounded, 'Transfer', 1,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferScreen()))),
                // Center QR button
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ScanQrScreen())),
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withAlpha(80),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
                  ),
                ),
                _buildNavItem(context, Icons.receipt_long_rounded, 'Bills', 3,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PayBillsScreen()))),
                _buildNavItem(context, Icons.person_rounded, 'Profile', 4,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──── Helper Widgets ────

  Widget _buildHeaderIcon(BuildContext context, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(8) : Colors.grey.withAlpha(20),
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? Colors.white.withAlpha(10) : Colors.grey.withAlpha(25),
          ),
        ),
        child: Icon(icon, color: theme.colorScheme.onSurface.withAlpha(180), size: 20),
      ),
    );
  }

  Widget _buildInsightChip(BuildContext context, IconData icon, String label,
      String value, Gradient gradient) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withAlpha(130);
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(
            color: theme.colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 15,
          )),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: mutedColor, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInsightDivider(bool isDark) {
    return Container(
      width: 1, height: 40,
      color: isDark ? Colors.white.withAlpha(12) : Colors.grey.withAlpha(30),
    );
  }

  Widget _buildActionChip(BuildContext context, IconData icon, String label,
      Widget screen, Gradient gradient) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(6) : Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: isDark ? Colors.white.withAlpha(10) : Colors.grey.withAlpha(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 15 : 5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700, fontSize: 13,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, {
    required IconData icon, required String title, required String subtitle,
    required Gradient gradient, required Widget screen,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withAlpha(50),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16,
            )),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(
              color: Colors.white.withAlpha(180), fontSize: 12, fontWeight: FontWeight.w500,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSendAvatar(BuildContext context, String name, Color bgColor,
      Color iconColor, {bool isAdd = false}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        if (isAdd) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchContactsScreen()));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => TransferScreen(initialRecipient: name)));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: iconColor.withAlpha(50), width: 2),
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: bgColor,
                child: isAdd
                    ? Icon(Icons.add, color: iconColor, size: 24)
                    : Text(name[0], style: TextStyle(
                        color: iconColor, fontWeight: FontWeight.w800, fontSize: 18,
                      )),
              ),
            ),
            const SizedBox(height: 6),
            Text(name, style: TextStyle(
              fontSize: 12, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index,
      {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final isActive = _selectedNavIndex == index;
    final primaryColor = theme.colorScheme.primary;
    final mutedColor = theme.colorScheme.onSurface.withAlpha(100);

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap();
        } else {
          setState(() => _selectedNavIndex = index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? primaryColor : mutedColor, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            color: isActive ? primaryColor : mutedColor,
            fontSize: 10, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          )),
        ],
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
              'No transactions yet',
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
