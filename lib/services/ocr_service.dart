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

    final replacements = <String, String>{
      '\u2212': '-',  // − (minus sign)
      '\u2014': '-',  // — (em dash)
      '\u2013': '-',  // – (en dash)
      'X': 'x',       // uppercase X to lowercase for variables
    };

    for (final entry in replacements.entries) {
      cleaned = cleaned.replaceAll(entry.key, entry.value);
    }

    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    return cleaned;
  }

  void dispose() {
    _textRecognizer?.close();
  }
}
