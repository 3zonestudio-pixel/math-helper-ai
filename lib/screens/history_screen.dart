import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/math_provider.dart';
import '../models/math_problem.dart';
import '../widgets/problem_card.dart';
import '../theme.dart';
import 'solution_screen.dart';
import 'multi_solution_screen.dart';

class HistoryScreen extends StatefulWidget {
  final bool showFavoritesOnly;

  const HistoryScreen({super.key, this.showFavoritesOnly = false});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mathProvider = context.watch<MathProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = widget.showFavoritesOnly
        ? mathProvider.favorites
        : mathProvider.history;

    final filtered = _searchQuery.isEmpty
        ? items
        : items.where((p) =>
            p.problem.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.solution.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    // Group problems by groupId — ungrouped items stay individual
    final displayItems = _buildDisplayItems(filtered);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.showFavoritesOnly ? l10n.favorites : l10n.history),
        actions: [
          if (!widget.showFavoritesOnly && items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () => _showClearDialog(context, l10n, mathProvider),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: l10n.searchProblems,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
              ),
            ),

          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.showFavoritesOnly
                              ? Icons.favorite_border
                              : Icons.history,
                          size: 64,
                          color: isDark
                              ? AppTheme.textLight.withAlpha(77)
                              : Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.showFavoritesOnly
                              ? l10n.noFavorites
                              : l10n.noHistory,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark
                                ? AppTheme.textLight.withAlpha(128)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: displayItems.length,
                    itemBuilder: (context, index) {
                      final item = displayItems[index];
                      if (item is List<MathProblem>) {
                        // Grouped scan — show as expandable card
                        return _buildGroupCard(context, item, l10n, isDark, mathProvider);
                      }
                      final problem = item as MathProblem;
                      return Dismissible(
                        key: Key(problem.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withAlpha(51),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: AppTheme.errorRed),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(l10n.delete),
                              content: Text('Delete "${problem.problem}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(l10n.cancel),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(l10n.confirm,
                                      style: const TextStyle(color: AppTheme.errorRed)),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) => mathProvider.deleteProblem(problem.id),
                        child: ProblemCard(
                          problem: problem,
                          onTap: () => _viewSolution(context, problem),
                          onFavoriteToggle: () => mathProvider.toggleFavorite(problem),
                          onDelete: () => mathProvider.deleteProblem(problem.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Build display items: group problems with same groupId together, keep singles as-is.
  List<dynamic> _buildDisplayItems(List<MathProblem> problems) {
    final items = <dynamic>[];
    final seenGroups = <String>{};

    for (final p in problems) {
      if (p.groupId != null && p.groupId!.isNotEmpty) {
        if (seenGroups.contains(p.groupId)) continue;
        seenGroups.add(p.groupId!);
        final group = problems.where((q) => q.groupId == p.groupId).toList();
        items.add(group);
      } else {
        items.add(p);
      }
    }
    return items;
  }

  Widget _buildGroupCard(
    BuildContext context,
    List<MathProblem> group,
    AppLocalizations l10n,
    bool isDark,
    MathProvider mathProvider,
  ) {
    final first = group.first;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentPurple.withAlpha(40),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MultiSolutionScreen(problems: group),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '${group.length} ${l10n.steps.toLowerCase()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatGroupDate(first.createdAt, l10n),
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
                ...group.take(3).map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 6, color: AppTheme.accentPurple.withAlpha(150)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.problem,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppTheme.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                if (group.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '+${group.length - 3} more',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.accentPurple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatGroupDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inHours < 1) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l10n.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
    return '${date.day}/${date.month}/${date.year}';
  }

  void _viewSolution(BuildContext context, MathProblem problem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SolutionScreen(problem: problem),
      ),
    );
  }

  void _showClearDialog(
    BuildContext context,
    AppLocalizations l10n,
    MathProvider mathProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearHistory),
        content: Text(l10n.clearHistoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              mathProvider.clearHistory();
              Navigator.pop(context);
            },
            child: Text(l10n.confirm,
                style: const TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }
}
