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
    _drawSuperscript2(canvas, size);
  }

  void _drawSuperscript2(Canvas canvas, Size size) {
    // Position to upper-right of x
    final s = size.width * 0.11;
    final ox = size.width * 0.64;
    final oy = size.height * 0.28;
    final strokeW = size.width * 0.032;

    final glowPaint = Paint()
      ..color = AppTheme.accentCyan.withAlpha(30)
      ..strokeWidth = strokeW + 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final paint = Paint()
      ..color = AppTheme.accentCyan
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Curved "2": top arc + diagonal swoop
    final path = Path()
      ..moveTo(ox - s * 0.65, oy - s * 0.15)
      ..cubicTo(
        ox - s * 0.55, oy - s * 1.05,
        ox + s * 0.85, oy - s * 1.05,
        ox + s * 0.7, oy + s * 0.05,
      )
      ..cubicTo(
        ox + s * 0.5, oy + s * 0.55,
        ox + s * 0.05, oy + s * 0.7,
        ox - s * 0.7, oy + s * 0.85,
      );

    // Bottom bar
    final bar = Path()
      ..moveTo(ox - s * 0.75, oy + s * 0.85)
      ..lineTo(ox + s * 0.75, oy + s * 0.85);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(bar, glowPaint);
    canvas.drawPath(path, paint);
    canvas.drawPath(bar, paint);
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
