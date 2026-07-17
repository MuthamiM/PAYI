import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../theme/colors.dart';
import '../theme/widgets.dart';

class InternationalTransferScreen extends StatefulWidget {
  const InternationalTransferScreen({super.key});

  @override
  State<InternationalTransferScreen> createState() => _InternationalTransferScreenState();
}

class _InternationalTransferScreenState extends State<InternationalTransferScreen> {
  final _amountController = TextEditingController();
  final _recipientController = TextEditingController();
  
  String _selectedCountry = 'United Kingdom';
  String _selectedCurrency = 'GBP';
  double _exchangeRate = 0.79; // Mock rate
  bool _isLoading = false;

  final Map<String, Map<String, String>> _countries = {
    'United Kingdom': {'currency': 'GBP', 'flag': '🇬🇧', 'rate': '0.79'},
    'United States': {'currency': 'USD', 'flag': '🇺🇸', 'rate': '1.00'},
    'Kenya': {'currency': 'KES', 'flag': '🇰🇪', 'rate': '132.50'},
    'Nigeria': {'currency': 'NGN', 'flag': '🇳🇬', 'rate': '1450.00'},
    'Europe': {'currency': 'EUR', 'flag': '🇪🇺', 'rate': '0.92'},
  };

  @override
  void dispose() {
    _amountController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  void _onCountryChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedCountry = newValue;
        _selectedCurrency = _countries[newValue]!['currency']!;
        _exchangeRate = double.parse(_countries[newValue]!['rate']!);
      });
    }
  }

  Future<void> _processTransfer() async {
    if (_amountController.text.isEmpty || _recipientController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<WalletProvider>().sendMoney(
        amount,
        'USD', // Deducting from USD balance
        _selectedCountry,
        'International Recipient', 
        _recipientController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('International transfer initiated successfully!'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transfer failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);
    final primaryColor = theme.colorScheme.primary;
    final amountText = _amountController.text.isEmpty ? '0.00' : _amountController.text;
    final convertedAmount = (double.tryParse(amountText) ?? 0.0) * _exchangeRate;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Global Transfer'),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        
                        // Destination Country Picker
                        StaggeredSlideIn(
                          index: 0,
                          child: GlassContainer(
                            borderRadius: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DESTINATION COUNTRY',
                                  style: TextStyle(
                                    color: mutedColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withAlpha(8) : AppColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? Colors.white.withAlpha(10) : AppColors.surfaceLightBorder,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedCountry,
                                      isExpanded: true,
                                      dropdownColor: isDark ? AppColors.cardDark : Colors.white,
                                      items: _countries.keys.map((String country) {
                                        return DropdownMenuItem<String>(
                                          value: country,
                                          child: Row(
                                            children: [
                                              Text(_countries[country]!['flag']!, style: const TextStyle(fontSize: 20)),
                                              const SizedBox(width: 12),
                                              Text(
                                                country,
                                                style: TextStyle(
                                                  color: theme.colorScheme.onSurface,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: _onCountryChanged,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Recipient details
                        StaggeredSlideIn(
                          index: 1,
                          child: GlassContainer(
                            borderRadius: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'RECIPIENT IBAN / ACCOUNT NUMBER',
                                  style: TextStyle(
                                    color: mutedColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _recipientController,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter destination details',
                                    filled: true,
                                    fillColor: isDark ? Colors.white.withAlpha(8) : AppColors.surfaceLight,
                                    prefixIcon: Icon(Icons.account_balance, color: primaryColor, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Send Amount
                        StaggeredSlideIn(
                          index: 2,
                          child: GlassContainer(
                            borderRadius: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AMOUNT TO SEND (USD)',
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
                                  onChanged: (_) => setState(() {}),
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.0,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: isDark ? Colors.white.withAlpha(8) : AppColors.surfaceLight,
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Text(
                                        '\$',
                                        style: TextStyle(
                                          color: primaryColor,
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
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Conversion Details Card
                        StaggeredSlideIn(
                          index: 3,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: AppColors.heroCardGradient,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark ? Colors.white.withAlpha(15) : AppColors.surfaceLightBorder,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(10),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildDetailRow('Recipient gets', '${convertedAmount.toStringAsFixed(2)} $_selectedCurrency', isHighlight: true),
                                const Divider(height: 32),
                                _buildDetailRow('Exchange Rate', '1 USD = $_exchangeRate $_selectedCurrency'),
                                _buildDetailRow('Transfer Fee', '\$ 2.50 USD'),
                                _buildDetailRow('Estimated Arrival', 'Within 24 hours'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Submit Button
                StaggeredSlideIn(
                  index: 4,
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
                      onPressed: _isLoading ? null : _processTransfer,
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
                              'Confirm & Send',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(180), fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isHighlight ? 18 : 14,
              color: isHighlight ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
