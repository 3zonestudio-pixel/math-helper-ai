import 'package:flutter/material.dart';
import '../theme.dart';

class LogoWidget extends StatelessWidget {
  final double size;

  const LogoWidget({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(),
        child: Center(
          child: ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.primaryGradient.createShader(bounds),
            child: Text(
              'x\u00B2',
              style: TextStyle(
                fontSize: size * 0.45,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFamily: 'monospace',
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cornerLength = size.width * 0.28;
    final cornerRadius = size.width * 0.12;

    // Purple corner paint
    final purplePaint = Paint()
      ..color = AppTheme.accentPurple
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Cyan corner paint
    final cyanPaint = Paint()
      ..color = AppTheme.accentCyan
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left corner (purple) — rounded
    final tlPath = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, cornerRadius)
      ..quadraticBezierTo(0, 0, cornerRadius, 0)
      ..lineTo(cornerLength, 0);
    canvas.drawPath(tlPath, purplePaint);

    // Top-right corner (cyan) — rounded
    final trPath = Path()
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width - cornerRadius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, cornerRadius)
      ..lineTo(size.width, cornerLength);
    canvas.drawPath(trPath, cyanPaint);

    // Bottom-left corner (cyan) — rounded
    final blPath = Path()
      ..moveTo(0, size.height - cornerLength)
      ..lineTo(0, size.height - cornerRadius)
      ..quadraticBezierTo(0, size.height, cornerRadius, size.height)
      ..lineTo(cornerLength, size.height);
    canvas.drawPath(blPath, cyanPaint);

    // Bottom-right corner (purple) — rounded
    final brPath = Path()
      ..moveTo(size.width, size.height - cornerLength)
      ..lineTo(size.width, size.height - cornerRadius)
      ..quadraticBezierTo(size.width, size.height, size.width - cornerRadius, size.height)
      ..lineTo(size.width - cornerLength, size.height);
    canvas.drawPath(brPath, purplePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
