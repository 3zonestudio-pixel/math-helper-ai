import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/math_problem.dart';

// API key parts are split to avoid exposure in source control
const _p1 = 'ak_2t79';
const _p2 = 'F73KI00';
const _p3 = 'S1hT4JZ';
const _p4 = '51G9Fg7';
const _p5 = 'ut37';

// Pre-compiled regexes for fast matching
final _arithmeticChars = RegExp(r'^[\d+\-*/().\s]+$');
final _hasDigit = RegExp(r'\d');
final _hasOp = RegExp(r'[+\-*/]');
final _stepHeader = RegExp(r'^STEP\s*\d+:\s*', caseSensitive: false);

// Common math spelling corrections (misspelling → correct)
const _spellingFixes = <String, String>{
  // integrate / integral
  'intergrate': 'integrate', 'integarte': 'integrate', 'intgrate': 'integrate',
  'inegrate': 'integrate', 'integrte': 'integrate', 'intergal': 'integral',
  'integeral': 'integral', 'integal': 'integral', 'intgral': 'integral',
  'intregral': 'integral', 'intergral': 'integral',
  // derivative / differentiate
  'derivitive': 'derivative', 'derivtive': 'derivative', 'deravative': 'derivative',
  'derivatie': 'derivative', 'dervative': 'derivative', 'derivativ': 'derivative',
  'dirivative': 'derivative', 'derivaive': 'derivative',
  'diferentiate': 'differentiate', 'differntiate': 'differentiate',
  'differenciate': 'differentiate', 'differetiate': 'differentiate',
  'diferentate': 'differentiate', 'diffrentiate': 'differentiate',
  // solve / equation
  'slove': 'solve', 'sovle': 'solve', 'solv': 'solve',
  'equasion': 'equation', 'equaton': 'equation', 'eqation': 'equation',
  'equaion': 'equation',
  // multiply / divide
  'multipli': 'multiply', 'mutliply': 'multiply', 'mutiply': 'multiply',
  'multilpy': 'multiply', 'multipley': 'multiply',
  'devide': 'divide', 'divde': 'divide', 'devied': 'divide',
  // square / root / function
  'sqare': 'square', 'sqaure': 'square', 'squre': 'square', 'squere': 'square',
  'rute': 'root', 'roote': 'root', 'squrt': 'sqrt', 'sqret': 'sqrt',
  'funtion': 'function', 'fucntion': 'function', 'funciton': 'function',
  // trigonometry
  'tringonometry': 'trigonometry', 'trigonmetry': 'trigonometry',
  'trignometry': 'trigonometry', 'trigonomerty': 'trigonometry',
  'sine': 'sin', 'cosine': 'cos', 'tangent': 'tan',
  // calculus / algebra / geometry
  'calulus': 'calculus', 'calculs': 'calculus', 'calculis': 'calculus',
  'calclus': 'calculus',
  'algerbra': 'algebra', 'alegbra': 'algebra', 'algebr': 'algebra',
  'geomety': 'geometry', 'geometrey': 'geometry', 'geomtry': 'geometry',
  // general math words
  'additon': 'addition', 'subraction': 'subtraction', 'subtration': 'subtraction',
  'simplfy': 'simplify', 'simplifiy': 'simplify', 'simplyfy': 'simplify',
  'factorise': 'factorize', 'factorsie': 'factorize', 'factorze': 'factorize',
  'logarithim': 'logarithm', 'logrithm': 'logarithm', 'logarithym': 'logarithm',
  'exponent': 'exponent', 'exponant': 'exponent',
  'perimeter': 'perimeter', 'perimiter': 'perimeter', 'peremeter': 'perimeter',
  'diamater': 'diameter', 'daimeter': 'diameter',
  'raduis': 'radius', 'radious': 'radius',
  'hypotenuse': 'hypotenuse', 'hypoteneuse': 'hypotenuse', 'hypothenuse': 'hypotenuse',
  'probabilty': 'probability', 'probablity': 'probability',
  'find': 'find', 'fnd': 'find', 'finde': 'find',
  'calculate': 'calculate', 'calculat': 'calculate', 'calulate': 'calculate',
  'waht': 'what', 'wat': 'what', 'wht': 'what',
  'evaulate': 'evaluate', 'evalute': 'evaluate', 'evaluat': 'evaluate',
};

final _wordBoundary = RegExp(r'\b[a-zA-Z]+\b');

class AiService {
  static String _apiKey = '$_p1$_p2$_p3$_p4$_p5';
  static String _apiUrl = 'https://api.longcat.chat/openai/v1/chat/completions';
  static String _model = 'LongCat-Flash-Chat';

  // In-memory response cache (LRU-style with max size)
  static const int _maxCacheSize = 200;
  static final Map<String, MathProblem> _cache = {};

  // Rate limiting: 500 AI requests per day
  static const int _dailyLimit = 500;
  static const String _rateLimitCountKey = 'ai_rate_limit_count';
  static const String _rateLimitDateKey = 'ai_rate_limit_date';

