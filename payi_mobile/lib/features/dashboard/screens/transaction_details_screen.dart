import 'package:flutter/material.dart';
import 'package:payi_mobile/core/models/models.dart';
import 'package:intl/intl.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailsScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSend = transaction.direction == 'Send';
    
    // Dynamic colors based on theme
    final successColor = const Color(0xFF00C853);
    final amountColor = isSend ? theme.colorScheme.onSurface : successColor;
    final prefix = isSend ? '-' : '+';
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);
    final dividerColor = theme.brightness == Brightness.dark 
        ? const Color(0xFF2C3544) 
        : const Color(0xFFE2E8F0);

    // Fallback format if date parsing fails
    String formattedDate = transaction.createdAtUtc.toString();
    try {
      formattedDate = DateFormat(
        'MMM d, yyyy • h:mm a',
      ).format(transaction.createdAtUtc.toLocal());
    } catch (_) {}

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Transaction Details',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSend
                      ? theme.brightness == Brightness.dark 
                          ? const Color(0xFF2C3544) 
                          : const Color(0xFFF1F5F9)
                      : theme.colorScheme.primary.withAlpha(26), // 0.1 opacity
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSend ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 48,
                  color: isSend ? theme.colorScheme.onSurface : theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '$prefix\$${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: amountColor,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: successColor.withAlpha(26), // 0.1 opacity
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Completed',
                style: TextStyle(
                  color: successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 48),
            _buildDetailRow('Reference', transaction.reference, theme, mutedColor),
            Divider(color: dividerColor, height: 32),
            _buildDetailRow('Date', formattedDate, theme, mutedColor),
            Divider(color: dividerColor, height: 32),
            _buildDetailRow('Counterparty', transaction.counterpartyName, theme, mutedColor),
            Divider(color: dividerColor, height: 32),
            _buildDetailRow('Payment Method', transaction.method, theme, mutedColor),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.onSurface,
                  side: BorderSide(
                    color: theme.brightness == Brightness.dark 
                        ? const Color(0xFF2C3544) 
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(
                  Icons.help_outline,
                  color: theme.colorScheme.primary,
                ),
                label: const Text('Report an Issue'),
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

  Widget _buildDetailRow(String label, String value, ThemeData theme, Color mutedColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(color: mutedColor, fontSize: 16),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
