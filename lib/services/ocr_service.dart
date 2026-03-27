import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show compute;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

class OcrService {
  TextRecognizer? _textRecognizer;
  TextRecognizer? _chineseRecognizer;
  TextRecognizer? _devanagariRecognizer;
  TextRecognizer? _japaneseRecognizer;
  TextRecognizer? _koreanRecognizer;

  TextRecognizer get textRecognizer {
    _textRecognizer ??= TextRecognizer();
    return _textRecognizer!;
  }

  /// Get all recognizers for multi-script OCR
  List<TextRecognizer> get _allRecognizers {
    final recognizers = <TextRecognizer>[];
    recognizers.add(textRecognizer); // Latin (en, fr, es, de, pt, tr, it, ru)
    try {
      _chineseRecognizer ??= TextRecognizer(script: TextRecognitionScript.chinese);
      if (_chineseRecognizer != null) recognizers.add(_chineseRecognizer!);
    } catch (e) {
      print('OCR: Chinese recognizer unavailable: $e');
    }
    try {
      _devanagariRecognizer ??= TextRecognizer(script: TextRecognitionScript.devanagiri);
      if (_devanagariRecognizer != null) recognizers.add(_devanagariRecognizer!);
    } catch (e) {
      print('OCR: Devanagari recognizer unavailable: $e');
    }
    try {
      _japaneseRecognizer ??= TextRecognizer(script: TextRecognitionScript.japanese);
      if (_japaneseRecognizer != null) recognizers.add(_japaneseRecognizer!);
    } catch (e) {
      print('OCR: Japanese recognizer unavailable: $e');
    }
    try {
      _koreanRecognizer ??= TextRecognizer(script: TextRecognitionScript.korean);
      if (_koreanRecognizer != null) recognizers.add(_koreanRecognizer!);
    } catch (e) {
      print('OCR: Korean recognizer unavailable: $e');
    }
    return recognizers;
  }

  Future<String> recognizeText(String imagePath) async {
    try {
      // Validate file exists and size is reasonable (max 20MB)
      final file = File(imagePath);
      if (!file.existsSync()) return '';
      final fileSize = await file.length();
      if (fileSize > 20 * 1024 * 1024) return '';

      // === MULTI-SCRIPT + MULTI-PASS OCR ===
      final results = <String>[];

      // Try all script recognizers on original image
      InputImage? inputImage;
      try {
        inputImage = InputImage.fromFilePath(imagePath);
      } catch (e) {
        print('OCR: Failed to create InputImage: $e');
        return '';
      }
      for (final recognizer in _allRecognizers) {
        try {
          final recognized = await recognizer.processImage(inputImage);
          if (recognized.text.isNotEmpty) {
            results.add(_extractWithStructure(recognized));
          }
        } catch (e) {
          print('OCR: Recognizer failed: $e');
        }
      }

      // Pass 2: Enhanced (grayscale + sharpen + contrast) — Latin only
      final enhancedPath = await _preprocessImage(imagePath, binarize: false);
      if (enhancedPath != null) {
        final enhancedResult = await _recognizeSingle(enhancedPath);
        if (enhancedResult.isNotEmpty) results.add(enhancedResult);
        try { File(enhancedPath).deleteSync(); } catch (e) { print('OCR: Delete enhanced failed: $e'); }
      }

      // Pass 3: Binarized (for low-contrast / faded math) — Latin only
      final binarizedPath = await _preprocessImage(imagePath, binarize: true);
      if (binarizedPath != null) {
        final binarizedResult = await _recognizeSingle(binarizedPath);
        if (binarizedResult.isNotEmpty) results.add(binarizedResult);
        try { File(binarizedPath).deleteSync(); } catch (e) { print('OCR: Delete binarized failed: $e'); }
      }

      if (results.isEmpty) return '';

      // Pick the result with the highest math score
      String best = results.first;
      int bestScore = _mathScore(best);
      for (int i = 1; i < results.length; i++) {
        final score = _mathScore(results[i]);
        if (score > bestScore) {
          bestScore = score;
          best = results[i];
        }
      }

      return _cleanMathText(best);
    } catch (e, st) {
      print('OCR: Unexpected error: $e\n$st');
      return '';
    }
  }

