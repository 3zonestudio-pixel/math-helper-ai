// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '수학 도우미 AI';

  @override
  String get typeProblem => '문제 입력';

  @override
  String get scanProblem => '문제 스캔';

  @override
  String get history => '기록';

  @override
  String get favorites => '즐겨찾기';

  @override
  String get settings => '설정';

  @override
  String get solve => '풀기';

  @override
  String get enterProblem => '수학 문제를 입력하세요...';

  @override
  String get solution => '풀이';

  @override
  String get steps => '단계';

  @override
  String get explanation => '설명';

  @override
  String get tip => '팁';

  @override
  String get copy => '복사';

  @override
  String get share => '공유';

  @override
  String get saveToFavorites => '즐겨찾기에 추가';

  @override
  String get removeFromFavorites => '즐겨찾기에서 제거';

  @override
  String get language => '언어';

  @override
  String get difficulty => '난이도';

  @override
  String get beginner => '초급';

  @override
  String get intermediate => '중급';

  @override
  String get advanced => '고급';

  @override
  String get simple => '간단';

  @override
  String get detailed => '상세';

  @override
  String get explanationMode => '설명 모드';

  @override
  String get noHistory => '아직 풀은 문제가 없습니다';

  @override
  String get noFavorites => '저장된 즐겨찾기가 없습니다';

  @override
  String get camera => '카메라';

  @override
  String get gallery => '갤러리';

  @override
  String get scanInstruction => '수학 문제에 카메라를 맞추세요';

  @override
  String get recognizedText => '인식된 텍스트';

  @override
  String get solveThis => '이것을 풀기';

  @override
  String get solving => '풀이 중...';

  @override
  String get error => '오류';

  @override
  String get tryAgain => '다시 시도';

  @override
  String get problemSolved => '문제가 풀렸습니다!';

  @override
  String get step => '단계';

  @override
  String get searchProblems => '문제 검색...';

  @override
  String get delete => '삭제';

  @override
  String get clearHistory => '기록 삭제';

  @override
  String get clearHistoryConfirm => '모든 기록을 삭제하시겠습니까?';

  @override
  String get cancel => '취소';

  @override
  String get confirm => '확인';

  @override
  String get copiedToClipboard => '클립보드에 복사됨';

  @override
  String get savedToFavorites => '즐겨찾기에 추가됨';

  @override
  String get removedFromFavorites => '즐겨찾기에서 제거됨';

  @override
  String get yourAIMathTutor => '당신의 AI 수학 튜터';

  @override
  String get algebra => '대수학';

  @override
  String get calculus => '미적분';

  @override
  String get geometry => '기하학';

  @override
  String get statistics => '통계';

  @override
  String get general => '일반';

  @override
  String get darkMode => '다크 모드';

  @override
  String get about => '앱 정보';

  @override
  String get version => '버전';

  @override
  String get appDescription =>
      '수학 도우미 AI는 당신의 개인 수학 튜터입니다. 어떤 문제든 단계별로 상세한 설명과 함께 풀어드립니다.';

  @override
  String get ocrNotAvailable => '이 기기에서는 OCR을 사용할 수 없습니다';

  @override
  String get cameraPermissionDenied => '카메라 권한이 거부되었습니다';

  @override
  String get noTextRecognized => '텍스트가 인식되지 않았습니다. 다시 시도해주세요.';

  @override
  String get selectImage => '이미지 선택';

  @override
  String get solved => '풀이 완료';

  @override
  String get typeSubtitle => '수학 문제를 입력하세요';

  @override
  String get scanSubtitle => '사진을 찍고 즉시 풀기';

  @override
  String get processingImage => '이미지 처리 중...';

  @override
  String get supportedFormats => '지원: +, -, ×, ÷, x², √, ∫, 분수';

  @override
  String get problemLabel => '문제';

  @override
  String get solvedByApp => '수학 도우미 AI가 풀었습니다';

  @override
  String get aiConfiguration => 'AI 설정';

  @override
  String get apiKeyLabel => 'API 키';

  @override
  String get poweredByAI => 'LongCat AI 지원 (하루 50만 무료 토큰)';

  @override
  String get apiConfigured => 'AI 설정 완료';

  @override
  String get apiNotConfigured => '내장 솔버 사용 중. 완전한 AI 솔루션을 위해 API를 추가하세요.';

  @override
  String get apiSaved => 'API 설정 저장됨';

  @override
  String get simpleDescription => '간략하고 핵심적인 설명';

  @override
  String get detailedDescription => '이론이 포함된 상세한 설명';

  @override
  String get justNow => '방금';

  @override
  String minutesAgo(int count) {
    return '$count분 전';
  }

  @override
  String hoursAgo(int count) {
    return '$count시간 전';
  }

  @override
  String daysAgo(int count) {
    return '$count일 전';
  }

  @override
  String nSteps(int count) {
    return '$count단계';
  }

  @override
  String get apiUrl => 'API URL';

  @override
  String get deleteConfirmTitle => '삭제';

  @override
  String get solutionLabel => '풀이';
}