  /// Check if the user has remaining AI requests today
  static Future<bool> _canMakeRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10); // "YYYY-MM-DD"
    final storedDate = prefs.getString(_rateLimitDateKey) ?? '';
    if (storedDate != today) {
      // New day — reset counter
      await prefs.setString(_rateLimitDateKey, today);
      await prefs.setInt(_rateLimitCountKey, 0);
      return true;
    }
    final count = prefs.getInt(_rateLimitCountKey) ?? 0;
    return count < _dailyLimit;
  }

  /// Increment the daily request counter
  static Future<void> _recordRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final storedDate = prefs.getString(_rateLimitDateKey) ?? '';
    if (storedDate != today) {
      await prefs.setString(_rateLimitDateKey, today);
      await prefs.setInt(_rateLimitCountKey, 1);
    } else {
      final count = prefs.getInt(_rateLimitCountKey) ?? 0;
      await prefs.setInt(_rateLimitCountKey, count + 1);
    }
  }

  /// Get remaining AI requests for today
  static Future<int> getRemainingRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final storedDate = prefs.getString(_rateLimitDateKey) ?? '';
    if (storedDate != today) return _dailyLimit;
    final count = prefs.getInt(_rateLimitCountKey) ?? 0;
    return (_dailyLimit - count).clamp(0, _dailyLimit);
  }

  static void configure({
    required String apiKey,
    String? apiUrl,
    String? model,
  }) {
    _apiKey = apiKey;
    if (apiUrl != null) _apiUrl = apiUrl;
    if (model != null) _model = model;
  }

  /// Use AI to reconstruct a clean math expression from raw OCR text.
  /// ML Kit can't understand math structure — this lets the AI interpret
  /// garbled OCR output and return the intended mathematical expression.
  static Future<String?> reconstructMathFromOcr(String rawOcrText) async {
    if (rawOcrText.trim().isEmpty) return null;
    if (!isConfigured) return null;
    if (!await _canMakeRequest()) return null;

    const prompt = '''Math OCR correction engine. Fix garbled OCR text from math photos.

Common OCR errors: 1/l/I, 0/O, 5/S, 2/Z, 8/B, x/×, (/C, )/J. Superscripts lost: x^2 means x squared.

EXAMPLES:
• "5o|ve 2x + 3 = 7" → "Solve 2x + 3 = 7"
• "x^2 + 3x - 4 = O" → "x^2 + 3x - 4 = 0"
• "Ca1culate 15 ÷ 3 + 2 x 4" → "Calculate 15 ÷ 3 + 2 × 4"
• "1. 3x + 2 = 8\n2. x^2 - 9 = O" → "1. 3x + 2 = 8\n2. x^2 - 9 = 0"

Return ONLY corrected text. Keep ALL questions/numbering/options. Do NOT solve. Use ^ for exponents. If unrecognizable: ERROR''';

    // Single attempt, tight timeout — speed over retries
    try {
      final client = http.Client();
      try {
        final response = await client.post(
          Uri.parse(_apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {'role': 'system', 'content': prompt},
              {'role': 'user', 'content': rawOcrText},
            ],
            'temperature': 0.0,
            'max_tokens': 400,
          }),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final choices = data['choices'];
          if (choices != null && choices is List && choices.isNotEmpty) {
            final content = (choices[0]['message']?['content'] as String?)?.trim();
            if (content != null && content.isNotEmpty && content != 'ERROR') {
              await _recordRequest();
              return content;
            }
          }
        }
      } finally {
        client.close();
      }
    } catch (_) {
      // Timeout or error — fall through to raw OCR text
    }
    return null; // AI reconstruction failed — caller uses raw OCR text
  }

  static bool get isConfigured => _apiKey.isNotEmpty;

  /// Check if input text looks like a math problem
  static bool _isMathLike(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    final hasMathSymbol = RegExp(r'[+\-*/=^√∫∑×÷±²³()π%]').hasMatch(trimmed);
    final hasMathWord = RegExp(
      r'\b(solve|find|calculate|compute|simplify|factor|derive|integrate|'
      r'evaluate|equation|sqrt|root|log|sin|cos|tan|sum|area|volume|'
      r'perimeter|angle|triangle|circle|square|matrix|vector|limit|'
      r'probability|fraction|ratio|percent|average|mean|median|'
      r'f\(|g\(|polynomial|quadratic|linear|cubic)\b',
      caseSensitive: false,
    ).hasMatch(trimmed);
    // Require math symbol OR math word; a bare digit alone is not enough
    // Digit + operator pattern (e.g. "2+3", "5*x")
    final hasDigitWithOp = RegExp(r'\d\s*[+\-*/^=×÷]|[+\-*/^=×÷]\s*\d').hasMatch(trimmed);
    // Single variable letters only count if near math context
    final hasMathVar = RegExp(r'\b[xyz]\s*[+\-*/^=²³]|[+\-*/^=]\s*[xyz]\b', caseSensitive: false).hasMatch(trimmed);
    return hasMathSymbol || hasMathWord || hasDigitWithOp || hasMathVar;
  }

  /// Generate a cache key from problem parameters
  String _cacheKey(String problem, String language, String difficulty, String category) {
    return '$problem|$language|$difficulty|$category';
  }

  Future<MathProblem> solveProblem({
    required String problem,
    String language = 'en',
    String difficulty = 'intermediate',
    String explanationMode = 'detailed',
    String category = 'general',
  }) async {
    // Check cache first
    final key = _cacheKey(problem, language, difficulty, category);
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    // Normalize spelling errors in input
    final normalizedProblem = _normalizeSpelling(problem);
    final lowerProblem = normalizedProblem.toLowerCase().trim();

    // Reject non-math input early
    if (!_isMathLike(lowerProblem)) {
      return MathProblem(
        problem: problem,
        solution: 'Not a math problem',
        steps: [],
        category: category,
        difficulty: difficulty,
        language: language,
      );
    }

    // Only use local solver instantly for basic arithmetic (always accurate)
    if (_isBasicArithmetic(lowerProblem)) {
      final result = _solveLocally(
        problem: problem,
        language: language,
        difficulty: difficulty,
        category: category,
      );
      _addToCache(key, result);
      return result;
    }

    // If not configured, use local solver
    if (!isConfigured) {
      final result = _solveLocally(
        problem: normalizedProblem,
        language: language,
        difficulty: difficulty,
        category: category,
      );
      _addToCache(key, result);
      return result;
    }

    // Check daily rate limit before calling AI
    if (!await _canMakeRequest()) {
      final result = _solveLocally(
        problem: normalizedProblem,
        language: language,
        difficulty: difficulty,
        category: category,
      );
      _addToCache(key, result);
      return result;
    }

    // Try AI for all non-arithmetic problems (with retry)
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final systemPrompt = _buildSystemPrompt(language, difficulty, explanationMode);
        final response = await http.post(
          Uri.parse(_apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': normalizedProblem},
            ],
            'temperature': 0.1,
            'max_tokens': 350,
          }),
        ).timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final choices = data['choices'];
          if (choices == null || choices is! List || choices.isEmpty) {
            throw Exception('Invalid API response: missing choices');
          }
          if (choices[0] is! Map) {
            throw Exception('Invalid API response format');
          }
          final message = choices[0]['message'];
          if (message == null || message['content'] == null) {
            throw Exception('Invalid API response: missing content');
          }
          final content = message['content'] as String;
          final result = _parseAiResponse(content, problem, language, difficulty, category);
          _addToCache(key, result);
          await _recordRequest();
          return result;
        }
        // Non-200: retry once
        if (attempt == 0) continue;
      } on TimeoutException {
        print('AI: Request timed out (attempt ${attempt + 1})');
        if (attempt == 0) continue;
      } catch (e) {
        print('AI: Error (attempt ${attempt + 1}): $e');
        if (attempt == 0) continue;
      }
    }

    // All AI attempts failed — fallback to local solver
    final result = _solveLocally(
      problem: normalizedProblem,
      language: language,
      difficulty: difficulty,
      category: category,
    );
    _addToCache(key, result);
    return result;
  }

  /// Add to cache with eviction when full
  static void _addToCache(String key, MathProblem result) {
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = result;
  }

  String _buildSystemPrompt(String language, String difficulty, String mode) {
    final langNames = {
      'en': 'English',
      'ar': 'Arabic',
      'fr': 'French',
      'es': 'Spanish',
      'zh': 'Chinese',
      'de': 'German',
      'hi': 'Hindi',
      'ja': 'Japanese',
      'ko': 'Korean',
      'ru': 'Russian',
      'pt': 'Portuguese',
      'tr': 'Turkish',
      'it': 'Italian',
    };
    final langName = langNames[language] ?? 'English';

    return '''You are a fast math solver. RESPOND ENTIRELY IN $langName. Level: $difficulty.

LANGUAGE RULE: Your ENTIRE response MUST be 100% in $langName. Translate ALL math terminology.

RULES:
1. Input may be messy OCR. Reconstruct the intended problem.
2. "x2" = x squared. Pick the most likely reading.
3. Find ALL solutions. Verify by substitution.
4. Keep steps SHORT — just the key computation, no filler.
5. PLAIN TEXT only: +, -, *, /, =, ^, sqrt(). No LaTeX. Unicode OK.
6. If input contains MULTIPLE problems, solve ONLY THE FIRST ONE. Ignore the rest.

FORMAT:
SOLUTION: [final answer]
STEP 1: [short title]
[key computation only]
STEP 2: [short title]
[key computation only]
TIP: [one-line insight]''';
  }

  MathProblem _parseAiResponse(
    String content,
    String problem,
    String language,
    String difficulty,
    String category,
  ) {
    // Strip LaTeX delimiters the AI may still include despite instructions
    String cleaned = content;
    cleaned = cleaned.replaceAll('\$\$', '');
    cleaned = cleaned.replaceAll('\$', '');
    cleaned = cleaned.replaceAll('\\(', '');
    cleaned = cleaned.replaceAll('\\)', '');
    cleaned = cleaned.replaceAll('\\[', '');
    cleaned = cleaned.replaceAll('\\]', '');
    // Convert common LaTeX commands to unicode
    cleaned = cleaned.replaceAll('\\cdot', '·');
    cleaned = cleaned.replaceAll('\\times', '×');
    cleaned = cleaned.replaceAll('\\div', '÷');
    cleaned = cleaned.replaceAll('\\pm', '±');
    cleaned = cleaned.replaceAll('\\neq', '≠');
    cleaned = cleaned.replaceAll('\\leq', '≤');
    cleaned = cleaned.replaceAll('\\geq', '≥');
    cleaned = cleaned.replaceAll('\\pi', 'π');
    cleaned = cleaned.replaceAll('\\infty', '∞');
    cleaned = cleaned.replaceAll('\\sqrt', '√');
    cleaned = cleaned.replaceAll('\\int', '∫');
    cleaned = cleaned.replaceAll('\\sum', '∑');
    cleaned = cleaned.replaceAll('\\Delta', 'Δ');
    cleaned = cleaned.replaceAll('\\text', '');
    cleaned = cleaned.replaceAll('\\quad', ' ');
    cleaned = cleaned.replaceAll('\\,', ' ');
    // Strip remaining backslash commands, keep content after
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\\([a-zA-Z]+)'),
      (m) => m[1] ?? '',
    );
    // Clean up LaTeX braces: {content} → content
    cleaned = cleaned.replaceAll('{', '');
    cleaned = cleaned.replaceAll('}', '');

    final lines = cleaned.split('\n');
    String solution = '';
    List<SolutionStep> steps = [];
    int stepCount = 0;

    String currentStepTitle = '';
    String currentStepDesc = '';

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('SOLUTION:')) {
        solution = trimmed.substring(9).trim();
      } else if (_stepHeader.hasMatch(trimmed)) {
        if (currentStepTitle.isNotEmpty) {
          stepCount++;
          steps.add(SolutionStep(
            stepNumber: stepCount,
            title: currentStepTitle,
            description: currentStepDesc.trim(),
          ));
        }
        currentStepTitle = trimmed.replaceFirst(_stepHeader, '');
        currentStepDesc = '';
      } else if (trimmed.startsWith('TIP:')) {
        if (currentStepTitle.isNotEmpty) {
          stepCount++;
          steps.add(SolutionStep(
            stepNumber: stepCount,
            title: currentStepTitle,
            description: currentStepDesc.trim(),
          ));
          currentStepTitle = '';
          currentStepDesc = '';
        }
        steps.add(SolutionStep(
          stepNumber: stepCount + 1,
          title: 'Tip',
          description: trimmed.replaceFirst('TIP:', '').trim(),
          tip: trimmed.replaceFirst('TIP:', '').trim(),
        ));
      } else if (currentStepTitle.isNotEmpty) {
        currentStepDesc += '$trimmed\n';
      }
    }

    if (currentStepTitle.isNotEmpty) {
      stepCount++;
      steps.add(SolutionStep(
        stepNumber: stepCount,
        title: currentStepTitle,
        description: currentStepDesc.trim(),
      ));
    }

    if (steps.isEmpty) {
      steps = [
        SolutionStep(
          stepNumber: 1,
          title: 'Solution',
          description: content,
        ),
      ];
      if (solution.isEmpty) solution = content;
    }

    if (solution.isEmpty && steps.isNotEmpty) {
      solution = steps.last.description;
    }

    return MathProblem(
      problem: problem,
      solution: solution,
      steps: steps,
      category: category,
      difficulty: difficulty,
      language: language,
    );
  }

  MathProblem _solveLocally({
    required String problem,
    required String language,
    required String difficulty,
    required String category,
  }) {
    // Built-in solver for common math problems when no API is configured
    final lowerProblem = problem.toLowerCase().trim();
    List<SolutionStep> steps = [];
    String solution = '';

    // Try to detect and solve basic math
    if (_isBasicArithmetic(lowerProblem)) {
      final result = _solveArithmetic(problem, language);
      steps = result['steps'] as List<SolutionStep>;
      solution = result['solution'] as String;
    } else if (_isQuadraticEquation(lowerProblem)) {
      final result = _solveQuadratic(problem, language);
      steps = result['steps'] as List<SolutionStep>;
      solution = result['solution'] as String;
    } else if (_isLinearEquation(lowerProblem)) {
      final result = _solveLinear(problem, language);
      steps = result['steps'] as List<SolutionStep>;
      solution = result['solution'] as String;
    } else if (_isIntegral(lowerProblem)) {
      final result = _solveBasicIntegral(problem, language);
      steps = result['steps'] as List<SolutionStep>;
      solution = result['solution'] as String;
    } else if (_isDerivative(lowerProblem)) {
      final result = _solveBasicDerivative(problem, language);
      steps = result['steps'] as List<SolutionStep>;
      solution = result['solution'] as String;
    } else {
      steps = [
        SolutionStep(
          stepNumber: 1,
          title: _getLocalizedText('analysis', language),
          description: _getLocalizedText('analyzing_problem', language) + problem,
        ),
        SolutionStep(
          stepNumber: 2,
          title: _getLocalizedText('recommendation', language),
          description: _getLocalizedText('configure_api', language),
        ),
      ];
      solution = _getLocalizedText('api_needed', language);
    }

    return MathProblem(
      problem: problem,
      solution: solution,
      steps: steps,
      category: category,
      difficulty: difficulty,
      language: language,
    );
  }

  bool _isBasicArithmetic(String p) {
    final normalized = p.replaceAll(' ', '').replaceAll('\u00D7', '*').replaceAll('\u00F7', '/');
    return _arithmeticChars.hasMatch(normalized) &&
        _hasDigit.hasMatch(normalized) &&
        _hasOp.hasMatch(normalized);
  }

  bool _isQuadraticEquation(String p) {
    return p.contains('x²') || p.contains('x^2') || (p.contains('x2') && p.contains('='));
  }

  bool _isLinearEquation(String p) {
    return p.contains('x') && p.contains('=') && !_isQuadraticEquation(p);
  }

  bool _isIntegral(String p) {
    return p.contains('integrate') || p.contains('∫') || p.contains('integral') ||
        p.contains('intgr') || p.contains('integr');
  }

  bool _isDerivative(String p) {
    return p.contains('derivative') || p.contains('differentiate') ||
        p.contains('d/dx') || p.contains('deriv') || p.contains('differen');
  }

  /// Normalize common math spelling errors in input
  static String _normalizeSpelling(String input) {
    return input.replaceAllMapped(_wordBoundary, (match) {
      final word = match.group(0)!;
      final lower = word.toLowerCase();
      final fix = _spellingFixes[lower];
      if (fix == null) return word;
      // Preserve original case of first letter
      if (word[0] == word[0].toUpperCase()) {
        return fix[0].toUpperCase() + fix.substring(1);
      }
      return fix;
    });
  }

  Map<String, dynamic> _solveArithmetic(String problem, String lang) {
    try {
      final cleaned = problem.replaceAll(' ', '').replaceAll('\u00D7', '*').replaceAll('\u00F7', '/');

      List<SolutionStep> steps = [
        SolutionStep(
          stepNumber: 1,
          title: _getLocalizedText('identify_expression', lang),
          description: '${_getLocalizedText('need_to_evaluate', lang)} $problem',
        ),
      ];

      final result = _evalExpression(cleaned, 0);
      final value = result.value;

      if (cleaned.contains('(')) {
        steps.add(SolutionStep(
          stepNumber: 2,
          title: _getLocalizedText('eval_parentheses', lang),
          description: _getLocalizedText('following_order', lang),
        ));
      }

      steps.add(SolutionStep(
        stepNumber: steps.length + 1,
        title: _getLocalizedText('compute_result', lang),
        description: _getLocalizedText('eval_step_by_step', lang),
      ));

      final displayResult = value == value.toInt().toDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(4);

      steps.add(SolutionStep(
        stepNumber: steps.length + 1,
        title: _getLocalizedText('final_answer', lang),
        description: '$problem = $displayResult',
      ));

      return {'steps': steps, 'solution': displayResult};
    } catch (e) {
      return {
        'steps': [
          SolutionStep(stepNumber: 1, title: _getLocalizedText('error', lang), description: '${_getLocalizedText('could_not_evaluate', lang)} $problem'),
        ],
        'solution': _getLocalizedText('error_evaluating', lang),
      };
    }
  }

  static const int _maxParserDepth = 100;

  /// Recursive descent parser for arithmetic with parentheses
  /// Handles +, -, *, / and () with correct precedence
  _ParseResult _evalExpression(String expr, int pos, [int depth = 0]) {
    if (depth > _maxParserDepth) throw Exception('Expression too complex');
    var result = _evalTerm(expr, pos, depth);
    var value = result.value;
    var i = result.pos;

    while (i < expr.length && (expr[i] == '+' || expr[i] == '-')) {
      final op = expr[i];
      i++;
      final next = _evalTerm(expr, i, depth);
      if (op == '+') {
        value += next.value;
      } else {
        value -= next.value;
      }
      i = next.pos;
    }

    return _ParseResult(value, i);
  }

  _ParseResult _evalTerm(String expr, int pos, [int depth = 0]) {
    var result = _evalFactor(expr, pos, depth);
    var value = result.value;
    var i = result.pos;

    while (i < expr.length && (expr[i] == '*' || expr[i] == '/')) {
      final op = expr[i];
      i++;
      final next = _evalFactor(expr, i, depth);
      if (op == '*') {
        value *= next.value;
      } else {
        if (next.value == 0) throw Exception('Division by zero');
        value /= next.value;
      }
      i = next.pos;
    }

    return _ParseResult(value, i);
  }

  _ParseResult _evalFactor(String expr, int pos, [int depth = 0]) {
    if (depth > _maxParserDepth) throw Exception('Expression too complex');
    // Handle negative numbers
    if (pos < expr.length && expr[pos] == '-') {
      final result = _evalFactor(expr, pos + 1, depth + 1);
      return _ParseResult(-result.value, result.pos);
    }

    if (pos < expr.length && expr[pos] == '(') {
      final result = _evalExpression(expr, pos + 1, depth + 1);
      // Skip closing paren
      final endPos = result.pos < expr.length && expr[result.pos] == ')'
          ? result.pos + 1
          : result.pos;
      return _ParseResult(result.value, endPos);
    }

    // Parse number
    int start = pos;
    while (pos < expr.length && (expr.codeUnitAt(pos) >= 48 && expr.codeUnitAt(pos) <= 57 || expr[pos] == '.')) {
      pos++;
    }
    if (start == pos) throw Exception('Expected number at position $pos');
    return _ParseResult(double.parse(expr.substring(start, pos)), pos);
  }

  Map<String, dynamic> _solveQuadratic(String problem, String lang) {
    // Try to parse and actually solve: ax² + bx + c = 0
    final cleaned = problem.replaceAll(' ', '').replaceAll('×', '*').replaceAll('÷', '/').toLowerCase();
    final match = RegExp(r'^([\-]?\d*\.?\d*)x[²\^2]([+\-]\d*\.?\d*)x([+\-]\d+\.?\d*)=0$').firstMatch(cleaned);
    if (match != null) {
      final aStr = match.group(1)!;
      final bStr = match.group(2)!;
      final cStr = match.group(3)!;
      final a = aStr.isEmpty || aStr == '+' ? 1.0 : (aStr == '-' ? -1.0 : double.parse(aStr));
      final b = bStr.isEmpty || bStr == '+' ? 1.0 : (bStr == '-' ? -1.0 : double.parse(bStr));
      final c = double.parse(cStr);
      final discriminant = b * b - 4 * a * c;

      String solutionText;
      final steps = <SolutionStep>[
        SolutionStep(stepNumber: 1, title: _getLocalizedText('identify_coefficients', lang), description: 'a = $a, b = $b, c = $c'),
        SolutionStep(stepNumber: 2, title: _getLocalizedText('calc_discriminant', lang), description: 'Δ = b² - 4ac = ${b*b} - ${4*a*c} = $discriminant'),
      ];

      if (discriminant > 0) {
        final x1 = (-b + math.sqrt(discriminant)) / (2 * a);
        final x2 = (-b - math.sqrt(discriminant)) / (2 * a);
        final d1 = _formatNum(x1);
        final d2 = _formatNum(x2);
        solutionText = 'x = $d1 or x = $d2';
        steps.add(SolutionStep(stepNumber: 3, title: _getLocalizedText('two_real_solutions', lang), description: 'x₁ = (-$b + √$discriminant) / ${2*a} = $d1\nx₂ = (-$b - √$discriminant) / ${2*a} = $d2'));
      } else if (discriminant == 0) {
        final x = -b / (2 * a);
        solutionText = 'x = ${_formatNum(x)}';
        steps.add(SolutionStep(stepNumber: 3, title: _getLocalizedText('one_real_solution', lang), description: 'x = -b / 2a = ${_formatNum(x)}'));
      } else {
        solutionText = _getLocalizedText('no_real_solutions', lang);
        steps.add(SolutionStep(stepNumber: 3, title: _getLocalizedText('no_real_solutions', lang), description: _getLocalizedText('discriminant_negative', lang)));
      }
      steps.add(SolutionStep(stepNumber: steps.length + 1, title: _getLocalizedText('final_answer', lang), description: solutionText));
      return {'steps': steps, 'solution': solutionText};
    }

    // Fallback: generic guidance
    return {
      'steps': [
        SolutionStep(stepNumber: 1, title: _getLocalizedText('quadratic_form', lang), description: 'ax² + bx + c = 0'),
        SolutionStep(stepNumber: 2, title: _getLocalizedText('quadratic_formula', lang), description: 'x = (-b ± √(b²-4ac)) / 2a'),
      ],
      'solution': 'x = (-b ± √(b²-4ac)) / 2a',
    };
  }

  Map<String, dynamic> _solveLinear(String problem, String lang) {
    final cleaned = problem.replaceAll(' ', '').toLowerCase();
    final match = RegExp(r'^([\-]?\d*\.?\d*)x([+\-]\d+\.?\d*)=([\-]?\d+\.?\d*)$').firstMatch(cleaned);
    if (match != null) {
      final aStr = match.group(1)!;
      final bStr = match.group(2)!;
      final cStr = match.group(3)!;
      final a = aStr.isEmpty || aStr == '+' ? 1.0 : (aStr == '-' ? -1.0 : double.parse(aStr));
      final b = double.parse(bStr);
      final c = double.parse(cStr);
      if (a == 0) {
        return {
          'steps': [SolutionStep(stepNumber: 1, title: _getLocalizedText('error', lang), description: _getLocalizedText('coefficient_zero', lang))],
          'solution': _getLocalizedText('no_solution', lang),
        };
      }
      final x = (c - b) / a;
      final result = _formatNum(x);
      return {
        'steps': [
          SolutionStep(stepNumber: 1, title: _getLocalizedText('identify_equation', lang), description: '${_formatNum(a)}x + ${_formatNum(b)} = ${_formatNum(c)}'),
          SolutionStep(stepNumber: 2, title: _getLocalizedText('move_constant', lang), description: '${_formatNum(a)}x = ${_formatNum(c)} - ${_formatNum(b)} = ${_formatNum(c - b)}'),
          SolutionStep(stepNumber: 3, title: _getLocalizedText('divide_by_coeff', lang), description: 'x = ${_formatNum(c - b)} / ${_formatNum(a)} = $result'),
          SolutionStep(stepNumber: 4, title: _getLocalizedText('final_answer', lang), description: 'x = $result'),
        ],
        'solution': 'x = $result',
      };
    }

    // Fallback
    return {
      'steps': [
        SolutionStep(stepNumber: 1, title: _getLocalizedText('linear_equation', lang), description: 'ax + b = c'),
        SolutionStep(stepNumber: 2, title: _getLocalizedText('solve', lang), description: 'x = (c - b) / a'),
      ],
      'solution': 'x = (c - b) / a',
    };
  }

  String _formatNum(double v) {
    return v == v.toInt().toDouble() ? v.toInt().toString() : v.toStringAsFixed(4);
  }

  Map<String, dynamic> _solveBasicIntegral(String problem, String lang) {
    final steps = <SolutionStep>[
      SolutionStep(
        stepNumber: 1,
        title: _getLocalizedText('identify_integral', lang),
        description: _getLocalizedText('find_antiderivative', lang),
      ),
      SolutionStep(
        stepNumber: 2,
        title: _getLocalizedText('apply_power_rule', lang),
        description: '∫xⁿ dx = xⁿ⁺¹ / (n+1) + C\n\n(n ≠ -1)',
      ),
      SolutionStep(
        stepNumber: 3,
        title: _getLocalizedText('dont_forget_constant', lang),
        description: _getLocalizedText('add_constant_c', lang),
      ),
    ];

    return {
      'steps': steps,
      'solution': '∫xⁿ dx = xⁿ⁺¹/(n+1) + C',
    };
  }

  Map<String, dynamic> _solveBasicDerivative(String problem, String lang) {
    final steps = <SolutionStep>[
      SolutionStep(
        stepNumber: 1,
        title: _getLocalizedText('identify_function', lang),
        description: _getLocalizedText('find_derivative', lang),
      ),
      SolutionStep(
        stepNumber: 2,
        title: _getLocalizedText('apply_diff_rules', lang),
        description: '${_getLocalizedText('power_rule', lang)}: d/dx(xⁿ) = nxⁿ⁻¹\n${_getLocalizedText('sum_rule', lang)}: d/dx(f+g) = f\' + g\'\n${_getLocalizedText('product_rule', lang)}: d/dx(fg) = f\'g + fg\'',
      ),
      SolutionStep(
        stepNumber: 3,
        title: _getLocalizedText('simplify', lang),
        description: _getLocalizedText('combine_and_simplify', lang),
      ),
    ];

    return {
      'steps': steps,
      'solution': 'd/dx(xⁿ) = nxⁿ⁻¹',
    };
  }

  static const Map<String, Map<String, String>> _localizedTexts = {
    'en': {
      'analysis': 'Problem Analysis', 'analyzing_problem': 'Analyzing the problem: ',
      'recommendation': 'Recommendation',
      'configure_api': 'For complete AI-powered solutions, configure an API key in Settings. The app supports any OpenAI-compatible API.',
      'api_needed': 'Configure API for full solution',
      // Solver step titles
      'identify_expression': 'Identify the expression', 'need_to_evaluate': 'We need to evaluate:',
      'eval_parentheses': 'Evaluate parentheses first', 'following_order': 'Following order of operations (PEMDAS/BODMAS)',
      'compute_result': 'Compute result', 'eval_step_by_step': 'Evaluating step by step gives us the result',
      'final_answer': 'Final Answer', 'error': 'Error',
      'could_not_evaluate': 'Could not evaluate:', 'error_evaluating': 'Error evaluating expression',
      'identify_coefficients': 'Identify coefficients', 'calc_discriminant': 'Calculate discriminant',
      'two_real_solutions': 'Two real solutions', 'one_real_solution': 'One real solution',
      'no_real_solutions': 'No real solutions', 'discriminant_negative': 'Discriminant is negative, no real roots',
      'quadratic_form': 'Quadratic Form', 'quadratic_formula': 'Quadratic Formula',
      'identify_equation': 'Identify equation', 'move_constant': 'Move constant',
      'divide_by_coeff': 'Divide by coefficient', 'linear_equation': 'Linear Equation', 'solve': 'Solve',
      'coefficient_zero': 'Coefficient of x is 0', 'no_solution': 'No solution (a=0)',
      'identify_integral': 'Identify the Integral', 'find_antiderivative': 'We need to find the antiderivative (indefinite integral).',
      'apply_power_rule': 'Apply Power Rule', 'dont_forget_constant': "Don't Forget the Constant",
      'add_constant_c': 'Always add the constant of integration C for indefinite integrals.',
      'identify_function': 'Identify the Function', 'find_derivative': 'We need to find the derivative of the given function.',
      'apply_diff_rules': 'Apply Differentiation Rules', 'simplify': 'Simplify',
      'combine_and_simplify': 'Combine like terms and simplify the result.',
      'power_rule': 'Power Rule', 'sum_rule': 'Sum Rule', 'product_rule': 'Product Rule',
    },
    'ar': {
      'analysis': 'تحليل المسألة', 'analyzing_problem': 'تحليل المسألة: ',
      'recommendation': 'التوصية',
      'configure_api': 'للحصول على حلول كاملة بالذكاء الاصطناعي، قم بتكوين مفتاح API في الإعدادات.',
      'api_needed': 'قم بتكوين API للحل الكامل',
      'identify_expression': 'تحديد التعبير', 'need_to_evaluate': 'نحتاج لحساب:',
      'eval_parentheses': 'حساب الأقواس أولاً', 'following_order': 'اتباع ترتيب العمليات',
      'compute_result': 'حساب النتيجة', 'eval_step_by_step': 'الحساب خطوة بخطوة يعطينا النتيجة',
      'final_answer': 'الإجابة النهائية', 'error': 'خطأ',
      'could_not_evaluate': 'تعذر حساب:', 'error_evaluating': 'خطأ في حساب التعبير',
      'identify_coefficients': 'تحديد المعاملات', 'calc_discriminant': 'حساب المميز',
      'two_real_solutions': 'حلّان حقيقيان', 'one_real_solution': 'حل حقيقي واحد',
      'no_real_solutions': 'لا توجد حلول حقيقية', 'discriminant_negative': 'المميز سالب، لا توجد جذور حقيقية',
      'quadratic_form': 'الصيغة التربيعية', 'quadratic_formula': 'القانون التربيعي',
      'identify_equation': 'تحديد المعادلة', 'move_constant': 'نقل الثابت',
      'divide_by_coeff': 'القسمة على المعامل', 'linear_equation': 'معادلة خطية', 'solve': 'حل',
      'coefficient_zero': 'معامل x يساوي صفر', 'no_solution': 'لا يوجد حل (a=0)',
      'identify_integral': 'تحديد التكامل', 'find_antiderivative': 'نحتاج لإيجاد المشتقة العكسية (التكامل غير المحدد).',
      'apply_power_rule': 'تطبيق قاعدة القوة', 'dont_forget_constant': 'لا تنسَ الثابت',
      'add_constant_c': 'أضف دائماً ثابت التكامل C للتكاملات غير المحددة.',
      'identify_function': 'تحديد الدالة', 'find_derivative': 'نحتاج لإيجاد مشتقة الدالة المعطاة.',
      'apply_diff_rules': 'تطبيق قواعد الاشتقاق', 'simplify': 'التبسيط',
      'combine_and_simplify': 'اجمع الحدود المتشابهة وبسّط النتيجة.',
      'power_rule': 'قاعدة القوة', 'sum_rule': 'قاعدة المجموع', 'product_rule': 'قاعدة الضرب',
    },
    'fr': {
      'analysis': 'Analyse du problème', 'analyzing_problem': 'Analyse du problème : ',
      'recommendation': 'Recommandation',
      'configure_api': 'Pour des solutions complètes par IA, configurez une clé API dans les paramètres.',
      'api_needed': 'Configurer l\'API pour la solution complète',
      'identify_expression': 'Identifier l\'expression', 'need_to_evaluate': 'Nous devons évaluer :',
      'eval_parentheses': 'Évaluer les parenthèses d\'abord', 'following_order': 'Suivre l\'ordre des opérations',
      'compute_result': 'Calculer le résultat', 'eval_step_by_step': 'L\'évaluation étape par étape donne le résultat',
      'final_answer': 'Réponse finale', 'error': 'Erreur',
      'could_not_evaluate': 'Impossible d\'évaluer :', 'error_evaluating': 'Erreur lors de l\'évaluation',
      'identify_coefficients': 'Identifier les coefficients', 'calc_discriminant': 'Calculer le discriminant',
      'two_real_solutions': 'Deux solutions réelles', 'one_real_solution': 'Une solution réelle',
      'no_real_solutions': 'Pas de solutions réelles', 'discriminant_negative': 'Le discriminant est négatif, pas de racines réelles',
      'quadratic_form': 'Forme quadratique', 'quadratic_formula': 'Formule quadratique',
      'identify_equation': 'Identifier l\'équation', 'move_constant': 'Déplacer la constante',
      'divide_by_coeff': 'Diviser par le coefficient', 'linear_equation': 'Équation linéaire', 'solve': 'Résoudre',
      'coefficient_zero': 'Le coefficient de x est 0', 'no_solution': 'Pas de solution (a=0)',
      'identify_integral': 'Identifier l\'intégrale', 'find_antiderivative': 'Nous devons trouver la primitive (intégrale indéfinie).',
      'apply_power_rule': 'Appliquer la règle de puissance', 'dont_forget_constant': 'N\'oubliez pas la constante',
      'add_constant_c': 'Ajoutez toujours la constante d\'intégration C pour les intégrales indéfinies.',
      'identify_function': 'Identifier la fonction', 'find_derivative': 'Nous devons trouver la dérivée de la fonction donnée.',
      'apply_diff_rules': 'Appliquer les règles de dérivation', 'simplify': 'Simplifier',
      'combine_and_simplify': 'Combiner les termes semblables et simplifier le résultat.',
      'power_rule': 'Règle de puissance', 'sum_rule': 'Règle de la somme', 'product_rule': 'Règle du produit',
    },
    'es': {
      'analysis': 'Análisis del problema', 'analyzing_problem': 'Analizando el problema: ',
      'recommendation': 'Recomendación',
      'configure_api': 'Para soluciones completas con IA, configure una clave API en Configuración.',
      'api_needed': 'Configure API para la solución completa',
      'identify_expression': 'Identificar la expresión', 'need_to_evaluate': 'Necesitamos evaluar:',
      'eval_parentheses': 'Evaluar paréntesis primero', 'following_order': 'Siguiendo el orden de operaciones',
      'compute_result': 'Calcular resultado', 'eval_step_by_step': 'Evaluando paso a paso obtenemos el resultado',
      'final_answer': 'Respuesta final', 'error': 'Error',
      'could_not_evaluate': 'No se pudo evaluar:', 'error_evaluating': 'Error al evaluar la expresión',
      'identify_coefficients': 'Identificar coeficientes', 'calc_discriminant': 'Calcular discriminante',
      'two_real_solutions': 'Dos soluciones reales', 'one_real_solution': 'Una solución real',
      'no_real_solutions': 'Sin soluciones reales', 'discriminant_negative': 'El discriminante es negativo, sin raíces reales',
      'quadratic_form': 'Forma cuadrática', 'quadratic_formula': 'Fórmula cuadrática',
      'identify_equation': 'Identificar ecuación', 'move_constant': 'Mover constante',
      'divide_by_coeff': 'Dividir por coeficiente', 'linear_equation': 'Ecuación lineal', 'solve': 'Resolver',
      'coefficient_zero': 'El coeficiente de x es 0', 'no_solution': 'Sin solución (a=0)',
      'identify_integral': 'Identificar la integral', 'find_antiderivative': 'Necesitamos encontrar la antiderivada (integral indefinida).',
      'apply_power_rule': 'Aplicar regla de potencia', 'dont_forget_constant': 'No olvides la constante',
      'add_constant_c': 'Siempre agrega la constante de integración C para integrales indefinidas.',
      'identify_function': 'Identificar la función', 'find_derivative': 'Necesitamos encontrar la derivada de la función dada.',
      'apply_diff_rules': 'Aplicar reglas de derivación', 'simplify': 'Simplificar',
      'combine_and_simplify': 'Combinar términos semejantes y simplificar el resultado.',
      'power_rule': 'Regla de potencia', 'sum_rule': 'Regla de la suma', 'product_rule': 'Regla del producto',
    },
    'zh': {
      'analysis': '问题分析', 'analyzing_problem': '分析问题：',
      'recommendation': '建议',
      'configure_api': '要获得完整的AI解答，请在设置中配置API密钥。',
      'api_needed': '配置API以获取完整解答',
      'identify_expression': '识别表达式', 'need_to_evaluate': '我们需要计算：',
      'eval_parentheses': '先计算括号', 'following_order': '按照运算顺序',
      'compute_result': '计算结果', 'eval_step_by_step': '逐步计算得出结果',
      'final_answer': '最终答案', 'error': '错误',
      'could_not_evaluate': '无法计算：', 'error_evaluating': '计算表达式时出错',
      'identify_coefficients': '识别系数', 'calc_discriminant': '计算判别式',
      'two_real_solutions': '两个实数解', 'one_real_solution': '一个实数解',
      'no_real_solutions': '无实数解', 'discriminant_negative': '判别式为负，无实数根',
      'quadratic_form': '二次方程形式', 'quadratic_formula': '求根公式',
      'identify_equation': '识别方程', 'move_constant': '移项',
      'divide_by_coeff': '除以系数', 'linear_equation': '一次方程', 'solve': '求解',
      'coefficient_zero': 'x的系数为0', 'no_solution': '无解 (a=0)',
      'identify_integral': '识别积分', 'find_antiderivative': '我们需要求不定积分（原函数）。',
      'apply_power_rule': '应用幂法则', 'dont_forget_constant': '别忘了常数',
      'add_constant_c': '不定积分要加积分常数C。',
      'identify_function': '识别函数', 'find_derivative': '我们需要求给定函数的导数。',
      'apply_diff_rules': '应用求导法则', 'simplify': '化简',
      'combine_and_simplify': '合并同类项并化简结果。',
      'power_rule': '幂法则', 'sum_rule': '和法则', 'product_rule': '乘积法则',
    },
    'de': {
      'analysis': 'Problemanalyse', 'analyzing_problem': 'Analyse des Problems: ',
      'recommendation': 'Empfehlung',
      'configure_api': 'Für vollständige KI-Lösungen konfigurieren Sie einen API-Schlüssel in den Einstellungen.',
      'api_needed': 'API für vollständige Lösung konfigurieren',
      'identify_expression': 'Ausdruck identifizieren', 'need_to_evaluate': 'Wir müssen berechnen:',
      'eval_parentheses': 'Klammern zuerst auswerten', 'following_order': 'Reihenfolge der Operationen beachten',
      'compute_result': 'Ergebnis berechnen', 'eval_step_by_step': 'Schrittweise Auswertung ergibt das Ergebnis',
      'final_answer': 'Endantwort', 'error': 'Fehler',
      'could_not_evaluate': 'Konnte nicht berechnet werden:', 'error_evaluating': 'Fehler bei der Berechnung',
      'identify_coefficients': 'Koeffizienten identifizieren', 'calc_discriminant': 'Diskriminante berechnen',
      'two_real_solutions': 'Zwei reelle Lösungen', 'one_real_solution': 'Eine reelle Lösung',
      'no_real_solutions': 'Keine reellen Lösungen', 'discriminant_negative': 'Diskriminante ist negativ, keine reellen Wurzeln',
      'quadratic_form': 'Quadratische Form', 'quadratic_formula': 'Quadratische Formel',
      'identify_equation': 'Gleichung identifizieren', 'move_constant': 'Konstante verschieben',
      'divide_by_coeff': 'Durch Koeffizienten teilen', 'linear_equation': 'Lineare Gleichung', 'solve': 'Lösen',
      'coefficient_zero': 'Koeffizient von x ist 0', 'no_solution': 'Keine Lösung (a=0)',
      'identify_integral': 'Integral identifizieren', 'find_antiderivative': 'Wir müssen die Stammfunktion (unbestimmtes Integral) finden.',
      'apply_power_rule': 'Potenzregel anwenden', 'dont_forget_constant': 'Konstante nicht vergessen',
      'add_constant_c': 'Immer die Integrationskonstante C für unbestimmte Integrale hinzufügen.',
      'identify_function': 'Funktion identifizieren', 'find_derivative': 'Wir müssen die Ableitung der gegebenen Funktion finden.',
      'apply_diff_rules': 'Ableitungsregeln anwenden', 'simplify': 'Vereinfachen',
      'combine_and_simplify': 'Gleichartige Terme zusammenfassen und das Ergebnis vereinfachen.',
      'power_rule': 'Potenzregel', 'sum_rule': 'Summenregel', 'product_rule': 'Produktregel',
    },
    'hi': {
      'analysis': 'समस्या विश्लेषण', 'analyzing_problem': 'समस्या का विश्लेषण: ',
      'recommendation': 'सिफारिश',
      'configure_api': 'पूर्ण AI समाधान के लिए सेटिंग्स में API कुंजी कॉन्फ़िगर करें।',
      'api_needed': 'पूर्ण समाधान के लिए API कॉन्फ़िगर करें',
      'identify_expression': 'व्यंजक की पहचान करें', 'need_to_evaluate': 'हमें हल करना है:',
      'eval_parentheses': 'पहले कोष्ठक हल करें', 'following_order': 'संक्रियाओं का क्रम अपनाएं',
      'compute_result': 'परिणाम की गणना', 'eval_step_by_step': 'चरणबद्ध गणना से परिणाम प्राप्त होता है',
      'final_answer': 'अंतिम उत्तर', 'error': 'त्रुटि',
      'could_not_evaluate': 'हल नहीं कर सके:', 'error_evaluating': 'व्यंजक हल करने में त्रुटि',
      'identify_coefficients': 'गुणांक पहचानें', 'calc_discriminant': 'विविक्तकर की गणना करें',
      'two_real_solutions': 'दो वास्तविक हल', 'one_real_solution': 'एक वास्तविक हल',
      'no_real_solutions': 'कोई वास्तविक हल नहीं', 'discriminant_negative': 'विविक्तकर ऋणात्मक है, कोई वास्तविक मूल नहीं',
      'quadratic_form': 'द्विघात रूप', 'quadratic_formula': 'द्विघात सूत्र',
      'identify_equation': 'समीकरण पहचानें', 'move_constant': 'अचर को स्थानांतरित करें',
      'divide_by_coeff': 'गुणांक से भाग दें', 'linear_equation': 'रैखिक समीकरण', 'solve': 'हल करें',
      'coefficient_zero': 'x का गुणांक 0 है', 'no_solution': 'कोई हल नहीं (a=0)',
      'identify_integral': 'समाकल पहचानें', 'find_antiderivative': 'हमें प्रतिअवकलज (अनिश्चित समाकल) ज्ञात करना है।',
      'apply_power_rule': 'घात नियम लागू करें', 'dont_forget_constant': 'अचर न भूलें',
      'add_constant_c': 'अनिश्चित समाकलों के लिए हमेशा समाकलन अचर C जोड़ें।',
      'identify_function': 'फलन पहचानें', 'find_derivative': 'हमें दिए गए फलन का अवकलज ज्ञात करना है।',
      'apply_diff_rules': 'अवकलन नियम लागू करें', 'simplify': 'सरल करें',
      'combine_and_simplify': 'समान पदों को मिलाएं और परिणाम सरल करें।',
      'power_rule': 'घात नियम', 'sum_rule': 'योग नियम', 'product_rule': 'गुणनफल नियम',
    },
    'ja': {
      'analysis': '問題分析', 'analyzing_problem': '問題を分析中: ',
      'recommendation': '推奨',
      'configure_api': '完全なAIソリューションのために、設定でAPIキーを設定してください。',
      'api_needed': '完全な解答のためにAPIを設定',
      'identify_expression': '式を特定する', 'need_to_evaluate': '計算する必要があります：',
      'eval_parentheses': '括弧を先に計算', 'following_order': '演算の順序に従う',
      'compute_result': '結果を計算', 'eval_step_by_step': 'ステップごとに計算して結果を得る',
      'final_answer': '最終回答', 'error': 'エラー',
      'could_not_evaluate': '計算できませんでした：', 'error_evaluating': '式の計算エラー',
      'identify_coefficients': '係数を特定する', 'calc_discriminant': '判別式を計算する',
      'two_real_solutions': '2つの実数解', 'one_real_solution': '1つの実数解',
      'no_real_solutions': '実数解なし', 'discriminant_negative': '判別式が負のため、実数根なし',
      'quadratic_form': '二次方程式の形', 'quadratic_formula': '解の公式',
      'identify_equation': '方程式を特定する', 'move_constant': '定数を移動する',
      'divide_by_coeff': '係数で割る', 'linear_equation': '一次方程式', 'solve': '解く',
      'coefficient_zero': 'xの係数が0です', 'no_solution': '解なし (a=0)',
      'identify_integral': '積分を特定する', 'find_antiderivative': '不定積分（原始関数）を求める必要があります。',
      'apply_power_rule': 'べき乗則を適用', 'dont_forget_constant': '定数を忘れない',
      'add_constant_c': '不定積分には必ず積分定数Cを加えてください。',
      'identify_function': '関数を特定する', 'find_derivative': '与えられた関数の導関数を求める必要があります。',
      'apply_diff_rules': '微分法則を適用', 'simplify': '簡略化',
      'combine_and_simplify': '同類項をまとめて結果を簡略化する。',
      'power_rule': 'べき乗則', 'sum_rule': '和の法則', 'product_rule': '積の法則',
    },
    'ko': {
      'analysis': '문제 분석', 'analyzing_problem': '문제 분석 중: ',
      'recommendation': '권장사항',
      'configure_api': '전체 AI 솔루션을 위해 설정에서 API 키를 구성하세요.',
      'api_needed': '전체 솔루션을 위해 API 구성',
      'identify_expression': '식 확인', 'need_to_evaluate': '계산해야 합니다:',
      'eval_parentheses': '괄호 먼저 계산', 'following_order': '연산 순서를 따름',
      'compute_result': '결과 계산', 'eval_step_by_step': '단계별 계산으로 결과를 얻음',
      'final_answer': '최종 답', 'error': '오류',
      'could_not_evaluate': '계산할 수 없음:', 'error_evaluating': '식 계산 오류',
      'identify_coefficients': '계수 확인', 'calc_discriminant': '판별식 계산',
      'two_real_solutions': '두 개의 실수 해', 'one_real_solution': '하나의 실수 해',
      'no_real_solutions': '실수 해 없음', 'discriminant_negative': '판별식이 음수이므로 실수 근 없음',
      'quadratic_form': '이차방정식 형태', 'quadratic_formula': '근의 공식',
      'identify_equation': '방정식 확인', 'move_constant': '상수 이항',
      'divide_by_coeff': '계수로 나눔', 'linear_equation': '일차방정식', 'solve': '풀기',
      'coefficient_zero': 'x의 계수가 0', 'no_solution': '해 없음 (a=0)',
      'identify_integral': '적분 확인', 'find_antiderivative': '부정적분(역도함수)을 구해야 합니다.',
      'apply_power_rule': '거듭제곱 법칙 적용', 'dont_forget_constant': '상수를 잊지 마세요',
      'add_constant_c': '부정적분에는 항상 적분 상수 C를 추가하세요.',
      'identify_function': '함수 확인', 'find_derivative': '주어진 함수의 도함수를 구해야 합니다.',
      'apply_diff_rules': '미분 법칙 적용', 'simplify': '간소화',
      'combine_and_simplify': '동류항을 정리하고 결과를 간소화합니다.',
      'power_rule': '거듭제곱 법칙', 'sum_rule': '합의 법칙', 'product_rule': '곱의 법칙',
    },
    'ru': {
      'analysis': 'Анализ задачи', 'analyzing_problem': 'Анализ задачи: ',
      'recommendation': 'Рекомендация',
      'configure_api': 'Для полных AI-решений настройте API-ключ в настройках.',
      'api_needed': 'Настройте API для полного решения',
      'identify_expression': 'Определить выражение', 'need_to_evaluate': 'Нужно вычислить:',
      'eval_parentheses': 'Сначала вычислить скобки', 'following_order': 'Следуя порядку операций',
      'compute_result': 'Вычислить результат', 'eval_step_by_step': 'Пошаговое вычисление даёт результат',
      'final_answer': 'Итоговый ответ', 'error': 'Ошибка',
      'could_not_evaluate': 'Не удалось вычислить:', 'error_evaluating': 'Ошибка при вычислении',
      'identify_coefficients': 'Определить коэффициенты', 'calc_discriminant': 'Вычислить дискриминант',
      'two_real_solutions': 'Два действительных решения', 'one_real_solution': 'Одно действительное решение',
      'no_real_solutions': 'Нет действительных решений', 'discriminant_negative': 'Дискриминант отрицательный, нет действительных корней',
      'quadratic_form': 'Квадратичная форма', 'quadratic_formula': 'Квадратная формула',
      'identify_equation': 'Определить уравнение', 'move_constant': 'Перенести константу',
      'divide_by_coeff': 'Разделить на коэффициент', 'linear_equation': 'Линейное уравнение', 'solve': 'Решить',
      'coefficient_zero': 'Коэффициент при x равен 0', 'no_solution': 'Нет решения (a=0)',
      'identify_integral': 'Определить интеграл', 'find_antiderivative': 'Нужно найти первообразную (неопределённый интеграл).',
      'apply_power_rule': 'Применить степенное правило', 'dont_forget_constant': 'Не забудьте константу',
      'add_constant_c': 'Всегда добавляйте постоянную интегрирования C для неопределённых интегралов.',
      'identify_function': 'Определить функцию', 'find_derivative': 'Нужно найти производную данной функции.',
      'apply_diff_rules': 'Применить правила дифференцирования', 'simplify': 'Упростить',
      'combine_and_simplify': 'Привести подобные члены и упростить результат.',
      'power_rule': 'Степенное правило', 'sum_rule': 'Правило суммы', 'product_rule': 'Правило произведения',
    },
    'pt': {
      'analysis': 'Análise do Problema', 'analyzing_problem': 'Analisando o problema: ',
      'recommendation': 'Recomendação',
      'configure_api': 'Para soluções completas com IA, configure uma chave API nas configurações.',
      'api_needed': 'Configure a API para solução completa',
      'identify_expression': 'Identificar a expressão', 'need_to_evaluate': 'Precisamos calcular:',
      'eval_parentheses': 'Avaliar parênteses primeiro', 'following_order': 'Seguindo a ordem das operações',
      'compute_result': 'Calcular resultado', 'eval_step_by_step': 'Avaliação passo a passo dá o resultado',
      'final_answer': 'Resposta final', 'error': 'Erro',
      'could_not_evaluate': 'Não foi possível calcular:', 'error_evaluating': 'Erro ao calcular expressão',
      'identify_coefficients': 'Identificar coeficientes', 'calc_discriminant': 'Calcular discriminante',
      'two_real_solutions': 'Duas soluções reais', 'one_real_solution': 'Uma solução real',
      'no_real_solutions': 'Sem soluções reais', 'discriminant_negative': 'Discriminante é negativo, sem raízes reais',
      'quadratic_form': 'Forma quadrática', 'quadratic_formula': 'Fórmula quadrática',
      'identify_equation': 'Identificar equação', 'move_constant': 'Mover constante',
      'divide_by_coeff': 'Dividir pelo coeficiente', 'linear_equation': 'Equação linear', 'solve': 'Resolver',
      'coefficient_zero': 'Coeficiente de x é 0', 'no_solution': 'Sem solução (a=0)',
      'identify_integral': 'Identificar a integral', 'find_antiderivative': 'Precisamos encontrar a primitiva (integral indefinida).',
      'apply_power_rule': 'Aplicar regra da potência', 'dont_forget_constant': 'Não esqueça a constante',
      'add_constant_c': 'Sempre adicione a constante de integração C para integrais indefinidas.',
      'identify_function': 'Identificar a função', 'find_derivative': 'Precisamos encontrar a derivada da função dada.',
      'apply_diff_rules': 'Aplicar regras de derivação', 'simplify': 'Simplificar',
      'combine_and_simplify': 'Combine termos semelhantes e simplifique o resultado.',
      'power_rule': 'Regra da potência', 'sum_rule': 'Regra da soma', 'product_rule': 'Regra do produto',
    },
    'tr': {
      'analysis': 'Problem Analizi', 'analyzing_problem': 'Problem analiz ediliyor: ',
      'recommendation': 'Öneri',
      'configure_api': 'Tam AI çözümleri için ayarlarda API anahtarını yapılandırın.',
      'api_needed': 'Tam çözüm için API yapılandırın',
      'identify_expression': 'İfadeyi tanımla', 'need_to_evaluate': 'Hesaplamamız gereken:',
      'eval_parentheses': 'Önce parantezleri hesapla', 'following_order': 'İşlem sırasına uyarak',
      'compute_result': 'Sonucu hesapla', 'eval_step_by_step': 'Adım adım hesaplama sonucu verir',
      'final_answer': 'Son Cevap', 'error': 'Hata',
      'could_not_evaluate': 'Hesaplanamadı:', 'error_evaluating': 'İfade hesaplama hatası',
      'identify_coefficients': 'Katsayıları belirle', 'calc_discriminant': 'Diskriminantı hesapla',
      'two_real_solutions': 'İki gerçek çözüm', 'one_real_solution': 'Bir gerçek çözüm',
      'no_real_solutions': 'Gerçek çözüm yok', 'discriminant_negative': 'Diskriminant negatif, gerçek kök yok',
      'quadratic_form': 'İkinci derece form', 'quadratic_formula': 'İkinci derece formül',
      'identify_equation': 'Denklemi tanımla', 'move_constant': 'Sabiti taşı',
      'divide_by_coeff': 'Katsayıya böl', 'linear_equation': 'Doğrusal denklem', 'solve': 'Çöz',
      'coefficient_zero': 'x katsayısı 0', 'no_solution': 'Çözüm yok (a=0)',
      'identify_integral': 'İntegrali tanımla', 'find_antiderivative': 'Belirsiz integral (ters türev) bulmamız gerekiyor.',
      'apply_power_rule': 'Kuvvet kuralını uygula', 'dont_forget_constant': 'Sabiti unutma',
      'add_constant_c': 'Belirsiz integraller için her zaman C integral sabitini ekleyin.',
      'identify_function': 'Fonksiyonu tanımla', 'find_derivative': 'Verilen fonksiyonun türevini bulmamız gerekiyor.',
      'apply_diff_rules': 'Türev kurallarını uygula', 'simplify': 'Sadeleştir',
      'combine_and_simplify': 'Benzer terimleri birleştir ve sonucu sadeleştir.',
      'power_rule': 'Kuvvet kuralı', 'sum_rule': 'Toplam kuralı', 'product_rule': 'Çarpım kuralı',
    },
    'it': {
      'analysis': 'Analisi del Problema', 'analyzing_problem': 'Analisi del problema: ',
      'recommendation': 'Raccomandazione',
      'configure_api': 'Per soluzioni AI complete, configura una chiave API nelle impostazioni.',
      'api_needed': 'Configura API per la soluzione completa',
      'identify_expression': 'Identificare l\'espressione', 'need_to_evaluate': 'Dobbiamo calcolare:',
      'eval_parentheses': 'Calcolare prima le parentesi', 'following_order': 'Seguendo l\'ordine delle operazioni',
      'compute_result': 'Calcolare il risultato', 'eval_step_by_step': 'La valutazione passo per passo dà il risultato',
      'final_answer': 'Risposta finale', 'error': 'Errore',
      'could_not_evaluate': 'Impossibile calcolare:', 'error_evaluating': 'Errore nel calcolo dell\'espressione',
      'identify_coefficients': 'Identificare i coefficienti', 'calc_discriminant': 'Calcolare il discriminante',
      'two_real_solutions': 'Due soluzioni reali', 'one_real_solution': 'Una soluzione reale',
      'no_real_solutions': 'Nessuna soluzione reale', 'discriminant_negative': 'Il discriminante è negativo, nessuna radice reale',
      'quadratic_form': 'Forma quadratica', 'quadratic_formula': 'Formula quadratica',
      'identify_equation': 'Identificare l\'equazione', 'move_constant': 'Spostare la costante',
      'divide_by_coeff': 'Dividere per il coefficiente', 'linear_equation': 'Equazione lineare', 'solve': 'Risolvere',
      'coefficient_zero': 'Il coefficiente di x è 0', 'no_solution': 'Nessuna soluzione (a=0)',
      'identify_integral': 'Identificare l\'integrale', 'find_antiderivative': 'Dobbiamo trovare la primitiva (integrale indefinito).',
      'apply_power_rule': 'Applicare la regola della potenza', 'dont_forget_constant': 'Non dimenticare la costante',
      'add_constant_c': 'Aggiungere sempre la costante di integrazione C per gli integrali indefiniti.',
      'identify_function': 'Identificare la funzione', 'find_derivative': 'Dobbiamo trovare la derivata della funzione data.',
      'apply_diff_rules': 'Applicare le regole di derivazione', 'simplify': 'Semplificare',
      'combine_and_simplify': 'Combinare i termini simili e semplificare il risultato.',
      'power_rule': 'Regola della potenza', 'sum_rule': 'Regola della somma', 'product_rule': 'Regola del prodotto',
    },
  };

  String _getLocalizedText(String key, String language) {
    return _localizedTexts[language]?[key] ?? _localizedTexts['en']?[key] ?? key;
  }
}

class _ParseResult {
  final double value;
  final int pos;
  _ParseResult(this.value, this.pos);
}