  /// Run OCR on a single image path, returning structural text
  Future<String> _recognizeSingle(String path) async {
    try {
      final inputImage = InputImage.fromFilePath(path);
      final recognizedText = await textRecognizer.processImage(inputImage);
      if (recognizedText.text.isEmpty) return '';
      return _extractWithStructure(recognizedText);
    } catch (_) {
      return '';
    }
  }

  /// Score how "math-like" text is (higher = more math symbols/patterns)
  int _mathScore(String text) {
    if (text.isEmpty) return 0;
    int score = 0;
    const mathChars = '0123456789+-×÷*/=()[]{}xyzπ∫√∂∞²³⁴⁵⁶⁷⁸⁹≤≥≠≈αβγδθσΣΔΩ°±';
    for (final ch in text.split('')) {
      if (mathChars.contains(ch)) score += 2;
    }
    // Bonus for known math patterns
    if (RegExp(r'[a-zA-Z]\s*[²³⁴⁵⁶⁷⁸⁹^]').hasMatch(text)) score += 10;
    if (RegExp(r'\d\s*[+\-×÷*/]\s*\d').hasMatch(text)) score += 5;
    if (text.contains('=')) score += 5;
    if (RegExp(r'(?:sin|cos|tan|log|ln|lim|∫|√|d/d)', caseSensitive: false).hasMatch(text)) score += 15;
    // Bonus for fraction patterns: a/b
    if (RegExp(r'\d+\s*/\s*\d+').hasMatch(text)) score += 8;
    // Bonus for equation pattern: expression = expression
    if (RegExp(r'.+\s*=\s*.+').hasMatch(text)) score += 10;
    // Bonus for parenthesized expressions
    final parenCount = RegExp(r'[()]').allMatches(text).length;
    score += parenCount * 2;
    // Bonus for variable-operator-variable pattern
    if (RegExp(r'[a-zA-Z]\s*[+\-×÷*/^]\s*[a-zA-Z0-9]').hasMatch(text)) score += 8;
    // Penalize excessive non-math text (long English sentences)
    final wordCount = RegExp(r'[a-zA-Z]{4,}').allMatches(text).length;
    score -= wordCount * 3;
    return score;
  }

  Future<String> recognizeTextFromFile(File file) async {
    return recognizeText(file.path);
  }

