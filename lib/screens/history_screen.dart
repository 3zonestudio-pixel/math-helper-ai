import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/math_provider.dart';
import '../models/math_problem.dart';
import '../widgets/problem_card.dart';
import '../theme.dart';
import 'solution_screen.dart';

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
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final problem = filtered[index];
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
                          onDelete: () async {
                            final confirm = await showDialog<bool>(
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
                            if (confirm == true) {
                              mathProvider.deleteProblem(problem.id);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
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
