import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/color.dart';

class AnimatedSubscribeButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool isBuy;
  final double height;
  final double radius;
  final double strokeWidth;
  final List<Color>? gradientColors;

  const AnimatedSubscribeButton({
    super.key,
    required this.onTap,
    required this.child,
    this.isBuy = false,
    this.height = 30.0,
    this.radius = 40.0,
    this.strokeWidth = 1.3,
    this.gradientColors,
  });

  @override
  State<AnimatedSubscribeButton> createState() =>
      _AnimatedSubscribeButtonState();
}

class _AnimatedSubscribeButtonState extends State<AnimatedSubscribeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = widget.gradientColors ??
        (widget.isBuy
            ? const [
                colorPrimary,
                Color(0xFFFFD700),
                colorPrimaryDark,
                Color(0xFFFFA500),
                colorPrimary,
              ]
            : const [
                colorPrimary,
                colorPrimaryDark,
                complimentryColor,
                Color(0xFFD946EF),
                colorPrimary,
              ]);

    return InkWell(
      borderRadius: BorderRadius.circular(widget.radius),
      splashColor: transparent,
      highlightColor: transparent,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _RotatingBorderPainter(
              animationValue: _controller.value,
              strokeWidth: widget.strokeWidth,
              radius: widget.radius,
              colors: colors,
            ),
            child: child,
          );
        },
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.isBuy
                ? complimentryColor.withValues(alpha: 0.35)
                : black.withValues(alpha: 0.50),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}

class _RotatingBorderPainter extends CustomPainter {
  final double animationValue;
  final double strokeWidth;
  final double radius;
  final List<Color> colors;

  _RotatingBorderPainter({
    required this.animationValue,
    required this.strokeWidth,
    required this.radius,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );

    final shader = SweepGradient(
      center: Alignment.center,
      colors: colors,
      transform: GradientRotation(animationValue * 2 * math.pi),
    ).createShader(rect);

    // 1. Subtle soft neon glow behind the border
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 1.2
      ..shader = shader
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
    canvas.drawRRect(rrect, glowPaint);

    // 2. Sharp rotating border stroke
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = shader;
    canvas.drawRRect(rrect, strokePaint);
  }

  @override
  bool shouldRepaint(_RotatingBorderPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.colors != colors;
}
