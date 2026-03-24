// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Math Helper AI';

  @override
  String get typeProblem => 'Escribir problema';

  @override
  String get scanProblem => 'Escanear problema';

  @override
  String get history => 'Historial';

  @override
  String get favorites => 'Favoritos';

  @override
  String get settings => 'Configuración';

  @override
  String get solve => 'Resolver';

  @override
  String get enterProblem => 'Ingresa tu problema matemático...';

  @override
  String get solution => 'Solución';

  @override
  String get steps => 'Pasos';

  @override
  String get explanation => 'Explicación';

  @override
  String get tip => 'Consejo';

  @override
  String get copy => 'Copiar';

  @override
  String get share => 'Compartir';

  @override
  String get saveToFavorites => 'Guardar en favoritos';

  @override
  String get removeFromFavorites => 'Eliminar de favoritos';

  @override
  String get language => 'Idioma';

  @override
  String get difficulty => 'Dificultad';

  @override
  String get beginner => 'Principiante';

  @override
  String get intermediate => 'Intermedio';

  @override
  String get advanced => 'Avanzado';

  @override
  String get simple => 'Simple';

  @override
  String get detailed => 'Detallado';

  @override
  String get explanationMode => 'Modo de explicación';

  @override
  String get noHistory => 'No hay problemas resueltos';

  @override
  String get noFavorites => 'No hay favoritos guardados';

  @override
  String get camera => 'Cámara';

  @override
  String get gallery => 'Galería';

  @override
  String get scanInstruction => 'Apunta tu cámara al problema matemático';

  @override
  String get recognizedText => 'Texto reconocido';

  @override
  String get solveThis => 'Resolver esto';

  @override
  String get solving => 'Resolviendo...';

  @override
  String get error => 'Error';

  @override
  String get tryAgain => 'Intentar de nuevo';

  @override
  String get problemSolved => '¡Problema resuelto!';

  @override
  String get step => 'Paso';

  @override
  String get searchProblems => 'Buscar problemas...';

  @override
  String get delete => 'Eliminar';

  @override
  String get clearHistory => 'Borrar historial';

  @override
  String get clearHistoryConfirm =>
      '¿Estás seguro de borrar todo el historial?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get copiedToClipboard => 'Copiado al portapapeles';

  @override
  String get savedToFavorites => 'Guardado en favoritos';

  @override
  String get removedFromFavorites => 'Eliminado de favoritos';

  @override
  String get yourAIMathTutor => 'Tu tutor de matemáticas IA';

  @override
  String get algebra => 'Álgebra';

  @override
  String get calculus => 'Cálculo';

  @override
  String get geometry => 'Geometría';

  @override
  String get statistics => 'Estadística';

  @override
  String get general => 'General';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get about => 'Acerca de';

  @override
  String get version => 'Versión';

  @override
  String get appDescription =>
      'Math Helper AI es tu tutor personal de matemáticas. Resuelve cualquier problema paso a paso.';

  @override
  String get ocrNotAvailable => 'OCR no disponible en este dispositivo';

  @override
  String get cameraPermissionDenied => 'Permiso de cámara denegado';

  @override
  String get noTextRecognized => 'No se reconoció texto. Inténtalo de nuevo.';

  @override
  String get selectImage => 'Seleccionar imagen';

  @override
  String get solved => 'Resuelto';

  @override
  String get typeSubtitle => 'Escribe cualquier problema matemático';

  @override
  String get scanSubtitle => 'Toma una foto y resuelve al instante';

  @override
  String get processingImage => 'Procesando imagen...';

  @override
  String get supportedFormats => 'Soporta: +, -, ×, ÷, x², √, ∫, fracciones';

  @override
  String get problemLabel => 'Problema';

  @override
  String get solvedByApp => 'Resuelto por Math Helper AI';

  @override
  String get aiConfiguration => 'Configuración IA';

  @override
  String get apiKeyLabel => 'Clave API';

  @override
  String get poweredByAI => 'Solucionador de matemáticas con IA paso a paso';

  @override
  String get apiConfigured => 'IA configurada';

  @override
  String get apiNotConfigured =>
      'Usando solucionador integrado. Añade API para soluciones completas.';

  @override
  String get apiSaved => 'Configuración API guardada';

  @override
  String get simpleDescription => 'Explicaciones breves y concisas';

  @override
  String get detailedDescription => 'Explicaciones detalladas con teoría';

  @override
  String get justNow => 'Ahora mismo';

  @override
  String minutesAgo(int count) {
    return 'hace $count min';
  }

  @override
  String hoursAgo(int count) {
    return 'hace $count h';
  }

  @override
  String daysAgo(int count) {
    return 'hace $count d';
  }

  @override
  String nSteps(int count) {
    return '$count pasos';
  }

  @override
  String get apiUrl => 'URL de la API';

  @override
  String get deleteConfirmTitle => 'Eliminar';

  @override
  String get solutionLabel => 'Solución';

  @override
  String get explainIn => 'Explicar en';

  @override
  String get autoDetect => 'Auto';

  @override
  String get edit => 'Editar';

  @override
  String get home => 'Inicio';

  @override
  String get notMathProblem =>
      'Esto no parece ser un problema matemático. Por favor, ingresa una expresión o ecuación matemática.';
}
