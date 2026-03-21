import 'package:flutter/material.dart';
import '../theme.dart';

class LogoWidget extends StatelessWidget {
  final double size;

  const LogoWidget({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0E1428),
        borderRadius: BorderRadius.circular(size * 0.18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentPurple.withAlpha(40),
            blurRadius: 24,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: AppTheme.accentCyan.withAlpha(25),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _LogoPainter(logoSize: size),
        child: Align(
          alignment: const Alignment(0.38, -0.38),
          child: Text(
            '\u00B2',
            style: TextStyle(
              fontSize: size * 0.32,
              fontWeight: FontWeight.w800,
              color: AppTheme.accentCyan,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final double logoSize;
  _LogoPainter({required this.logoSize});

  @override
  void paint(Canvas canvas, Size size) {
    _drawScanCorners(canvas, size);
    _drawCurvedX(canvas, size);
  }

  void _drawCurvedX(Canvas canvas, Size size) {
    final cx = size.width * 0.45;
    final cy = size.height * 0.52;
    final arm = size.width * 0.18;
    final strokeW = size.width * 0.055;

    // Glow paint
    final glowPaint = Paint()
      ..color = Colors.white.withAlpha(30)
      ..strokeWidth = strokeW + 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Main stroke paint
    final xPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Stroke 1: top-left → bottom-right with gentle S-curve
    final p1 = Path()
      ..moveTo(cx - arm, cy - arm)
      ..cubicTo(
        cx - arm * 0.15, cy - arm * 0.4,
        cx + arm * 0.15, cy + arm * 0.4,
        cx + arm, cy + arm,
      );

    // Stroke 2: top-right → bottom-left with gentle S-curve
    final p2 = Path()
      ..moveTo(cx + arm, cy - arm)
      ..cubicTo(
        cx + arm * 0.15, cy - arm * 0.4,
        cx - arm * 0.15, cy + arm * 0.4,
        cx - arm, cy + arm,
      );

    // Draw glow then strokes
    canvas.drawPath(p1, glowPaint);
    canvas.drawPath(p2, glowPaint);
    canvas.drawPath(p1, xPaint);
    canvas.drawPath(p2, xPaint);
  }

  void _drawScanCorners(Canvas canvas, Size size) {
    final inset = size.width * 0.12;
    final cornerLength = size.width * 0.22;
    final cornerRadius = size.width * 0.06;

    // Purple corner paint
    final purplePaint = Paint()
      ..color = AppTheme.accentPurple
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Cyan corner paint
    final cyanPaint = Paint()
      ..color = AppTheme.accentCyan
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final left = inset;
    final top = inset;
    final right = size.width - inset;
    final bottom = size.height - inset;

    // Top-left corner (purple)
    final tlPath = Path()
      ..moveTo(left, top + cornerLength)
      ..lineTo(left, top + cornerRadius)
      ..quadraticBezierTo(left, top, left + cornerRadius, top)
      ..lineTo(left + cornerLength, top);
    canvas.drawPath(tlPath, purplePaint);

    // Top-right corner (cyan)
    final trPath = Path()
      ..moveTo(right - cornerLength, top)
      ..lineTo(right - cornerRadius, top)
      ..quadraticBezierTo(right, top, right, top + cornerRadius)
      ..lineTo(right, top + cornerLength);
    canvas.drawPath(trPath, cyanPaint);

    // Bottom-left corner (cyan)
    final blPath = Path()
      ..moveTo(left, bottom - cornerLength)
      ..lineTo(left, bottom - cornerRadius)
      ..quadraticBezierTo(left, bottom, left + cornerRadius, bottom)
      ..lineTo(left + cornerLength, bottom);
    canvas.drawPath(blPath, cyanPaint);

    // Bottom-right corner (purple)
    final brPath = Path()
      ..moveTo(right, bottom - cornerLength)
      ..lineTo(right, bottom - cornerRadius)
      ..quadraticBezierTo(right, bottom, right - cornerRadius, bottom)
      ..lineTo(right - cornerLength, bottom);
    canvas.drawPath(brPath, purplePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
