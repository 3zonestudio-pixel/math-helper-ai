import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'ai_service.dart';

/// Math-specialized OCR service.
/// Wraps ML Kit text recognition with math-aware post-processing
/// and AI reconstruction for accurate math transcription.
class MathOcrService {
  TextRecognizer? _textRecognizer;

  TextRecognizer get _recognizer {
    _textRecognizer ??= TextRecognizer();
    return _textRecognizer!;
  }

  /// Main entry point: image path → accurate math text.
  /// Pipeline: ML Kit → structure extraction → math correction → AI polish
  Future<String> recognizeMath(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) return '';
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) return '';

      InputImage? inputImage;
      try {
        inputImage = InputImage.fromFilePath(imagePath);
      } catch (e) {
        print('MathOCR: Failed to create InputImage: $e');
        return '';
      }

      // Step 1: ML Kit extraction
      RecognizedText recognized;
      try {
        recognized = await _recognizer.processImage(inputImage);
        if (recognized.text.isEmpty) return '';
      } catch (e) {
        print('MathOCR: Recognition failed: $e');
        return '';
      }

      // Step 2: Structure-aware extraction (block-by-block with spatial analysis)
      final structured = _extractMathStructure(recognized);

      // Step 3: Math-specific character corrections
      final corrected = _applyMathCorrections(structured);

      // Step 4: Unicode normalization + spacing cleanup
      final cleaned = _normalizeAndClean(corrected);

      // Step 5: AI reconstruction — only if text looks garbled
      // Skip AI call for clean-looking text (saves ~5-8s)
      if (_needsAiReconstruction(cleaned)) {
        final aiResult = await AiService.reconstructMathFromOcr(cleaned);
        return aiResult ?? cleaned;
      }

      return cleaned;
    } catch (e, st) {
      print('MathOCR: Unexpected error: $e\n$st');
      return '';
    }
  }

  /// Heuristic: does the text need AI to clean up further?
  /// Returns false if it already looks like clean math.
  bool _needsAiReconstruction(String text) {
    if (text.trim().isEmpty) return false;

    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return false;

    // Count lines that look like valid math or instructions
    int cleanLines = 0;
    final mathPattern = RegExp(r'[\d+\-×÷*/=^√∫xyzπ()]');
    final wordPattern = RegExp(
      r'\b(solve|find|calculate|simplify|evaluate|factor|integrate|'
      r'derive|limit|sum|area|volume|perimeter|prove|show|graph|'
      r'choose|select|answer|correct|true|false)\b',
      caseSensitive: false,
    );
    for (final line in lines) {
      if (mathPattern.hasMatch(line) || wordPattern.hasMatch(line)) {
        cleanLines++;
      }
    }

    // If most lines look clean, skip AI reconstruction
    final cleanRatio = cleanLines / lines.length;
    if (cleanRatio >= 0.7) return false;

    // If very short text (single expression), corrections are enough
    if (text.length < 30 && mathPattern.hasMatch(text)) return false;

    return true;
  }

  /// Extract text preserving spatial structure.
  /// Processes each block independently to keep question separation.
  /// Detects superscripts, subscripts, and fraction-like layouts.
  String _extractMathStructure(RecognizedText recognized) {
    final blocks = <_MathBlock>[];

    for (final block in recognized.blocks) {
      final blockLines = <String>[];

      for (final line in block.lines) {
        if (line.elements.isEmpty) continue;

        if (line.elements.length == 1) {
          blockLines.add(line.text);
          continue;
        }

        // Compute baselines for super/subscript detection
        final bottoms = line.elements.map((e) => e.boundingBox.bottom).toList()..sort();
        final medianBottom = bottoms[bottoms.length ~/ 2];
        final tops = line.elements.map((e) => e.boundingBox.top).toList()..sort();
        final medianTop = tops[tops.length ~/ 2];
        final avgHeight = line.elements.map((e) => e.boundingBox.height).reduce((a, b) => a + b) / line.elements.length;

        final lineBuf = StringBuffer();

        for (int i = 0; i < line.elements.length; i++) {
          final el = line.elements[i];
          final elBottom = el.boundingBox.bottom;
          final elTop = el.boundingBox.top;
          final elHeight = el.boundingBox.height;
          final text = el.text;

          final isSmaller = elHeight < avgHeight * 0.65;

          // Superscript: small element with bottom clearly above median bottom
          final isSuperscript = i > 0 &&
              isSmaller &&
              (medianBottom - elBottom) > avgHeight * 0.30;

          // Subscript: small element with top clearly below median top
          final isSubscript = i > 0 &&
              isSmaller &&
              (elTop - medianTop) > avgHeight * 0.30 &&
              !isSuperscript;

          if (isSuperscript) {
            // Use ^ notation for exponents — AI will understand it
            lineBuf.write('^');
            if (text.length > 1) {
              lineBuf.write('($text)');
            } else {
              lineBuf.write(text);
            }
          } else if (isSubscript) {
            lineBuf.write('_');
            if (text.length > 1) {
              lineBuf.write('($text)');
            } else {
              lineBuf.write(text);
            }
          } else {
            if (i > 0) lineBuf.write(' ');
            lineBuf.write(text);
          }
        }

        blockLines.add(lineBuf.toString());
      }

      if (blockLines.isNotEmpty) {
        blocks.add(_MathBlock(
          text: blockLines.join('\n'),
          top: block.boundingBox.top,
          left: block.boundingBox.left,
        ));
      }
    }

    // Sort blocks top-to-bottom, left-to-right (reading order)
    blocks.sort((a, b) {
      final dy = (a.top - b.top).abs();
      // If blocks are on roughly the same vertical line, sort by left
      if (dy < 20) return a.left.compareTo(b.left);
      return a.top.compareTo(b.top);
    });

    return blocks.map((b) => b.text).join('\n');
  }

  /// Apply math-specific character corrections.
  /// Context-aware: uses surrounding characters to decide corrections.
  String _applyMathCorrections(String text) {
    final lines = text.split('\n');
    final corrected = <String>[];

    for (final line in lines) {
      corrected.add(_correctMathLine(line));
    }

    return corrected.join('\n');
  }

  /// Correct a single line with math-aware rules.
  /// Covers: arithmetic, algebra, calculus, trigonometry, geometry,
  /// statistics, set theory, logic, matrices, and exam/MCQ formatting.
  String _correctMathLine(String line) {
    if (line.trim().isEmpty) return line;

    var r = line;

    // ════════════════════════════════════════════════════
    // 1. CHARACTER-LEVEL CONFUSIONS (digit ↔ letter)
    // ════════════════════════════════════════════════════

    // "O" in math context → "0"
    r = r.replaceAllMapped(RegExp(r'(?<=[\d+\-*/=^(])\s*O\s*(?=[\d+\-*/=^)])'), (m) => '0');
    r = r.replaceAllMapped(RegExp(r'(=\s*)O\b'), (m) => '${m.group(1)}0');
    r = r.replaceAllMapped(RegExp(r'\bO(?=\s*[+\-*/^])'), (m) => '0');

    // "l" / "I" between digits → "1"
    r = r.replaceAllMapped(RegExp(r'(?<=\d)[lI](?=\d)'), (m) => '1');
    // Standalone "l" or "I" as a number in math (e.g. "= l" → "= 1")
    r = r.replaceAllMapped(RegExp(r'(=\s*)[lI]\b(?!\s*[a-zA-Z])'), (m) => '${m.group(1)}1');

    // "S" between digits → "5"
    r = r.replaceAllMapped(RegExp(r'(?<=\d)S(?=\d)'), (m) => '5');

    // "Z" between digits → "2"
    r = r.replaceAllMapped(RegExp(r'(?<=\d)Z(?=\d)'), (m) => '2');

    // "B" between digits → "8"
    r = r.replaceAllMapped(RegExp(r'(?<=\d)B(?=\d)'), (m) => '8');

    // "G" between digits → "6"
    r = r.replaceAllMapped(RegExp(r'(?<=\d)G(?=\d)'), (m) => '6');

    // "g" / "q" between digits → "9"
    r = r.replaceAllMapped(RegExp(r'(?<=\d)[gq](?=\d)'), (m) => '9');

    // "D" between digits → "0" (handwriting)
    r = r.replaceAllMapped(RegExp(r'(?<=\d)D(?=\d)'), (m) => '0');

    // "b" between digits → "6" (handwriting)
    r = r.replaceAllMapped(RegExp(r'(?<=\d)b(?=\d)'), (m) => '6');

    // "o" in pure-number context → "0"
    r = r.replaceAllMapped(RegExp(r'(?<=\d)o(?=\d)'), (m) => '0');

    // "=" misread as "-" between two expressions
    // "t" misread as "+" in math context
    r = r.replaceAllMapped(RegExp(r'(\d)\s*t\s*(\d)'), (m) => '${m.group(1)} + ${m.group(2)}');

    // ════════════════════════════════════════════════════
    // 2. UNIT EXPONENTS (must run BEFORE variable-exponent detection)
    // ════════════════════════════════════════════════════

    // "cm2" → "cm²", "m3" → "m³" (unit exponents)
    r = r.replaceAllMapped(
      RegExp(r'\b(cm|mm|km|in|ft|yd|mi)\s*2\b'),
      (m) => '${m.group(1)}²',
    );
    r = r.replaceAllMapped(
      RegExp(r'\b(cm|mm|km|in|ft|yd|mi)\s*3\b'),
      (m) => '${m.group(1)}³',
    );
    // Single "m" unit: only "m2" or "m3" at word boundary
    r = r.replaceAllMapped(
      RegExp(r'(?<=\d\s*)m\s*2\b'),
      (m) => 'm²',
    );
    r = r.replaceAllMapped(
      RegExp(r'(?<=\d\s*)m\s*3\b'),
      (m) => 'm³',
    );

    // ════════════════════════════════════════════════════
    // 3. EXPONENT / SUBSCRIPT DETECTION
    // ════════════════════════════════════════════════════

    // variable + digits → exponent: "y2" → "y^2", "z3" → "z^3"
    // Excludes "x" here (handled separately below after multiplication rule)
    r = r.replaceAllMapped(
      RegExp(r'([a-wyzA-WYZ])\s*(\d{1,2})(?!\w)'),
      (m) {
        final v = m.group(1)!;
        final d = m.group(2)!;
        final n = int.tryParse(d);
        if (n != null && n <= 19) return '$v^$d';
        return m.group(0)!;
      },
    );

    // Parenthesis + digits → exponent: "(x+1)2" → "(x+1)^2"
    r = r.replaceAllMapped(
      RegExp(r'(\))\s*(\d{1,2})(?!\w)'),
      (m) {
        final d = m.group(2)!;
        final n = int.tryParse(d);
        if (n != null && n <= 19) return ')^$d';
        return m.group(0)!;
      },
    );

    // "x" NOT preceded by digit + small number → exponent
    // e.g. "x2" → "x^2", but NOT "3x2" (that's multiplication)
    r = r.replaceAllMapped(
      RegExp(r'(?<!\d)x(\d{1,2})(?!\w)'),
      (m) => 'x^${m.group(1)}',
    );

    // ════════════════════════════════════════════════════
    // 4. OPERATOR CORRECTIONS
    // ════════════════════════════════════════════════════

    // "x" between two numbers → "×" (multiplication)
    r = r.replaceAllMapped(
      RegExp(r'(\d)\s*x\s*(\d)'),
      (m) => '${m.group(1)} × ${m.group(2)}',
    );

    // "X" between two numbers → "×"
    r = r.replaceAllMapped(
      RegExp(r'(\d)\s*X\s*(\d)'),
      (m) => '${m.group(1)} × ${m.group(2)}',
    );

    // "*" → "×" for display (in number×number context)
    r = r.replaceAllMapped(
      RegExp(r'(\d)\s*\*\s*(\d)'),
      (m) => '${m.group(1)} × ${m.group(2)}',
    );

    // "+-" → "± " (plus-minus)
    r = r.replaceAll('+-', '±');

    // Double minus "--" → "+"
    r = r.replaceAll('--', '+');

    // ════════════════════════════════════════════════════
    // 5. COMMON MATH WORD OCR FIXES
    // ════════════════════════════════════════════════════

    // Words with digit substitutions (5=S, 1=l/I, 0=O)
    final wordFixes = <RegExp, String>{
      RegExp(r'\b5olve\b', caseSensitive: false): 'Solve',
      RegExp(r'\b5implify\b', caseSensitive: false): 'Simplify',
      RegExp(r'\b5ubstitute\b', caseSensitive: false): 'Substitute',
      RegExp(r'\b5ubtract\b', caseSensitive: false): 'Subtract',
      RegExp(r'\b5quare\b', caseSensitive: false): 'Square',
      RegExp(r'\beva1uate\b', caseSensitive: false): 'Evaluate',
      RegExp(r'\bca1culate\b', caseSensitive: false): 'Calculate',
      RegExp(r'\bsimp1ify\b', caseSensitive: false): 'Simplify',
      RegExp(r'\bmu1tiply\b', caseSensitive: false): 'Multiply',
      RegExp(r'\bdifferentia1\b', caseSensitive: false): 'Differential',
      RegExp(r'\bintegra1\b', caseSensitive: false): 'Integral',
      RegExp(r'\bpo1ynomial\b', caseSensitive: false): 'Polynomial',
      RegExp(r'\bfactoria1\b', caseSensitive: false): 'Factorial',
      RegExp(r'\blogari[t]?hm\b', caseSensitive: false): 'Logarithm',
      RegExp(r'\b1imit\b', caseSensitive: false): 'Limit',
      RegExp(r'\b1inear\b', caseSensitive: false): 'Linear',
      RegExp(r'\bproba[b]?i1ity\b', caseSensitive: false): 'Probability',
      RegExp(r'\bgeome[t]?ry\b', caseSensitive: false): 'Geometry',
      RegExp(r'\btrigonom[e]?try\b', caseSensitive: false): 'Trigonometry',
      RegExp(r'\bhy[p]?otenuse\b', caseSensitive: false): 'Hypotenuse',
      RegExp(r'\bpara[b]?o1a\b', caseSensitive: false): 'Parabola',
      RegExp(r'\bmatri[x]?\b', caseSensitive: false): 'Matrix',
      RegExp(r'\bvect[o0]r\b', caseSensitive: false): 'Vector',
      RegExp(r'\bradiu[s5]\b', caseSensitive: false): 'Radius',
      RegExp(r'\bdiame[t]?er\b', caseSensitive: false): 'Diameter',
      RegExp(r'\bperime[t]?er\b', caseSensitive: false): 'Perimeter',
      RegExp(r'\bvo1ume\b', caseSensitive: false): 'Volume',
    };
    for (final entry in wordFixes.entries) {
      r = r.replaceAllMapped(entry.key, (m) => entry.value);
    }

    // ════════════════════════════════════════════════════
    // 6. TRIGONOMETRY FIXES
    // ════════════════════════════════════════════════════

    // "5in" → "sin", "c0s" → "cos", "1og" → "log"
    r = r.replaceAllMapped(RegExp(r'\b5in\b'), (m) => 'sin');
    r = r.replaceAllMapped(RegExp(r'\b5inh\b'), (m) => 'sinh');
    r = r.replaceAllMapped(RegExp(r'\bc[0O]s\b'), (m) => 'cos');
    r = r.replaceAllMapped(RegExp(r'\bc[0O]sh\b'), (m) => 'cosh');
    r = r.replaceAllMapped(RegExp(r'\b[t1]an\b'), (m) => 'tan');
    r = r.replaceAllMapped(RegExp(r'\b[t1]anh\b'), (m) => 'tanh');
    r = r.replaceAllMapped(RegExp(r'\bcot\b'), (m) => 'cot');
    r = r.replaceAllMapped(RegExp(r'\bsec\b'), (m) => 'sec');
    r = r.replaceAllMapped(RegExp(r'\bcsc\b'), (m) => 'csc');
    r = r.replaceAllMapped(RegExp(r'\b1og\b'), (m) => 'log');
    r = r.replaceAllMapped(RegExp(r'\b1n\b'), (m) => 'ln');

    // Inverse trig: "sin-1" → "sin⁻¹", "arcsin" stays
    r = r.replaceAllMapped(
      RegExp(r'\b(sin|cos|tan|cot|sec|csc)\s*-\s*1\b'),
      (m) => '${m.group(1)}⁻¹',
    );
    // "arc5in" → "arcsin"
    r = r.replaceAllMapped(RegExp(r'\barc5in\b', caseSensitive: false), (m) => 'arcsin');
    r = r.replaceAllMapped(RegExp(r'\barcc[0O]s\b', caseSensitive: false), (m) => 'arccos');
    r = r.replaceAllMapped(RegExp(r'\barc[t1]an\b', caseSensitive: false), (m) => 'arctan');

    // ════════════════════════════════════════════════════
    // 7. CALCULUS FIXES
    // ════════════════════════════════════════════════════

    // "d/dx" variants: "d/ dx", "d /dx"
    r = r.replaceAllMapped(
      RegExp(r'd\s*/\s*d\s*([xyztuv])', caseSensitive: false),
      (m) => 'd/d${m.group(1)!.toLowerCase()}',
    );

    // "lim" with arrow: "lim x->0" stays, "1im" → "lim"
    r = r.replaceAllMapped(RegExp(r'\b1im\b'), (m) => 'lim');

    // Integral sign misread as "f" or "J": standalone "f" or "J" before a math expression
    // Only when it looks like ∫: "f x dx" → "∫ x dx"  (conservative — only with "dx" nearby)
    r = r.replaceAllMapped(
      RegExp(r'(?:^|\s)[fJ]\s+(.+?\s*d[xyztuv])\b'),
      (m) => ' ∫ ${m.group(1)}',
    );

    // "dx", "dy", "dt" normalization
    r = r.replaceAllMapped(
      RegExp(r'\bd\s+([xyztuv])\b'),
      (m) => 'd${m.group(1)}',
    );

    // Summation: "E" misread as "Σ" — only in "E i=1" pattern
    r = r.replaceAllMapped(
      RegExp(r'\bE\s*(\(\s*[a-z]\s*=)'),
      (m) => 'Σ${m.group(1)}',
    );

    // ════════════════════════════════════════════════════
    // 8. ALGEBRA & NUMBER THEORY
    // ════════════════════════════════════════════════════

    // "√" misread as "V" before a number or parenthesis
    r = r.replaceAllMapped(
      RegExp(r'(?:^|(?<=\s|=|[+\-*/]))V\s*(\d|\()'),
      (m) => '√${m.group(1)}',
    );
    // "v/" at start → "√"
    r = r.replaceAllMapped(
      RegExp(r'(?:^|(?<=\s|=|[+\-*/]))v/\s*(\d|\()'),
      (m) => '√${m.group(1)}',
    );

    // Absolute value: "|x|" — normalize pipe chars
    r = r.replaceAll('ǀ', '|');
    r = r.replaceAll('ꟾ', '|');

    // Factorial: "n!" stays, but "n !" → "n!"
    r = r.replaceAllMapped(
      RegExp(r'(\w)\s+!'),
      (m) => '${m.group(1)}!',
    );

    // "mod" / "%" normalization
    r = r.replaceAllMapped(
      RegExp(r'\bm[0O]d\b', caseSensitive: false),
      (m) => 'mod',
    );

    // ════════════════════════════════════════════════════
    // 9. GEOMETRY & MEASUREMENT
    // ════════════════════════════════════════════════════

    // Degree symbol: "°" misread — "30 o" or "30o" → "30°"
    r = r.replaceAllMapped(
      RegExp(r'(\d)\s*o(?=\s|$|\)|,)'),
      (m) => '${m.group(1)}°',
    );

    // "pi" → "π" (when standalone)
    r = r.replaceAllMapped(
      RegExp(r'\bpi\b', caseSensitive: false),
      (m) => 'π',
    );

    // Angle symbol: "<" before letter might be "∠"
    // e.g. "<ABC" → "∠ABC"
    r = r.replaceAllMapped(
      RegExp(r'<\s*([A-Z]{3})\b'),
      (m) => '∠${m.group(1)}',
    );

    // "perpendicular" symbol: "_|_" or "⊥"
    r = r.replaceAll('_|_', '⊥');
    // "parallel" symbol: "||" (keep as-is, context-dependent)

    // Triangle symbol: misread "A" → "△" — too ambiguous, leave for AI

    // ════════════════════════════════════════════════════
    // 10. STATISTICS & PROBABILITY
    // ════════════════════════════════════════════════════

    // "P(A)" stays, "P (A)" → "P(A)"
    r = r.replaceAllMapped(
      RegExp(r'\b([PpCc])\s+\('),
      (m) => '${m.group(1)}(',
    );

    // "nCr" / "nPr" normalization
    r = r.replaceAllMapped(
      RegExp(r'(\d+)\s*[Cc]\s*(\d+)'),
      (m) => '${m.group(1)}C${m.group(2)}',
    );
    r = r.replaceAllMapped(
      RegExp(r'(\d+)\s*[Pp]\s*(\d+)'),
      (m) => '${m.group(1)}P${m.group(2)}',
    );

    // "x-bar" (mean): "x" with overline — hard to detect, leave for AI
    // "sigma" → "σ" (if standalone word)
    r = r.replaceAllMapped(
      RegExp(r'\bsigma\b', caseSensitive: false),
      (m) => 'σ',
    );
    // "mu" → "μ"
    r = r.replaceAllMapped(
      RegExp(r'\bmu\b', caseSensitive: false),
      (m) => 'μ',
    );

    // ════════════════════════════════════════════════════
    // 11. SET THEORY & LOGIC
    // ════════════════════════════════════════════════════

    // "U" as union when between sets: "{A} U {B}" → "{A} ∪ {B}"
    r = r.replaceAllMapped(
      RegExp(r'(\})\s*U\s*(\{)'),
      (m) => '${m.group(1)} ∪ ${m.group(2)}',
    );

    // "n" as intersection: "{A} n {B}" → "{A} ∩ {B}" — too ambiguous alone
    // Keep for AI

    // "E" as element-of in set context: already handled by AI

    // ════════════════════════════════════════════════════
    // 12. MATRIX / BRACKET FIXES
    // ════════════════════════════════════════════════════

    // "C" misread as "(" — only when before a digit and after operator/space
    r = r.replaceAllMapped(
      RegExp(r'(?<=[=+\-*/\s])C(?=\s*\d)'),
      (m) => '(',
    );

    // "J" misread as ")" — only when after a digit and before operator/space/end
    r = r.replaceAllMapped(
      RegExp(r'(?<=\d\s*)J(?=[\s+\-*/=]|$)'),
      (m) => ')',
    );

    // "[" and "]" sometimes read as "(" and ")"  — leave as-is, both valid

    // ════════════════════════════════════════════════════
    // 13. SPACING & FORMATTING
    // ════════════════════════════════════════════════════

    // Ensure operators have spaces: "2+3" → "2 + 3" (readability)
    // Only for top-level, not inside superscripts etc.
    r = r.replaceAllMapped(
      RegExp(r'(\d)\s*([+\-])\s*(\d)'),
      (m) => '${m.group(1)} ${m.group(2)} ${m.group(3)}',
    );

    // Clean up multiple spaces
    r = r.replaceAll(RegExp(r'  +'), ' ');

    // "= =" → "=" (double equals from OCR stutter)
    r = r.replaceAll(RegExp(r'=\s*='), '=');

    // MCQ option spacing: "a)" or "a )" → "a) "
    r = r.replaceAllMapped(
      RegExp(r'\b([a-dA-D])\s*\)\s*'),
      (m) => '${m.group(1)}) ',
    );

    // Question numbering: "1 ." or "1." → "1. "
    r = r.replaceAllMapped(
      RegExp(r'^(\d+)\s*\.\s*'),
      (m) => '${m.group(1)}. ',
    );

    return r;
  }

  /// Normalize Unicode variants and clean up spacing while preserving line structure.
  String _normalizeAndClean(String text) {
    var cleaned = text;

    // Unicode math symbol normalization
    const replacements = <String, String>{
      // Minus / dash variants
      '\u2212': '-', '\u2014': '-', '\u2013': '-',
      '\uFE63': '-', '\uFF0D': '-',
      // Plus variants
      '\uFF0B': '+',
      // Multiplication
      '\u00D7': '×', '\u2715': '×', '\u2716': '×',
      '\u22C5': '·', '\u2022': '·',
      // Division
      '\u00F7': '÷', '\u2215': '/',
      // Equals / comparison
      '\uFF1D': '=', '\u2260': '≠',
      '\u2264': '≤', '\u2265': '≥',
      '\u2248': '≈', '\u2245': '≅',
      // Superscript digits
      '\u00B2': '²', '\u00B3': '³',
      '\u2070': '⁰', '\u00B9': '¹', '\u2074': '⁴',
      '\u2075': '⁵', '\u2076': '⁶', '\u2077': '⁷',
      '\u2078': '⁸', '\u2079': '⁹', '\u207F': 'ⁿ',
      '\u207A': '⁺', '\u207B': '⁻',
      // Subscript digits
      '\u2080': '₀', '\u2081': '₁', '\u2082': '₂',
      '\u2083': '₃', '\u2084': '₄', '\u2085': '₅',
      '\u2086': '₆', '\u2087': '₇', '\u2088': '₈',
      '\u2089': '₉',
      // Roots & calculus
      '\u221A': '√', '\u221B': '∛', '\u221C': '∜',
      '\u222B': '∫', '\u222C': '∬', '\u222D': '∭',
      '\u2202': '∂', '\u221E': '∞',
      '\u2211': 'Σ', '\u220F': 'Π',
      // Greek
      '\u03B1': 'α', '\u03B2': 'β', '\u03B3': 'γ', '\u03B4': 'δ',
      '\u03B5': 'ε', '\u03B8': 'θ', '\u03BB': 'λ', '\u03BC': 'μ',
      '\u03C0': 'π', '\u03C3': 'σ', '\u03C6': 'φ', '\u03C9': 'ω',
      '\u0394': 'Δ', '\u03A3': 'Σ', '\u03A9': 'Ω',
      // Misc math
      '\u00B1': '±', '\u00B0': '°', '\u2220': '∠',
      // Parentheses variants
      '\uFF08': '(', '\uFF09': ')', '\uFF3B': '[', '\uFF3D': ']',
      '\uFF5B': '{', '\uFF5D': '}',
      // Pipes
      '\uFF5C': '|',
    };

    for (final entry in replacements.entries) {
      cleaned = cleaned.replaceAll(entry.key, entry.value);
    }

    // Collapse multiple spaces per line, preserve newlines
    cleaned = cleaned
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'  +'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .join('\n');

    return cleaned;
  }

  void dispose() {
    _textRecognizer?.close();
  }
}

/// Internal helper to track block positions for reading-order sorting.
class _MathBlock {
  final String text;
  final double top;
  final double left;
  _MathBlock({required this.text, required this.top, required this.left});
}
