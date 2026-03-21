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
                fontSize: size * 0.5,
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
    final cornerLength = size.width * 0.25;

    // Purple corner paint
    final purplePaint = Paint()
      ..color = AppTheme.accentPurple
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Cyan corner paint
    final cyanPaint = Paint()
      ..color = AppTheme.accentCyan
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left corner (purple)
    canvas.drawLine(Offset(0, cornerLength), const Offset(0, 0), purplePaint);
    canvas.drawLine(const Offset(0, 0), Offset(cornerLength, 0), purplePaint);

    // Top-right corner (cyan)
    canvas.drawLine(Offset(size.width - cornerLength, 0), Offset(size.width, 0), cyanPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), cyanPaint);

    // Bottom-left corner (cyan)
    canvas.drawLine(Offset(0, size.height - cornerLength), Offset(0, size.height), cyanPaint);
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), cyanPaint);

    // Bottom-right corner (purple)
    canvas.drawLine(Offset(size.width, size.height - cornerLength), Offset(size.width, size.height), purplePaint);
    canvas.drawLine(Offset(size.width - cornerLength, size.height), Offset(size.width, size.height), purplePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
