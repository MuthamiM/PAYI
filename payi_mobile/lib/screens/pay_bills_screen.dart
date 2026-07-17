import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/widgets.dart';

class PayBillsScreen extends StatelessWidget {
  const PayBillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Pay Bills'),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'BILL CATEGORIES',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withAlpha(153),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      StaggeredSlideIn(
                        index: 0,
                        child: _buildBillCategory(context, Icons.lightbulb_outline, 'Electricity', Colors.orange),
                      ),
                      StaggeredSlideIn(
                        index: 1,
                        child: _buildBillCategory(context, Icons.water_drop_outlined, 'Water', Colors.blue),
                      ),
                      StaggeredSlideIn(
                        index: 2,
                        child: _buildBillCategory(context, Icons.wifi, 'Internet', Colors.purple),
                      ),
                      StaggeredSlideIn(
                        index: 3,
                        child: _buildBillCategory(context, Icons.tv, 'TV & Cable', Colors.red),
                      ),
                      StaggeredSlideIn(
                        index: 4,
                        child: _buildBillCategory(context, Icons.phone_iphone, 'Mobile Postpaid', Colors.green),
                      ),
                      StaggeredSlideIn(
                        index: 5,
                        child: _buildBillCategory(context, Icons.school_outlined, 'Education', Colors.indigo),
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

  void _showPayBillDialog(BuildContext context, String category, Color color) {
    final accountController = TextEditingController();
    final amountController = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.receipt_long, color: color),
            const SizedBox(width: 12),
            Text(
              'Pay $category',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BILL DETAILS',
              style: TextStyle(
                color: mutedColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: accountController,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? Colors.white.withAlpha(8) : AppColors.surfaceLight,
                hintText: 'Account / Meter Number',
                hintStyle: TextStyle(color: mutedColor),
                prefixIcon: Icon(Icons.tag, color: color),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? Colors.white.withAlpha(8) : AppColors.surfaceLight,
                hintText: '0.00',
                hintStyle: TextStyle(color: mutedColor),
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    '\$',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: mutedColor, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (accountController.text.isEmpty || amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Enter account number and valid amount.'),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              context
                  .read<WalletProvider>()
                  .payBill(amount, ApiService.currentAuthCurrency, category, accountController.text);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text('Paid \$${amount.toStringAsFixed(2)} for $category!'),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildBillCategory(BuildContext context, IconData icon, String label, Color color) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () => _showPayBillDialog(context, label, color),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 22,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withAlpha(26), // ~0.1 opacity
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
