import 'dart:io';
import 'dart:typed_data';
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

      return _cleanMathText(recognizedText.text);
    } catch (e) {
      return '';
    }
  }

  Future<String> recognizeTextFromFile(File file) async {
    return recognizeText(file.path);
  }

  /// Preprocess image: grayscale + contrast enhancement + sharpen
  Future<String?> _preprocessImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      var image = img.decodeImage(Uint8List.fromList(bytes));
      if (image == null) return null;

      // Convert to grayscale
      image = img.grayscale(image);

      // Adjust contrast (+50%)
      image = img.adjustColor(image, contrast: 1.5);

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

  String _cleanMathText(String raw) {
    String cleaned = raw.trim();

    // --- 1. Unicode math symbol normalization ---
    final replacements = <String, String>{
      // Minus / dash variants
      '\u2212': '-', '\u2014': '-', '\u2013': '-', '\uFE63': '-', '\uFF0D': '-',
      // Multiplication variants
      '\u00D7': '×', '\u2715': '×', '\u2716': '×', '\u22C5': '×',
      // Division variants
      '\u00F7': '÷', '\u2215': '/',
      // Equals / comparison
      '\uFF1D': '=', '\u2260': '≠', '\u2264': '≤', '\u2265': '≥',
      // Plus variants
      '\uFF0B': '+',
      // Superscript digits → Unicode superscripts
      '\u00B2': '²', '\u00B3': '³',
      // Common Unicode math
      '\u221A': '√', '\u03C0': 'π', '\u222B': '∫',
      // Parentheses variants
      '\uFF08': '(', '\uFF09': ')', '\u27E8': '(', '\u27E9': ')',
      '\uFF3B': '[', '\uFF3D': ']', '\uFF5B': '{', '\uFF5D': '}',
    };

    for (final entry in replacements.entries) {
      cleaned = cleaned.replaceAll(entry.key, entry.value);
    }

    // --- 2. Common OCR misreads for math ---
    // 'X' → 'x' for variables (but not at start of sentence followed by space+lowercase)
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<=[0-9+\-*/=(\s])X(?=[0-9+\-*/=²³^)\s]|$)'),
      (m) => 'x',
    );
    // Standalone capital X that looks like a variable
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'^X(?=[²³^0-9+\-*/=\s])'),
      (m) => 'x',
    );

    // OCR often reads '²' as '2' after a variable: "x2" → "x²" in math context
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([a-zA-Z)\]])2(?=\s*[+\-*/=)\s]|$)'),
      (m) => '${m.group(1)}²',
    );
    // "x3" → "x³" in math context
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([a-zA-Z)\]])3(?=\s*[+\-*/=)\s]|$)'),
      (m) => '${m.group(1)}³',
    );
    // General exponent: "x^2" stays, but "x 2" near operators → "x²"
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([a-zA-Z])\s+2(?=\s*[+\-*/=)\s]|$)'),
      (m) => '${m.group(1)}²',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([a-zA-Z])\s+3(?=\s*[+\-*/=)\s]|$)'),
      (m) => '${m.group(1)}³',
    );

    // OCR may read integral sign '∫' as 'f' or 'S' at start
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'^[fS]\s*(?=[a-zA-Z0-9(].*d[a-zA-Z])'),
      (m) => '∫',
    );

    // OCR may read square root '√' as 'V' or 'v' before numbers/parens
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<![a-zA-Z])[Vv](?=\s*[\d(])'),
      (m) => '√',
    );

    // Fix common "d / dx" or "d/ dx" → "d/dx"
    cleaned = cleaned.replaceAll(RegExp(r'd\s*/\s*d\s*x'), 'd/dx');

    // Fix "dx" at end of expression (integral notation) — keep it
    // Fix spaces around operators for cleaner parsing
    cleaned = cleaned.replaceAll(RegExp(r'\s*([+\-*/=])\s*'), ' ${' '}');
    // Actually, preserve operators with proper spacing
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\s*([+\-×÷=])\s*'),
      (m) => ' ${m.group(1)} ',
    );

    // Collapse multiple spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Fix common letter/digit confusions
    // 'l' or 'I' (letter i) read as '1' or vice versa near variables
    // 'O' or 'o' read as '0' in numeric context
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<=\d)[Oo](?=\d)'),
      (m) => '0',
    );

    return cleaned;
  }

  void dispose() {
    _textRecognizer?.close();
  }
}
