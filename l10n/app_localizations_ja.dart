// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '数学ヘルパー AI';

  @override
  String get typeProblem => '問題を入力';

  @override
  String get scanProblem => '問題をスキャン';

  @override
  String get history => '履歴';

  @override
  String get favorites => 'お気に入り';

  @override
  String get settings => '設定';

  @override
  String get solve => '解く';

  @override
  String get enterProblem => '数学の問題を入力してください...';

  @override
  String get solution => '解答';

  @override
  String get steps => '手順';

  @override
  String get explanation => '説明';

  @override
  String get tip => 'ヒント';

  @override
  String get copy => 'コピー';

  @override
  String get share => '共有';

  @override
  String get saveToFavorites => 'お気に入りに追加';

  @override
  String get removeFromFavorites => 'お気に入りから削除';

  @override
  String get language => '言語';

  @override
  String get difficulty => '難易度';

  @override
  String get beginner => '初級';

  @override
  String get intermediate => '中級';

  @override
  String get advanced => '上級';

  @override
  String get simple => 'シンプル';

  @override
  String get detailed => '詳細';

  @override
  String get explanationMode => '説明モード';

  @override
  String get noHistory => 'まだ解いた問題はありません';

  @override
  String get noFavorites => 'お気に入りはまだありません';

  @override
  String get camera => 'カメラ';

  @override
  String get gallery => 'ギャラリー';

  @override
  String get scanInstruction => '数学の問題にカメラを向けてください';

  @override
  String get recognizedText => '認識されたテキスト';

  @override
  String get solveThis => 'これを解く';

  @override
  String get solving => '解答中...';

  @override
  String get error => 'エラー';

  @override
  String get tryAgain => '再試行';

  @override
  String get problemSolved => '解決しました！';

  @override
  String get step => '手順';

  @override
  String get searchProblems => '問題を検索...';

  @override
  String get delete => '削除';

  @override
  String get clearHistory => '履歴を消去';

  @override
  String get clearHistoryConfirm => 'すべての履歴を消去しますか？';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => '確認';

  @override
  String get copiedToClipboard => 'クリップボードにコピーしました';

  @override
  String get savedToFavorites => 'お気に入りに追加しました';

  @override
  String get removedFromFavorites => 'お気に入りから削除しました';

  @override
  String get yourAIMathTutor => 'あなたのAI数学チューター';

  @override
  String get algebra => '代数';

  @override
  String get calculus => '微積分';

  @override
  String get geometry => '幾何学';

  @override
  String get statistics => '統計';

  @override
  String get general => '一般';

  @override
  String get darkMode => 'ダークモード';

  @override
  String get about => 'アプリについて';

  @override
  String get version => 'バージョン';

  @override
  String get appDescription =>
      '数学ヘルパーAIはあなたの個人的な数学チューターです。どんな問題も詳しい説明付きでステップバイステップで解決します。';

  @override
  String get ocrNotAvailable => 'このデバイスではOCRは利用できません';

  @override
  String get cameraPermissionDenied => 'カメラの許可が拒否されました';

  @override
  String get noTextRecognized => 'テキストが認識されませんでした。もう一度お試しください。';

  @override
  String get selectImage => '画像を選択';

  @override
  String get solved => '解決済み';

  @override
  String get typeSubtitle => '任意の数学の問題を入力してください';

  @override
  String get scanSubtitle => '写真を撮って即座に解決';

  @override
  String get processingImage => '画像を処理中...';

  @override
  String get supportedFormats => '対応: +, -, ×, ÷, x², √, ∫, 分数';

  @override
  String get problemLabel => '問題';

  @override
  String get solvedByApp => '数学ヘルパーAIが解決';

  @override
  String get aiConfiguration => 'AI設定';

  @override
  String get apiKeyLabel => 'APIキー';

  @override
  String get poweredByAI => 'LongCat AI搭載（1日50万トークン無料）';

  @override
  String get apiConfigured => 'AI設定済み';

  @override
  String get apiNotConfigured => '内蔵ソルバーを使用中。完全なAI解答にはAPIを追加してください。';

  @override
  String get apiSaved => 'API設定を保存しました';

  @override
  String get simpleDescription => '簡潔で分かりやすい説明';

  @override
  String get detailedDescription => '理論を含む詳細な説明';

  @override
  String get justNow => 'たった今';

  @override
  String minutesAgo(int count) {
    return '$count分前';
  }

  @override
  String hoursAgo(int count) {
    return '$count時間前';
  }

  @override
  String daysAgo(int count) {
    return '$count日前';
  }

  @override
  String nSteps(int count) {
    return '$countステップ';
  }

  @override
  String get apiUrl => 'API URL';

  @override
  String get deleteConfirmTitle => '削除';

  @override
  String get solutionLabel => '解答';
}
