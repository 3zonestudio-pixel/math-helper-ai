import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../models/math_problem.dart';
import '../widgets/step_card.dart';
import '../widgets/math_text.dart';
import '../theme.dart';

class MultiSolutionScreen extends StatefulWidget {
  final List<MathProblem> problems;

  const MultiSolutionScreen({super.key, required this.problems});

  @override
  State<MultiSolutionScreen> createState() => _MultiSolutionScreenState();
}

class _MultiSolutionScreenState extends State<MultiSolutionScreen> {
  // Track which problems are expanded to show steps
  late List<bool> _expanded;

  @override
  void initState() {
    super.initState();
    // If only 1 problem, expand it by default
    _expanded = List.generate(
      widget.problems.length,
      (i) => widget.problems.length == 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.solution} (${widget.problems.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            onPressed: () => _copyAll(context, l10n),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20),
            onPressed: () => _shareAll(l10n),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: widget.problems.length,
        itemBuilder: (context, index) {
          final problem = widget.problems[index];
          final isExpanded = _expanded[index];
          return _buildProblemCard(problem, index, isExpanded, isDark, l10n);
        },
      ),
    );
  }

  Widget _buildProblemCard(
    MathProblem problem,
    int index,
    bool isExpanded,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: problem number + problem text + answer
          InkWell(
            onTap: () {
              setState(() => _expanded[index] = !_expanded[index]);
            },
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
              bottom: Radius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Problem number badge + problem text
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MathText(
                          text: problem.problem,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.textDark,
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: isDark
                            ? AppTheme.textLight.withAlpha(120)
                            : Colors.grey[400],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Answer badge (always visible)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.accentGreen.withAlpha(40),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.accentGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: MathText(
                            text: problem.solution,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable steps section
          if (isExpanded) ...[
            Divider(
              height: 1,
              color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.steps,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...problem.steps.map((step) => StepCard(step: step)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _buildAllText(AppLocalizations l10n) {
    final buffer = StringBuffer();
    for (int i = 0; i < widget.problems.length; i++) {
      final p = widget.problems[i];
      buffer.writeln('${i + 1}) ${p.problem}');
      buffer.writeln('   ${l10n.solutionLabel}: ${p.solution}');
      for (final step in p.steps) {
        if (step.tip != null) {
          buffer.writeln('   💡 ${step.description}');
        } else {
          buffer.writeln('   ${step.stepNumber}. ${step.title}: ${step.description}');
        }
      }
      buffer.writeln();
    }
    buffer.writeln('— ${l10n.solvedByApp}');
    return buffer.toString();
  }

  void _copyAll(BuildContext context, AppLocalizations l10n) {
    Clipboard.setData(ClipboardData(text: _buildAllText(l10n)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.copiedToClipboard),
        backgroundColor: AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _shareAll(AppLocalizations l10n) {
    Share.share(_buildAllText(l10n));
  }
}
