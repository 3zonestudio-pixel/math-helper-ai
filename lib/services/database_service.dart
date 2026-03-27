import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/math_problem.dart';

class DatabaseService {
  static const String _boxName = 'problems';
  static bool _initialized = false;
  static Completer<void>? _initCompleter;

  static Future<void> init() async {
    if (_initialized) return;
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    _initCompleter = Completer<void>();
    try {
      await Hive.initFlutter();
      await Hive.openBox<Map>(_boxName);
      _initialized = true;
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
      rethrow;
    }
  }

  Box<Map> get _box => Hive.box<Map>(_boxName);

  Future<void> insertProblem(MathProblem problem) async {
    final map = problem.toMap();
    map['steps'] = problem.stepsToString();
    await _box.put(problem.id, map);
  }

  Future<List<MathProblem>> getHistory() async {
    final items = _box.values.toList();
    final problems = <MathProblem>[];
    for (final m in items) {
      try {
        final map = Map<String, dynamic>.from(m);
        problems.add(MathProblem.fromMap(map));
      } catch (_) {
        // Skip corrupted entries
      }
    }
    problems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return problems;
  }

  Future<List<MathProblem>> getHistoryPaginated(int offset, int limit) async {
    final all = await getHistory();
    if (offset >= all.length) return [];
    return all.skip(offset).take(limit).toList();
  }

  Future<int> getHistoryCount() async {
    return _box.length;
  }

  Future<List<MathProblem>> getFavorites() async {
    final all = await getHistory();
    return all.where((p) => p.isFavorite).toList();
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final raw = _box.get(id);
    if (raw != null) {
      final map = Map<String, dynamic>.from(raw);
      map['isFavorite'] = isFavorite ? 1 : 0;
      await _box.put(id, map);
    }
  }

  Future<void> deleteProblem(String id) async {
    await _box.delete(id);
  }

  Future<void> clearHistory() async {
    await _box.clear();
  }

  Future<List<MathProblem>> searchProblems(String query) async {
    final all = await getHistory();
    final q = query.toLowerCase();
    return all.where((p) =>
        p.problem.toLowerCase().contains(q) ||
        p.solution.toLowerCase().contains(q)).toList();
  }
}
