import 'package:flutter/material.dart';

class FortunePenguin extends StatelessWidget {
  const FortunePenguin({super.key, this.size = 150});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _FortunePenguinPainter(),
    );
  }
}

class _FortunePenguinPainter extends CustomPainter {
  const _FortunePenguinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 150;
    final body = Paint()..color = const Color(0xFF231A34);
    final belly = Paint()..color = const Color(0xFFFFF7E8);
    final gold = Paint()..color = const Color(0xFFFFCA45);
    final red = Paint()..color = const Color(0xFFFF4A52);
    final orange = Paint()..color = const Color(0xFFFF8F31);
    final shadow = Paint()..color = Colors.black.withOpacity(0.12);

    canvas.drawOval(
      Rect.fromLTWH(22 * unit, 34 * unit, 106 * unit, 106 * unit),
      body,
    );
    canvas.drawOval(
      Rect.fromLTWH(42 * unit, 56 * unit, 66 * unit, 76 * unit),
      belly,
    );
    canvas.drawOval(
      Rect.fromLTWH(38 * unit, 40 * unit, 74 * unit, 56 * unit),
      body,
    );

    canvas.drawCircle(Offset(55 * unit, 65 * unit), 5 * unit, belly);
    canvas.drawCircle(Offset(95 * unit, 65 * unit), 5 * unit, belly);
    canvas.drawCircle(Offset(56 * unit, 66 * unit), 2.4 * unit, body);
    canvas.drawCircle(Offset(94 * unit, 66 * unit), 2.4 * unit, body);

    final beak = Path()
      ..moveTo(68 * unit, 73 * unit)
      ..lineTo(82 * unit, 73 * unit)
      ..lineTo(75 * unit, 82 * unit)
      ..close();
    canvas.drawPath(beak, orange);

    final hat = Path()
      ..moveTo(44 * unit, 38 * unit)
      ..quadraticBezierTo(75 * unit, 12 * unit, 106 * unit, 38 * unit)
      ..lineTo(98 * unit, 50 * unit)
      ..quadraticBezierTo(75 * unit, 42 * unit, 52 * unit, 50 * unit)
      ..close();
    canvas.drawPath(hat, red);
    canvas.drawCircle(Offset(75 * unit, 28 * unit), 13 * unit, gold);
    canvas.drawCircle(Offset(75 * unit, 28 * unit), 6 * unit, red);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(57 * unit, 96 * unit, 36 * unit, 18 * unit),
        Radius.circular(5 * unit),
      ),
      red,
    );
    final badgeText = TextPainter(
      text: TextSpan(
        text: '发财',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9 * unit,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    badgeText.paint(canvas, Offset(66 * unit, 99 * unit));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(100 * unit, 92 * unit, 28 * unit, 24 * unit),
        Radius.circular(6 * unit),
      ),
      Paint()..color = const Color(0xFFFFF1C2),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(104 * unit, 86 * unit, 20 * unit, 8 * unit),
        Radius.circular(4 * unit),
      ),
      gold,
    );
    canvas.drawLine(
      Offset(112 * unit, 82 * unit),
      Offset(124 * unit, 68 * unit),
      Paint()
        ..color = const Color(0xFF5A2D17)
        ..strokeWidth = 2 * unit,
    );

    canvas.drawOval(
      Rect.fromLTWH(38 * unit, 132 * unit, 74 * unit, 10 * unit),
      shadow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
