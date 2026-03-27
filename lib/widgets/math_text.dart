import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Renders math expressions using LaTeX when possible, falls back to plain text.
class MathText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;

  const MathText({
    super.key,
    required this.text,
    this.fontSize = 16,
    this.color,
    this.fontWeight,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = color ?? (isDark ? Colors.white : Colors.black87);

    // Check if text contains LaTeX-like patterns
    if (_containsMath(text)) {
      return _buildMixedContent(textColor);
    }

    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: fontSize,
        color: textColor,
        fontWeight: fontWeight,
        height: 1.5,
      ),
    );
  }

  bool _containsMath(String text) {
    return text.contains(r'\') ||
        text.contains('²') ||
        text.contains('³') ||
        text.contains('√') ||
        text.contains('∫') ||
        text.contains('∑') ||
        text.contains('π') ||
        text.contains('±') ||
        text.contains('≠') ||
        text.contains('≤') ||
        text.contains('≥') ||
        text.contains('Δ') ||
        RegExp(r'x\^?\d').hasMatch(text) ||
        text.contains('/dx') ||
        text.contains('d/d');
  }

  Widget _buildMixedContent(Color textColor) {
    // Convert common math notation to LaTeX
    final latex = _toLatex(text);

    // Try rendering as a single LaTeX block first
    try {
      final widget = Math.tex(
        latex,
        textStyle: TextStyle(
          fontSize: fontSize,
          color: textColor,
          fontWeight: fontWeight,
        ),
      );
      // Validate by building — Math.tex may defer errors
      return widget;
    } catch (e) {
      print('LaTeX render failed: $e');
    }

    // Fallback: render as plain text
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: fontSize,
        color: textColor,
        fontWeight: fontWeight,
        height: 1.5,
      ),
    );
  }

  String _toLatex(String input) {
    String latex = input;

    // Strip LaTeX dollar-sign delimiters that cause parser errors
    latex = latex.replaceAll(r'$$', '');
    latex = latex.replaceAll(r'$', '');

    // Strip \( \) and \[ \] delimiters
    latex = latex.replaceAll(r'\(', '');
    latex = latex.replaceAll(r'\)', '');
    latex = latex.replaceAll(r'\[', '');
    latex = latex.replaceAll(r'\]', '');

    // Already LaTeX — return as-is
    if (latex.contains(r'\frac') || latex.contains(r'\int') || latex.contains(r'\sqrt')) {
      return latex;
    }

    // Convert unicode math symbols to LaTeX
    latex = latex.replaceAll('²', '^{2}');
    latex = latex.replaceAll('³', '^{3}');
    latex = latex.replaceAll('⁴', '^{4}');
    latex = latex.replaceAll('⁵', '^{5}');
    latex = latex.replaceAll('√', r'\sqrt');
    latex = latex.replaceAll('∫', r'\int ');
    latex = latex.replaceAll('∑', r'\sum ');
    latex = latex.replaceAll('π', r'\pi ');
    latex = latex.replaceAll('±', r'\pm ');
    latex = latex.replaceAll('≠', r'\neq ');
    latex = latex.replaceAll('≤', r'\leq ');
    latex = latex.replaceAll('≥', r'\geq ');
    latex = latex.replaceAll('Δ', r'\Delta ');
    latex = latex.replaceAll('×', r'\times ');
    latex = latex.replaceAll('÷', r'\div ');
    latex = latex.replaceAll('∞', r'\infty ');

    // Convert x^n notation
    latex = latex.replaceAllMapped(
      RegExp(r'(\w)\^(\d+)'),
      (m) => '${m[1]}^{${m[2]}}',
    );

    // Convert d/dx notation
    latex = latex.replaceAllMapped(
      RegExp(r'd/d([a-z])'),
      (m) => r'\frac{d}{d' '${m[1]}}',
    );

    return latex;
  }
}
