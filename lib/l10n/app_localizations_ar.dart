// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'مساعد الرياضيات الذكي';

  @override
  String get typeProblem => 'اكتب المسألة';

  @override
  String get scanProblem => 'امسح المسألة';

  @override
  String get history => 'السجل';

  @override
  String get favorites => 'المفضلة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get solve => 'حل';

  @override
  String get enterProblem => 'أدخل مسألتك الرياضية...';

  @override
  String get solution => 'الحل';

  @override
  String get steps => 'الخطوات';

  @override
  String get explanation => 'الشرح';

  @override
  String get tip => 'نصيحة';

  @override
  String get copy => 'نسخ';

  @override
  String get share => 'مشاركة';

  @override
  String get saveToFavorites => 'حفظ في المفضلة';

  @override
  String get removeFromFavorites => 'إزالة من المفضلة';

  @override
  String get language => 'اللغة';

  @override
  String get difficulty => 'المستوى';

  @override
  String get beginner => 'مبتدئ';

  @override
  String get intermediate => 'متوسط';

  @override
  String get advanced => 'متقدم';

  @override
  String get simple => 'بسيط';

  @override
  String get detailed => 'مفصل';

  @override
  String get explanationMode => 'نمط الشرح';

  @override
  String get noHistory => 'لم يتم حل أي مسائل بعد';

  @override
  String get noFavorites => 'لا توجد مفضلات محفوظة';

  @override
  String get camera => 'الكاميرا';

  @override
  String get gallery => 'المعرض';

  @override
  String get scanInstruction => 'وجه الكاميرا نحو المسألة الرياضية';

  @override
  String get recognizedText => 'النص المعروف';

  @override
  String get solveThis => 'حل هذا';

  @override
  String get solving => 'جاري الحل...';

  @override
  String get error => 'خطأ';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get problemSolved => 'تم حل المسألة!';

  @override
  String get step => 'خطوة';

  @override
  String get searchProblems => 'البحث في المسائل...';

  @override
  String get delete => 'حذف';

  @override
  String get clearHistory => 'مسح السجل';

  @override
  String get clearHistoryConfirm => 'هل أنت متأكد من مسح كل السجل؟';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get copiedToClipboard => 'تم النسخ';

  @override
  String get savedToFavorites => 'تم الحفظ في المفضلة';

  @override
  String get removedFromFavorites => 'تمت الإزالة من المفضلة';

  @override
  String get yourAIMathTutor => 'معلم الرياضيات الذكي الخاص بك';

  @override
  String get algebra => 'الجبر';

  @override
  String get calculus => 'التفاضل والتكامل';

  @override
  String get geometry => 'الهندسة';

  @override
  String get statistics => 'الإحصاء';

  @override
  String get general => 'عام';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get about => 'حول';

  @override
  String get version => 'الإصدار';

  @override
  String get appDescription =>
      'مساعد الرياضيات الذكي هو معلمك الشخصي للرياضيات. حل أي مسألة رياضية خطوة بخطوة مع شرح مفصل.';

  @override
  String get ocrNotAvailable => 'التعرف الضوئي غير متاح على هذا الجهاز';

  @override
  String get cameraPermissionDenied => 'تم رفض إذن الكاميرا';

  @override
  String get noTextRecognized => 'لم يتم التعرف على أي نص. حاول مرة أخرى.';

  @override
  String get selectImage => 'اختر صورة';

  @override
  String get solved => 'تم الحل';

  @override
  String get typeSubtitle => 'اكتب أي مسألة رياضية بأي لغة';

  @override
  String get scanSubtitle => 'التقط صورة للمسألة وحلها فوراً';

  @override
  String get processingImage => 'جاري معالجة الصورة...';

  @override
  String get supportedFormats => 'يدعم: +، -، ×، ÷، x²، √، ∫، الكسور';

  @override
  String get problemLabel => 'المسألة';

  @override
  String get solvedByApp => 'تم الحل بواسطة مساعد الرياضيات الذكي';

  @override
  String get aiConfiguration => 'إعدادات الذكاء الاصطناعي';

  @override
  String get apiKeyLabel => 'مفتاح API';

  @override
  String get poweredByAI =>
      'حلّال رياضيات مدعوم بالذكاء الاصطناعي مع حلول خطوة بخطوة';

  @override
  String get apiConfigured => 'تم تكوين الذكاء الاصطناعي';

  @override
  String get apiNotConfigured => 'يستخدم الحل المدمج. أضف API للحلول الكاملة.';

  @override
  String get apiSaved => 'تم حفظ إعدادات API';

  @override
  String get simpleDescription => 'شرح موجز وبسيط';

  @override
  String get detailedDescription => 'شرح مفصل مع النظرية';

  @override
  String get justNow => 'الآن';

  @override
  String minutesAgo(int count) {
    return 'منذ $count د';
  }

  @override
  String hoursAgo(int count) {
    return 'منذ $count س';
  }

  @override
  String daysAgo(int count) {
    return 'منذ $count ي';
  }

  @override
  String nSteps(int count) {
    return '$count خطوات';
  }

  @override
  String get apiUrl => 'رابط API';

  @override
  String get deleteConfirmTitle => 'حذف';

  @override
  String get solutionLabel => 'الحل';

  @override
  String get explainIn => 'اشرح بـ';

  @override
  String get autoDetect => 'تلقائي';

  @override
  String get edit => 'تعديل';

  @override
  String get home => 'الرئيسية';

  @override
  String get notMathProblem =>
      'لا يبدو أن هذا مسألة رياضية. يرجى إدخال تعبير أو معادلة رياضية.';
}
