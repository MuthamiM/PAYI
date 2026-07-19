import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/colors.dart';
import '../theme/widgets.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  final List<Map<String, dynamic>> _savingsGoals = [
    {
      'name': 'Emergency Fund',
      'icon': Icons.shield_outlined,
      'target': 5000.0,
      'saved': 3250.0,
      'color': AppColors.primaryTeal,
    },
    {
      'name': 'Vacation',
      'icon': Icons.flight_takeoff_outlined,
      'target': 2000.0,
      'saved': 850.0,
      'color': AppColors.accentViolet,
    },
    {
      'name': 'New Gadget',
      'icon': Icons.devices_outlined,
      'target': 1200.0,
      'saved': 1200.0,
      'color': AppColors.accentGold,
    },
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);
    final primaryColor = theme.colorScheme.primary;

    final totalSaved =
        _savingsGoals.fold<double>(0, (sum, g) => sum + (g['saved'] as double));
    final totalTarget = _savingsGoals.fold<double>(
        0, (sum, g) => sum + (g['target'] as double));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Savings Goals')),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Total Savings Summary Card
                StaggeredSlideIn(
                  index: 0,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? AppColors.heroCardGradient
                          : AppColors.heroCardLightGradient,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withAlpha(15)
                            : AppColors.surfaceLightBorder,
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
                    child: Row(
                      children: [
                        // Animated circular progress
                        AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, child) {
                            return SizedBox(
                              width: 90,
                              height: 90,
                              child: CustomPaint(
                                painter: _RingProgressPainter(
                                  progress: (totalSaved / totalTarget) *
                                      _progressController.value,
                                  color: primaryColor,
                                  bgColor: primaryColor.withAlpha(30),
                                  strokeWidth: 8,
                                ),
                                child: Center(
                                  child: Text(
                                    '${((totalSaved / totalTarget) * 100 * _progressController.value).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL SAVINGS',
                                style: TextStyle(
                                  color: mutedColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              AnimatedCounter(
                                targetValue: totalSaved,
                                prefix: '\$',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'of \$${totalTarget.toStringAsFixed(0)} goal',
                                style: TextStyle(
                                  color: mutedColor,
                                  fontSize: 13,
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
                const SizedBox(height: 32),

                // Goals List
                Text(
                  'YOUR GOALS',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                ..._savingsGoals.asMap().entries.map((entry) {
                  final i = entry.key;
                  final goal = entry.value;
                  final progress =
                      (goal['saved'] as double) / (goal['target'] as double);
                  final isComplete = progress >= 1.0;

                  return StaggeredSlideIn(
                    index: i + 1,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: GlassContainer(
                        borderRadius: 22,
                        borderColor: isComplete
                            ? AppColors.success.withAlpha(80)
                            : null,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color:
                                        (goal['color'] as Color).withAlpha(26),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    goal['icon'] as IconData,
                                    color: goal['color'] as Color,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            goal['name'] as String,
                                            style: TextStyle(
                                              color:
                                                  theme.colorScheme.onSurface,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                          ),
                                          if (isComplete)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.success
                                                    .withAlpha(26),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                '✓ Complete',
                                                style: TextStyle(
                                                  color: AppColors.success,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '\$${(goal['saved'] as double).toStringAsFixed(0)} / \$${(goal['target'] as double).toStringAsFixed(0)}',
                                        style: TextStyle(
                                          color: mutedColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, _) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progress *
                                        _progressController.value,
                                    backgroundColor:
                                        (goal['color'] as Color).withAlpha(30),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        goal['color'] as Color),
                                    minHeight: 8,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // Create New Goal Button
                StaggeredSlideIn(
                  index: _savingsGoals.length + 1,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCreateGoalSheet(context),
                    icon: Icon(Icons.add_circle_outline, color: primaryColor),
                    label: const Text('Create New Goal'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor, width: 1.5),
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
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

  void _showCreateGoalSheet(BuildContext context) {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    IconData selectedIcon = Icons.star_border_outlined;
    Color selectedColor = AppColors.primaryTeal;

    final icons = [
      Icons.star_border_outlined,
      Icons.home_outlined,
      Icons.directions_car_outlined,
      Icons.flight_takeoff_outlined,
      Icons.shopping_bag_outlined,
      Icons.school_outlined,
    ];

    final colors = [
      AppColors.primaryTeal,
      AppColors.accentViolet,
      AppColors.accentGold,
      Colors.pinkAccent,
      Colors.blueAccent,
      Colors.orangeAccent,
    ];

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
                    'Create Savings Goal',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Goal Name',
                      hintText: 'e.g., Down Payment, New Laptop',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target Amount (\$)',
                      hintText: 'e.g., 1000',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'CHOOSE ICON',
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
                    children: icons.map((icon) {
                      final isSelected = selectedIcon == icon;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedIcon = icon),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withAlpha(30)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withAlpha(30),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(icon, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'CHOOSE COLOR',
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
                    children: colors.map((color) {
                      final isSelected = selectedColor == color;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedColor = color),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: theme.colorScheme.onSurface, width: 2.5)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      final target = double.tryParse(targetController.text) ?? 0.0;
                      if (name.isEmpty || target <= 0.0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid goal name and target.')),
                        );
                        return;
                      }

                      setState(() {
                        _savingsGoals.add({
                          'name': name,
                          'icon': selectedIcon,
                          'target': target,
                          'saved': 0.0,
                          'color': selectedColor,
                        });
                        _progressController.reset();
                        _progressController.forward();
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Savings goal "$name" created!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Create Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _RingProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;
  final double strokeWidth;

  _RingProgressPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
