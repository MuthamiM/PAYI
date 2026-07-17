import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';

class BalanceDetailsScreen extends StatelessWidget {
  const BalanceDetailsScreen({super.key});

  static const Map<String, Map<String, dynamic>> _currencyInfo = {
    'USD': {'icon': Icons.attach_money, 'label': 'US Dollar', 'color': Colors.green},
    'KES': {'icon': Icons.currency_exchange, 'label': 'Kenyan Shilling', 'color': Colors.blue},
    'NGN': {'icon': Icons.currency_exchange, 'label': 'Nigerian Naira', 'color': Colors.orange},
  };

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>().wallet;
    final balances = wallet?.balances ?? {};
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);

    double totalUsd = 0;
    for (final entry in balances.entries) {
      if (entry.key == 'USD') {
        totalUsd += entry.value;
      } else if (entry.key == 'KES') {
        totalUsd += entry.value / 130;
      } else if (entry.key == 'NGN') {
        totalUsd += entry.value / 780;
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Balance Details',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Balance Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withAlpha(51),
                    theme.colorScheme.primary.withAlpha(12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.primary.withAlpha(76),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Total Balance (USD Equivalent)',
                    style: TextStyle(color: mutedColor, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${totalUsd.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Currencies',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Currency Cards
            ...balances.entries.map((entry) {
              final info = _currencyInfo[entry.key] ??
                  {'icon': Icons.monetization_on, 'label': entry.key, 'color': Colors.grey};
              final color = info['color'] as Color;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.brightness == Brightness.dark 
                      ? const Color(0xFF2C3544)
                      : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withAlpha(38),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        info['icon'] as IconData,
                        color: color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            info['label'] as String,
                            style: TextStyle(
                              color: mutedColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      entry.value.toStringAsFixed(2),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => _showAddCurrencyDialog(context),
                icon: Icon(Icons.add, color: theme.colorScheme.primary),
                label: const Text('Add Currency'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: theme.colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCurrencyDialog(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);
    final extraCurrencies = {
      'ZAR': {'label': 'South African Rand', 'flag': '🇿🇦'},
      'GHS': {'label': 'Ghanaian Cedi', 'flag': '🇬🇭'},
      'UGX': {'label': 'Ugandan Shilling', 'flag': '🇺🇬'},
      'EUR': {'label': 'Euro', 'flag': '🇪🇺'},
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add New Currency', style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: extraCurrencies.entries.map((e) => ListTile(
            leading: Text(e.value['flag']!, style: const TextStyle(fontSize: 24)),
            title: Text(e.key, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
            subtitle: Text(e.value['label']!, style: TextStyle(color: mutedColor, fontSize: 12)),
            onTap: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${e.key} account activated!'),
                  backgroundColor: const Color(0xFF00C853),
                ),
              );
            },
          )).toList(),
        ),
      ),
    );
  }
}
