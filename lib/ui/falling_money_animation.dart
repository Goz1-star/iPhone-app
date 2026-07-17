import 'dart:math' as math;

import 'package:flutter/material.dart';

class FallingMoneyAnimation extends StatefulWidget {
  const FallingMoneyAnimation({super.key, required this.enabled});

  final bool enabled;

  @override
  State<FallingMoneyAnimation> createState() => _FallingMoneyAnimationState();
}

class _FallingMoneyAnimationState extends State<FallingMoneyAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_MoneyParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _particles = List.generate(26, (index) => _MoneyParticle.seed(index));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _MoneyRainPainter(
                progress: _controller.value,
                particles: _particles,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MoneyParticle {
  const _MoneyParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.spin,
    required this.isCoin,
  });

  factory _MoneyParticle.seed(int index) {
    final random = math.Random(index * 91 + 17);
    return _MoneyParticle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: 14 + random.nextDouble() * 18,
      speed: 0.45 + random.nextDouble() * 0.72,
      spin: random.nextDouble() * math.pi * 2,
      isCoin: random.nextBool(),
    );
  }

  final double x;
  final double y;
  final double size;
  final double speed;
  final double spin;
  final bool isCoin;
}

class _MoneyRainPainter extends CustomPainter {
  const _MoneyRainPainter({
    required this.progress,
    required this.particles,
  });

  final double progress;
  final List<_MoneyParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final coinPaint = Paint()..color = const Color(0xFFFFD65A);
    final coinStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFF9D5C00).withOpacity(0.7);
    final billPaint = Paint()..color = const Color(0xFF72F0A0).withOpacity(0.78);

    for (final particle in particles) {
      final fall = (particle.y + progress * particle.speed) % 1.18;
      final x = particle.x * size.width;
      final y = fall * size.height - 80;
      final drift = math.sin(progress * math.pi * 2 + particle.spin) * 18;

      canvas.save();
      canvas.translate(x + drift, y);
      canvas.rotate(progress * math.pi * 2 + particle.spin);
      if (particle.isCoin) {
        canvas.drawCircle(Offset.zero, particle.size * 0.42, coinPaint);
        canvas.drawCircle(Offset.zero, particle.size * 0.42, coinStroke);
        canvas.drawCircle(Offset.zero, particle.size * 0.22, coinStroke);
      } else {
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size * 1.45,
            height: particle.size * 0.72,
          ),
          const Radius.circular(5),
        );
        canvas.drawRRect(rect, billPaint);
        canvas.drawRRect(rect, coinStroke);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _MoneyRainPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
