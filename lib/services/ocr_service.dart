import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

class OcrService {
  TextRecognizer? _textRecognizer;

  TextRecognizer get textRecognizer {
    _textRecognizer ??= TextRecognizer();
    return _textRecognizer!;
  }

  Future<String> recognizeText(String imagePath) async {
    try {
      // Preprocess image for better OCR accuracy
      final preprocessedPath = await _preprocessImage(imagePath);
      final pathToUse = preprocessedPath ?? imagePath;

      final inputImage = InputImage.fromFilePath(pathToUse);
      final recognizedText = await textRecognizer.processImage(inputImage);

      // Clean up temp file
      if (preprocessedPath != null && preprocessedPath != imagePath) {
        try { File(preprocessedPath).deleteSync(); } catch (_) {}
      }

      if (recognizedText.text.isEmpty) {
        return '';
      }

      // Use structural analysis for superscript/subscript detection
      final structuralText = _extractWithStructure(recognizedText);

      return _cleanMathText(structuralText);
    } catch (e) {
      return '';
    }
  }

  Future<String> recognizeTextFromFile(File file) async {
    return recognizeText(file.path);
  }

  /// Preprocess image: grayscale + contrast + sharpen + binarize
  Future<String?> _preprocessImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      var image = img.decodeImage(Uint8List.fromList(bytes));
      if (image == null) return null;

      // Convert to grayscale
      image = img.grayscale(image);

      // Sharpen to make math symbols crisper
      image = img.convolution(image, filter: [
        0, -1, 0,
        -1, 5, -1,
        0, -1, 0,
      ]);

      // Adjust contrast (+60%) for clearer symbol edges
      image = img.adjustColor(image, contrast: 1.6);

      // Normalize brightness
      image = img.normalize(image, min: 0, max: 255);

