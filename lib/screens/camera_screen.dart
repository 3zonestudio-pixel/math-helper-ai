import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/ocr_service.dart';
import '../services/ai_service.dart';
import '../constants.dart';
import '../providers/app_provider.dart';
import '../providers/math_provider.dart';
import '../theme.dart';
import 'text_input_screen.dart';
import 'solution_screen.dart';
import 'multi_solution_screen.dart';

/// Painter that draws rounded scan-style corner brackets
class _ScanCornerPainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double cornerRadius;
  final double strokeWidth;

  _ScanCornerPainter({
    required this.color,
    this.cornerLength = 32,
    this.cornerRadius = 14,
    this.strokeWidth = 3.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final cl = cornerLength;
    final r = cornerRadius;

    // Top-left corner
    final topLeft = Path()
      ..moveTo(0, cl)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(cl, 0);
    canvas.drawPath(topLeft, paint);

    // Top-right corner
    final topRight = Path()
      ..moveTo(w - cl, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, cl);
    canvas.drawPath(topRight, paint);

    // Bottom-left corner
    final bottomLeft = Path()
      ..moveTo(0, h - cl)
      ..lineTo(0, h - r)
      ..quadraticBezierTo(0, h, r, h)
      ..lineTo(cl, h);
    canvas.drawPath(bottomLeft, paint);

    // Bottom-right corner
    final bottomRight = Path()
      ..moveTo(w - cl, h)
      ..lineTo(w - r, h)
      ..quadraticBezierTo(w, h, w, h - r)
      ..lineTo(w, h - cl);
    canvas.drawPath(bottomRight, paint);
  }

  @override
  bool shouldRepaint(covariant _ScanCornerPainter old) =>
      color != old.color ||
      cornerLength != old.cornerLength ||
      cornerRadius != old.cornerRadius ||
      strokeWidth != old.strokeWidth;
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final OcrService _ocrService = OcrService();
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  bool _isSolving = false;
  String _processingStatus = '';
  String? _recognizedText;
  String? _errorMessage;
  String _explainLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _explainLanguage = _detectDeviceLanguage();
  }

  static String _detectDeviceLanguage() {
    try {
      final locales = WidgetsBinding.instance.platformDispatcher.locales;
      if (locales.isEmpty) return 'en';
      for (final locale in locales) {
        final code = locale.languageCode.toLowerCase();
        if (AppConstants.supportedLanguages.containsKey(code)) {
          return code;
        }
      }
      return 'en';
    } catch (_) {
      return 'en';
    }
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanProblem),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scan area with corner brackets
              Expanded(
                flex: 2,
                child: Stack(
                  children: [
                    // Background card
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withAlpha(10)
                              : Colors.black.withAlpha(8),
                        ),
                      ),
                      child: _isProcessing
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppTheme.accentPurple),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    _processingStatus.isNotEmpty
                                        ? _processingStatus
                                        : l10n.processingImage,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isDark
                                          ? AppTheme.textLight
                                          : AppTheme.textDark,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _recognizedText != null
                              ? _buildRecognizedResult(l10n, isDark)
                              : _buildScanPlaceholder(l10n, isDark),
                    ),
                    // Scan-style rounded corner overlay
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: CustomPaint(
                            painter: _ScanCornerPainter(
                              color: AppTheme.accentPurple.withAlpha(180),
                              cornerLength: 36,
                              cornerRadius: 18,
                              strokeWidth: 3.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withAlpha(15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.errorRed.withAlpha(40)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppTheme.errorRed, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: AppTheme.errorRed, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              if (_recognizedText == null || _recognizedText!.isEmpty) ...[
                // Camera/Gallery buttons — only before scan
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.camera_alt_rounded,
                        label: l10n.camera,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFF8B5CF6)],
                        ),
                        onTap: () => _captureImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.photo_library_rounded,
                        label: l10n.gallery,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00B4D8), Color(0xFF0096C7)],
                        ),
                        onTap: () => _captureImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
              ],

              if (_recognizedText != null && _recognizedText!.isNotEmpty) ...[
                const SizedBox(height: 14),
                _buildLanguageSelector(l10n, isDark),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Direct Solve button
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: _isSolving ? null : AppTheme.primaryGradient,
                          color: _isSolving
                              ? (isDark ? AppTheme.surfaceDark : Colors.grey[300])
                              : null,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: _isSolving
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppTheme.accentPurple.withAlpha(50),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isSolving ? null : () => _directSolve(context),
                            borderRadius: BorderRadius.circular(22),
                            child: Center(
                              child: _isSolving
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.auto_awesome,
                                            size: 20, color: Colors.white),
                                        const SizedBox(width: 10),
                                        Text(
                                          l10n.solve,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Edit button
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: AppTheme.accentPurple.withAlpha(80),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isSolving ? null : () => _editRecognizedText(context),
                            borderRadius: BorderRadius.circular(22),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_rounded,
                                      size: 18, color: AppTheme.accentPurple),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.edit,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.accentPurple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanPlaceholder(AppLocalizations l10n, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.accentPurple.withAlpha(18),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(
            Icons.document_scanner_rounded,
            size: 40,
            color: AppTheme.accentPurple.withAlpha(180),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          l10n.scanInstruction,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppTheme.textLight.withAlpha(180)
                : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.supportedFormats,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppTheme.textLight.withAlpha(100)
                : Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildRecognizedResult(AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.text_fields_rounded,
                    color: AppTheme.accentGreen, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.recognizedText,
                style: const TextStyle(
                  color: AppTheme.accentGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                _recognizedText!,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.6,
                  color: isDark ? Colors.white : AppTheme.textDark,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isProcessing ? null : onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 74,
          decoration: BoxDecoration(
            gradient: _isProcessing ? null : gradient,
            color: _isProcessing ? Colors.grey.withAlpha(50) : null,
            borderRadius: BorderRadius.circular(22),
            boxShadow: _isProcessing
                ? null
                : [
                    BoxShadow(
                      color: gradient.colors.first.withAlpha(40),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(height: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _captureImage(ImageSource source) async {
    if (kIsWeb) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)?.ocrNotAvailable ??
            'OCR is not available on web. Please use the Android app.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingStatus = '';
      _errorMessage = null;
      _recognizedText = null;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 2560,
        maxHeight: 2560,
        imageQuality: 95,
      );

      if (image == null) {
        setState(() => _isProcessing = false);
        return;
      }

      // Phase 1: ML Kit text extraction
      if (mounted) {
        setState(() => _processingStatus = 'Scanning text...');
      }
      final rawText = await _ocrService.recognizeText(image.path);

      if (!mounted) return;

      if (rawText.isEmpty) {
        setState(() {
          _isProcessing = false;
          _processingStatus = '';
          _errorMessage = AppLocalizations.of(context)?.noTextRecognized ??
              'No text recognized. Please try again.';
        });
        return;
      }

      // Phase 2: AI-powered math reconstruction
      setState(() => _processingStatus = 'Interpreting math...');
      final aiReconstructed = await AiService.reconstructMathFromOcr(rawText);

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _processingStatus = '';
        // Use AI-reconstructed text if available, otherwise fall back to raw OCR
        _recognizedText = aiReconstructed ?? rawText;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _processingStatus = '';
        _errorMessage = AppLocalizations.of(context)?.noTextRecognized ??
            'Failed to recognize text. Please try again.';
      });
    }
  }

  /// Split input text into individual math problems (same logic as TextInputScreen).
  static List<String> _splitProblems(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.length <= 1) return [text.trim()];
    final numberedPattern = RegExp(r'^(?:Q?\.?\s*#?\s*\d+[.):\-]\s*|\(?\d+[).]\s*)', caseSensitive: false);
    final hasNumbering = lines.where((l) => numberedPattern.hasMatch(l)).length >= 2;
    if (hasNumbering) {
      final problems = <String>[];
      String current = '';
      for (final line in lines) {
        if (numberedPattern.hasMatch(line)) {
          if (current.isNotEmpty) problems.add(current.trim());
          current = line.replaceFirst(numberedPattern, '').trim();
        } else {
          current += ' $line';
        }
      }
      if (current.isNotEmpty) problems.add(current.trim());
      if (problems.length >= 2) return problems;
    }
    final mathLinePattern = RegExp(r'[\d+\-×÷*/=^√∫xyzπ()\[\]]');
    final mathLines = lines.where((l) => mathLinePattern.hasMatch(l)).toList();
    if (mathLines.length >= 2 && mathLines.length == lines.length) {
      return mathLines;
    }
    return [text.trim()];
  }

  Future<void> _directSolve(BuildContext context) async {
    if (_recognizedText == null || _recognizedText!.isEmpty) return;

    setState(() => _isSolving = true);

    final appProvider = context.read<AppProvider>();
    final mathProvider = context.read<MathProvider>();
    final solveLanguage = _explainLanguage;
    final problems = _splitProblems(_recognizedText!);

    if (problems.length >= 2) {
      final results = await mathProvider.solveMultipleProblems(
        problems: problems,
        language: solveLanguage,
        difficulty: appProvider.difficulty,
        explanationMode: appProvider.explanationMode,
      );
      if (!mounted) return;
      setState(() => _isSolving = false);
      if (results.isNotEmpty) {
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MultiSolutionScreen(problems: results)),
        );
      } else {
        _showSolveError(context, mathProvider);
      }
    } else {
      final result = await mathProvider.solveProblem(
        problem: _recognizedText!,
        language: solveLanguage,
        difficulty: appProvider.difficulty,
        explanationMode: appProvider.explanationMode,
      );
      if (!mounted) return;
      setState(() => _isSolving = false);
      if (result != null) {
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SolutionScreen(problem: result)),
        );
      } else {
        _showSolveError(context, mathProvider);
      }
    }
  }

  Widget _buildLanguageSelector(AppLocalizations l10n, bool isDark) {
    final languages = AppConstants.supportedLanguages;
    return Row(
      children: [
        Icon(
          Icons.translate,
          size: 18,
          color: isDark ? AppTheme.accentCyan : AppTheme.accentPurple,
        ),
        const SizedBox(width: 8),
        Text(
          l10n.explainIn,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? AppTheme.textLight : AppTheme.textDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: languages.entries.map((entry) {
                final isSelected = _explainLanguage == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    selectedColor: AppTheme.accentPurple,
                    backgroundColor: isDark ? AppTheme.cardDark : Colors.grey[100],
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppTheme.textLight : AppTheme.textDark),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 12,
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.accentPurple
                          : (isDark ? Colors.white.withAlpha(13) : Colors.black.withAlpha(10)),
                    ),
                    onSelected: (_) {
                      setState(() => _explainLanguage = entry.key);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _showSolveError(BuildContext context, MathProvider mathProvider) {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final msg = mathProvider.error ?? l10n.error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _editRecognizedText(BuildContext context) {
    if (_recognizedText == null || _recognizedText!.isEmpty) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TextInputScreen(initialProblem: _recognizedText),
      ),
    );
  }
}
