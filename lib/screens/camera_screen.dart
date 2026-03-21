import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import '../services/ocr_service.dart';
import '../theme.dart';
import 'text_input_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final OcrService _ocrService = OcrService();
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  String? _recognizedText;
  String? _errorMessage;

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
              // Scan area
              Expanded(
                flex: 2,
                child: Container(
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
                                l10n.processingImage,
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

              // Camera/Gallery buttons
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

              if (_recognizedText != null && _recognizedText!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
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
                      onTap: () => _solveRecognizedText(context),
                      borderRadius: BorderRadius.circular(22),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_awesome,
                                size: 20, color: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              l10n.solveThis,
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
      _errorMessage = null;
      _recognizedText = null;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (image == null) {
        setState(() => _isProcessing = false);
        return;
      }

      final text = await _ocrService.recognizeText(image.path);

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        if (text.isEmpty) {
          _errorMessage = AppLocalizations.of(context)?.noTextRecognized ??
              'No text recognized. Please try again.';
        } else {
          _recognizedText = text;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = AppLocalizations.of(context)?.noTextRecognized ??
            'Failed to recognize text. Please try again.';
      });
    }
  }

  void _solveRecognizedText(BuildContext context) {
    if (_recognizedText == null || _recognizedText!.isEmpty) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TextInputScreen(initialProblem: _recognizedText),
      ),
    );
  }
}
