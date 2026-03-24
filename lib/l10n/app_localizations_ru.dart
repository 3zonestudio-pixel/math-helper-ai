// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Математический помощник AI';

  @override
  String get typeProblem => 'Ввести задачу';

  @override
  String get scanProblem => 'Сканировать задачу';

  @override
  String get history => 'История';

  @override
  String get favorites => 'Избранное';

  @override
  String get settings => 'Настройки';

  @override
  String get solve => 'Решить';

  @override
  String get enterProblem => 'Введите вашу математическую задачу...';

  @override
  String get solution => 'Решение';

  @override
  String get steps => 'Шаги';

  @override
  String get explanation => 'Объяснение';

  @override
  String get tip => 'Совет';

  @override
  String get copy => 'Копировать';

  @override
  String get share => 'Поделиться';

  @override
  String get saveToFavorites => 'Добавить в избранное';

  @override
  String get removeFromFavorites => 'Удалить из избранного';

  @override
  String get language => 'Язык';

  @override
  String get difficulty => 'Сложность';

  @override
  String get beginner => 'Начальный';

  @override
  String get intermediate => 'Средний';

  @override
  String get advanced => 'Продвинутый';

  @override
  String get simple => 'Простой';

  @override
  String get detailed => 'Подробный';

  @override
  String get explanationMode => 'Режим объяснения';

  @override
  String get noHistory => 'Пока нет решённых задач';

  @override
  String get noFavorites => 'Нет сохранённых избранных';

  @override
  String get camera => 'Камера';

  @override
  String get gallery => 'Галерея';

  @override
  String get scanInstruction => 'Наведите камеру на математическую задачу';

  @override
  String get recognizedText => 'Распознанный текст';

  @override
  String get solveThis => 'Решить это';

  @override
  String get solving => 'Решение...';

  @override
  String get error => 'Ошибка';

  @override
  String get tryAgain => 'Попробовать снова';

  @override
  String get problemSolved => 'Задача решена!';

  @override
  String get step => 'Шаг';

  @override
  String get searchProblems => 'Поиск задач...';

  @override
  String get delete => 'Удалить';

  @override
  String get clearHistory => 'Очистить историю';

  @override
  String get clearHistoryConfirm =>
      'Вы уверены, что хотите очистить всю историю?';

  @override
  String get cancel => 'Отмена';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get copiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get savedToFavorites => 'Добавлено в избранное';

  @override
  String get removedFromFavorites => 'Удалено из избранного';

  @override
  String get yourAIMathTutor => 'Ваш AI репетитор по математике';

  @override
  String get algebra => 'Алгебра';

  @override
  String get calculus => 'Математический анализ';

  @override
  String get geometry => 'Геометрия';

  @override
  String get statistics => 'Статистика';

  @override
  String get general => 'Общее';

  @override
  String get darkMode => 'Тёмная тема';

  @override
  String get about => 'О приложении';

  @override
  String get version => 'Версия';

  @override
  String get appDescription =>
      'Математический помощник AI — ваш личный репетитор по математике. Решайте любую задачу пошагово с подробными объяснениями.';

  @override
  String get ocrNotAvailable => 'OCR недоступен на этом устройстве';

  @override
  String get cameraPermissionDenied => 'Разрешение на камеру отклонено';

  @override
  String get noTextRecognized => 'Текст не распознан. Попробуйте ещё раз.';

  @override
  String get selectImage => 'Выбрать изображение';

  @override
  String get solved => 'Решено';

  @override
  String get typeSubtitle => 'Введите любую математическую задачу';

  @override
  String get scanSubtitle => 'Сфотографируйте и решите мгновенно';

  @override
  String get processingImage => 'Обработка изображения...';

  @override
  String get supportedFormats => 'Поддержка: +, -, ×, ÷, x², √, ∫, дроби';

  @override
  String get problemLabel => 'Задача';

  @override
  String get solvedByApp => 'Решено Math Helper AI';

  @override
  String get aiConfiguration => 'Настройка AI';

  @override
  String get apiKeyLabel => 'API ключ';

  @override
  String get poweredByAI => 'Решатель задач с ИИ и пошаговыми решениями';

  @override
  String get apiConfigured => 'AI настроен';

  @override
  String get apiNotConfigured =>
      'Используется встроенный решатель. Добавьте API для полных решений.';

  @override
  String get apiSaved => 'Настройки API сохранены';

  @override
  String get simpleDescription => 'Краткие и лаконичные объяснения';

  @override
  String get detailedDescription => 'Подробные объяснения с теорией';

  @override
  String get justNow => 'Только что';

  @override
  String minutesAgo(int count) {
    return '$count мин назад';
  }

  @override
  String hoursAgo(int count) {
    return '$count ч назад';
  }

  @override
  String daysAgo(int count) {
    return '$count д назад';
  }

  @override
  String nSteps(int count) {
    return '$count шагов';
  }

  @override
  String get apiUrl => 'URL API';

  @override
  String get deleteConfirmTitle => 'Удалить';

  @override
  String get solutionLabel => 'Решение';

  @override
  String get explainIn => 'Объяснить на';

  @override
  String get autoDetect => 'Авто';

  @override
  String get edit => 'Редактировать';

  @override
  String get home => 'Главная';

  @override
  String get notMathProblem =>
      'Это не похоже на математическую задачу. Пожалуйста, введите математическое выражение или уравнение.';
}
