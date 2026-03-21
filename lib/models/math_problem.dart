import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class MathProblem {
  final String id;
  final String problem;
  final String solution;
  final List<SolutionStep> steps;
  final String category;
  final String difficulty;
  final String language;
  final DateTime createdAt;
  bool isFavorite;

  MathProblem({
    String? id,
    required this.problem,
    required this.solution,
    required this.steps,
    this.category = 'general',
    this.difficulty = 'intermediate',
    this.language = 'en',
    DateTime? createdAt,
    this.isFavorite = false,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'problem': problem,
      'solution': solution,
      'steps': stepsToString(),
      'category': category,
      'difficulty': difficulty,
      'language': language,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory MathProblem.fromMap(Map<String, dynamic> map) {
    List<SolutionStep> parsedSteps = [];
    if (map['steps'] != null) {
      try {
        final stepsStr = map['steps'] as String;
        final stepParts = stepsStr.split('|||');
        for (int i = 0; i < stepParts.length; i++) {
          final parts = stepParts[i].split('::');
          if (parts.length >= 2) {
            parsedSteps.add(SolutionStep(
              stepNumber: i + 1,
              title: parts[0].trim(),
              description: parts[1].trim(),
            ));
          }
        }
      } catch (_) {
        parsedSteps = [];
      }
    }

    return MathProblem(
      id: map['id'] as String,
      problem: map['problem'] as String,
      solution: map['solution'] as String,
      steps: parsedSteps,
      category: map['category'] as String? ?? 'general',
      difficulty: map['difficulty'] as String? ?? 'intermediate',
      language: map['language'] as String? ?? 'en',
      createdAt: DateTime.parse(map['createdAt'] as String),
      isFavorite: (map['isFavorite'] as int?) == 1,
    );
  }

  String stepsToString() {
    return steps.map((s) => '${s.title}::${s.description}').join('|||');
  }
}

class SolutionStep {
  final int stepNumber;
  final String title;
  final String description;
  final String? tip;

  SolutionStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    this.tip,
  });

  Map<String, dynamic> toJson() {
    return {
      'stepNumber': stepNumber,
      'title': title,
      'description': description,
      'tip': tip,
    };
  }
}
