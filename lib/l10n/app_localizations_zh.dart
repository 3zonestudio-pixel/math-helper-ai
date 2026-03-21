// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '数学助手 AI';

  @override
  String get typeProblem => '输入题目';

  @override
  String get scanProblem => '扫描题目';

  @override
  String get history => '历史记录';

  @override
  String get favorites => '收藏夹';

  @override
  String get settings => '设置';

  @override
  String get solve => '求解';

  @override
  String get enterProblem => '输入你的数学问题...';

  @override
  String get solution => '解答';

  @override
  String get steps => '步骤';

  @override
  String get explanation => '解释';

  @override
  String get tip => '提示';

  @override
  String get copy => '复制';

  @override
  String get share => '分享';

  @override
  String get saveToFavorites => '添加到收藏';

  @override
  String get removeFromFavorites => '从收藏中移除';

  @override
  String get language => '语言';

  @override
  String get difficulty => '难度';

  @override
  String get beginner => '初级';

  @override
  String get intermediate => '中级';

  @override
  String get advanced => '高级';

  @override
  String get simple => '简单';

  @override
  String get detailed => '详细';

  @override
  String get explanationMode => '解释模式';

  @override
  String get noHistory => '还没有解过的题目';

  @override
  String get noFavorites => '还没有收藏';

  @override
  String get camera => '相机';

  @override
  String get gallery => '相册';

  @override
  String get scanInstruction => '将相机对准数学题目';

  @override
  String get recognizedText => '识别文字';

  @override
  String get solveThis => '求解';

  @override
  String get solving => '求解中...';

  @override
  String get error => '错误';

  @override
  String get tryAgain => '重试';

  @override
  String get problemSolved => '已解决！';

  @override
  String get step => '步骤';

  @override
  String get searchProblems => '搜索题目...';

  @override
  String get delete => '删除';

  @override
  String get clearHistory => '清除历史';

  @override
  String get clearHistoryConfirm => '确定要清除所有历史记录吗？';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get copiedToClipboard => '已复制到剪贴板';

  @override
  String get savedToFavorites => '已添加到收藏';

  @override
  String get removedFromFavorites => '已从收藏中移除';

  @override
  String get yourAIMathTutor => '你的AI数学导师';

  @override
  String get algebra => '代数';

  @override
  String get calculus => '微积分';

  @override
  String get geometry => '几何';

  @override
  String get statistics => '统计';

  @override
  String get general => '通用';

  @override
  String get darkMode => '深色模式';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get appDescription => '数学助手AI是你的私人数学导师。逐步解决任何数学问题，附带详细解释。';

  @override
  String get ocrNotAvailable => '此设备不支持OCR';

  @override
  String get cameraPermissionDenied => '相机权限被拒绝';

  @override
  String get noTextRecognized => '未识别到文字，请重试。';

  @override
  String get selectImage => '选择图片';

  @override
  String get solved => '已解决';

  @override
  String get typeSubtitle => '输入任何数学问题';

  @override
  String get scanSubtitle => '拍照并立即求解';

  @override
  String get processingImage => '正在处理图片...';

  @override
  String get supportedFormats => '支持：+、-、×、÷、x²、√、∫、分数';

  @override
  String get problemLabel => '题目';

  @override
  String get solvedByApp => '由数学助手AI求解';

  @override
  String get aiConfiguration => 'AI配置';

  @override
  String get apiKeyLabel => 'API密钥';

  @override
  String get poweredByAI => 'AI驱动的数学求解器，提供智能分步解答';

  @override
  String get apiConfigured => 'AI已配置';

  @override
  String get apiNotConfigured => '使用内置求解器。添加API获取完整AI解答。';

  @override
  String get apiSaved => 'API配置已保存';

  @override
  String get simpleDescription => '简短扼要的解释';

  @override
  String get detailedDescription => '详细的解释附带理论';

  @override
  String get justNow => '刚刚';

  @override
  String minutesAgo(int count) {
    return '$count分钟前';
  }

  @override
  String hoursAgo(int count) {
    return '$count小时前';
  }

  @override
  String daysAgo(int count) {
    return '$count天前';
  }

  @override
  String nSteps(int count) {
    return '$count个步骤';
  }

  @override
  String get apiUrl => 'API地址';

  @override
  String get deleteConfirmTitle => '删除';

  @override
  String get solutionLabel => '解答';

  @override
  String get explainIn => '用以下语言解释';

  @override
  String get autoDetect => '自动';
}
