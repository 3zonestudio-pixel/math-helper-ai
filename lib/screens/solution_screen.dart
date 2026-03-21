import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../models/math_problem.dart';
import '../providers/math_provider.dart';
import '../widgets/step_card.dart';
import '../widgets/math_text.dart';
import '../theme.dart';

class SolutionScreen extends StatelessWidget {
  final MathProblem problem;

  const SolutionScreen({super.key, required this.problem});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mathProvider = context.watch<MathProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.solution),
        actions: [
          IconButton(
            icon: Icon(
              problem.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: problem.isFavorite ? AppTheme.errorRed : null,
            ),
            onPressed: () => mathProvider.toggleFavorite(problem),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Problem card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentPurple.withAlpha(22),
                    AppTheme.accentCyan.withAlpha(10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentPurple.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.functions_rounded,
                            color: AppTheme.accentPurple, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.problemLabel,
                        style: TextStyle(
                          color: AppTheme.accentPurple,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  MathText(
                    text: problem.problem,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.textDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Answer badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withAlpha(18),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.accentGreen.withAlpha(50)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: AppTheme.accentGreen, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.solution,
                          style: TextStyle(
                            color: AppTheme.accentGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        MathText(
                          text: problem.solution,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppTheme.textDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // Steps header
            Text(
              l10n.steps,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.textDark,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 14),

            // Steps
            ...problem.steps.map((step) => StepCard(step: step)),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionBtn(
                    icon: Icons.copy_rounded,
                    label: l10n.copy,
                    color: AppTheme.accentCyan,
                    isDark: isDark,
                    onTap: () => _copyToClipboard(context, l10n),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionBtn(
                    icon: Icons.share_rounded,
                    label: l10n.share,
                    color: AppTheme.accentPurple,
                    isDark: isDark,
                    onTap: () => _share(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withAlpha(18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(50)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, AppLocalizations l10n) {
    final text = _buildShareText(l10n);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.copiedToClipboard),
        backgroundColor: AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _share(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = _buildShareText(l10n);
    Share.share(text);
  }

  String _buildShareText(AppLocalizations l10n) {
    final buffer = StringBuffer();
    buffer.writeln('📐 ${problem.problem}');
    buffer.writeln();
    buffer.writeln('✅ ${l10n.solutionLabel}: ${problem.solution}');
    buffer.writeln();
    buffer.writeln('${l10n.steps}:');
    for (final step in problem.steps) {
      if (step.tip != null) {
        buffer.writeln('💡 Tip: ${step.description}');
      } else {
        buffer.writeln('${step.stepNumber}. ${step.title}');
        buffer.writeln('   ${step.description}');
      }
    }
    buffer.writeln();
    buffer.writeln('— ${l10n.solvedByApp}');
    return buffer.toString();
  }
}
