import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/widgets.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final List<Map<String, dynamic>> _loans = [
    {
      'type': 'Personal Loan',
      'id': '#PL-9821',
      'amount': 5000.0,
      'remaining': 2450.0,
      'interest': '8.5%',
      'dueDate': 'Aug 15, 2026',
      'status': 'Active',
      'color': AppColors.accentBlue,
    },
    {
      'type': 'Device Financing',
      'id': '#DF-1102',
      'amount': 1200.0,
      'remaining': 600.0,
      'interest': '0.0%',
      'dueDate': 'Jul 30, 2026',
      'status': 'Active',
      'color': AppColors.accentGold,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);
    final primaryColor = theme.colorScheme.primary;

    final totalDebt = _loans.fold<double>(0, (sum, l) => sum + (l['remaining'] as double));
    final totalBorrowed = _loans.fold<double>(0, (sum, l) => sum + (l['amount'] as double));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Loans & Credit'),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Loan Credit Summary Card
                StaggeredSlideIn(
                  index: 0,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL OUTSTANDING DEBT',
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            AnimatedCounter(
                              targetValue: totalDebt,
                              prefix: '\$',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total borrowed: \$${totalBorrowed.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Divider(color: isDark ? Colors.white.withAlpha(15) : AppColors.surfaceLightBorder),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Credit Limit: \$15,000.00',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Excellent score',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Active Loans
                Text(
                  'ACTIVE LOANS',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                ..._loans.asMap().entries.map((entry) {
                  final i = entry.key;
                  final loan = entry.value;
                  final progress = (loan['amount'] - loan['remaining']) / loan['amount'];

                  return StaggeredSlideIn(
                    index: i + 1,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: GlassContainer(
                        borderRadius: 22,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loan['type'],
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      loan['id'],
                                      style: TextStyle(
                                        color: mutedColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withAlpha(26),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'On Time',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildLoanMeta(context, 'Remaining', '\$${(loan['remaining'] as double).toStringAsFixed(0)}'),
                                _buildLoanMeta(context, 'Interest', loan['interest']),
                                _buildLoanMeta(context, 'Next Due', loan['dueDate']),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: (loan['color'] as Color).withAlpha(30),
                                valueColor: AlwaysStoppedAnimation<Color>(loan['color'] as Color),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${(progress * 100).toStringAsFixed(0)}% Paid',
                                  style: TextStyle(color: mutedColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Original: \$${(loan['amount'] as double).toStringAsFixed(0)}',
                                  style: TextStyle(color: mutedColor, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Actions Button
                StaggeredSlideIn(
                  index: _loans.length + 1,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withAlpha(80),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => _showApplyLoanSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Apply for a New Loan',
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
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showApplyLoanSheet(BuildContext context) {
    final amountController = TextEditingController();
    String selectedType = 'Personal Loan';
    int selectedMonths = 6;
    double interestRate = 0.085; // 8.5%
    double computedMonthly = 0.0;

    final loanTypes = ['Personal Loan', 'Business Expansion', 'Device Financing'];
    final terms = [3, 6, 12];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: Colors.white.withAlpha(15)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withAlpha(40),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Apply for New Loan',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Loan Type'),
                    dropdownColor: theme.scaffoldBackgroundColor,
                    items: loanTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type, style: TextStyle(color: theme.colorScheme.onSurface)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedType = val;
                          if (selectedType == 'Personal Loan') interestRate = 0.085;
                          if (selectedType == 'Business Expansion') interestRate = 0.12;
                          if (selectedType == 'Device Financing') interestRate = 0.0;
                          final amt = double.tryParse(amountController.text) ?? 0.0;
                          final totalToRepay = amt * (1 + interestRate);
                          computedMonthly = totalToRepay / selectedMonths;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount ($)',
                      hintText: 'e.g., 5000',
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        final amt = double.tryParse(val) ?? 0.0;
                        final totalToRepay = amt * (1 + interestRate);
                        computedMonthly = totalToRepay / selectedMonths;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'REPAYMENT TERM',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: terms.map((term) {
                      final isSelected = selectedMonths == term;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedMonths = term;
                            final amt = double.tryParse(amountController.text) ?? 0.0;
                            final totalToRepay = amt * (1 + interestRate);
                            computedMonthly = totalToRepay / selectedMonths;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withAlpha(30)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withAlpha(30),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            '$term Mos',
                            style: TextStyle(
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Monthly Installment:',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withAlpha(150),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '\$${computedMonthly.toStringAsFixed(2)} / mo',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      final amt = double.tryParse(amountController.text) ?? 0.0;
                      if (amt <= 0.0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid loan amount.')),
                        );
                        return;
                      }

                      final newLoanId = '#LN-${1000 + Random().nextInt(9000)}';
                      final due = DateTime.now().add(Duration(days: selectedMonths * 30));
                      final dueStr = '${_getMonthName(due.month)} ${due.day}, ${due.year}';

                      setState(() {
                        _loans.add({
                          'type': selectedType,
                          'id': newLoanId,
                          'amount': amt,
                          'remaining': amt * (1 + interestRate),
                          'interest': '${(interestRate * 100).toStringAsFixed(1)}%',
                          'dueDate': dueStr,
                          'status': 'Active',
                          'color': selectedType == 'Personal Loan'
                              ? AppColors.accentBlue
                              : (selectedType == 'Business Expansion'
                                  ? AppColors.accentViolet
                                  : AppColors.accentGold),
                        });
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.success,
                          content: Text(
                            'Loan application for \$${amt.toStringAsFixed(0)} approved instantly!',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Confirm & Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

  Widget _buildLoanMeta(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: mutedColor,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
