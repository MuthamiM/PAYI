import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/widgets.dart';

class BankTransferScreen extends StatefulWidget {
  const BankTransferScreen({super.key});

  @override
  State<BankTransferScreen> createState() => _BankTransferScreenState();
}

class _BankTransferScreenState extends State<BankTransferScreen> {
  final List<Map<String, String>> _banks = [
    {'name': 'Chase Bank', 'account': '**** **** 1234'},
    {'name': 'Bank of America', 'account': '**** **** 5678'},
    {'name': 'Wells Fargo', 'account': '**** **** 9012'},
  ];

  void _showTransferDialog(String bankName) {
    final amountController = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Transfer to $bankName',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AMOUNT (USD)',
              style: TextStyle(
                color: mutedColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
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
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Enter a valid amount.'),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              context
                  .read<WalletProvider>()
                  .bankTransfer(amount, ApiService.currentAuthCurrency, bankName, 'External Bank Account');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text('\$${amount.toStringAsFixed(2)} transferred to $bankName!'),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showAddBankDialog() {
    final nameController = TextEditingController();
    final accountController = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Add New Bank',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BANK DETAILS',
              style: TextStyle(
                color: mutedColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? Colors.white.withAlpha(8) : AppColors.surfaceLight,
                hintText: 'Bank Name',
                hintStyle: TextStyle(color: mutedColor),
                prefixIcon: const Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: accountController,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? Colors.white.withAlpha(8) : AppColors.surfaceLight,
                hintText: 'Account Number',
                hintStyle: TextStyle(color: mutedColor),
                prefixIcon: const Icon(Icons.numbers),
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
              if (nameController.text.isEmpty || accountController.text.isEmpty) {
                return;
              }
              setState(() {
                final last4 = accountController.text.length >= 4
                    ? accountController.text.substring(accountController.text.length - 4)
                    : accountController.text;
                _banks.add({
                  'name': nameController.text,
                  'account': '**** **** $last4',
                });
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text('${nameController.text} added!'),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Add Bank'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Bank Transfer'),
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
                        Text(
                          'SELECT DESTINATION BANK',
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _banks.length,
                          itemBuilder: (context, index) {
                            final bank = _banks[index];
                            return StaggeredSlideIn(
                              index: index,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: _buildBankOption(bank['name']!, bank['account']!),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Add Bank Button
                StaggeredSlideIn(
                  index: _banks.length + 1,
                  child: OutlinedButton.icon(
                    onPressed: _showAddBankDialog,
                    icon: Icon(Icons.add_home_work_outlined, color: primaryColor),
                    label: const Text('Add New Bank Account'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor, width: 1.5),
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

  Widget _buildBankOption(String name, String accountStr) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);
    final primaryColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: () => _showTransferDialog(name),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withAlpha(8) : AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    accountStr,
                    style: TextStyle(color: mutedColor, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: mutedColor,
            ),
          ],
        ),
      ),
    );
  }
}
