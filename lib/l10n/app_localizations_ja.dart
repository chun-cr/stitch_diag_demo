// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '脈AI健康';

  @override
  String get appBrandPrefix => '脈 ';

  @override
  String get appBrandSuffix => ' 健康';

  @override
  String get authSeasonalTag => '春分・木旺';

  @override
  String get authInspectionMotto => '望・聞・問・切';

  @override
  String get authEmailOrPhoneLabel => '電話番号 / メール';

  @override
  String get authEmailOrPhoneHint => '電話番号またはメールを入力してください';

  @override
  String get authNameLabel => '氏名';

  @override
  String get authNameHint => 'お名前を入力してください';

  @override
  String get authPasswordLabel => 'パスワード';

  @override
  String get authPasswordHint => 'パスワードを入力してください';

  @override
  String get authPasswordMin6 => 'パスワードは6文字以上で入力してください';

  @override
  String get authPasswordMin8 => 'パスワードは8文字以上で入力してください';

  @override
  String get authConfirmPasswordLabel => 'パスワード確認';

  @override
  String get authConfirmPasswordHint => 'パスワードを再入力してください';

  @override
  String get authPasswordMismatch => 'パスワードが一致しません';

  @override
  String get authForgotPassword => 'パスワードをお忘れですか？';

  @override
  String get authLoginButton => 'ログイン';

  @override
  String get authOtherMethods => 'その他の方法';

  @override
  String get authWechatLogin => 'WeChat';

  @override
  String get authAppleLogin => 'Appleでサインイン';

  @override
  String get authNoAccount => 'アカウントをお持ちでないですか？';

  @override
  String get authRegisterNow => '今すぐ登録';

  @override
  String get authFeatureFaceScan => '顔診スキャン';

  @override
  String get authFeatureTongueAnalysis => '舌診分析';

  @override
  String get authFeatureAiDiagnosis => 'AI診断';

  @override
  String get registerGoLogin => 'ログインへ';

  @override
  String get registerStepBasicInfo => '基本情報';

  @override
  String get registerStepSetPassword => 'パスワード設定';

  @override
  String get registerCreateAccountTitle => 'アカウントを作成';

  @override
  String get registerCreateAccountSubtitle => '基本情報を入力して健康の旅を始めましょう';

  @override
  String get registerSetPasswordTitle => 'ログインパスワードを設定';

  @override
  String get registerSetPasswordSubtitle => '健康データを守るための安全なパスワードを設定してください';

  @override
  String get registerGenderOptional => '性別（任意）';

  @override
  String get registerGenderMale => '男性';

  @override
  String get registerGenderFemale => '女性';

  @override
  String get registerGenderUndisclosed => '回答しない';

  @override
  String get registerPasswordHint => '8文字以上で、英字と数字を含めてください';

  @override
  String get registerNeedBasicInfo => '氏名と電話番号またはメールを入力してください';

  @override
  String get registerAgreeTermsFirst => '先に利用規約とプライバシーポリシーに同意してください';

  @override
  String get registerNextStep => '次へ';

  @override
  String get registerComplete => '登録完了';

  @override
  String get registerThirdParty => 'または外部アカウントで続行';

  @override
  String get registerWechat => 'WeChat';

  @override
  String get registerReadAndAgree => '私は以下に同意します：';

  @override
  String get registerUserAgreement => '利用規約';

  @override
  String get registerAnd => 'および';

  @override
  String get registerPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get registerHealthDataClause => '（健康データの収集と利用に関する説明を含む）';

  @override
  String get registerPrivacyTip =>
      '健康データは AI 診断分析のみに使用され、暗号化して保存されます。商用利用や第三者共有は行いません。';

  @override
  String get passwordStrengthWeak => '弱い';

  @override
  String get passwordStrengthMedium => '普通';

  @override
  String get passwordStrengthStrong => '強い';

  @override
  String get passwordStrengthVeryStrong => '非常に強い';

  @override
  String get bottomNavHome => 'ホーム';

  @override
  String get bottomNavScan => 'スキャン';

  @override
  String get bottomNavReport => 'レポート';

  @override
  String get bottomNavProfile => 'プロフィール';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonConfirm => '確認';

  @override
  String get commonSave => '保存';

  @override
  String get commonLoading => '読み込み中';

  @override
  String get commonViewAll => 'すべて見る';

  @override
  String get commonFeatureInDevelopment => '機能は開発中です';

  @override
  String get commonPleaseEnterName => 'お名前を入力してください';

  @override
  String get unitTimes => '回';

  @override
  String get unitPoints => '点';

  @override
  String get unitStage => '段階';

  @override
  String get statusUnlocked => '解放済み';

  @override
  String get statusLocked => '未解放';

  @override
  String get actionUnlockNow => '今すぐ解放';

  @override
  String get historyReportTitle => '体質評価レポート';

  @override
  String get historyPastReports => '過去のレポート';

  @override
  String get historyHealthTrend => '健康推移';

  @override
  String get historyHealthIndex => '健康指数';

  @override
  String get historyRiskTrend => 'リスク指数推移';

  @override
  String homeGreetingMorning(String name) {
    return 'おはようございます、$nameさん';
  }

  @override
  String get homeGreetingQuestion => '今日の顔色はいかがですか？';

  @override
  String homeStatusSummary(String constitution, int days) {
    return '$constitution・前回のチェックは$days日前';
  }

  @override
  String get homeSuggestion => 'アドバイス：水分をしっかり取り、規則正しい生活を心がけましょう。';

  @override
  String get homeQuickScanTitle => 'AI望診チェック';

  @override
  String get homeQuickScanTag => '望・聞・問・切';

  @override
  String get homeQuickScanFaceTitle => '顔診チェック';

  @override
  String get homeQuickScanFaceSub => '顔色を確認';

  @override
  String get homeQuickScanTongueTitle => '舌象チェック';

  @override
  String get homeQuickScanTongueSub => '舌苔を確認';

  @override
  String get homeQuickScanPalmTitle => '掌紋チェック';

  @override
  String get homeQuickScanPalmSub => '掌紋を見る';

  @override
  String get homeFunctionNavTitle => '機能一覧';

  @override
  String get homeFunctionConstitution => '体質分析';

  @override
  String get homeFunctionMeridianTherapy => '経絡調理';

  @override
  String get homeFunctionDietAdvice => '食事提案';

  @override
  String get homeFunctionMentalWellness => '精神養生';

  @override
  String get homeFunctionSeasonalCare => '四季養生';

  @override
  String get homeFunctionHistory => '履歴一覧';

  @override
  String get homeTodayCareTitle => '本日の養生';

  @override
  String get homeTodayCareSeasonTag => '春分・木旺';

  @override
  String get homeTodayCareCount => 'おすすめ2件';

  @override
  String get homeTipDietTag => '食事';

  @override
  String get homeTipDietWuxing => '土';

  @override
  String get homeTipDietBody =>
      '本日の節気には、あっさりした食事がおすすめです。山薬や百合は肺を潤し、脾を助けるため、気虚傾向の方に向いています。';

  @override
  String get homeTipRoutineTag => '生活';

  @override
  String get homeTipRoutineWuxing => '水';

  @override
  String get homeTipRoutineBody =>
      '子の刻（23時前）までに眠ることで、肝胆の回復を助けます。夜の画面使用時間を減らすよう心がけましょう。';

  @override
  String get homeCollapsedTitle => '脈 AI 健康';

  @override
  String get homeHealthScoreLabel => '健康スコア';

  @override
  String get homeBalancedConstitution => '平和体質';

  @override
  String get homeBalanceState => '陰陽のバランスは比較的安定しています';

  @override
  String get homeStartFullScan => 'フルスマート診断を開始';

  @override
  String get homeLastReportInsight => '気虚傾向・脾胃虚弱';

  @override
  String get homeLastReportSummary =>
      '脾気が不足し、運化機能がやや低下しています。顔色はやや黄みがあり、舌は淡く白苔がみられます。脾気を補い、規則正しい生活を心がけましょう。';

  @override
  String get profileTitle => 'プロフィール';

  @override
  String get profileBadgeBalanced => '平和質';

  @override
  String get profileDisplayName => '小明';

  @override
  String get profileStatusStable => '本日の状態は安定しています。中庸を保つ養生を心がけましょう。';

  @override
  String get profileBalancedType => '平和体質';

  @override
  String get profileMetricConsultCount => '相談回数';

  @override
  String get profileMetricHealthScore => '現在の健康力';

  @override
  String get profileMetricConstitutionStages => '体質変化';

  @override
  String get profileSectionFoundation => '健康の土台';

  @override
  String get profileHeight => '身長';

  @override
  String get profileWeight => '体重';

  @override
  String get profileInnateBase => '先天的体質';

  @override
  String get profileInnateBaseValue => '脾胃虚弱の家族傾向';

  @override
  String get profileInnateBaseNote => '両親ともに脾胃虚弱の傾向があり、中気がやや弱い体質基盤が示唆されます。';

  @override
  String get profileCurrentBias => '現在の偏り';

  @override
  String get profileCurrentBiasValue => '気虚と湿の停滞';

  @override
  String get profileCurrentBiasNote => '最近は気虚と湿困の傾向が目立ち、睡眠や食事の影響を受けやすい状態です。';

  @override
  String get profileHealthScore30Days => '直近30日の健康スコア';

  @override
  String get profileHealthScoreTrendNote => '全体として安定しており、直近1週間は軽い変動があります。';

  @override
  String get profileSectionCabin => 'マイ養生ハブ';

  @override
  String get profileCabinAcupoints => '保存した経穴';

  @override
  String get profileCabinAcupointsValue => '足三里・気海・関元';

  @override
  String get profileCabinDiet => 'パーソナル食養生';

  @override
  String get profileCabinDietValue => '山薬とはと麦のお粥・党参と茯苓の鶏煮込み';

  @override
  String get profileCabinFollowup => '再評価リマインダー';

  @override
  String get profileCabinFollowupValue => '次回の調理評価まであと3日';

  @override
  String get profileSectionServices => '健康サポート';

  @override
  String get profileMenuAccount => 'アカウントと家族プロフィール';

  @override
  String get profileMenuAccountSub => '個人情報、家族情報、健康記録を管理します';

  @override
  String get profileMenuReminder => '季節の健康リマインダー';

  @override
  String get profileMenuReminderSub => '通知、生活リズム、季節養生の提案';

  @override
  String get profileMenuAdvisor => '専属アドバイザーに相談';

  @override
  String get profileMenuAdvisorSub => '養生相談、再診連絡、健康相談';

  @override
  String get profileMenuLanguage => '言語設定';

  @override
  String get profileMenuLanguageSub => 'アプリの表示言語を変更します';

  @override
  String get profileMenuAbout => '脈AIについて';

  @override
  String get profileMenuAboutSub => 'サービス案内と現在のバージョン v1.0.0';

  @override
  String get profileLogout => 'ログアウト';

  @override
  String get localeSheetTitle => '言語を選択';

  @override
  String get localeFollowSystem => 'システム設定に従う';

  @override
  String get localeChineseSimplified => '簡体字中国語';

  @override
  String get localeEnglish => 'English';

  @override
  String get localeJapanese => '日本語';

  @override
  String get localeKorean => '한국어';

  @override
  String get commonViewDetails => '詳細を見る';

  @override
  String get commonFiveElements => '五行';

  @override
  String get profileBmiNormal => '標準';

  @override
  String get scanStepFace => '顔';

  @override
  String get scanStepTongue => '舌';

  @override
  String get scanStepPalm => '手のひら';

  @override
  String get scanSkipThisStep => 'この手順をスキップ';

  @override
  String get scanProgressLabel => '進行状況';

  @override
  String scanAnalyzingProgress(int progress) {
    return '解析中 $progress%';
  }

  @override
  String scanCameraPreviewUnsupported(String platform) {
    return '$platform ではカメラプレビューにまだ対応していません。';
  }

  @override
  String get scanGuideHeaderTitle => '健康スキャンガイド';

  @override
  String get scanGuideHeroTitle => '3つのガイド付きスキャンを完了しましょう';

  @override
  String get scanGuideHeroSubtitle => '顔・舌・手のひらのスキャンを行い、AI健康レポートを生成します。';

  @override
  String get scanGuideStep1Title => '顔スキャン';

  @override
  String get scanGuideStep1Desc => '顔色と表情を確認します';

  @override
  String get scanGuideStep1Detail => '顔色、表情、全体的な顔の状態を確認します。';

  @override
  String get scanGuideStep2Title => '舌スキャン';

  @override
  String get scanGuideStep2Desc => '舌の色・形・苔を確認します';

  @override
  String get scanGuideStep2Detail => '舌の色、苔、形から体質傾向を確認します。';

  @override
  String get scanGuideStep3Title => '手のひらスキャン';

  @override
  String get scanGuideStep3Desc => '手相、色、手の状態を確認します';

  @override
  String get scanGuideStep3Detail => '手のひらの線、色、全体的な手の状態を確認します。';

  @override
  String scanGuideStepLabel(int step, String title) {
    return 'ステップ $step・$title';
  }

  @override
  String get scanGuideWarmPromptTitle => '開始前の注意';

  @override
  String get scanGuideWarmPromptContent =>
      '明るく安定した環境で行ってください。帽子や眼鏡、アクセサリーを外し、リラックスした状態で進めてください。';

  @override
  String get scanGuideEstimate => '約2分・明るい場所で行ってください';

  @override
  String get scanGuideStartButton => 'スキャン開始';

  @override
  String get scanGuidePrivacyNote => 'スキャン画像は今回の健康評価のみに使用され、第三者に共有されません。';

  @override
  String get scanFaceDetectionPermissionRequired => '顔検出にはカメラ権限が必要です。';

  @override
  String get scanCameraPermissionRequired => '続行するにはカメラ権限が必要です。';

  @override
  String get scanKeepStill => 'そのまま動かないでください';

  @override
  String get scanMoveLeft => '左へ移動してください';

  @override
  String get scanMoveRight => '右へ移動してください';

  @override
  String get scanMoveUp => '上へ移動してください';

  @override
  String get scanMoveDown => '下へ移動してください';

  @override
  String get scanTipBrightLight => '明るく均一な光で行ってください';

  @override
  String get scanTipKeepSteady => 'スキャン中は安定した姿勢を保ってください';

  @override
  String get scanScanning => 'スキャン中';

  @override
  String get scanFaceAlignInFrame => '顔をフレーム内に合わせてください';

  @override
  String get scanFaceDetectedReady => '顔を認識しました ✓';

  @override
  String get scanFaceTitle => '顔スキャン';

  @override
  String get scanFaceTag => '顔診';

  @override
  String get scanFaceSubtitle => '顔をフレーム内に入れ、正面を見て自然な表情を保ってください。';

  @override
  String get scanFaceDetail => '顔色、表情、全体的な顔の状態を確認します。';

  @override
  String get scanFaceTipNoMakeup => '濃いメイクは避けてください';

  @override
  String get scanFaceTipLookForward => '正面を見てください';

  @override
  String get scanFaceStartButton => '顔スキャン開始';

  @override
  String get scanTongueCompleted => '舌スキャン完了 ✓';

  @override
  String get scanTongueTapToStart => '下のボタンから舌スキャンを開始してください';

  @override
  String get scanTongueDetectedHold => '舌を認識しました。2秒間そのまま保ってください。';

  @override
  String get scanTongueMouthDetected => '口元を認識しました。自然に舌を出してください。';

  @override
  String get scanTongueAlignHint => '舌を出してフレーム内に合わせてください。';

  @override
  String get scanTongueTitle => '舌スキャン';

  @override
  String get scanTongueTag => '舌診';

  @override
  String get scanTongueSubtitle => '自然に舌を出し、平らに保って2秒ほど静止してください。';

  @override
  String get scanTongueDetail => '舌の色、苔、形から体質傾向を確認します。';

  @override
  String get scanTongueTipNoColoredFood => '色の強い食べ物は事前に避けてください';

  @override
  String get scanTongueTipTongueFlat => '舌をなるべく平らに保ってください';

  @override
  String get scanTongueStartButton => '舌スキャン開始';

  @override
  String get scanTongueNextPalm => '手のひらスキャンへ進む';

  @override
  String get scanPalmMoveCloser => '手のひらが遠すぎます。もう少し近づけてください。';

  @override
  String get scanPalmMoveFarther => '手のひらが近すぎます。少し離してください。';

  @override
  String get scanPalmWaitingPermission => 'カメラ権限を待機しています';

  @override
  String get scanPalmCompleted => '手のひらスキャン完了 ✓';

  @override
  String get scanPalmReadyHold => '手のひらを認識しました。2秒間そのまま保ってください。';

  @override
  String get scanPalmOpenDetectedStraighten => '開いた手を認識しました。手のひらをまっすぐにしてください。';

  @override
  String scanPalmDetectedGesture(String gesture) {
    return '認識したジェスチャー：$gesture';
  }

  @override
  String get scanPalmStretchOpen => '手のひらを自然に開いてまっすぐにしてください。';

  @override
  String get scanPalmAlignHint => '手のひらをフレーム内に合わせてください。';

  @override
  String get scanGestureOpenPalm => '手のひらを開く';

  @override
  String get scanGestureClosedFist => '握りこぶし';

  @override
  String get scanGestureVictory => 'ピース';

  @override
  String get scanGestureThumbUp => 'サムズアップ';

  @override
  String get scanGestureThumbDown => 'サムズダウン';

  @override
  String get scanGesturePointingUp => '人差し指を上に';

  @override
  String get scanGestureILoveYou => 'I Love You ジェスチャー';

  @override
  String get scanPalmTitle => '手のひらスキャン';

  @override
  String get scanPalmTag => '掌診';

  @override
  String get scanPalmSubtitle => '手のひらをカメラに向け、輪郭に合わせて自然に指を開いてください。';

  @override
  String get scanPalmDetail => '手のひらの線、色、全体的な状態を確認します。';

  @override
  String get scanPalmTipFlatten => '手のひらを平らに保ってください';

  @override
  String get scanPalmViewingReportSoon => 'レポートを開いています...';

  @override
  String get scanPalmHoldButton => '手のひらを2秒間キープ';

  @override
  String get reportTabOverview => '概要';

  @override
  String get reportTabConstitution => '体質';

  @override
  String get reportTabTherapy => 'ケア';

  @override
  String get reportTabAdvice => 'アドバイス';

  @override
  String get reportHeaderCollapsedTitle => 'AI健康レポート';

  @override
  String get reportHeroMeta => '2025.03.14 ・ AI四診評価';

  @override
  String reportHeroTitle(String name) {
    return '$nameさんの健康レポート';
  }

  @override
  String get reportHeroSecondaryBias => '気虚傾向';

  @override
  String get reportHeroSummary =>
      '脾気が不足し、運化機能がやや低下しています。顔色はやや黄みがあり、舌は淡く白苔がみられます。';

  @override
  String get reportHealthScoreLabel => '健康スコア';

  @override
  String get reportHealthStatus => '体質状態・良好';

  @override
  String get reportOverviewFaceDiagnosisDesc => '顔色はやや黄みがあり、気力はまずまずです';

  @override
  String get reportOverviewTongueDiagnosisDesc => '舌は淡く、やや厚い白苔がみられます';

  @override
  String get reportOverviewPalmDiagnosisDesc => '掌紋は細めで、掌色は比較的安定しています';

  @override
  String get reportOverviewDiagScoresTitle => '三診スコア';

  @override
  String get reportOverviewFeatureDetailsTitle => '所見の詳細';

  @override
  String get reportOverviewTongueTitle => '舌象';

  @override
  String get reportOverviewTongueImagePlaceholder => '舌象画像';

  @override
  String get reportOverviewTongueColorLabel => '舌色';

  @override
  String get reportOverviewTongueColorValue => '淡紅';

  @override
  String get reportOverviewTongueCoatingLabel => '苔質';

  @override
  String get reportOverviewTongueCoatingValue => '白苔・やや厚め';

  @override
  String get reportOverviewTongueShapeLabel => '舌形';

  @override
  String get reportOverviewTongueShapeValue => '正常';

  @override
  String get reportOverviewWuxingTitle => '五行・木旺';

  @override
  String get reportOverviewDiagnosisSummaryTitle => '弁証サマリー';

  @override
  String get reportOverviewDiagnosisSummaryBody =>
      '今回の所見は、脾気虚によって運化機能がやや低下している状態を示しています。顔色はやや黄みがあり、舌は淡く白苔がみられ、脈は細めでやや緩やかです。息切れ、疲れやすさ、食欲の低下が出やすく、脾気虚に湿が加わった傾向が考えられます。';

  @override
  String get reportOverviewDiagnosisTagSpleenWeak => '脾胃虚弱';

  @override
  String get reportOverviewModuleConstitutionTitle => '体質詳解';

  @override
  String get reportOverviewModuleConstitutionSubtitle => 'あなたの体質を確認します';

  @override
  String get reportOverviewModuleAcupointTitle => 'おすすめ経穴';

  @override
  String get reportOverviewModuleAcupointSubtitle => '経穴ケアプラン';

  @override
  String get reportOverviewModuleDietTitle => '食事提案';

  @override
  String get reportOverviewModuleDietSubtitle => '食養生の提案';

  @override
  String get reportOverviewModuleSeasonalTitle => '四季養生';

  @override
  String get reportOverviewModuleSeasonalSubtitle => '季節に合わせた養生';

  @override
  String get reportOverviewModuleNavTitle => '機能ガイド';

  @override
  String get reportOverviewScanMetaDisclaimer =>
      '本レポートは AI 四診評価に基づく健康参考情報であり、医療診断ではありません。必要に応じて専門医にご相談ください。';

  @override
  String get reportConstitutionDetailTitle => '体質詳解';

  @override
  String get reportConstitutionCoreConclusionLabel => '主な所見';

  @override
  String get reportConstitutionCoreConclusionValue => '主たる体質傾向：気虚質';

  @override
  String get reportConstitutionCoreConclusionBody =>
      '全体としては平和体質を土台にしつつ、気虚傾向が比較的はっきり見られます。レーダーチャートでは平和質と気虚質が目立っており、基礎体力は保たれている一方で、疲労や食事の乱れ、睡眠不足が続くと、倦怠感や脾胃の働きの低下が出やすい状態です。';

  @override
  String get reportConstitutionYangDeficiency => '陽虚質';

  @override
  String get reportConstitutionYinDeficiency => '陰虚質';

  @override
  String get reportConstitutionDampHeat => '湿熱質';

  @override
  String get reportConstitutionBloodStasis => '血瘀質';

  @override
  String get reportConstitutionQiStagnation => '気鬱質';

  @override
  String get reportConstitutionSpecial => '特稟質';

  @override
  String get reportCausalAnalysisTitle => '要因分析';

  @override
  String get reportCauseRoutine => '生活リズム';

  @override
  String get reportCauseRoutineBody =>
      '慢性的な夜更かしや深夜までの覚醒は、肝腎の精を損ない、気血の生成不足につながります。';

  @override
  String get reportCauseDiet => '食事';

  @override
  String get reportCauseDietBody => '冷たい物や生ものの摂り過ぎは脾陽を傷つけ、運化機能を低下させます。';

  @override
  String get reportCauseEmotion => '情緒';

  @override
  String get reportCauseEmotionBody => '考えすぎや心配のしすぎは脾を損ね、気機の巡りを滞らせ、運化を弱めます。';

  @override
  String get reportCauseExercise => '運動';

  @override
  String get reportCauseExerciseBody => '長時間の座位や運動不足は気血の巡りを鈍らせ、中気を徐々に弱めます。';

  @override
  String get reportDiseaseTendencyTitle => '起こりやすい不調';

  @override
  String get reportDiseaseSpleenWeak => '脾胃虚弱';

  @override
  String get reportDiseaseSpleenWeakBody => '消化不良、腹部膨満、軟便';

  @override
  String get reportDiseaseQiBloodDeficiency => '気血両虚';

  @override
  String get reportDiseaseQiBloodDeficiencyBody => 'めまい、倦怠感、顔色不良';

  @override
  String get reportDiseaseLowImmunity => '免疫低下';

  @override
  String get reportDiseaseLowImmunityBody => '風邪をひきやすい、疲れやすい';

  @override
  String get reportDiseaseEmotional => '情緒の不調';

  @override
  String get reportDiseaseEmotionalBody => '不安、不眠、気分の落ち込み傾向';

  @override
  String get reportBadHabitsTitle => '避けたい習慣';

  @override
  String get reportBadHabitOverwork => '過労';

  @override
  String get reportBadHabitOverworkBody => '気を消耗し、脾を傷つけ、気虚を悪化させます';

  @override
  String get reportBadHabitColdFood => '冷たい飲食の摂り過ぎ';

  @override
  String get reportBadHabitColdFoodBody => '寒邪が陽気を損ね、脾胃を弱らせます';

  @override
  String get reportBadHabitLateSleep => '夜更かし';

  @override
  String get reportBadHabitLateSleepBody => '陰が十分に収まらず、精気を消耗します';

  @override
  String get reportBadHabitDieting => '過度な食事制限';

  @override
  String get reportBadHabitDietingBody => '気血の生成源が不足し、中気をさらに弱めます';

  @override
  String get reportBadHabitBinge => '暴飲暴食';

  @override
  String get reportBadHabitBingeBody => '脾胃に負担をかけ、運化機能を乱します';

  @override
  String get reportTherapyAcupointsTitle => 'おすすめ経穴';

  @override
  String get reportTherapyAcupointsIntro =>
      '脾気虚の証に基づき、以下の経穴へのお灸または指圧をおすすめします。1日10〜15分を目安に行ってください。';

  @override
  String get reportTherapyAcuPointZusanli => '足三里';

  @override
  String get reportTherapyAcuPointZusanliLocation => '外膝眼の下3寸、脛骨の外側1横指';

  @override
  String get reportTherapyAcuPointZusanliEffect => '脾胃を整え、気血を補う代表的な強壮穴です';

  @override
  String get reportTherapyAcuPointZusanliMeridian => '足陽明胃経';

  @override
  String get reportTherapyAcuPointPishu => '脾兪';

  @override
  String get reportTherapyAcuPointPishuLocation => '第11胸椎棘突起下、外側1.5寸';

  @override
  String get reportTherapyAcuPointPishuEffect => '健脾化湿、補気作用があり、脾胃機能を整えます';

  @override
  String get reportTherapyAcuPointPishuMeridian => '足太陽膀胱経';

  @override
  String get reportTherapyAcuPointQihai => '気海';

  @override
  String get reportTherapyAcuPointQihaiLocation => 'へその下1.5寸、腹部正中線上';

  @override
  String get reportTherapyAcuPointQihaiEffect => '元気を補い、陽気を温め、気虚による疲労感を和らげます';

  @override
  String get reportTherapyAcuPointQihaiMeridian => '任脈';

  @override
  String get reportTherapyAcuPointGuanyuan => '関元';

  @override
  String get reportTherapyAcuPointGuanyuanLocation => 'へその下3寸、腹部正中線上';

  @override
  String get reportTherapyAcuPointGuanyuanEffect => '元を養い、陽気と気を補い、体質強化を助けます';

  @override
  String get reportTherapyAcuPointGuanyuanMeridian => '任脈';

  @override
  String get reportTherapyAcupointsWarning =>
      '妊娠中、皮膚損傷部位、生理期間中はお灸を避けてください。やけど防止のため温度管理にご注意ください。';

  @override
  String get reportMentalWellnessTitle => '精神養生';

  @override
  String get reportMentalTipCalm => '心を穏やかに保つ';

  @override
  String get reportMentalTipCalmBody =>
      '考えすぎを減らし、心を穏やかに保ちましょう。中医学では思い悩みすぎることが脾を損ない、脾気を消耗しやすいと考えられています。';

  @override
  String get reportMentalTipNature => '自然のリズムに合わせる';

  @override
  String get reportMentalTipNatureBody =>
      '昼夜のリズムに合わせて生活し、できるだけ日付が変わる前に眠り、朝は軽く体を動かして陽気の巡りを促しましょう。';

  @override
  String get reportMentalTipEmotion => '感情を整える';

  @override
  String get reportMentalTipEmotionBody =>
      '前向きな気持ちを保ち、感情の波を大きくしすぎないことが大切です。適度に気分転換を行い、気の滞りをため込まないようにしましょう。';

  @override
  String get reportMentalTipMeditation => '静坐瞑想';

  @override
  String get reportMentalTipMeditationBody =>
      '毎日10分ほど静かに座り、呼吸に意識を向けることで、脾胃の気機を整え、正気を支えます。';

  @override
  String get reportSeasonalCareTitle => '四季養生';

  @override
  String get reportSeasonSpring => '春';

  @override
  String get reportSeasonSpringAdvice =>
      '春は肝をいたわり、ほどよく酸味を取り入れましょう。ニラやほうれん草を食べ、体を伸ばし、朝の散歩で陽気の巡りを助けるのがおすすめです。';

  @override
  String get reportSeasonSpringAvoid => '過労や辛味の強い発散性の食べ物は控えましょう';

  @override
  String get reportSeasonSummer => '夏';

  @override
  String get reportSeasonSummerAdvice =>
      '夏は心を養い、熱をため込みすぎないことが大切です。蓮の実やはと麦を適度に取り入れ、昼に少し休み、汗をかきすぎないようにしましょう。';

  @override
  String get reportSeasonSummerAvoid => '冷たい飲食や激しい運動による大量発汗は避けましょう';

  @override
  String get reportSeasonAutumn => '秋';

  @override
  String get reportSeasonAutumnAdvice =>
      '秋は肺を潤すことを意識し、梨、百合、白きくらげなどを取り入れましょう。早寝早起きを心がけて精気を守ります。';

  @override
  String get reportSeasonAutumnAvoid => '悲しみすぎや辛く乾燥した食べ物は控えましょう';

  @override
  String get reportSeasonWinter => '冬';

  @override
  String get reportSeasonWinterAdvice =>
      '冬は腎を養い、エネルギーを蓄えることを重視します。黒ごま、くるみ、羊肉を適度に取り、早めに休み、少し遅めに起きて腎陽を守りましょう。';

  @override
  String get reportSeasonWinterAvoid => '過労や大量発汗で陽気を散らすことは避けましょう';

  @override
  String get reportAdviceTongueAnalysisTitle => '舌象詳解';

  @override
  String get reportAdviceTongueScoreLabel => '舌象総合スコア';

  @override
  String get reportAdviceTongueScoreSummary => '脾虚湿盛・気血やや不足';

  @override
  String get reportAdviceTongueFeatureColor => '舌色';

  @override
  String get reportAdviceTongueFeatureColorValue => '淡紅';

  @override
  String get reportAdviceTongueFeatureColorDesc =>
      '淡紅は概ね正常で、淡すぎる場合は気血不足を示すことがあります。';

  @override
  String get reportAdviceTongueFeatureShape => '舌形';

  @override
  String get reportAdviceTongueFeatureShapeValue => 'やや胖大';

  @override
  String get reportAdviceTongueFeatureShapeDesc =>
      'やや胖大で歯痕がある場合、脾虚と湿の停滞を示すことがあります。';

  @override
  String get reportAdviceTongueFeatureCoatingColor => '苔色';

  @override
  String get reportAdviceTongueFeatureCoatingColorValue => '白';

  @override
  String get reportAdviceTongueFeatureCoatingColorDesc =>
      '白苔は寒や表証傾向を示し、陽気不足の兆候となる場合があります。';

  @override
  String get reportAdviceTongueFeatureTexture => '苔質';

  @override
  String get reportAdviceTongueFeatureTextureValue => '厚くやや膩';

  @override
  String get reportAdviceTongueFeatureTextureDesc =>
      '厚く膩った苔は、湿がやや重く、脾の運化が弱いことを示します。';

  @override
  String get reportAdviceTongueFeatureTeethMarks => '歯痕';

  @override
  String get reportAdviceTongueFeatureTeethMarksValue => 'あり';

  @override
  String get reportAdviceTongueFeatureTeethMarksDesc =>
      '舌辺の歯痕は脾虚による運化力低下の典型所見です。';

  @override
  String get reportAdviceDietTitle => '食事提案';

  @override
  String get reportAdviceDietIntro =>
      '脾気虚には、脾を補って胃を整える、やや温性で補気作用のある食材が向いています。冷たい物、生もの、消化に負担のかかる食べ物は控えめにしましょう。';

  @override
  String get reportAdviceDietRecommendedTitle => 'おすすめ';

  @override
  String get reportAdviceDietAvoidTitle => '控えたいもの';

  @override
  String get reportAdviceDietRecipeTitle => 'おすすめレシピ';

  @override
  String get reportAdviceDietRecipeBody =>
      '山薬とはと麦のお粥：山薬50g、はと麦30g、なつめ5個を一緒に煮て朝食にすると、脾気をしっかり補えます。\n\n党参と茯苓の鶏煮込み：中気を補い、気虚体質の日常養生に適しています。';

  @override
  String get reportAdviceFoodShanyao => '山薬';

  @override
  String get reportAdviceFoodShanyaoDesc => '脾腎を補い、補気・養陰を助けます';

  @override
  String get reportAdviceFoodYiyiren => 'はと麦';

  @override
  String get reportAdviceFoodYiyirenDesc => '利湿し、脾を助け、下痢を和らげます';

  @override
  String get reportAdviceFoodHongzao => 'なつめ';

  @override
  String get reportAdviceFoodHongzaoDesc => '気血を補い、脾胃を整え、心を安定させます';

  @override
  String get reportAdviceFoodBiandou => '白扁豆';

  @override
  String get reportAdviceFoodBiandouDesc => '脾を助け、湿をさばき、夏のだるさを和らげます';

  @override
  String get reportAdviceFoodDangshen => '党参';

  @override
  String get reportAdviceFoodDangshenDesc => '中気を補い、脾胃を支えます';

  @override
  String get reportAdviceFoodFuling => '茯苓';

  @override
  String get reportAdviceFoodFulingDesc => '脾を助け、中を整え、湿をさばきます';

  @override
  String get reportAdviceAvoidColdFood => '冷たい食べ物';

  @override
  String get reportAdviceAvoidGreasy => '油っこい食べ物';

  @override
  String get reportAdviceAvoidSpicy => '刺激の強い辛味';

  @override
  String get reportAdviceAvoidSweet => '甘く重たい食べ物';

  @override
  String get reportAdviceAvoidAlcohol => '酒・たばこ';

  @override
  String get reportAdviceProductsTitle => 'おすすめ商品';

  @override
  String get reportAdviceProductsSubtitle => '体質に合わせたご提案';

  @override
  String get reportAdviceProductsDisclaimer =>
      'これらのおすすめは体質分析に基づく参考情報です。中成薬を使用する場合は、医師または薬剤師の指導のもとで行ってください。';

  @override
  String get reportUnlockTitle => 'レポート全体を解放';

  @override
  String get reportUnlockDescription => '体質分析、調理プラン、個別アドバイスの全文を確認できます。';

  @override
  String get reportUnlockButton => 'レポートを解放';

  @override
  String get reportUnlockSheetTitle => 'レポート全体を解放';

  @override
  String get reportUnlockSheetBody => '解放後は、体質の詳しい分析、調理プラン、個別アドバイスのすべてを確認できます。';

  @override
  String get reportUnlockInvitationTag => '上質な健康インサイト';

  @override
  String get reportUnlockInvitationSubtitle =>
      'レポート全体を解放すると、より深い体質の洞察、調理の道筋、個別の養生提案を続けて確認できます。';

  @override
  String get reportUnlockBenefitConstitution => '体質の原因、リスク傾向、詳しい解釈をまとめて確認できます';

  @override
  String get reportUnlockBenefitTherapy => '専用の経穴提案、精神養生、四季のケア提案を受け取れます';

  @override
  String get reportUnlockBenefitAdvice => '舌象の詳細解説、食養生の方向性、関連商品の提案を解放します';

  @override
  String get reportUnlockSheetPrice => '模擬価格：¥29.90';

  @override
  String get reportUnlockSheetPriceFallback => 'App Store の価格を読み込み中';

  @override
  String get reportUnlockSheetConfirm => 'Apple IAP で解放する';

  @override
  String get reportUnlockSheetPurchasing => '購入を開始しています…';

  @override
  String get reportUnlockSheetRestoring => '購入履歴を復元しています…';

  @override
  String get reportUnlockRestoreButton => '購入を復元';

  @override
  String get reportUnlockSheetStoreHint =>
      'Apple App Store の安全な決済を使用し、この非消耗型購入は復元に対応しています。';

  @override
  String get reportUnlockStatusStoreUnavailable =>
      '現在 App Store に接続できません。通信状態をご確認のうえ再度お試しください。';

  @override
  String get reportUnlockStatusProductUnavailable =>
      '購入可能な商品を取得できませんでした。商品 ID を確認するか、後でもう一度お試しください。';

  @override
  String get reportUnlockStatusPurchaseFailed =>
      '購入が完了しませんでした。時間をおいて再度お試しください。';

  @override
  String get reportUnlockStatusPurchaseCancelled => '今回の購入はキャンセルされました。';

  @override
  String get reportUnlockStatusRestoreNotFound =>
      'この Apple ID で復元できる購入は見つかりませんでした。';

  @override
  String get reportUnlockStatusPurchasing => 'App Store からの購入結果を待っています。';

  @override
  String get reportUnlockStatusRestoring => 'App Store から購入履歴を復元しています。';

  @override
  String get reportUnlockSheetMockHint =>
      '現在はローカルの模擬購入フローです。後で Apple IAP に置き換えできます。';

  @override
  String get reportUnlockCausalAnalysisTitle => '成因の深掘り分析を解放';

  @override
  String get reportUnlockDiseaseTendencyTitle => '疾患傾向アラートを解放';

  @override
  String get reportUnlockBadHabitsTitle => '望ましくない行動の注意点を解放';

  @override
  String get reportUnlockAcupuncturePointsTitle => '専用の経穴プランを解放';

  @override
  String get reportUnlockMentalWellnessTitle => '精神養生アドバイスを解放';

  @override
  String get reportUnlockSeasonalCareTitle => '四季の養生プランを解放';

  @override
  String get reportUnlockTongueAnalysisTitle => '舌象の詳細解説を解放';

  @override
  String get reportUnlockDietAdviceTitle => '個別の食養生プランを解放';

  @override
  String get reportPremiumConstitutionSubtitle => '体質の原因やリスク傾向を含む詳しい分析を確認できます。';

  @override
  String get reportPremiumConstitutionPreview1 => '主な傾向：気虚質';

  @override
  String get reportPremiumConstitutionPreview2 => '体質とリスク傾向の詳しい解釈を解放';

  @override
  String get reportPremiumTherapySubtitle => 'おすすめ経穴、精神養生、四季のケア提案を確認できます。';

  @override
  String get reportPremiumTherapyPreview1 => 'おすすめ重点：足三里・気海';

  @override
  String get reportPremiumTherapyPreview2 => '具体的なケア手順と実践提案を解放';

  @override
  String get reportPremiumAdviceSubtitle => '食養生、舌象詳解、関連商品の提案を確認できます。';

  @override
  String get reportPremiumAdvicePreview1 => '食養生の方向性：健脾祛湿';

  @override
  String get reportPremiumAdvicePreview2 => '食事・舌象・商品提案の全文を解放';

  @override
  String get reportProductJianpiwan => '健脾益気丸';

  @override
  String get reportProductJianpiwanType => '中成薬';

  @override
  String get reportProductJianpiwanDesc =>
      '中気を補い、脾を整え、胃を調和させます。疲れやすさや食欲低下を伴う気虚体質に適しています。';

  @override
  String get reportProductJianpiwanTag => '人気';

  @override
  String get reportProductShenling => '参苓白朮散';

  @override
  String get reportProductShenlingType => '伝統方剤';

  @override
  String get reportProductShenlingDesc =>
      '脾気を補い、湿をさばき、下痢を和らげます。脾虚による食欲低下、軟便、倦怠感に用いられます。';

  @override
  String get reportProductShenlingTag => '定番';

  @override
  String get reportProductAijiu => 'お灸セット';

  @override
  String get reportProductAijiuType => '養生器具';

  @override
  String get reportProductAijiuDesc => 'やさしい艾条と経穴ガイド付きで、足三里・気海・関元の家庭養生に適しています。';

  @override
  String get reportProductAijiuTag => 'おすすめ';

  @override
  String get reportProductFoodPack => '中医食養生セット';

  @override
  String get reportProductFoodPackType => '養生食材';

  @override
  String get reportProductFoodPackDesc =>
      '山薬、はと麦、党参、茯苓、なつめを組み合わせた1週間分の食養生セットです。';

  @override
  String get reportProductFoodPackTag => '新着';

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
  String get reportAdviceProductDetailButton => '詳細を見る >';

  @override
  String get metricFaceDiagnosis => '顔診';

  @override
  String get metricTongueDiagnosis => '舌診';

  @override
  String get metricPalmDiagnosis => '掌診';

  @override
  String get scanGuideTitle => 'AI健康スキャン';

  @override
  String get constitutionBalanced => '平和質';

  @override
  String get constitutionQiDeficiency => '気虚質';

  @override
  String get constitutionDampness => '痰湿質';

  @override
  String get riskSpleenStomach => '脾胃';

  @override
  String get riskQiDeficiency => '気虚';

  @override
  String get riskDampness => '湿困';

  @override
  String daysAgo(int days) {
    return '$days日前';
  }

  @override
  String scoreWithUnit(num score) {
    return '$score点';
  }

  @override
  String percentValue(num value) {
    return '$value%';
  }

  @override
  String get reportConstitutionPhlegmDampness => '痰湿質';

  @override
  String get reportConstitutionInheritedSpecial => '特稟質';

  @override
  String get reportConstitutionCausalTitle => '要因分析';

  @override
  String get reportConstitutionCauseRoutineTitle => '生活リズム';

  @override
  String get reportConstitutionCauseRoutineDesc =>
      '慢性的な夜更かしや深夜まで起きている習慣は、肝腎の精を損ない、気血の不足につながりやすくなります。';

  @override
  String get reportConstitutionCauseDietTitle => '食事';

  @override
  String get reportConstitutionCauseDietDesc =>
      '冷たい物や生ものを摂り過ぎると脾陽を傷つけ、消化吸収の働きが弱まりやすくなります。';

  @override
  String get reportConstitutionCauseEmotionTitle => '情緒';

  @override
  String get reportConstitutionCauseEmotionDesc =>
      '考えすぎや不安が続くと脾を損ない、気の巡りが滞って運化機能が弱まりやすくなります。';

  @override
  String get reportConstitutionCauseExerciseTitle => '運動';

  @override
  String get reportConstitutionCauseExerciseDesc =>
      '長時間座ったままでいたり運動不足が続いたりすると、気血の巡りが鈍くなり、中気が徐々に弱まりやすくなります。';

  @override
  String get reportConstitutionDiseaseTitle => '起こりやすい不調';

  @override
  String get reportConstitutionDiseaseSpleenWeakTitle => '脾胃虚弱';

  @override
  String get reportConstitutionDiseaseSpleenWeakDesc => '消化不良、腹部膨満、軟便';

  @override
  String get reportConstitutionDiseaseQiBloodTitle => '気血両虚';

  @override
  String get reportConstitutionDiseaseQiBloodDesc => 'めまい、倦怠感、顔色不良';

  @override
  String get reportConstitutionDiseaseLowImmunityTitle => '免疫低下';

  @override
  String get reportConstitutionDiseaseLowImmunityDesc => '風邪をひきやすい、疲れやすい';

  @override
  String get reportConstitutionDiseaseEmotionTitle => '情緒の不調';

  @override
  String get reportConstitutionDiseaseEmotionDesc => '不安、不眠、気分の落ち込み傾向';

  @override
  String get reportConstitutionBadHabitsTitle => '避けたい習慣';

  @override
  String get reportConstitutionHabitOverworkTitle => '過労';

  @override
  String get reportConstitutionHabitOverworkDesc => '気を消耗し、脾を傷つけ、気虚を悪化させます';

  @override
  String get reportConstitutionHabitColdFoodTitle => '冷たい飲食の摂り過ぎ';

  @override
  String get reportConstitutionHabitColdFoodDesc => '寒邪が陽気を損ね、脾胃を弱らせます';

  @override
  String get reportConstitutionHabitLateSleepTitle => '夜更かし';

  @override
  String get reportConstitutionHabitLateSleepDesc => '陰が十分に収まらず、精気を消耗します';

  @override
  String get reportConstitutionHabitDietingTitle => '過度な食事制限';

  @override
  String get reportConstitutionHabitDietingDesc => '気血の生成源が不足し、中気をさらに弱めます';

  @override
  String get reportConstitutionHabitBingeTitle => '暴飲暴食';

  @override
  String get reportConstitutionHabitBingeDesc => '脾胃に負担をかけ、運化機能を乱します';

  @override
  String get reportTherapyAcupointTitle => 'おすすめ経穴';

  @override
  String get reportTherapyAcupointIntro =>
      '脾気虚の証に基づき、以下の経穴へのお灸または指圧をおすすめします。1日10〜15分を目安に行ってください。';

  @override
  String get reportTherapyPointZusanliName => '足三里';

  @override
  String get reportTherapyPointZusanliLocation => '外膝眼の下3寸、脛骨の外側1横指';

  @override
  String get reportTherapyPointZusanliEffect => '脾胃を整え、気血を補う代表的な強壮穴です';

  @override
  String get reportTherapyPointZusanliMeridian => '足陽明胃経';

  @override
  String get reportTherapyPointPishuName => '脾兪';

  @override
  String get reportTherapyPointPishuLocation => '第11胸椎棘突起下、外側1.5寸';

  @override
  String get reportTherapyPointPishuEffect => '健脾化湿、補気作用があり、脾胃機能を整えます';

  @override
  String get reportTherapyPointPishuMeridian => '足太陽膀胱経';

  @override
  String get reportTherapyPointQihaiName => '気海';

  @override
  String get reportTherapyPointQihaiLocation => 'へその下1.5寸、腹部正中線上';

  @override
  String get reportTherapyPointQihaiEffect => '元気を補い、陽気を温め、気虚による疲労感を和らげます';

  @override
  String get reportTherapyPointQihaiMeridian => '任脈';

  @override
  String get reportTherapyPointGuanyuanName => '関元';

  @override
  String get reportTherapyPointGuanyuanLocation => 'へその下3寸、腹部正中線上';

  @override
  String get reportTherapyPointGuanyuanEffect => '元を養い、陽気と気を補い、体質強化を助けます';

  @override
  String get reportTherapyPointGuanyuanMeridian => '任脈';

  @override
  String get reportTherapyAcupointWarning =>
      '妊娠中、皮膚損傷部位、生理期間中はお灸を避けてください。やけど防止のため温度管理にご注意ください。';

  @override
  String get reportTherapyMentalTitle => '精神養生';

  @override
  String get reportTherapyMentalCalmTitle => '心を静かに保つ';

  @override
  String get reportTherapyMentalCalmDesc =>
      '考えすぎを減らし、心を落ち着かせましょう。中医学では思慮過多が脾を損ない、脾気を消耗しやすいと考えられています。';

  @override
  String get reportTherapyMentalNatureTitle => '自然のリズムに合わせる';

  @override
  String get reportTherapyMentalNatureDesc =>
      '昼夜のリズムに沿って生活し、深夜前には就寝し、朝に軽く体を伸ばして陽気の巡りを助けましょう。';

  @override
  String get reportTherapyMentalEmotionTitle => '感情を整える';

  @override
  String get reportTherapyMentalEmotionDesc =>
      '前向きな気持ちを保ち、感情の波を大きくしすぎないことが大切です。適度な発散で気の滞りを和らげましょう。';

  @override
  String get reportTherapyMentalMeditationTitle => '静坐瞑想';

  @override
  String get reportTherapyMentalMeditationDesc =>
      '毎日10分ほど静かに座り、呼吸に意識を向けることで、脾胃の気機を整え、正気を支えます。';

  @override
  String get reportTherapySeasonalTitle => '四季養生';

  @override
  String get reportTherapySeasonSpringName => '春';

  @override
  String get reportTherapySeasonSpringAdvice =>
      '春は肝を養い、ほどよく酸味を取り入れましょう。ニラやほうれん草を食べ、体を伸ばし、朝の散歩で陽気の発散を助けます。';

  @override
  String get reportTherapySeasonSpringAvoid => '過労や辛味の強い発散性の食べ物は控えましょう';

  @override
  String get reportTherapySeasonSummerName => '夏';

  @override
  String get reportTherapySeasonSummerAdvice =>
      '夏は心を養い、熱をこもらせないようにしましょう。蓮の実やはと麦を適度に取り、昼に短く休み、汗をかきすぎないようにします。';

  @override
  String get reportTherapySeasonSummerAvoid => '冷たい飲食や激しい運動による大量発汗は避けましょう';

  @override
  String get reportTherapySeasonAutumnName => '秋';

  @override
  String get reportTherapySeasonAutumnAdvice =>
      '秋は肺を潤し、梨、百合、白きくらげなどを取り入れましょう。早寝早起きで精気を守ります。';

  @override
  String get reportTherapySeasonAutumnAvoid => '悲しみすぎや辛く乾燥した食べ物は控えましょう';

  @override
  String get reportTherapySeasonWinterName => '冬';

  @override
  String get reportTherapySeasonWinterAdvice =>
      '冬は腎を養い、蓄えることを重視します。黒ごま、くるみ、羊肉を適度に取り、早寝してやや遅く起き、腎陽を守りましょう。';

  @override
  String get reportTherapySeasonWinterAvoid => '過労や大量発汗で陽気を散らすことは避けましょう';

  @override
  String get reportAdviceTongueFeatureColorLabel => '舌色';

  @override
  String get reportAdviceTongueFeatureShapeLabel => '舌形';

  @override
  String get reportAdviceTongueFeatureCoatingColorLabel => '苔色';

  @override
  String get reportAdviceTongueFeatureCoatingTextureLabel => '苔質';

  @override
  String get reportAdviceTongueFeatureCoatingTextureValue => '厚くやや膩';

  @override
  String get reportAdviceTongueFeatureCoatingTextureDesc =>
      '厚く膩った苔は、湿がやや重く、脾の運化が弱いことを示します。';

  @override
  String get reportAdviceTongueFeatureTeethMarksLabel => '歯痕';

  @override
  String get reportAdviceDietRecommendedLabel => 'おすすめ';

  @override
  String get reportAdviceDietFoodYamName => '山薬';

  @override
  String get reportAdviceDietFoodYamDesc => '脾腎を補い、補気・養陰を助けます';

  @override
  String get reportAdviceDietFoodCoixName => 'はと麦';

  @override
  String get reportAdviceDietFoodCoixDesc => '利湿し、脾を助け、下痢を和らげます';

  @override
  String get reportAdviceDietFoodJujubeName => 'なつめ';

  @override
  String get reportAdviceDietFoodJujubeDesc => '気血を補い、脾胃を整え、心を安定させます';

  @override
  String get reportAdviceDietFoodLablabName => '白扁豆';

  @override
  String get reportAdviceDietFoodLablabDesc => '脾を助け、湿をさばき、夏のだるさを和らげます';

  @override
  String get reportAdviceDietFoodCodonopsisName => '党参';

  @override
  String get reportAdviceDietFoodCodonopsisDesc => '中気を補い、脾胃を支えます';

  @override
  String get reportAdviceDietFoodPoriaName => '茯苓';

  @override
  String get reportAdviceDietFoodPoriaDesc => '脾を助け、中を整え、湿をさばきます';

  @override
  String get reportAdviceDietAvoidLabel => '控えたいもの';

  @override
  String get reportAdviceDietAvoidColdFoods => '冷たい物・生もの';

  @override
  String get reportAdviceDietAvoidGreasy => '油っこく重たい食べ物';

  @override
  String get reportAdviceDietAvoidSpicy => '刺激の強い辛味';

  @override
  String get reportAdviceDietAvoidSweetRich => '甘くこってりした食べ物';

  @override
  String get reportAdviceDietAvoidAlcoholTobacco => '酒・たばこ';

  @override
  String get reportAdviceProductTitle => 'おすすめ商品';

  @override
  String get reportAdviceProductSubtitle => '体質に合わせたおすすめ';

  @override
  String get reportAdviceProductOneName => '健脾益気丸';

  @override
  String get reportAdviceProductOneType => '中成薬';

  @override
  String get reportAdviceProductOneDesc =>
      '中気を補い、脾を整え、胃を調和させます。疲れやすさや食欲低下を伴う気虚体質に適しています。';

  @override
  String get reportAdviceProductOneTag => '人気';

  @override
  String get reportAdviceProductTwoName => '参苓白朮散';

  @override
  String get reportAdviceProductTwoType => '伝統方剤';

  @override
  String get reportAdviceProductTwoDesc =>
      '脾気を補い、湿をさばき、下痢を和らげます。脾虚による食欲低下、軟便、倦怠感に用いられます。';

  @override
  String get reportAdviceProductTwoTag => '定番';

  @override
  String get reportAdviceProductThreeName => 'お灸セット';

  @override
  String get reportAdviceProductThreeType => '養生器具';

  @override
  String get reportAdviceProductThreeDesc =>
      'やさしい艾条と経穴ガイド付きで、足三里・気海・関元の家庭養生に適しています。';

  @override
  String get reportAdviceProductThreeTag => 'おすすめ';

  @override
  String get reportAdviceProductFourName => '中医食養生セット';

  @override
  String get reportAdviceProductFourType => '養生食材';

  @override
  String get reportAdviceProductFourDesc =>
      '山薬、はと麦、党参、茯苓、なつめを組み合わせた1週間分の食養生セットです。';

  @override
  String get reportAdviceProductFourTag => '新着';

  @override
  String get reportAdviceProductDisclaimer =>
      'これらのおすすめは体質分析に基づく参考情報です。中成薬の使用は医師または薬剤師の指導のもとで行ってください。';
}
