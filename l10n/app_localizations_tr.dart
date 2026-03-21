// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Matematik Yardımcısı AI';

  @override
  String get typeProblem => 'Problem yaz';

  @override
  String get scanProblem => 'Problem tara';

  @override
  String get history => 'Geçmiş';

  @override
  String get favorites => 'Favoriler';

  @override
  String get settings => 'Ayarlar';

  @override
  String get solve => 'Çöz';

  @override
  String get enterProblem => 'Matematik probleminizi girin...';

  @override
  String get solution => 'Çözüm';

  @override
  String get steps => 'Adımlar';

  @override
  String get explanation => 'Açıklama';

  @override
  String get tip => 'İpucu';

  @override
  String get copy => 'Kopyala';

  @override
  String get share => 'Paylaş';

  @override
  String get saveToFavorites => 'Favorilere ekle';

  @override
  String get removeFromFavorites => 'Favorilerden kaldır';

  @override
  String get language => 'Dil';

  @override
  String get difficulty => 'Zorluk';

  @override
  String get beginner => 'Başlangıç';

  @override
  String get intermediate => 'Orta';

  @override
  String get advanced => 'İleri';

  @override
  String get simple => 'Basit';

  @override
  String get detailed => 'Detaylı';

  @override
  String get explanationMode => 'Açıklama modu';

  @override
  String get noHistory => 'Henüz çözülen problem yok';

  @override
  String get noFavorites => 'Henüz favori kaydedilmedi';

  @override
  String get camera => 'Kamera';

  @override
  String get gallery => 'Galeri';

  @override
  String get scanInstruction => 'Kamerayı matematik problemine doğrultun';

  @override
  String get recognizedText => 'Tanınan metin';

  @override
  String get solveThis => 'Bunu çöz';

  @override
  String get solving => 'Çözülüyor...';

  @override
  String get error => 'Hata';

  @override
  String get tryAgain => 'Tekrar dene';

  @override
  String get problemSolved => 'Problem çözüldü!';

  @override
  String get step => 'Adım';

  @override
  String get searchProblems => 'Problem ara...';

  @override
  String get delete => 'Sil';

  @override
  String get clearHistory => 'Geçmişi temizle';

  @override
  String get clearHistoryConfirm =>
      'Tüm geçmişi silmek istediğinizden emin misiniz?';

  @override
  String get cancel => 'İptal';

  @override
  String get confirm => 'Onayla';

  @override
  String get copiedToClipboard => 'Panoya kopyalandı';

  @override
  String get savedToFavorites => 'Favorilere eklendi';

  @override
  String get removedFromFavorites => 'Favorilerden kaldırıldı';

  @override
  String get yourAIMathTutor => 'AI Matematik Öğretmeniniz';

  @override
  String get algebra => 'Cebir';

  @override
  String get calculus => 'Kalkülüs';

  @override
  String get geometry => 'Geometri';

  @override
  String get statistics => 'İstatistik';

  @override
  String get general => 'Genel';

  @override
  String get darkMode => 'Karanlık mod';

  @override
  String get about => 'Hakkında';

  @override
  String get version => 'Sürüm';

  @override
  String get appDescription =>
      'Matematik Yardımcısı AI kişisel matematik öğretmeninizdir. Herhangi bir problemi adım adım detaylı açıklamalarla çözün.';

  @override
  String get ocrNotAvailable => 'Bu cihazda OCR kullanılamıyor';

  @override
  String get cameraPermissionDenied => 'Kamera izni reddedildi';

  @override
  String get noTextRecognized => 'Metin tanınamadı. Lütfen tekrar deneyin.';

  @override
  String get selectImage => 'Resim seç';

  @override
  String get solved => 'Çözüldü';

  @override
  String get typeSubtitle => 'Herhangi bir matematik problemi yazın';

  @override
  String get scanSubtitle => 'Fotoğraf çekin ve anında çözün';

  @override
  String get processingImage => 'Resim işleniyor...';

  @override
  String get supportedFormats => 'Desteklenen: +, -, ×, ÷, x², √, ∫, kesirler';

  @override
  String get problemLabel => 'Problem';

  @override
  String get solvedByApp => 'Math Helper AI tarafından çözüldü';

  @override
  String get aiConfiguration => 'AI Yapılandırması';

  @override
  String get apiKeyLabel => 'API Anahtarı';

  @override
  String get poweredByAI =>
      'LongCat AI ile desteklenmektedir (günlük 500K ücretsiz token)';

  @override
  String get apiConfigured => 'AI yapılandırıldı';

  @override
  String get apiNotConfigured =>
      'Yerleşik çözücü kullanılıyor. Tam AI çözümleri için API ekleyin.';

  @override
  String get apiSaved => 'API yapılandırması kaydedildi';

  @override
  String get simpleDescription => 'Kısa ve öz açıklamalar';

  @override
  String get detailedDescription => 'Teori içeren detaylı açıklamalar';

  @override
  String get justNow => 'Az önce';

  @override
  String minutesAgo(int count) {
    return '$count dk önce';
  }

  @override
  String hoursAgo(int count) {
    return '$count sa önce';
  }

  @override
  String daysAgo(int count) {
    return '$count gün önce';
  }

  @override
  String nSteps(int count) {
    return '$count adım';
  }

  @override
  String get apiUrl => 'API URL';

  @override
  String get deleteConfirmTitle => 'Sil';

  @override
  String get solutionLabel => 'Çözüm';
}
