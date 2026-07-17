import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../providers/wallet_provider.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/widgets.dart';

class TopupScreen extends StatefulWidget {
  const TopupScreen({super.key});

  @override
  State<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends State<TopupScreen> {
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _processTopUp() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid amount.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final apiService = ApiService();
    final theme = Theme.of(context);

    try {
      // 1. Get Publishable Key
      final pubKey = await apiService.getStripePublishableKey();
      Stripe.publishableKey = pubKey;

      // 2. Create Payment Intent
      final currency = ApiService.currentAuthCurrency;
      final intentData = await apiService.createStripePaymentIntent(
        amount: amount,
        currency: currency,
      );

      final clientSecret = intentData['clientSecret'];
      final paymentIntentId = intentData['paymentIntentId'];

      // 3. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'PAYI SaaS',
          style: theme.brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              background: theme.colorScheme.surface,
              primary: theme.colorScheme.primary,
              componentBackground: theme.brightness == Brightness.dark 
                  ? const Color(0xFF2C3544) 
                  : const Color(0xFFF1F5F9),
              primaryText: theme.colorScheme.onSurface,
              secondaryText: theme.colorScheme.onSurface.withAlpha(153),
            ),
          ),
        ),
      );

      // 4. Present Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // 5. Confirm with Backend
      await apiService.confirmStripePayment(
        paymentIntentId: paymentIntentId,
        currency: currency,
      );

      if (mounted) {
        await context.read<WalletProvider>().refreshAfterTopUp();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text('\$${amount.toStringAsFixed(2)} added to your wallet!'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } on StripeException catch (e) {
      debugPrint('Stripe error: ${e.error.localizedMessage}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment canceled or failed.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('Top-up error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Top-up failed. Please try again later.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectPreset(double amount) {
    setState(() {
      _amountController.text = amount.toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Wallet Top-up'),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        
                        // Amount input
                        StaggeredSlideIn(
                          index: 0,
                          child: GlassContainer(
                            borderRadius: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AMOUNT TO ADD (USD)',
                                  style: TextStyle(
                                    color: mutedColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _amountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.0,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: isDark ? Colors.white.withAlpha(8) : AppColors.surfaceLight,
                                    hintText: '0.00',
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Text(
                                        '\$',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 36,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Preset Chips
                        StaggeredSlideIn(
                          index: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildPresetChip(10),
                              _buildPresetChip(25),
                              _buildPresetChip(50),
                              _buildPresetChip(100),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Info Card
                        StaggeredSlideIn(
                          index: 2,
                          child: GlassContainer(
                            borderRadius: 20,
                            borderColor: primaryColor.withAlpha(60),
                            child: Row(
                              children: [
                                Icon(Icons.shield_outlined, color: primaryColor, size: 28),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Secure Payment',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Transactions are encrypted securely via Stripe.',
                                        style: TextStyle(
                                          color: mutedColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
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
                  ),
                ),
                
                // Top-up Button
                StaggeredSlideIn(
                  index: 3,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: _isLoading ? null : AppColors.primaryGradient,
                      color: _isLoading ? primaryColor.withAlpha(100) : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isLoading
                          ? null
                          : [
                              BoxShadow(
                                color: primaryColor.withAlpha(80),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _processTopUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Top-up via Stripe',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(double amount) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _amountController.text == amount.toStringAsFixed(0);

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectPreset(amount),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 48,
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.primaryGradient : null,
            color: isSelected ? null : (isDark ? AppColors.cardDark : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isDark ? Colors.white.withAlpha(10) : AppColors.surfaceLightBorder),
            ),
          ),
          child: Center(
            child: Text(
              '+\$${amount.toStringAsFixed(0)}',
              style: TextStyle(
                color: isSelected
                    ? (isDark ? AppColors.backgroundDark : Colors.white)
                    : theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
