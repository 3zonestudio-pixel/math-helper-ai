import 'package:flutter/material.dart';
import '../models/math_problem.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';

class MathProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final AiService _aiService = AiService();

  List<MathProblem> _history = [];
  List<MathProblem> _favorites = [];
  bool _isLoading = false;
  String? _error;
  MathProblem? _currentProblem;

  List<MathProblem> get history => _history;
  List<MathProblem> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get error => _error;
  MathProblem? get currentProblem => _currentProblem;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  MathProvider() {
    _init();
  }

  Future<void> _init() async {
    await loadHistory();
    await loadFavorites();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> loadHistory() async {
    try {
      _history = await _dbService.getHistory();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadFavorites() async {
    try {
      _favorites = await _dbService.getFavorites();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<MathProblem?> solveProblem({
    required String problem,
    required String language,
    required String difficulty,
    required String explanationMode,
    String category = 'general',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _aiService.solveProblem(
        problem: problem,
        language: language,
        difficulty: difficulty,
        explanationMode: explanationMode,
        category: category,
      );

      _currentProblem = result;
      _isLoading = false;
      notifyListeners();

      // Prepend to local list immediately — no DB roundtrip needed
      _history.insert(0, result);
      notifyListeners();

      // Save to DB — await to prevent data loss
      try {
        await _dbService.insertProblem(result);
      } catch (e) {
        print('DB: Failed to insert problem: $e');
      }
      return result;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> toggleFavorite(MathProblem problem) async {
    problem.isFavorite = !problem.isFavorite;
    // Update local lists immediately
    if (problem.isFavorite) {
      _favorites.insert(0, problem);
    } else {
      _favorites.removeWhere((p) => p.id == problem.id);
    }
    notifyListeners();
    try {
      await _dbService.toggleFavorite(problem.id, problem.isFavorite);
    } catch (e) {
      print('DB: Failed to toggle favorite: $e');
    }
  }

  Future<void> deleteProblem(String id) async {
    _history.removeWhere((p) => p.id == id);
    _favorites.removeWhere((p) => p.id == id);
    notifyListeners();
    try {
      await _dbService.deleteProblem(id);
    } catch (e) {
      print('DB: Failed to delete problem: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      await _dbService.clearHistory();
    } catch (e) {
      print('DB: Failed to clear history: $e');
    }
    _history = [];
    _favorites = [];
    notifyListeners();
  }

  /// Solve multiple problems in sequence. Returns list of solved problems.
  Future<List<MathProblem>> solveMultipleProblems({
    required List<String> problems,
    required String language,
    required String difficulty,
    required String explanationMode,
    String category = 'general',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final groupId = DateTime.now().millisecondsSinceEpoch.toString();
    final results = <MathProblem>[];
    try {
      for (final problem in problems) {
        final trimmed = problem.trim();
        if (trimmed.isEmpty) continue;
        try {
          final result = await _aiService.solveProblem(
            problem: trimmed,
            language: language,
            difficulty: difficulty,
            explanationMode: explanationMode,
            category: category,
          );
          // Re-create with groupId
          final grouped = MathProblem(
            id: result.id,
            problem: result.problem,
            solution: result.solution,
            steps: result.steps,
            category: result.category,
            difficulty: result.difficulty,
            language: result.language,
            createdAt: result.createdAt,
            isFavorite: result.isFavorite,
            groupId: groupId,
          );
          results.add(grouped);
          // Add to history immediately
          _history.insert(0, grouped);
          try {
            await _dbService.insertProblem(grouped);
          } catch (e) {
            print('DB: Failed to insert grouped problem: $e');
          }
        } catch (e) {
          print('Solve: Failed to solve problem "$trimmed": $e');
        }
        // Notify after each solve so UI can update progress
        notifyListeners();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return results;
  }

  Future<List<MathProblem>> searchProblems(String query) async {
    try {
      return await _dbService.searchProblems(query);
    } catch (_) {
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
