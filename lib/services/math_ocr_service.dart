import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Simple OCR service: scan all text from image, return raw result.
/// All intelligence (correction, separation, understanding) is handled by AI.
class MathOcrService {
  TextRecognizer? _textRecognizer;

  TextRecognizer get _recognizer {
    _textRecognizer ??= TextRecognizer();
    return _textRecognizer!;
  }

  /// Scan image and return all recognized text, preserving line structure.
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
        print('OCR: Failed to create InputImage: $e');
        return '';
      }

      RecognizedText recognized;
      try {
        recognized = await _recognizer.processImage(inputImage);
        if (recognized.text.isEmpty) return '';
      } catch (e) {
        print('OCR: Recognition failed: $e');
        return '';
      }

      // Extract text block-by-block in reading order (top鈫抌ottom, left鈫抮ight)
      final blocks = recognized.blocks.toList()..sort((a, b) {
        final dy = (a.boundingBox.top - b.boundingBox.top).abs();
        if (dy < 20) return a.boundingBox.left.compareTo(b.boundingBox.left);
        return a.boundingBox.top.compareTo(b.boundingBox.top);
      });

      final lines = <String>[];
      for (final block in blocks) {
        for (final line in block.lines) {
          final text = line.text.trim();
          if (text.isNotEmpty) lines.add(text);
        }
        // Blank line between blocks to preserve structure
        if (block.lines.isNotEmpty) lines.add('');
      }

      // Clean up: collapse multiple blanks, trim
      final result = lines
          .join('\n')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();

      return result;
    } catch (e) {
      print('OCR: Unexpected error: $e');
      return '';
    }
  }

  void dispose() {
    _textRecognizer?.close();
  }
}
