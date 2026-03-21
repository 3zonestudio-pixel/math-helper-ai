import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/math_problem.dart';
import '../theme.dart';

class ProblemCard extends StatelessWidget {
  final MathProblem problem;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onDelete;

  const ProblemCard({
    super.key,
    required this.problem,
    required this.onTap,
    required this.onFavoriteToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(8),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        problem.category.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(problem.createdAt, l10n),
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.textLight.withAlpha(100)
                            : Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  problem.problem,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.textDark,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  problem.solution,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppTheme.textLight.withAlpha(150)
                        : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPurple.withAlpha(18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.nSteps(problem.steps.length),
                        style: TextStyle(
                          color: AppTheme.accentPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (onDelete != null)
                      _buildIconBtn(
                        Icons.delete_outline_rounded,
                        AppTheme.errorRed,
                        onDelete!,
                      ),
                    const SizedBox(width: 4),
                    _buildIconBtn(
                      problem.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      problem.isFavorite
                          ? AppTheme.errorRed
                          : (isDark
                              ? AppTheme.textLight.withAlpha(100)
                              : Colors.grey[400]!),
                      onFavoriteToggle,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inHours < 1) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l10n.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
    return '${date.day}/${date.month}/${date.year}';
  }
}