  /// Preprocess image: grayscale + contrast + sharpen + optional binarize
  /// Runs heavy image processing in a background isolate to avoid UI jank.
  Future<String?> _preprocessImage(String imagePath, {bool binarize = false}) async {
    try {
      return await compute(
        preprocessImageIsolate,
        PreprocessParams(imagePath, binarize),
      );
    } catch (e) {
      print('OCR: Preprocess failed: $e');
      return null;
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
        // Compute median top for subscript detection
        final tops = line.elements.map((e) => e.boundingBox.top).toList()..sort();
        final medianTop = tops[tops.length ~/ 2];
        // Average element height for thresholding
        final avgHeight = line.elements.map((e) => e.boundingBox.height).reduce((a, b) => a + b) / line.elements.length;

        for (int i = 0; i < line.elements.length; i++) {
          final el = line.elements[i];
          final elBottom = el.boundingBox.bottom;
          final elTop = el.boundingBox.top;
          final elHeight = el.boundingBox.height;
          final text = el.text;

          // Superscript detection: element's bottom is clearly above the median bottom
          // and the element is notably smaller than average
          final isSmaller = elHeight < avgHeight * 0.65;
          final isSuperscript = i > 0 &&
              isSmaller &&
              (medianBottom - elBottom) > avgHeight * 0.30;

          // Subscript detection: element's top is clearly below the median top
          // and the element is notably smaller
          final isSubscript = i > 0 &&
              isSmaller &&
              (elTop - medianTop) > avgHeight * 0.30 &&
              !isSuperscript;

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
      'n': 'ⁿ', 'x': 'ˣ', 'y': 'ʸ', 'a': 'ᵃ', 'b': 'ᵇ',
      'c': 'ᶜ', 'd': 'ᵈ', 'e': 'ᵉ', 'f': 'ᶠ', 'g': 'ᵍ',
      'h': 'ʰ', 'i': 'ⁱ', 'j': 'ʲ', 'k': 'ᵏ', 'l': 'ˡ',
      'm': 'ᵐ', 'o': 'ᵒ', 'p': 'ᵖ', 'r': 'ʳ', 's': 'ˢ',
      't': 'ᵗ', 'u': 'ᵘ', 'v': 'ᵛ', 'w': 'ʷ',
      '+': '⁺', '-': '⁻', '(': '⁽', ')': '⁾',
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
    //    (normalize variant Unicode chars to standard forms)
    // ═══════════════════════════════════════════════════
    final replacements = <String, String>{
      // --- Minus / dash variants ---
      '\u2212': '-', '\u2014': '-', '\u2013': '-',
      '\uFE63': '-', '\uFF0D': '-',
      // --- Plus variants ---
      '\uFF0B': '+',
      // --- Multiplication variants → × ---
      '\u00D7': '×', '\u2715': '×', '\u2716': '×',
      '\u22C5': '·', '\u2022': '·',
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
      // --- Greek letters ---
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
      '\u221D': '∝', '\u2234': '∴', '\u2235': '∵',
      '\u00B0': '°', '\u2220': '∠', '\u22A5': '⊥',
      '\u2225': '∥', '\u2261': '≡',
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
    // 2. MINIMAL SPACING NORMALIZATION
    // ═══════════════════════════════════════════════════
    // Collapse multiple spaces/newlines, trim
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  void dispose() {
    _textRecognizer?.close();
    _chineseRecognizer?.close();
    _devanagariRecognizer?.close();
    _japaneseRecognizer?.close();
    _koreanRecognizer?.close();
  }
}

/// Parameters for isolate-based image preprocessing
class PreprocessParams {
  final String imagePath;
  final bool binarize;
  PreprocessParams(this.imagePath, this.binarize);
}

/// Top-level function for compute() isolate — must be public for isolate access
Future<String?> preprocessImageIsolate(PreprocessParams params) async {
  try {
    final file = File(params.imagePath);
    final bytes = await file.readAsBytes();
    var image = img.decodeImage(Uint8List.fromList(bytes));
    if (image == null) return null;

    if (image.width > 3000 || image.height > 3000) {
      final scale = 3000 / math.max(image.width, image.height);
      image = img.copyResize(image,
          width: (image.width * scale).round(),
          height: (image.height * scale).round(),
          interpolation: img.Interpolation.linear);
    }

    image = img.grayscale(image);
    image = img.convolution(image, filter: [0, -1, 0, -1, 5, -1, 0, -1, 0]);
    image = img.adjustColor(image, contrast: params.binarize ? 1.8 : 1.3);
    image = img.normalize(image, min: 0, max: 255);

    if (params.binarize) {
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final lum = img.getLuminance(pixel);
          if (lum > 128) {
            image.setPixelRgb(x, y, 255, 255, 255);
          } else {
            image.setPixelRgb(x, y, 0, 0, 0);
          }
        }
      }
    }

    final dir = file.parent.path;
    final suffix = params.binarize ? 'binarized' : 'enhanced';
    final outPath = '$dir/ocr_$suffix.png';
    final outFile = File(outPath);
    await outFile.writeAsBytes(img.encodePng(image));
    return outPath;
  } catch (e) {
    print('OCR isolate: Preprocess failed: $e');
    return null;
  }
}
