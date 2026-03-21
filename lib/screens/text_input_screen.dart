import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../constants.dart';
import '../providers/app_provider.dart';
import '../providers/math_provider.dart';
import '../theme.dart';
import 'solution_screen.dart';

class TextInputScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialProblem;

  const TextInputScreen({
    super.key,
    this.initialCategory,
    this.initialProblem,
  });

  @override
  State<TextInputScreen> createState() => _TextInputScreenState();
}

class _TextInputScreenState extends State<TextInputScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _selectedCategory = 'general';
  String _explainLanguage = 'en';
  bool _showInputError = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    if (widget.initialProblem != null) {
      _controller.text = widget.initialProblem!;
    }
    // Auto-detect explanation language from device locale
    _explainLanguage = _detectDeviceLanguage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialProblem == null) {
        _focusNode.requestFocus();
      }
    });
  }

  /// Detect the best matching supported language from the device's locale list.
  /// Walks through the user's preferred locales (primary, secondary, etc.)
  /// and returns the first match. Falls back to 'en' if none match.
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
      // No supported language found in device preferences
      return 'en';
    } catch (_) {
      return 'en';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appProvider = context.watch<AppProvider>();
    final mathProvider = context.watch<MathProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.typeProblem),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category chips
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryChip(l10n.general, 'general', isDark),
                  _buildCategoryChip(l10n.algebra, 'algebra', isDark),
                  _buildCategoryChip(l10n.calculus, 'calculus', isDark),
                  _buildCategoryChip(l10n.geometry, 'geometry', isDark),
                  _buildCategoryChip(l10n.statistics, 'statistics', isDark),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Input field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _showInputError
                        ? AppTheme.errorRed
                        : (isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(10)),
                    width: _showInputError ? 2 : 1,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.white : AppTheme.textDark,
                    height: 1.6,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.enterProblem,
                    hintStyle: TextStyle(
                      color: isDark
                          ? AppTheme.textLight.withAlpha(80)
                          : Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Quick examples
            _buildExamples(isDark),

            const SizedBox(height: 12),

            // Explanation language selector
            _buildLanguageSelector(l10n, isDark),

            const SizedBox(height: 12),

            // Solve button with gradient
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: mathProvider.isLoading
                    ? null
                    : AppTheme.primaryGradient,
                color: mathProvider.isLoading
                    ? (isDark ? AppTheme.surfaceDark : Colors.grey[300])
                    : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: mathProvider.isLoading
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
                  onTap: mathProvider.isLoading
                      ? null
                      : () => _solve(context, appProvider, mathProvider),
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: mathProvider.isLoading
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
                              const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
                              const SizedBox(width: 10),
                              Text(
                                l10n.solve,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value, bool isDark) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppTheme.accentPurple,
        backgroundColor: isDark ? AppTheme.cardDark : Colors.grey[100],
        labelStyle: TextStyle(
          color: isSelected
              ? Colors.white
              : (isDark ? AppTheme.textLight : AppTheme.textDark),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(
          color: isSelected
              ? AppTheme.accentPurple
              : (isDark ? Colors.white.withAlpha(13) : Colors.black.withAlpha(10)),
        ),
        onSelected: (selected) {
          if (selected) setState(() => _selectedCategory = value);
        },
      ),
    );
  }

  Widget _buildExamples(bool isDark) {
    final examples = [
      '2x + 5 = 15',
      'x\u00B2 + 5x + 6 = 0',
      '\u222B x\u00B2 dx',
      'd/dx(x\u00B3 + 2x)',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: examples.map((example) {
        return ActionChip(
          label: Text(
            example,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.accentCyan : AppTheme.accentPurple,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: isDark
              ? AppTheme.accentCyan.withAlpha(18)
              : AppTheme.accentPurple.withAlpha(18),
          side: BorderSide(
            color: isDark
                ? AppTheme.accentCyan.withAlpha(50)
                : AppTheme.accentPurple.withAlpha(50),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onPressed: () {
            _controller.text = example;
          },
        );
      }).toList(),
    );
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

  Future<void> _solve(
    BuildContext context,
    AppProvider appProvider,
    MathProvider mathProvider,
  ) async {
    final problem = _controller.text.trim();
    if (problem.isEmpty) {
      setState(() => _showInputError = true);
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showInputError = false);
      });
      return;
    }

    setState(() => _showInputError = false);
    HapticFeedback.lightImpact();

    // Unfocus keyboard in parallel with solve — don't wait for animation
    FocusScope.of(context).unfocus();

    final result = await mathProvider.solveProblem(
      problem: problem,
      language: _explainLanguage,
      difficulty: appProvider.difficulty,
      explanationMode: appProvider.explanationMode,
      category: _selectedCategory,
    );

    if (result != null && mounted) {
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SolutionScreen(problem: result),
        ),
      );
    } else if (result == null && mounted) {
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.error),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
