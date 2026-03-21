import 'package:flutter/material.dart';
import '../models/math_problem.dart';
import '../theme.dart';
import 'math_text.dart';

class StepCard extends StatelessWidget {
  final SolutionStep step;

  const StepCard({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final isTip = step.tip != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isTip
            ? AppTheme.accentGreen.withAlpha(12)
            : (isDark ? AppTheme.cardDark : Colors.white),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isTip
              ? AppTheme.accentGreen.withAlpha(40)
              : (isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(8)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: isTip
                        ? null
                        : AppTheme.primaryGradient,
                    color: isTip ? AppTheme.accentGreen : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: isTip
                        ? const Icon(Icons.lightbulb_rounded,
                            color: Colors.white, size: 18)
                        : Text(
                            '${step.stepNumber}',
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
                  child: Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isTip
                          ? AppTheme.accentGreen
                          : (isDark ? Colors.white : AppTheme.textDark),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: MathText(
                text: step.description,
                fontSize: 14,
                color: isDark
                    ? AppTheme.textLight.withAlpha(190)
                    : AppTheme.textDark.withAlpha(170),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
