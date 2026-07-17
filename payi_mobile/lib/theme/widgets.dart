import 'dart:ui';
import 'package:flutter/material.dart';
import 'colors.dart';

/// A frosted glass container with blur effect and subtle border
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final Color? borderColor;
  final Gradient? gradient;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding,
    this.margin,
    this.blur = 10,
    this.borderColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: gradient ??
                  LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.glassDark,
                            AppColors.glassDark.withAlpha(10),
                          ]
                        : [
                            AppColors.glassLight,
                            AppColors.glassLight.withAlpha(200),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ??
                    (isDark
                        ? AppColors.glassDarkBorder
                        : AppColors.glassLightBorder),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Animated gradient background
class GradientBackground extends StatefulWidget {
  final Widget child;
  final List<Color>? colors;
  final bool animate;

  const GradientBackground({
    super.key,
    required this.child,
    this.colors,
    this.animate = true,
  });

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = widget.colors ??
        (isDark
            ? [
                AppColors.backgroundDark,
                const Color(0xFF0F1520),
                const Color(0xFF0B1018),
              ]
            : [
                AppColors.backgroundLight,
                const Color(0xFFEFF4FC),
                const Color(0xFFE8F0FE),
              ]);

    if (!widget.animate) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment(
                -1.0 + _controller.value * 0.5,
                -1.0 + _controller.value * 0.3,
              ),
              end: Alignment(
                1.0 - _controller.value * 0.5,
                1.0 - _controller.value * 0.3,
              ),
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Shimmer loading effect
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.isLoading = true,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Color(0x33FFFFFF),
                Color(0x80FFFFFF),
                Color(0x33FFFFFF),
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Animated counter that counts up to a target value
class AnimatedCounter extends StatefulWidget {
  final double targetValue;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final Duration duration;
  final int decimals;

  const AnimatedCounter({
    super.key,
    required this.targetValue,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.duration = const Duration(milliseconds: 1200),
    this.decimals = 2,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0, end: widget.targetValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetValue != widget.targetValue) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.targetValue,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${widget.prefix}${_animation.value.toStringAsFixed(widget.decimals)}${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}

/// Staggered list animation for items entering the screen
class StaggeredSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delayPerItem;
  final Duration animationDuration;
  final Offset beginOffset;

  const StaggeredSlideIn({
    super.key,
    required this.child,
    required this.index,
    this.delayPerItem = const Duration(milliseconds: 80),
    this.animationDuration = const Duration(milliseconds: 500),
    this.beginOffset = const Offset(0, 0.15),
  });

  @override
  State<StaggeredSlideIn> createState() => _StaggeredSlideInState();
}

class _StaggeredSlideInState extends State<StaggeredSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delayPerItem * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: widget.child,
      ),
    );
  }
}

/// Pulsing glow effect around a widget
class PulsingGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double maxRadius;

  const PulsingGlow({
    super.key,
    required this.child,
    this.glowColor = AppColors.primaryTeal,
    this.maxRadius = 20,
  });

  @override
  State<PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<PulsingGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.glowColor
                    .withAlpha((80 * _controller.value).round()),
                blurRadius: widget.maxRadius * _controller.value,
                spreadRadius: widget.maxRadius * 0.3 * _controller.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
