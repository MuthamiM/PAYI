import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/widgets.dart';

class CryptoScreen extends StatefulWidget {
  const CryptoScreen({super.key});

  @override
  State<CryptoScreen> createState() => _CryptoScreenState();
}

class _CryptoScreenState extends State<CryptoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _tickerController;

  final List<Map<String, dynamic>> _cryptoAssets = [
    {
      'name': 'Bitcoin',
      'symbol': 'BTC',
      'price': 67842.50,
      'change': 2.34,
      'icon': '₿',
      'color': const Color(0xFFF7931A),
      'sparkline': [42.0, 44.0, 43.5, 46.0, 45.0, 48.0, 47.5, 50.0, 49.0, 52.0],
    },
    {
      'name': 'Ethereum',
      'symbol': 'ETH',
      'price': 3456.80,
      'change': -1.12,
      'icon': 'Ξ',
      'color': const Color(0xFF627EEA),
      'sparkline': [30.0, 32.0, 31.0, 29.0, 28.0, 30.0, 29.5, 31.0, 30.0, 28.5],
    },
    {
      'name': 'Solana',
      'symbol': 'SOL',
      'price': 178.25,
      'change': 5.67,
      'icon': '◎',
      'color': const Color(0xFF9945FF),
      'sparkline': [20.0, 22.0, 24.0, 23.0, 26.0, 28.0, 27.0, 30.0, 32.0, 35.0],
    },
    {
      'name': 'Ripple',
      'symbol': 'XRP',
      'price': 0.62,
      'change': 0.45,
      'icon': '✕',
      'color': const Color(0xFF00AAE4),
      'sparkline': [10.0, 10.5, 11.0, 10.8, 11.2, 11.5, 11.3, 11.8, 12.0, 12.2],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _tickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Crypto')),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Portfolio Value Card
                StaggeredSlideIn(
                  index: 0,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppColors.premiumGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentViolet.withAlpha(60),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PORTFOLIO VALUE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '\$12,483.55',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(26),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.trending_up,
                                  color: Colors.greenAccent, size: 16),
                              SizedBox(width: 4),
                              Text(
                                '+\$342.80 (2.82%) today',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
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

                // Quick Buy/Sell Buttons
                StaggeredSlideIn(
                  index: 1,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppColors.receiveGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withAlpha(60),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Buy crypto coming soon!')),
                              );
                            },
                            icon: const Icon(Icons.add_circle_outline,
                                color: Colors.white, size: 20),
                            label: const Text('Buy',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppColors.sendGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withAlpha(60),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Sell crypto coming soon!')),
                              );
                            },
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.white, size: 20),
                            label: const Text('Sell',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Market Section
                Text(
                  'MARKET',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                ..._cryptoAssets.asMap().entries.map((entry) {
                  final i = entry.key;
                  final crypto = entry.value;
                  final isPositive = (crypto['change'] as double) >= 0;

                  return StaggeredSlideIn(
                    index: i + 2,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        borderRadius: 20,
                        child: Row(
                          children: [
                            // Crypto Icon
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color:
                                    (crypto['color'] as Color).withAlpha(26),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  crypto['icon'] as String,
                                  style: TextStyle(
                                    color: crypto['color'] as Color,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Name & Symbol
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    crypto['name'] as String,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    crypto['symbol'] as String,
                                    style: TextStyle(
                                      color: mutedColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Mini sparkline
                            SizedBox(
                              width: 60,
                              height: 30,
                              child: CustomPaint(
                                painter: _SparklinePainter(
                                  data: crypto['sparkline'] as List<double>,
                                  color: isPositive
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Price & Change
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${(crypto['price'] as double).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isPositive
                                          ? Icons.arrow_drop_up
                                          : Icons.arrow_drop_down,
                                      color: isPositive
                                          ? AppColors.success
                                          : AppColors.error,
                                      size: 18,
                                    ),
                                    Text(
                                      '${isPositive ? '+' : ''}${(crypto['change'] as double).toStringAsFixed(2)}%',
                                      style: TextStyle(
                                        color: isPositive
                                            ? AppColors.success
                                            : AppColors.error,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final minVal = data.reduce((a, b) => a < b ? a : b);
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal;
    if (range == 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minVal) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}