      // Save preprocessed image to temp path
      final dir = file.parent.path;
      final outPath = '$dir/ocr_preprocessed.png';
      final outFile = File(outPath);
      await outFile.writeAsBytes(img.encodePng(image));
      return outPath;
    } catch (_) {
      return null; // Fall back to original image
    }
  }

  /// Use ML Kit's structural data (blocks → lines → elements) to detect
  /// superscripts/subscripts by comparing vertical positions of elements.
  String _extractWithStructure(RecognizedText recognizedText) {
    final buffer = StringBuffer();

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        if (line.elements.length <= 1) {
          buffer.write(line.text);
          buffer.write(' ');
          continue;
        }

        // Compute baseline: the median bottom-Y of all elements in the line
        final bottoms = line.elements.map((e) => e.boundingBox.bottom).toList()..sort();
        final medianBottom = bottoms[bottoms.length ~/ 2];
        // Average element height for thresholding
        final avgHeight = line.elements.map((e) => e.boundingBox.height).reduce((a, b) => a + b) / line.elements.length;

        for (int i = 0; i < line.elements.length; i++) {
          final el = line.elements[i];
          final elBottom = el.boundingBox.bottom;
          final elHeight = el.boundingBox.height;
          final text = el.text;

          // Superscript detection: element is significantly above the baseline
          // and smaller than average height
          final isSuperscript = (medianBottom - elBottom) > avgHeight * 0.25 &&
              elHeight < avgHeight * 0.75 &&
              i > 0;

          // Subscript detection: element is below the baseline
          final isSubscript = (elBottom - medianBottom) > avgHeight * 0.25 &&
              elHeight < avgHeight * 0.75 &&
              i > 0;

          if (isSuperscript) {
            // Convert to superscript notation
            final sup = _toSuperscript(text);
            if (sup != null) {
              buffer.write(sup);
            } else {
              buffer.write('^$text');
            }
          } else if (isSubscript) {
            final sub = _toSubscript(text);
            if (sub != null) {
              buffer.write(sub);
            } else {
              buffer.write('_$text');
            }
          } else {
            if (i > 0) buffer.write(' ');
            buffer.write(text);
          }
        }
        buffer.write(' ');
      }
      buffer.write('\n');
    }

    return buffer.toString().trim();
  }

  /// Convert text to Unicode superscript if possible
  String? _toSuperscript(String text) {
    const superscripts = {
      '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴',
      '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹',
      'n': 'ⁿ', 'x': 'ˣ', '+': '⁺', '-': '⁻',
    };
    final buf = StringBuffer();
    for (final ch in text.split('')) {
      final sup = superscripts[ch];
      if (sup == null) return null; // Can't convert this char
      buf.write(sup);
    }
    return buf.toString();
  }

  /// Convert text to Unicode subscript if possible
  String? _toSubscript(String text) {
    const subscripts = {
      '0': '₀', '1': '₁', '2': '₂', '3': '₃', '4': '₄',
      '5': '₅', '6': '₆', '7': '₇', '8': '₈', '9': '₉',
      'n': 'ₙ', 'x': 'ₓ', '+': '₊', '-': '₋',
    };
    final buf = StringBuffer();
    for (final ch in text.split('')) {
      final sub = subscripts[ch];
      if (sub == null) return null;
      buf.write(sub);
    }
    return buf.toString();
  }

  String _cleanMathText(String raw) {
    String cleaned = raw.trim();

    // ═══════════════════════════════════════════════════
    // 1. UNICODE MATH SYMBOL NORMALIZATION
    // ═══════════════════════════════════════════════════
    final replacements = <String, String>{
      // --- Minus / dash variants ---
      '\u2212': '-', '\u2014': '-', '\u2013': '-',
      '\uFE63': '-', '\uFF0D': '-',
      // --- Plus variants ---
      '\uFF0B': '+',
      // --- Multiplication variants → × ---
      '\u00D7': '×', '\u2715': '×', '\u2716': '×',
      '\u22C5': '·', '\u2022': '·',         // dot product
      // --- Division variants ---
      '\u00F7': '÷', '\u2215': '/',
      // --- Equals / comparison ---
      '\uFF1D': '=', '\u2260': '≠',
      '\u2264': '≤', '\u2265': '≥',
      '\u226A': '≪', '\u226B': '≫',
      '\u2248': '≈', '\u2245': '≅',
      // --- Superscript digits ---
      '\u00B2': '²', '\u00B3': '³',
      '\u2070': '⁰', '\u00B9': '¹', '\u2074': '⁴',
      '\u2075': '⁵', '\u2076': '⁶', '\u2077': '⁷',
      '\u2078': '⁸', '\u2079': '⁹', '\u207F': 'ⁿ',
      '\u207A': '⁺', '\u207B': '⁻',
      // --- Subscript digits ---
      '\u2080': '₀', '\u2081': '₁', '\u2082': '₂',
      '\u2083': '₃', '\u2084': '₄', '\u2085': '₅',
      '\u2086': '₆', '\u2087': '₇', '\u2088': '₈',
      '\u2089': '₉', '\u2090': 'ₐ', '\u2099': 'ₙ',
      '\u209C': 'ₜ', '\u2093': 'ₓ',
      // --- Roots ---
      '\u221A': '√', '\u221B': '∛', '\u221C': '∜',
      // --- Calculus / Analysis ---
      '\u222B': '∫', '\u222C': '∬', '\u222D': '∭', '\u222E': '∮',
      '\u2202': '∂', '\u221E': '∞',
      '\u2211': 'Σ', '\u220F': 'Π',
      // --- Greek letters (common in math) ---
      '\u03B1': 'α', '\u03B2': 'β', '\u03B3': 'γ', '\u03B4': 'δ',
      '\u03B5': 'ε', '\u03B6': 'ζ', '\u03B7': 'η', '\u03B8': 'θ',
      '\u03B9': 'ι', '\u03BA': 'κ', '\u03BB': 'λ', '\u03BC': 'μ',
      '\u03BD': 'ν', '\u03BE': 'ξ', '\u03BF': 'ο', '\u03C0': 'π',
      '\u03C1': 'ρ', '\u03C3': 'σ', '\u03C4': 'τ', '\u03C5': 'υ',
      '\u03C6': 'φ', '\u03C7': 'χ', '\u03C8': 'ψ', '\u03C9': 'ω',
      '\u0393': 'Γ', '\u0394': 'Δ', '\u0398': 'Θ', '\u039B': 'Λ',
      '\u039E': 'Ξ', '\u03A0': 'Π', '\u03A3': 'Σ', '\u03A6': 'Φ',
      '\u03A8': 'Ψ', '\u03A9': 'Ω',
      // --- Set theory / Logic ---
      '\u2208': '∈', '\u2209': '∉',
      '\u2282': '⊂', '\u2283': '⊃', '\u2286': '⊆', '\u2287': '⊇',
      '\u222A': '∪', '\u2229': '∩', '\u2205': '∅',
      '\u2200': '∀', '\u2203': '∃',
      '\u2227': '∧', '\u2228': '∨', '\u00AC': '¬',
      '\u21D2': '⟹', '\u21D4': '⟺',
      '\u2192': '→', '\u2190': '←', '\u2194': '↔',
      // --- Miscellaneous math ---
      '\u00B1': '±', '\u2213': '∓',
      '\u221D': '∝',      // proportional
      '\u2234': '∴',      // therefore
      '\u2235': '∵',      // because
      '\u00B0': '°',      // degree
      '\u2220': '∠',      // angle
      '\u22A5': '⊥',      // perpendicular
      '\u2225': '∥',      // parallel
      '\u2261': '≡',      // identical/congruent
      // --- Parentheses variants ---
      '\uFF08': '(', '\uFF09': ')', '\u27E8': '(', '\u27E9': ')',
      '\uFF3B': '[', '\uFF3D': ']', '\uFF5B': '{', '\uFF5D': '}',
      '\u2308': '⌈', '\u2309': '⌉', '\u230A': '⌊', '\u230B': '⌋',
      // --- Pipes for absolute value ---
      '\uFF5C': '|', '\u2016': '‖',
    };

    for (final entry in replacements.entries) {
      cleaned = cleaned.replaceAll(entry.key, entry.value);
    }

    // ═══════════════════════════════════════════════════
    // 2. MULTI-CHARACTER PATTERN NORMALIZATION
    //    (text sequences OCR produces for special symbols)
    // ═══════════════════════════════════════════════════

    // "+-" or "+/-" → ±
    cleaned = cleaned.replaceAll(RegExp(r'\+\s*/?\s*-'), '±');

    // "<=" or "=<" → ≤ ; ">=" or "=>" → ≥
    cleaned = cleaned.replaceAll('<=', '≤');
    cleaned = cleaned.replaceAll('=<', '≤');
    cleaned = cleaned.replaceAll('>=', '≥');
    cleaned = cleaned.replaceAll('=>', '≥');

    // "!=" or "/=" → ≠
    cleaned = cleaned.replaceAll('!=', '≠');
    cleaned = cleaned.replaceAll(RegExp(r'(?<!\d)/='), '≠');

    // "~=" or "~~" → ≈
    cleaned = cleaned.replaceAll('~=', '≈');
    cleaned = cleaned.replaceAll('~~', '≈');

    // "oo" or "co" in math context → ∞
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<=[→=<>≤≥,(\s])\s*(?:oo|co)\s*(?=[)\s,]|$)'),
      (m) => '∞',
    );
    // "-oo" → "-∞"
    cleaned = cleaned.replaceAll(RegExp(r'-\s*oo\b'), '-∞');

    // "pi" as standalone word → π
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\bpi\b', caseSensitive: false),
      (m) => 'π',
    );

    // "theta" → θ
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\btheta\b', caseSensitive: false), (m) => 'θ',
    );
    // "alpha" → α
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\balpha\b', caseSensitive: false), (m) => 'α',
    );
    // "beta" → β
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\bbeta\b', caseSensitive: false), (m) => 'β',
    );
    // "gamma" → γ
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\bgamma\b', caseSensitive: false), (m) => 'γ',
    );
    // "delta" → Δ (usually uppercase in math)
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\bdelta\b', caseSensitive: false), (m) => 'Δ',
    );
    // "sigma" → σ (or Σ for summation, handled by context)
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\bsigma\b', caseSensitive: false), (m) => 'σ',
    );
    // "omega" → ω
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\bomega\b', caseSensitive: false), (m) => 'ω',
    );
    // "lambda" → λ
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\blambda\b', caseSensitive: false), (m) => 'λ',
    );
    // "phi" → φ
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\bphi\b', caseSensitive: false), (m) => 'φ',
    );

    // "sqrt" → √
    cleaned = cleaned.replaceAll(RegExp(r'\bsqrt\b', caseSensitive: false), '√');

    // "infinity" or "inf" → ∞
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\b(?:infinity|inf)\b', caseSensitive: false), (m) => '∞',
    );

    // ═══════════════════════════════════════════════════
    // 3. OCR MISREAD CORRECTIONS
    // ═══════════════════════════════════════════════════

    // --- Variable X vs multiplication × ---
    // 'X' between digits or near operators → 'x' (variable)
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<=[0-9+\-*/=(\s])X(?=[0-9+\-*/=²³⁴⁵⁶⁷⁸⁹ⁿ^)\s]|$)'),
      (m) => 'x',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'^X(?=[²³⁴⁵⁶⁷⁸⁹ⁿ^0-9+\-*/=\s])'),
      (m) => 'x',
    );

    // --- Exponent misreads: variable followed by digit → superscript ---
    // x2 → x², x3 → x³, x4 → x⁴, etc. (in math context)
    final exponentMap = {'2': '²', '3': '³', '4': '⁴', '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹'};
    for (final entry in exponentMap.entries) {
      // "x2" where 2 is likely an exponent (followed by operator or end)
      cleaned = cleaned.replaceAllMapped(
        RegExp('([a-zA-Z)\\]])${entry.key}(?=\\s*[+\\-×÷*/=)\\s]|\$)'),
        (m) => '${m.group(1)}${entry.value}',
      );
      // "x 2" with space (OCR artifact)
      cleaned = cleaned.replaceAllMapped(
        RegExp('([a-zA-Z])\\s+${entry.key}(?=\\s*[+\\-×÷*/=)\\s]|\$)'),
        (m) => '${m.group(1)}${entry.value}',
      );
    }

    // --- Integral sign misreads ---
    // 'f', 'S', 'J' at start of expression followed by integrand and "dx"/"dy"/etc.
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'^[fSJj]\s*(?=[a-zA-Z0-9(].*d[a-zA-Z])'),
      (m) => '∫',
    );
    // Mid-expression: " f " or " S " before integrand with dx
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<=[\s=+\-])[fSJ]\s+(?=[a-zA-Z0-9(].*d[a-zA-Z])'),
      (m) => '∫',
    );

    // --- Square root misreads ---
    // 'V' or 'v' before number/parens (not part of a word) → √
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<![a-zA-Z])[Vv](?=\s*[\d(])'),
      (m) => '√',
    );
    // "V-" at start → √ (radical with a bar)
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'^[Vv][-—]\s*(?=[\d(a-zA-Z])'),
      (m) => '√',
    );

    // --- Pi misreads ---
    // "TT" or "II" or "n" in numeric context → π
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<=[\d*/×÷(=\s])(?:TT|II)(?=[\d*/×÷)=\s]|$)'),
      (m) => 'π',
    );

    // --- Infinity misreads ---
    // Standalone "8" that is clearly infinity (after lim, →, or comparison)
    // but this is risky — skip unless in clear context
    // "oc" or "0c" or "oO" → ∞ in math context
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<=[→=<>≤≥,(\s])(?:0c|oc|oO|0C|OC)(?=[)\s,]|$)'),
      (m) => '∞',
    );

    // --- Sigma / Summation misreads ---
    // Capital 'E' at start with limits notation → Σ
    // This is too risky as a blanket rule, only in clear summation context
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<=^|\s)E(?=\s*[\[({]?\s*[a-zA-Z]\s*=)'),
      (m) => 'Σ',
    );

    // --- Delta misreads ---
    // 'A' before a variable in differential context → Δ
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<=^|\s)A(?=[a-zA-Z]\s*=)'),
      (m) => 'Δ',
    );

    // --- Degree misreads ---
    // 'o' or '0' after a number when it looks like degrees → °
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(\d)\s*[oO](?=\s*[+\-×÷*/=,)\s]|$)'),
      (m) => '${m.group(1)}°',
    );

    // --- Angle misreads ---
    // '<' before a letter (angle notation) → ∠ if followed by three capital letters
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'<(?=[A-Z]{2,3}\b)'),
      (m) => '∠',
    );

    // --- Theta misreads in trig ---
    // "0" after sin/cos/tan → θ
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'((?:sin|cos|tan|cot|sec|csc)\s*\(?\s*)0(?=\s*\)?\s*[+\-×÷*/=\s]|$)', caseSensitive: false),
      (m) => '${m.group(1)}θ',
    );

    // ═══════════════════════════════════════════════════
    // 4. DERIVATIVE / CALCULUS NOTATION FIXES
    // ═══════════════════════════════════════════════════

    // "d / dx" or "d/ dx" or "d /dx" → "d/dx"
    cleaned = cleaned.replaceAll(RegExp(r'd\s*/\s*d\s*x'), 'd/dx');
    cleaned = cleaned.replaceAll(RegExp(r'd\s*/\s*d\s*y'), 'd/dy');
    cleaned = cleaned.replaceAll(RegExp(r'd\s*/\s*d\s*t'), 'd/dt');

    // "dy / dx" → "dy/dx"
    cleaned = cleaned.replaceAll(RegExp(r'd\s*y\s*/\s*d\s*x'), 'dy/dx');
    cleaned = cleaned.replaceAll(RegExp(r'd\s*x\s*/\s*d\s*t'), 'dx/dt');

    // Partial derivative: if "d" was misread — ∂ is likely already handled by Unicode
    // "df/dx" could be partial: keep as is, AI will interpret

    // "lim" formatting — preserve
    // "lim x->0" or "lim x→0" — normalize arrows
    cleaned = cleaned.replaceAll(RegExp(r'-\s*>'), '→');

    // f'(x) — prime notation: various quote chars → '
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([a-zA-Z])\s*[`´''ʼ]\s*(\()'),
      (m) => "${m.group(1)}'${m.group(2)}",
    );
    // f''(x) — double prime
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([a-zA-Z])\s*[`´''ʼ]{2}\s*(\()'),
      (m) => "${m.group(1)}''${m.group(2)}",
    );

    // ═══════════════════════════════════════════════════
    // 5. TRIG / LOG FUNCTION NAME FIXES
    // ═══════════════════════════════════════════════════

    // Common OCR misreads of function names
    final funcFixes = {
      'S1n': 'sin', 's1n': 'sin', 'SIN': 'sin', 'Sin': 'sin',
      'C0S': 'cos', 'c0s': 'cos', 'COS': 'cos', 'Cos': 'cos',
      'TAN': 'tan', 'Tan': 'tan',
      'COT': 'cot', 'Cot': 'cot',
      'SEC': 'sec', 'Sec': 'sec',
      'CSC': 'csc', 'Csc': 'csc',
      'LOG': 'log', 'Log': 'log', 'l0g': 'log', 'L0G': 'log', 'L0g': 'log',
      'LN': 'ln', 'Ln': 'ln',
      'LIM': 'lim', 'Lim': 'lim', 'L1M': 'lim', 'l1m': 'lim',
      'ABS': 'abs', 'Abs': 'abs',
    };
    for (final entry in funcFixes.entries) {
      cleaned = cleaned.replaceAll(
        RegExp('\\b${RegExp.escape(entry.key)}\\b'),
        entry.value,
      );
    }

    // arcsin, arccos, arctan — OCR sometimes splits or misreads
    cleaned = cleaned.replaceAll(RegExp(r'\barc\s*sin\b', caseSensitive: false), 'arcsin');
    cleaned = cleaned.replaceAll(RegExp(r'\barc\s*cos\b', caseSensitive: false), 'arccos');
    cleaned = cleaned.replaceAll(RegExp(r'\barc\s*tan\b', caseSensitive: false), 'arctan');

    // ═══════════════════════════════════════════════════
    // 6. SPACING NORMALIZATION
    // ═══════════════════════════════════════════════════

    // Proper spacing around binary operators
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\s*([+\-×÷=≠≤≥≈<>])\s*'),
      (m) => ' ${m.group(1)} ',
    );

    // No space between function name and parenthesis: "sin (" → "sin("
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\b(sin|cos|tan|cot|sec|csc|arcsin|arccos|arctan|log|ln|lim|abs|sqrt)\s+\(', caseSensitive: false),
      (m) => '${m.group(1)}(',
    );

    // Collapse multiple spaces, trim
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // ═══════════════════════════════════════════════════
    // 7. DIGIT/LETTER CONFUSION CLEANUP
    // ═══════════════════════════════════════════════════

    // 'O' or 'o' between digits → 0
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<=\d)[Oo](?=\d)'),
      (m) => '0',
    );
    // 'l' or 'I' between digits → 1
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<=\d)[lI](?=\d)'),
      (m) => '1',
    );

    return cleaned;
  }

  void dispose() {
    _textRecognizer?.close();
  }
}
