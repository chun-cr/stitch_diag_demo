// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '脉AI健康';

  @override
  String get appBrandPrefix => '脉 ';

  @override
  String get appBrandSuffix => ' 健康';

  @override
  String get authSeasonalTag => '春分 · 木旺';

  @override
  String get authInspectionMotto => '望 · 闻 · 问 · 切';

  @override
  String get authEmailOrPhoneLabel => '手机号 / 邮箱';

  @override
  String get authEmailOrPhoneHint => '请输入手机号或邮箱';

  @override
  String get authNameLabel => '姓名';

  @override
  String get authNameHint => '请输入你的姓名';

  @override
  String get authPasswordLabel => '密码';

  @override
  String get authPasswordHint => '请输入密码';

  @override
  String get authPasswordMin6 => '密码不能少于6位';

  @override
  String get authPasswordMin8 => '密码不少于8位';

  @override
  String get authConfirmPasswordLabel => '确认密码';

  @override
  String get authConfirmPasswordHint => '再次输入密码';

  @override
  String get authPasswordMismatch => '两次密码不一致';

  @override
  String get authForgotPassword => '忘记密码？';

  @override
  String get authLoginButton => '登录账号';

  @override
  String get authOtherMethods => '其他方式';

  @override
  String get authWechatLogin => '微信登录';

  @override
  String get authAppleLogin => 'Apple 登录';

  @override
  String get authNoAccount => '还没有账号？';

  @override
  String get authRegisterNow => '立即注册';

  @override
  String get authFeatureFaceScan => '面部扫描';

  @override
  String get authFeatureTongueAnalysis => '舌象分析';

  @override
  String get authFeatureAiDiagnosis => 'AI 诊断';

  @override
  String get registerGoLogin => '去登录';

  @override
  String get registerStepBasicInfo => '基本信息';

  @override
  String get registerStepSetPassword => '设置密码';

  @override
  String get registerCreateAccountTitle => '创建你的账号';

  @override
  String get registerCreateAccountSubtitle => '填写基本信息，开启你的健康之旅';

  @override
  String get registerSetPasswordTitle => '设置登录密码';

  @override
  String get registerSetPasswordSubtitle => '设置一个安全密码保护你的健康数据';

  @override
  String get registerGenderOptional => '性别（可选）';

  @override
  String get registerGenderMale => '男';

  @override
  String get registerGenderFemale => '女';

  @override
  String get registerGenderUndisclosed => '不透露';

  @override
  String get registerPasswordHint => '至少8位，包含字母和数字';

  @override
  String get registerNeedBasicInfo => '请填写姓名和手机号/邮箱';

  @override
  String get registerAgreeTermsFirst => '请先同意用户协议和隐私政策';

  @override
  String get registerNextStep => '下一步';

  @override
  String get registerComplete => '完成注册';

  @override
  String get registerThirdParty => '或使用第三方账号';

  @override
  String get registerWechat => '微信';

  @override
  String get registerReadAndAgree => '我已阅读并同意';

  @override
  String get registerUserAgreement => '《用户协议》';

  @override
  String get registerAnd => '和';

  @override
  String get registerPrivacyPolicy => '《隐私政策》';

  @override
  String get registerHealthDataClause => '，包括健康数据的收集与使用说明';

  @override
  String get registerPrivacyTip => '你的健康数据仅用于 AI 诊断分析，经过加密存储，不会用于商业用途或分享给第三方。';

  @override
  String get passwordStrengthWeak => '弱';

  @override
  String get passwordStrengthMedium => '中';

  @override
  String get passwordStrengthStrong => '强';

  @override
  String get passwordStrengthVeryStrong => '非常强';

  @override
  String get bottomNavHome => '首页';

  @override
  String get bottomNavScan => '扫描';

  @override
  String get bottomNavReport => '报告';

  @override
  String get bottomNavProfile => '我的';

  @override
  String get commonCancel => '取消';

  @override
  String get commonConfirm => '确认';

  @override
  String get commonSave => '保存';

  @override
  String get commonLoading => '加载中';

  @override
  String get commonViewAll => '查看全部';

  @override
  String get commonFeatureInDevelopment => '功能开发中';

  @override
  String get commonPleaseEnterName => '请输入姓名';

  @override
  String get unitTimes => '次';

  @override
  String get unitPoints => '分';

  @override
  String get unitStage => '阶段';

  @override
  String get statusUnlocked => '已解锁';

  @override
  String get statusLocked => '未解锁';

  @override
  String get actionUnlockNow => '立即解锁';

  @override
  String get historyReportTitle => '体质测评报告';

  @override
  String get historyPastReports => '过往报告';

  @override
  String get historyHealthTrend => '健康走势';

  @override
  String get historyHealthIndex => '健康指数';

  @override
  String get historyRiskTrend => '风险指数走势';

  @override
  String homeGreetingMorning(String name) {
    return '早安，$name';
  }

  @override
  String get homeGreetingQuestion => '今日气色如何？';

  @override
  String homeStatusSummary(String constitution, int days) {
    return '$constitution · 上次检测 $days天前';
  }

  @override
  String get homeSuggestion => '建议：多喝水，保持规律作息';

  @override
  String get homeQuickScanTitle => 'AI 望诊入口';

  @override
  String get homeQuickScanTag => '望·闻·问·切';

  @override
  String get homeQuickScanFaceTitle => '面部望诊';

  @override
  String get homeQuickScanFaceSub => '观气色';

  @override
  String get homeQuickScanTongueTitle => '舌象诊断';

  @override
  String get homeQuickScanTongueSub => '察舌苔';

  @override
  String get homeQuickScanPalmTitle => '手掌经络';

  @override
  String get homeQuickScanPalmSub => '看掌纹';

  @override
  String get homeFunctionNavTitle => '功能导航';

  @override
  String get homeFunctionConstitution => '体质分析';

  @override
  String get homeFunctionMeridianTherapy => '经络调理';

  @override
  String get homeFunctionDietAdvice => '饮食建议';

  @override
  String get homeFunctionMentalWellness => '精神养生';

  @override
  String get homeFunctionSeasonalCare => '四季保养';

  @override
  String get homeFunctionHistory => '历史记录';

  @override
  String get homeTodayCareTitle => '今日养生';

  @override
  String get homeTodayCareSeasonTag => '春分 · 木旺';

  @override
  String get homeTodayCareCount => '两则建议';

  @override
  String get homeTipDietTag => '饮食';

  @override
  String get homeTipDietWuxing => '土';

  @override
  String get homeTipDietBody => '今日节气宜食清淡，山药、百合有助于润肺健脾，适合气虚体质人群。';

  @override
  String get homeTipRoutineTag => '起居';

  @override
  String get homeTipRoutineWuxing => '水';

  @override
  String get homeTipRoutineBody => '子时（23:00 前）入睡有助于肝胆排毒，建议减少夜间屏幕使用时间。';

  @override
  String get homeCollapsedTitle => '脉 AI 健康';

  @override
  String get homeHealthScoreLabel => '健康分';

  @override
  String get homeBalancedConstitution => '平和体质';

  @override
  String get homeBalanceState => '阴阳较平衡';

  @override
  String get homeStartFullScan => '开始全套智能检测';

  @override
  String get homeLastReportInsight => '气虚偏颇 · 脾胃虚弱';

  @override
  String get homeLastReportSummary => '脾气亏虚，运化失健。面色偏黄，舌淡苔白，建议健脾益气，规律作息。';

  @override
  String get profileTitle => '我的';

  @override
  String get profileBadgeBalanced => '平和质';

  @override
  String get profileDisplayName => '小明';

  @override
  String get profileStatusStable => '今日状态平稳，宜守中养气';

  @override
  String get profileBalancedType => '平和体质';

  @override
  String get profileMetricConsultCount => '累计问诊';

  @override
  String get profileMetricHealthScore => '当前健康力';

  @override
  String get profileMetricConstitutionStages => '体质演变';

  @override
  String get profileSectionFoundation => '健康基底';

  @override
  String get profileHeight => '身高';

  @override
  String get profileWeight => '体重';

  @override
  String get profileInnateBase => '先天底色';

  @override
  String get profileInnateBaseValue => '脾胃偏虚家族倾向';

  @override
  String get profileInnateBaseNote => '父母均有脾胃虚弱史，先天底子偏向中气不足。';

  @override
  String get profileCurrentBias => '当前偏颇';

  @override
  String get profileCurrentBiasValue => '气虚夹湿';

  @override
  String get profileCurrentBiasNote => '近阶段偏颇主要集中在气虚与湿困，易受作息与饮食影响。';

  @override
  String get profileHealthScore30Days => '近30天健康分';

  @override
  String get profileHealthScoreTrendNote => '整体平稳，最近一周轻度波动。';

  @override
  String get profileSectionCabin => '我的调理舱';

  @override
  String get profileCabinAcupoints => '收藏穴位';

  @override
  String get profileCabinAcupointsValue => '足三里 · 气海 · 关元';

  @override
  String get profileCabinDiet => '专属食疗方';

  @override
  String get profileCabinDietValue => '山药薏仁粥 · 党参茯苓炖鸡';

  @override
  String get profileCabinFollowup => '复诊提醒';

  @override
  String get profileCabinFollowupValue => '距下次调理评估还有 3 天';

  @override
  String get profileSectionServices => '健康服务';

  @override
  String get profileMenuAccount => '账户与家人档案';

  @override
  String get profileMenuAccountSub => '个人资料、家人信息与健康档案';

  @override
  String get profileMenuReminder => '健康节气提醒';

  @override
  String get profileMenuReminderSub => '通知、作息与节气养护建议';

  @override
  String get profileMenuAdvisor => '联系专属健康顾问';

  @override
  String get profileMenuAdvisorSub => '调理疑问、复诊沟通与健康咨询';

  @override
  String get profileMenuLanguage => '语言设置';

  @override
  String get profileMenuLanguageSub => '切换应用显示语言';

  @override
  String get profileMenuAbout => '关于脉 AI';

  @override
  String get profileMenuAboutSub => '了解服务说明与当前版本 v1.0.0';

  @override
  String get profileLogout => '退出登录';

  @override
  String get localeSheetTitle => '选择语言';

  @override
  String get localeFollowSystem => '跟随系统';

  @override
  String get localeChineseSimplified => '简体中文';

  @override
  String get localeEnglish => 'English';

  @override
  String get localeJapanese => '日本語';

  @override
  String get localeKorean => '한국어';

  @override
  String get commonViewDetails => '查看详情';

  @override
  String get commonFiveElements => '五行';

  @override
  String get profileBmiNormal => '正常';

  @override
  String get scanStepFace => '面部';

  @override
  String get scanStepTongue => '舌头';

  @override
  String get scanStepPalm => '手掌';

  @override
  String get scanSkipThisStep => '跳过此步骤';

  @override
  String get scanProgressLabel => '扫描进度';

  @override
  String scanAnalyzingProgress(int progress) {
    return '分析中... $progress%';
  }

  @override
  String scanCameraPreviewUnsupported(String platform) {
    return '$platform 暂不支持相机预览。';
  }

  @override
  String get scanGuideHeaderTitle => 'AI 健康扫描';

  @override
  String get scanGuideHeroTitle => '三步望诊，辨识体质';

  @override
  String get scanGuideHeroSubtitle => '结合现代 AI 技术与传统中医望诊理论\n为您提供专属体质分析报告';

  @override
  String get scanGuideStep1Title => '面部扫描';

  @override
  String get scanGuideStep1Desc => '分析面色光泽与五官特征';

  @override
  String get scanGuideStep1Detail => '通过面部气色判断脏腑盛衰，观察神、色、形、态';

  @override
  String get scanGuideStep2Title => '舌头扫描';

  @override
  String get scanGuideStep2Desc => '观察舌质颜色与舌苔厚薄';

  @override
  String get scanGuideStep2Detail => '舌为心之苗，脾之外候，舌象反映气血津液盛衰';

  @override
  String get scanGuideStep3Title => '手掌扫描';

  @override
  String get scanGuideStep3Desc => '识别掌纹分布与局部气色';

  @override
  String get scanGuideStep3Detail => '手掌色泽与纹路折射经络气血的运行状态';

  @override
  String scanGuideStepLabel(int step, String title) {
    return '步骤 $step：$title';
  }

  @override
  String get scanGuideWarmPromptTitle => '温馨提示';

  @override
  String get scanGuideWarmPromptContent =>
      '请在自然光线充足处进行，扫描前清洁面部，取下帽子、眼镜等饰品，保持放松自然状态';

  @override
  String get scanGuideEstimate => '预计 2 分钟完成 · 请在光线充足处进行';

  @override
  String get scanGuideStartButton => '开始扫描';

  @override
  String get scanGuidePrivacyNote => '扫描数据仅用于健康分析，不会上传至第三方';

  @override
  String get scanFaceDetectionPermissionRequired => '需要相机权限才能进行面部描点';

  @override
  String get scanCameraPermissionRequired => '需要相机权限';

  @override
  String get scanKeepStill => '请保持不动';

  @override
  String get scanMoveLeft => '← 请向左移动';

  @override
  String get scanMoveRight => '→ 请向右移动';

  @override
  String get scanMoveUp => '↑ 请向上移动';

  @override
  String get scanMoveDown => '↓ 请向下移动';

  @override
  String get scanTipBrightLight => '光线充足';

  @override
  String get scanTipKeepSteady => '保持稳定';

  @override
  String get scanScanning => '扫描中…';

  @override
  String get scanFaceAlignInFrame => '请将面部对准框内';

  @override
  String get scanFaceDetectedReady => '面部已就位 ✓';

  @override
  String get scanFaceTitle => '面部望诊';

  @override
  String get scanFaceTag => '面诊';

  @override
  String get scanFaceSubtitle => '将面部置于椭圆框内，保持正视，自然放松表情';

  @override
  String get scanFaceDetail => '通过面部气色判断脏腑盛衰，观察神、色、形、态';

  @override
  String get scanFaceTipNoMakeup => '不要化妆';

  @override
  String get scanFaceTipLookForward => '正视前方';

  @override
  String get scanFaceStartButton => '开始面部扫描';

  @override
  String get scanTongueCompleted => '舌象扫描完成 ✓';

  @override
  String get scanTongueTapToStart => '点击下方按钮开始扫描';

  @override
  String get scanTongueDetectedHold => '已识别舌头，请保持 2 秒';

  @override
  String get scanTongueMouthDetected => '已检测口部，请自然伸舌';

  @override
  String get scanTongueAlignHint => '请伸出舌头，对准框内';

  @override
  String get scanTongueTitle => '舌象诊断';

  @override
  String get scanTongueTag => '舌诊';

  @override
  String get scanTongueSubtitle => '自然伸出舌头，舌面充分展开，保持 2 秒';

  @override
  String get scanTongueDetail => '舌为心之苗，脾之外候，舌象反映气血津液盛衰';

  @override
  String get scanTongueTipNoColoredFood => '勿食有色食物';

  @override
  String get scanTongueTipTongueFlat => '舌头平伸';

  @override
  String get scanTongueStartButton => '开始舌象扫描';

  @override
  String get scanTongueNextPalm => '下一步：手掌扫描';

  @override
  String get scanPalmMoveCloser => '手掌太远，请靠近一点';

  @override
  String get scanPalmMoveFarther => '手掌太近，请离远一点';

  @override
  String get scanPalmWaitingPermission => '等待权限';

  @override
  String get scanPalmCompleted => '手掌扫描完成 ✓';

  @override
  String get scanPalmReadyHold => '已识别伸直手掌，请保持 2 秒';

  @override
  String get scanPalmOpenDetectedStraighten => '已检测到张开手掌，请将手掌伸直';

  @override
  String scanPalmDetectedGesture(String gesture) {
    return '检测到：$gesture';
  }

  @override
  String get scanPalmStretchOpen => '请将手掌伸直并自然张开';

  @override
  String get scanPalmAlignHint => '请将手掌放入框内';

  @override
  String get scanGestureOpenPalm => '张开手掌';

  @override
  String get scanGestureClosedFist => '握拳';

  @override
  String get scanGestureVictory => '比耶';

  @override
  String get scanGestureThumbUp => '竖起拇指';

  @override
  String get scanGestureThumbDown => '拇指向下';

  @override
  String get scanGesturePointingUp => '食指向上';

  @override
  String get scanGestureILoveYou => '我爱你手势';

  @override
  String get scanPalmTitle => '手掌经络';

  @override
  String get scanPalmTag => '掌诊';

  @override
  String get scanPalmSubtitle => '将手掌自然伸向镜头，参考倾斜轮廓摆放，手指自然分开';

  @override
  String get scanPalmDetail => '观察手掌纹路、色泽、形态，推断五脏六腑之病理';

  @override
  String get scanPalmTipFlatten => '手掌展平';

  @override
  String get scanPalmViewingReportSoon => '即将查看报告';

  @override
  String get scanPalmHoldButton => '请伸直手掌并保持 2 秒';

  @override
  String get reportTabOverview => '总览';

  @override
  String get reportTabConstitution => '体质';

  @override
  String get reportTabTherapy => '调理';

  @override
  String get reportTabAdvice => '建议';

  @override
  String get reportHeaderCollapsedTitle => 'AI 健康报告';

  @override
  String get reportHeroMeta => '2025.03.14  ·  AI 四诊合参';

  @override
  String reportHeroTitle(String name) {
    return '$name的健康报告';
  }

  @override
  String get reportHeroSecondaryBias => '气虚偏颇';

  @override
  String get reportHeroSummary => '脾气亏虚，运化失健。面色偏黄，舌淡苔白。';

  @override
  String get reportHealthScoreLabel => '健康分';

  @override
  String get reportHealthStatus => '体质状况 良好';

  @override
  String get reportOverviewFaceDiagnosisDesc => '气色偏黄，神采尚可';

  @override
  String get reportOverviewTongueDiagnosisDesc => '舌淡苔白，略厚';

  @override
  String get reportOverviewPalmDiagnosisDesc => '掌纹细浅，气色平';

  @override
  String get reportOverviewDiagScoresTitle => '三诊评分';

  @override
  String get reportOverviewFeatureDetailsTitle => '体征详情';

  @override
  String get reportOverviewTongueTitle => '舌象';

  @override
  String get reportOverviewTongueImagePlaceholder => '舌象图片';

  @override
  String get reportOverviewTongueColorLabel => '舌色';

  @override
  String get reportOverviewTongueColorValue => '淡红';

  @override
  String get reportOverviewTongueCoatingLabel => '苔质';

  @override
  String get reportOverviewTongueCoatingValue => '白苔·略厚';

  @override
  String get reportOverviewTongueShapeLabel => '舌形';

  @override
  String get reportOverviewTongueShapeValue => '正常';

  @override
  String get reportOverviewWuxingTitle => '五行 · 木旺';

  @override
  String get reportOverviewDiagnosisSummaryTitle => '辨证摘要';

  @override
  String get reportOverviewDiagnosisSummaryBody =>
      '辨证：脾气亏虚，运化失健。面色偏黄，舌淡苔白，脉象细缓，气短乏力，食欲欠佳。证属脾虚气弱，兼有湿邪内阻。';

  @override
  String get reportOverviewDiagnosisTagSpleenWeak => '脾胃虚弱';

  @override
  String get reportOverviewModuleConstitutionTitle => '体质详解';

  @override
  String get reportOverviewModuleConstitutionSubtitle => '了解你的体质';

  @override
  String get reportOverviewModuleAcupointTitle => '辩证取穴';

  @override
  String get reportOverviewModuleAcupointSubtitle => '穴位调理方案';

  @override
  String get reportOverviewModuleDietTitle => '饮食建议';

  @override
  String get reportOverviewModuleDietSubtitle => '食补调养方案';

  @override
  String get reportOverviewModuleSeasonalTitle => '四季保养';

  @override
  String get reportOverviewModuleSeasonalSubtitle => '顺时养生';

  @override
  String get reportOverviewModuleNavTitle => '模块导航';

  @override
  String get reportOverviewScanMetaDisclaimer =>
      '本报告由 AI 四诊合参生成，仅供健康参考，不构成医疗诊断。如有不适请咨询专业医师。';

  @override
  String get reportConstitutionDetailTitle => '体质详解';

  @override
  String get reportConstitutionCoreConclusionLabel => '核心结论';

  @override
  String get reportConstitutionCoreConclusionValue => '主导偏颇体质：气虚质';

  @override
  String get reportConstitutionCoreConclusionBody =>
      '整体以平和质为基础，但伴有较明显的气虚倾向。雷达图中平和质与气虚质占比相对突出，说明体质底子尚可，但在劳累、饮食失调和作息紊乱时，更容易出现乏力、脾胃运化不足等表现。';

  @override
  String get reportConstitutionYangDeficiency => '阳虚质';

  @override
  String get reportConstitutionYinDeficiency => '阴虚质';

  @override
  String get reportConstitutionDampHeat => '湿热质';

  @override
  String get reportConstitutionBloodStasis => '血瘀质';

  @override
  String get reportConstitutionQiStagnation => '气郁质';

  @override
  String get reportConstitutionSpecial => '特禀质';

  @override
  String get reportCausalAnalysisTitle => '分析成因';

  @override
  String get reportCauseRoutine => '作息';

  @override
  String get reportCauseRoutineBody => '长期晚睡，子时未眠，伤及肝肾精气，导致气血生化不足。';

  @override
  String get reportCauseDiet => '饮食';

  @override
  String get reportCauseDietBody => '饮食偏凉，过食生冷，寒邪损伤脾阳，运化功能减退。';

  @override
  String get reportCauseEmotion => '情志';

  @override
  String get reportCauseEmotionBody => '思虑过度，忧思伤脾，气机郁结，运化失司。';

  @override
  String get reportCauseExercise => '运动';

  @override
  String get reportCauseExerciseBody => '久坐少动，气血运行不畅，中气渐虚。';

  @override
  String get reportDiseaseTendencyTitle => '易诱发的疾病';

  @override
  String get reportDiseaseSpleenWeak => '脾胃虚弱';

  @override
  String get reportDiseaseSpleenWeakBody => '消化不良、腹胀、便溏';

  @override
  String get reportDiseaseQiBloodDeficiency => '气血亏虚';

  @override
  String get reportDiseaseQiBloodDeficiencyBody => '头晕、乏力、面色萎黄';

  @override
  String get reportDiseaseLowImmunity => '免疫低下';

  @override
  String get reportDiseaseLowImmunityBody => '反复感冒、易疲劳';

  @override
  String get reportDiseaseEmotional => '情志疾患';

  @override
  String get reportDiseaseEmotionalBody => '焦虑、失眠、抑郁倾向';

  @override
  String get reportBadHabitsTitle => '不当的举动';

  @override
  String get reportBadHabitOverwork => '过度劳累';

  @override
  String get reportBadHabitOverworkBody => '耗气伤脾，加重气虚';

  @override
  String get reportBadHabitColdFood => '贪凉饮冷';

  @override
  String get reportBadHabitColdFoodBody => '寒邪伤阳，损伤脾胃';

  @override
  String get reportBadHabitLateSleep => '熬夜晚睡';

  @override
  String get reportBadHabitLateSleepBody => '阴气不得收敛，精气损耗';

  @override
  String get reportBadHabitDieting => '过度节食';

  @override
  String get reportBadHabitDietingBody => '气血生化无源，更伤中气';

  @override
  String get reportBadHabitBinge => '暴饮暴食';

  @override
  String get reportBadHabitBingeBody => '脾胃负担过重，运化失司';

  @override
  String get reportTherapyAcupointsTitle => '辩证取穴';

  @override
  String get reportTherapyAcupointsIntro =>
      '依据脾气亏虚证型，推荐以下穴位进行艾灸或按摩调理，每日10–15分钟。';

  @override
  String get reportTherapyAcuPointZusanli => '足三里';

  @override
  String get reportTherapyAcuPointZusanliLocation => '外膝眼下3寸，胫骨旁开1横指';

  @override
  String get reportTherapyAcuPointZusanliEffect => '健脾益胃、补益气血，为强壮要穴';

  @override
  String get reportTherapyAcuPointZusanliMeridian => '足阳明胃经';

  @override
  String get reportTherapyAcuPointPishu => '脾俞';

  @override
  String get reportTherapyAcuPointPishuLocation => '第11胸椎棘突下旁开1.5寸';

  @override
  String get reportTherapyAcuPointPishuEffect => '健脾化湿、益气补虚，调节脾胃功能';

  @override
  String get reportTherapyAcuPointPishuMeridian => '足太阳膀胱经';

  @override
  String get reportTherapyAcuPointQihai => '气海';

  @override
  String get reportTherapyAcuPointQihaiLocation => '脐下1.5寸，腹正中线上';

  @override
  String get reportTherapyAcuPointQihaiEffect => '补益元气、温阳固本，改善气虚乏力';

  @override
  String get reportTherapyAcuPointQihaiMeridian => '任脉';

  @override
  String get reportTherapyAcuPointGuanyuan => '关元';

  @override
  String get reportTherapyAcuPointGuanyuanLocation => '脐下3寸，腹正中线上';

  @override
  String get reportTherapyAcuPointGuanyuanEffect => '培元固本、温阳益气，增强体质';

  @override
  String get reportTherapyAcuPointGuanyuanMeridian => '任脉';

  @override
  String get reportTherapyAcupointsWarning =>
      '孕妇、皮肤破损处及月经期间请避免艾灸。操作时注意火候，防止烫伤。';

  @override
  String get reportMentalWellnessTitle => '精神养生';

  @override
  String get reportMentalTipCalm => '恬淡虚无';

  @override
  String get reportMentalTipCalmBody => '减少过度思虑，保持心神宁静。中医认为“思伤脾”，思虑过度最易损耗脾气。';

  @override
  String get reportMentalTipNature => '顺应自然';

  @override
  String get reportMentalTipNatureBody => '作息顺应昼夜节律，子时前入睡以养肝气，卯时舒展筋骨以助阳气升发。';

  @override
  String get reportMentalTipEmotion => '调畅情志';

  @override
  String get reportMentalTipEmotionBody => '保持乐观豁达，避免情绪大起大落。适度倾诉，疏导郁结气机。';

  @override
  String get reportMentalTipMeditation => '静坐冥想';

  @override
  String get reportMentalTipMeditationBody => '每日静坐10分钟，专注呼吸，有助于调节脾胃气机，增强正气。';

  @override
  String get reportSeasonalCareTitle => '四季保养';

  @override
  String get reportSeasonSpring => '春';

  @override
  String get reportSeasonSpringAdvice => '春季养肝，适当增酸。多食韭菜、菠菜，舒展筋骨，早起散步以助阳气升发。';

  @override
  String get reportSeasonSpringAvoid => '避免过度疲劳，勿食过于辛散之品';

  @override
  String get reportSeasonSummer => '夏';

  @override
  String get reportSeasonSummerAdvice => '夏季养心，注意清热。适当食用莲子、薏仁，午间小憩，避免大汗伤气。';

  @override
  String get reportSeasonSummerAvoid => '忌贪凉饮冷，忌剧烈运动大汗';

  @override
  String get reportSeasonAutumn => '秋';

  @override
  String get reportSeasonAutumnAdvice => '秋季养肺，以润为主。多食梨、百合、银耳，早睡早起，收敛精气。';

  @override
  String get reportSeasonAutumnAvoid => '忌过度悲忧，忌食辛辣燥烈之品';

  @override
  String get reportSeasonWinter => '冬';

  @override
  String get reportSeasonWinterAdvice => '冬季养肾，以藏为要。适食黑芝麻、核桃、羊肉，早卧晚起，固护肾阳。';

  @override
  String get reportSeasonWinterAvoid => '忌过度劳累，忌大量出汗耗散阳气';

  @override
  String get reportAdviceTongueAnalysisTitle => '舌象详解';

  @override
  String get reportAdviceTongueScoreLabel => '舌象综合评分';

  @override
  String get reportAdviceTongueScoreSummary => '脾虚湿盛，气血偏弱';

  @override
  String get reportAdviceTongueFeatureColor => '舌色';

  @override
  String get reportAdviceTongueFeatureColorValue => '淡红';

  @override
  String get reportAdviceTongueFeatureColorDesc => '舌色淡红为正常，偏淡提示气血不足';

  @override
  String get reportAdviceTongueFeatureShape => '舌形';

  @override
  String get reportAdviceTongueFeatureShapeValue => '正常偏胖';

  @override
  String get reportAdviceTongueFeatureShapeDesc => '舌体偏胖伴有齿痕，提示脾虚湿盛';

  @override
  String get reportAdviceTongueFeatureCoatingColor => '苔色';

  @override
  String get reportAdviceTongueFeatureCoatingColorValue => '白苔';

  @override
  String get reportAdviceTongueFeatureCoatingColorDesc => '苔白主寒主表，提示阳气稍不足';

  @override
  String get reportAdviceTongueFeatureTexture => '苔质';

  @override
  String get reportAdviceTongueFeatureTextureValue => '厚腻';

  @override
  String get reportAdviceTongueFeatureTextureDesc => '苔厚腻提示湿邪较重，脾运不畅';

  @override
  String get reportAdviceTongueFeatureTeethMarks => '齿痕';

  @override
  String get reportAdviceTongueFeatureTeethMarksValue => '有';

  @override
  String get reportAdviceTongueFeatureTeethMarksDesc => '舌边齿痕为脾虚典型表现，气虚无力运化';

  @override
  String get reportAdviceDietTitle => '饮食建议';

  @override
  String get reportAdviceDietIntro => '脾气亏虚宜食甘温益气、健脾和胃之品，忌食寒凉生冷及难消化食物。';

  @override
  String get reportAdviceDietRecommendedTitle => '宜食';

  @override
  String get reportAdviceDietAvoidTitle => '忌食';

  @override
  String get reportAdviceDietRecipeTitle => '推荐食谱';

  @override
  String get reportAdviceDietRecipeBody =>
      '山药薏仁粥：山药50g、薏仁30g、红枣5颗同煮，早餐食用，健脾益气效果显著。\n\n党参茯苓炖鸡：补中益气，适合气虚体质日常调养。';

  @override
  String get reportAdviceFoodShanyao => '山药';

  @override
  String get reportAdviceFoodShanyaoDesc => '健脾益肾，补气养阴';

  @override
  String get reportAdviceFoodYiyiren => '薏仁';

  @override
  String get reportAdviceFoodYiyirenDesc => '利水渗湿，健脾止泻';

  @override
  String get reportAdviceFoodHongzao => '红枣';

  @override
  String get reportAdviceFoodHongzaoDesc => '补气血，健脾胃，安神';

  @override
  String get reportAdviceFoodBiandou => '白扁豆';

  @override
  String get reportAdviceFoodBiandouDesc => '健脾化湿，消暑除烦';

  @override
  String get reportAdviceFoodDangshen => '党参';

  @override
  String get reportAdviceFoodDangshenDesc => '补中益气，健脾养胃';

  @override
  String get reportAdviceFoodFuling => '茯苓';

  @override
  String get reportAdviceFoodFulingDesc => '健脾和中，利水渗湿';

  @override
  String get reportAdviceAvoidColdFood => '生冷食物';

  @override
  String get reportAdviceAvoidGreasy => '油腻厚味';

  @override
  String get reportAdviceAvoidSpicy => '辛辣刺激';

  @override
  String get reportAdviceAvoidSweet => '甜腻之品';

  @override
  String get reportAdviceAvoidAlcohol => '烟酒';

  @override
  String get reportAdviceProductsTitle => '相关产品推荐';

  @override
  String get reportAdviceProductsSubtitle => '依据体质个性化推荐';

  @override
  String get reportAdviceProductsDisclaimer =>
      '以上产品推荐基于体质分析结果，仅供参考。中成药的使用请在医师或药师指导下进行。';

  @override
  String get reportUnlockTitle => '解锁完整报告';

  @override
  String get reportUnlockDescription => '查看完整体质分析、调理方案与个性化建议。';

  @override
  String get reportUnlockButton => '解锁报告';

  @override
  String get reportUnlockSheetTitle => '解锁完整报告';

  @override
  String get reportUnlockSheetBody => '解锁后可查看体质详解、调理方案和个性化建议的全部内容。';

  @override
  String get reportUnlockInvitationTag => '尊享深度健康解读';

  @override
  String get reportUnlockInvitationSubtitle =>
      '开启完整报告后，可继续查看更细致的体质洞察、调理路径与个性化养护建议。';

  @override
  String get reportUnlockBenefitConstitution => '完整查看体质成因、风险倾向与深度解读';

  @override
  String get reportUnlockBenefitTherapy => '获得专属穴位方案、精神养生与四季调理建议';

  @override
  String get reportUnlockBenefitAdvice => '解锁舌象详解、饮食方向与相关产品推荐';

  @override
  String get reportUnlockSheetPrice => '模拟价格：¥29.90';

  @override
  String get reportUnlockSheetPriceFallback => 'App Store 价格加载中';

  @override
  String get reportUnlockSheetConfirm => '通过 Apple IAP 解锁';

  @override
  String get reportUnlockSheetPurchasing => '正在发起购买…';

  @override
  String get reportUnlockSheetRestoring => '正在恢复购买…';

  @override
  String get reportUnlockRestoreButton => '恢复购买';

  @override
  String get reportUnlockSheetStoreHint =>
      '通过 Apple App Store 安全支付，支持恢复非消耗型购买。';

  @override
  String get reportUnlockStatusStoreUnavailable => '当前无法连接 App Store，请联网后重试。';

  @override
  String get reportUnlockStatusProductUnavailable =>
      '暂未获取到可售商品，请检查商品 ID 或稍后重试。';

  @override
  String get reportUnlockStatusPurchaseFailed => '购买未完成，请稍后重试。';

  @override
  String get reportUnlockStatusPurchaseCancelled => '你已取消本次购买。';

  @override
  String get reportUnlockStatusRestoreNotFound => '未找到可恢复的购买记录。';

  @override
  String get reportUnlockStatusPurchasing => '等待 App Store 返回购买结果。';

  @override
  String get reportUnlockStatusRestoring => '正在从 App Store 恢复已购记录。';

  @override
  String get reportUnlockSheetMockHint => '当前为本地模拟购买流程，后续可替换为 Apple IAP。';

  @override
  String get reportUnlockCausalAnalysisTitle => '解锁成因深度分析';

  @override
  String get reportUnlockDiseaseTendencyTitle => '解锁疾病倾向预警';

  @override
  String get reportUnlockBadHabitsTitle => '解锁不当行为提示';

  @override
  String get reportUnlockAcupuncturePointsTitle => '解锁专属穴位方案';

  @override
  String get reportUnlockMentalWellnessTitle => '解锁精神养生建议';

  @override
  String get reportUnlockSeasonalCareTitle => '解锁四季养生方案';

  @override
  String get reportUnlockTongueAnalysisTitle => '解锁舌象详细解读';

  @override
  String get reportUnlockDietAdviceTitle => '解锁个性化饮食方案';

  @override
  String get reportPremiumConstitutionSubtitle => '查看体质成因、风险倾向与完整分析。';

  @override
  String get reportPremiumConstitutionPreview1 => '主偏向：气虚质';

  @override
  String get reportPremiumConstitutionPreview2 => '可解锁完整体质与风险趋势解读';

  @override
  String get reportPremiumTherapySubtitle => '查看专属穴位、精神养生与四季调理建议。';

  @override
  String get reportPremiumTherapyPreview1 => '推荐重点：足三里 · 气海';

  @override
  String get reportPremiumTherapyPreview2 => '可解锁完整调理路径与执行建议';

  @override
  String get reportPremiumAdviceSubtitle => '查看食疗方案、舌象详解与产品建议。';

  @override
  String get reportPremiumAdvicePreview1 => '饮食方向：健脾祛湿';

  @override
  String get reportPremiumAdvicePreview2 => '可解锁完整食疗、舌象与产品内容';

  @override
  String get reportProductJianpiwan => '健脾益气丸';

  @override
  String get reportProductJianpiwanType => '中成药';

  @override
  String get reportProductJianpiwanDesc => '补中益气，健脾和胃。适合气虚体质，改善乏力、食欲不振。';

  @override
  String get reportProductJianpiwanTag => '热销';

  @override
  String get reportProductShenling => '参苓白术散';

  @override
  String get reportProductShenlingType => '传统方剂';

  @override
  String get reportProductShenlingDesc => '健脾益气，渗湿止泻。主治脾气虚弱，食少便溏，体倦乏力。';

  @override
  String get reportProductShenlingTag => '经典';

  @override
  String get reportProductAijiu => '艾灸套装';

  @override
  String get reportProductAijiuType => '调理器具';

  @override
  String get reportProductAijiuDesc => '温和艾条配合取穴定位图，居家艾灸足三里、气海、关元。';

  @override
  String get reportProductAijiuTag => '推荐';

  @override
  String get reportProductFoodPack => '中医食疗食材包';

  @override
  String get reportProductFoodPackType => '养生食材';

  @override
  String get reportProductFoodPackDesc => '山药、薏仁、党参、茯苓、红枣精选组合，一周食疗方案。';

  @override
  String get reportProductFoodPackTag => '新品';

  @override
  String get reportWuxingWood => '木';

  @override
  String get reportWuxingFire => '火';

  @override
  String get reportWuxingEarth => '土';

  @override
  String get reportWuxingMetal => '金';

  @override
  String get reportWuxingWater => '水';

  @override
  String get reportAdviceProductDetailButton => '了解详情 >';

  @override
  String get metricFaceDiagnosis => '面诊';

  @override
  String get metricTongueDiagnosis => '舌诊';

  @override
  String get metricPalmDiagnosis => '掌诊';

  @override
  String get scanGuideTitle => 'AI 望诊入口';

  @override
  String get constitutionBalanced => '平和质';

  @override
  String get constitutionQiDeficiency => '气虚质';

  @override
  String get constitutionDampness => '痰湿质';

  @override
  String get riskSpleenStomach => '脾胃';

  @override
  String get riskQiDeficiency => '气虚';

  @override
  String get riskDampness => '湿困';

  @override
  String daysAgo(int days) {
    return '$days天前';
  }

  @override
  String scoreWithUnit(num score) {
    return '$score分';
  }

  @override
  String percentValue(num value) {
    return '$value%';
  }

  @override
  String get reportConstitutionPhlegmDampness => '痰湿质';

  @override
  String get reportConstitutionInheritedSpecial => '特禀质';

  @override
  String get reportConstitutionCausalTitle => '分析成因';

  @override
  String get reportConstitutionCauseRoutineTitle => '作息';

  @override
  String get reportConstitutionCauseRoutineDesc => '长期晚睡，子时未眠，伤及肝肾精气，导致气血生化不足。';

  @override
  String get reportConstitutionCauseDietTitle => '饮食';

  @override
  String get reportConstitutionCauseDietDesc => '饮食偏凉，过食生冷，寒邪损伤脾阳，运化功能减退。';

  @override
  String get reportConstitutionCauseEmotionTitle => '情志';

  @override
  String get reportConstitutionCauseEmotionDesc => '思虑过度，忧思伤脾，气机郁结，运化失司。';

  @override
  String get reportConstitutionCauseExerciseTitle => '运动';

  @override
  String get reportConstitutionCauseExerciseDesc => '久坐少动，气血运行不畅，中气渐虚。';

  @override
  String get reportConstitutionDiseaseTitle => '易诱发的疾病';

  @override
  String get reportConstitutionDiseaseSpleenWeakTitle => '脾胃虚弱';

  @override
  String get reportConstitutionDiseaseSpleenWeakDesc => '消化不良、腹胀、便溏';

  @override
  String get reportConstitutionDiseaseQiBloodTitle => '气血亏虚';

  @override
  String get reportConstitutionDiseaseQiBloodDesc => '头晕、乏力、面色萎黄';

  @override
  String get reportConstitutionDiseaseLowImmunityTitle => '免疫低下';

  @override
  String get reportConstitutionDiseaseLowImmunityDesc => '反复感冒、易疲劳';

  @override
  String get reportConstitutionDiseaseEmotionTitle => '情志疾患';

  @override
  String get reportConstitutionDiseaseEmotionDesc => '焦虑、失眠、抑郁倾向';

  @override
  String get reportConstitutionBadHabitsTitle => '不当的举动';

  @override
  String get reportConstitutionHabitOverworkTitle => '过度劳累';

  @override
  String get reportConstitutionHabitOverworkDesc => '耗气伤脾，加重气虚';

  @override
  String get reportConstitutionHabitColdFoodTitle => '贪凉饮冷';

  @override
  String get reportConstitutionHabitColdFoodDesc => '寒邪伤阳，损伤脾胃';

  @override
  String get reportConstitutionHabitLateSleepTitle => '熬夜晚睡';

  @override
  String get reportConstitutionHabitLateSleepDesc => '阴气不得收敛，精气损耗';

  @override
  String get reportConstitutionHabitDietingTitle => '过度节食';

  @override
  String get reportConstitutionHabitDietingDesc => '气血生化无源，更伤中气';

  @override
  String get reportConstitutionHabitBingeTitle => '暴饮暴食';

  @override
  String get reportConstitutionHabitBingeDesc => '脾胃负担过重，运化失司';

  @override
  String get reportTherapyAcupointTitle => '辩证取穴';

  @override
  String get reportTherapyAcupointIntro =>
      '依据脾气亏虚证型，推荐以下穴位进行艾灸或按摩调理，每日10–15分钟。';

  @override
  String get reportTherapyPointZusanliName => '足三里';

  @override
  String get reportTherapyPointZusanliLocation => '外膝眼下3寸，胫骨旁开1横指';

  @override
  String get reportTherapyPointZusanliEffect => '健脾益胃、补益气血，为强壮要穴';

  @override
  String get reportTherapyPointZusanliMeridian => '足阳明胃经';

  @override
  String get reportTherapyPointPishuName => '脾俞';

  @override
  String get reportTherapyPointPishuLocation => '第11胸椎棘突下旁开1.5寸';

  @override
  String get reportTherapyPointPishuEffect => '健脾化湿、益气补虚，调节脾胃功能';

  @override
  String get reportTherapyPointPishuMeridian => '足太阳膀胱经';

  @override
  String get reportTherapyPointQihaiName => '气海';

  @override
  String get reportTherapyPointQihaiLocation => '脐下1.5寸，腹正中线上';

  @override
  String get reportTherapyPointQihaiEffect => '补益元气、温阳固本，改善气虚乏力';

  @override
  String get reportTherapyPointQihaiMeridian => '任脉';

  @override
  String get reportTherapyPointGuanyuanName => '关元';

  @override
  String get reportTherapyPointGuanyuanLocation => '脐下3寸，腹正中线上';

  @override
  String get reportTherapyPointGuanyuanEffect => '培元固本、温阳益气，增强体质';

  @override
  String get reportTherapyPointGuanyuanMeridian => '任脉';

  @override
  String get reportTherapyAcupointWarning => '孕妇、皮肤破损处及月经期间请避免艾灸。操作时注意火候，防止烫伤。';

  @override
  String get reportTherapyMentalTitle => '精神养生';

  @override
  String get reportTherapyMentalCalmTitle => '恬淡虚无';

  @override
  String get reportTherapyMentalCalmDesc =>
      '减少过度思虑，保持心神宁静。中医认为“思伤脾”，思虑过度最易损耗脾气。';

  @override
  String get reportTherapyMentalNatureTitle => '顺应自然';

  @override
  String get reportTherapyMentalNatureDesc =>
      '作息顺应昼夜节律，子时前入睡以养肝气，卯时舒展筋骨以助阳气升发。';

  @override
  String get reportTherapyMentalEmotionTitle => '调畅情志';

  @override
  String get reportTherapyMentalEmotionDesc => '保持乐观豁达，避免情绪大起大落。适度倾诉，疏导郁结气机。';

  @override
  String get reportTherapyMentalMeditationTitle => '静坐冥想';

  @override
  String get reportTherapyMentalMeditationDesc =>
      '每日静坐10分钟，专注呼吸，有助于调节脾胃气机，增强正气。';

  @override
  String get reportTherapySeasonalTitle => '四季保养';

  @override
  String get reportTherapySeasonSpringName => '春';

  @override
  String get reportTherapySeasonSpringAdvice =>
      '春季养肝，适当增酸。多食韭菜、菠菜，舒展筋骨，早起散步以助阳气升发。';

  @override
  String get reportTherapySeasonSpringAvoid => '避免过度疲劳，勿食过于辛散之品';

  @override
  String get reportTherapySeasonSummerName => '夏';

  @override
  String get reportTherapySeasonSummerAdvice =>
      '夏季养心，注意清热。适当食用莲子、薏仁，午间小憩，避免大汗伤气。';

  @override
  String get reportTherapySeasonSummerAvoid => '忌贪凉饮冷，忌剧烈运动大汗';

  @override
  String get reportTherapySeasonAutumnName => '秋';

  @override
  String get reportTherapySeasonAutumnAdvice =>
      '秋季养肺，以润为主。多食梨、百合、银耳，早睡早起，收敛精气。';

  @override
  String get reportTherapySeasonAutumnAvoid => '忌过度悲忧，忌食辛辣燥烈之品';

  @override
  String get reportTherapySeasonWinterName => '冬';

  @override
  String get reportTherapySeasonWinterAdvice =>
      '冬季养肾，以藏为要。适食黑芝麻、核桃、羊肉，早卧晚起，固护肾阳。';

  @override
  String get reportTherapySeasonWinterAvoid => '忌过度劳累，忌大量出汗耗散阳气';

  @override
  String get reportAdviceTongueFeatureColorLabel => '舌色';

  @override
  String get reportAdviceTongueFeatureShapeLabel => '舌形';

  @override
  String get reportAdviceTongueFeatureCoatingColorLabel => '苔色';

  @override
  String get reportAdviceTongueFeatureCoatingTextureLabel => '苔质';

  @override
  String get reportAdviceTongueFeatureCoatingTextureValue => '厚腻';

  @override
  String get reportAdviceTongueFeatureCoatingTextureDesc => '苔厚腻提示湿邪较重，脾运不畅';

  @override
  String get reportAdviceTongueFeatureTeethMarksLabel => '齿痕';

  @override
  String get reportAdviceDietRecommendedLabel => '宜食';

  @override
  String get reportAdviceDietFoodYamName => '山药';

  @override
  String get reportAdviceDietFoodYamDesc => '健脾益肾，补气养阴';

  @override
  String get reportAdviceDietFoodCoixName => '薏仁';

  @override
  String get reportAdviceDietFoodCoixDesc => '利水渗湿，健脾止泻';

  @override
  String get reportAdviceDietFoodJujubeName => '红枣';

  @override
  String get reportAdviceDietFoodJujubeDesc => '补气血，健脾胃，安神';

  @override
  String get reportAdviceDietFoodLablabName => '白扁豆';

  @override
  String get reportAdviceDietFoodLablabDesc => '健脾化湿，消暑除烦';

  @override
  String get reportAdviceDietFoodCodonopsisName => '党参';

  @override
  String get reportAdviceDietFoodCodonopsisDesc => '补中益气，健脾养胃';

  @override
  String get reportAdviceDietFoodPoriaName => '茯苓';

  @override
  String get reportAdviceDietFoodPoriaDesc => '健脾和中，利水渗湿';

  @override
  String get reportAdviceDietAvoidLabel => '忌食';

  @override
  String get reportAdviceDietAvoidColdFoods => '生冷食物';

  @override
  String get reportAdviceDietAvoidGreasy => '油腻厚味';

  @override
  String get reportAdviceDietAvoidSpicy => '辛辣刺激';

  @override
  String get reportAdviceDietAvoidSweetRich => '甜腻之品';

  @override
  String get reportAdviceDietAvoidAlcoholTobacco => '烟酒';

  @override
  String get reportAdviceProductTitle => '相关产品推荐';

  @override
  String get reportAdviceProductSubtitle => '依据体质个性化推荐';

  @override
  String get reportAdviceProductOneName => '健脾益气丸';

  @override
  String get reportAdviceProductOneType => '中成药';

  @override
  String get reportAdviceProductOneDesc => '补中益气，健脾和胃。适合气虚体质，改善乏力、食欲不振。';

  @override
  String get reportAdviceProductOneTag => '热销';

  @override
  String get reportAdviceProductTwoName => '参苓白术散';

  @override
  String get reportAdviceProductTwoType => '传统方剂';

  @override
  String get reportAdviceProductTwoDesc => '健脾益气，渗湿止泻。主治脾气虚弱，食少便溏，体倦乏力。';

  @override
  String get reportAdviceProductTwoTag => '经典';

  @override
  String get reportAdviceProductThreeName => '艾灸套装';

  @override
  String get reportAdviceProductThreeType => '调理器具';

  @override
  String get reportAdviceProductThreeDesc => '温和艾条配合取穴定位图，居家艾灸足三里、气海、关元。';

  @override
  String get reportAdviceProductThreeTag => '推荐';

  @override
  String get reportAdviceProductFourName => '中医食疗食材包';

  @override
  String get reportAdviceProductFourType => '养生食材';

  @override
  String get reportAdviceProductFourDesc => '山药、薏仁、党参、茯苓、红枣精选组合，一周食疗方案。';

  @override
  String get reportAdviceProductFourTag => '新品';

  @override
  String get reportAdviceProductDisclaimer =>
      '以上产品推荐基于体质分析结果，仅供参考。中成药的使用请在医师或药师指导下进行。';
}
