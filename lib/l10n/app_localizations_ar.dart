// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Pocketly';

  @override
  String get exitPressTwiceMore => 'اضغط رجوع مرتين كمان للخروج';

  @override
  String get exitPressOnceMore => 'اضغط رجوع مرة كمان للخروج';

  @override
  String get homeGuideNext => 'التالي';

  @override
  String get homeGuideDone => 'تمام';

  @override
  String get homeGuideTabsTitle => 'تبويبات فلوسك';

  @override
  String get homeGuideTabsBody => 'تنقل بين الدخل، المصاريف، الرصيد، القروض، الخطط، والجمعيات.';

  @override
  String get homeGuideIncomeTitle => 'ضيف أول دخل';

  @override
  String get homeGuideIncomeBody => 'اضغط إضافة دخل وسجّل مرتب أو شغل حر أو أي فلوس داخلة.';

  @override
  String get homeGuideExpenseTitle => 'سجّل المصاريف';

  @override
  String get homeGuideExpenseBody => 'من تبويب المصاريف اضغط إضافة مصروف أول ما تصرف.';

  @override
  String get homeGuideImportTitle => 'ضيف أسرع بالذكاء';

  @override
  String get homeGuideImportBody => 'اضغط إضافة ذكية واكتب أو قول المعاملة. أو استخدم استيراد لرسائل البنك واللصق.';

  @override
  String get homeGuideSettingsTitle => 'الإعدادات';

  @override
  String get homeGuideSettingsBody => 'من هنا تغيّر العملة واللغة والمظهر وقفل التطبيق. رسوم آخر 3 شهور من الإعدادات أو شريحة الإحصائيات في الرئيسية.';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingGetStarted => 'يلا نبدأ';

  @override
  String get onboardingPage1Title => 'فلوسك في مكان واحد';

  @override
  String get onboardingPage1Body => 'سجّل الدخل والمصاريف بالجنيه. شوف رصيدك وتابع صرفك بسهولة.';

  @override
  String get onboardingPage2Title => 'دفاتر واستيراد ذكي';

  @override
  String get onboardingPage2Body => 'دفتر شخصي أو جمعية. استورد من الرسائل أو النص المشارَك وضيف المعاملات بسرعة.';

  @override
  String get onboardingPage3Title => 'تذكيرات وإحصائيات';

  @override
  String get onboardingPage3Body => 'هنفكرك قبل مواعيد الفواتير، وتشوف رسوم آخر 3 شهور للدخل والمصاريف والتصنيفات.';

  @override
  String get tabIncomes => 'الدخل';

  @override
  String get tabExpenses => 'المصاريف';

  @override
  String get tabBalance => 'الرصيد';

  @override
  String get tabPlans => 'الخطط';

  @override
  String get tabStatistics => 'إحصائيات';

  @override
  String get tabLoans => 'القروض';

  @override
  String get tabCommitments => 'جمعيات';

  @override
  String get statisticsLast3Months => 'آخر 3 شهور';

  @override
  String get statisticsMonthlyTrend => 'الدخل والمصاريف كل شهر';

  @override
  String get statisticsNetPerMonth => 'الصافي كل شهر';

  @override
  String get statisticsTotalIncome => 'مجموع الدخل';

  @override
  String get statisticsTotalExpenses => 'مجموع المصاريف';

  @override
  String get statisticsNet3Months => 'الصافي (3 شهور)';

  @override
  String statisticsAvgMonthlyNet(String amount) {
    return 'المتوسط كل شهر: $amount';
  }

  @override
  String get statisticsTopExpenses => 'أكتر مصاريف (3 شهور)';

  @override
  String get statisticsTopIncomeSources => 'أكتر مصادر دخل (3 شهور)';

  @override
  String get statisticsEmpty => 'سجّل دخل ومصاريف عشان تشوف رسوم آخر 3 شهور.';

  @override
  String get loanNewFab => 'قرض جديد';

  @override
  String get loanAddTitle => 'إضافة قرض';

  @override
  String get loanEditTitle => 'تعديل القرض';

  @override
  String get loanPersonLabel => 'الشخص';

  @override
  String get loanPersonHint => 'مع مين القرض؟';

  @override
  String get loanDirectionLabel => 'النوع';

  @override
  String get loanDirectionGiven => 'أنا سلفت';

  @override
  String get loanDirectionReceived => 'أنا استلفت';

  @override
  String get loanPrincipalLabel => 'المبلغ';

  @override
  String get loanRepaidLabel => 'اتسدد منه';

  @override
  String get loanDueDateOptional => 'تاريخ الاستحقاق (اختياري)';

  @override
  String get loanNotesOptional => 'ملاحظات (اختياري)';

  @override
  String get loanNotesHint => 'السبب أو أي حاجة تفتكرها';

  @override
  String get loanSave => 'حفظ القرض';

  @override
  String get loanUpdate => 'تحديث القرض';

  @override
  String get loanRecordPayment => 'تسجيل دفعة';

  @override
  String get loanPaymentAmount => 'مبلغ الدفعة';

  @override
  String get loanPaymentSubmit => 'حفظ الدفعة';

  @override
  String get loanPaymentPayFromBalance => 'الدفع من';

  @override
  String get loanPaymentPayFromBalanceHint => 'المحفظة أو الحساب اللي هتدفع منه السداد';

  @override
  String get loanPaymentAddToBalance => 'إضافة إلى';

  @override
  String get loanPaymentAddToBalanceHint => 'المحفظة أو الحساب اللي هيتضاف له السداد';

  @override
  String loanPaymentBalanceEntryTitle(String personName) {
    return 'سداد قرض · $personName';
  }

  @override
  String get errorSelectLoanPaymentSource => 'اختار محفظة أو مصدر دفع';

  @override
  String get loanOverview => 'وضع القروض';

  @override
  String get loanOwedToYou => 'مستحق لك';

  @override
  String get loanYouOwe => 'عليك';

  @override
  String get loanNetPositive => 'الصافي: الناس مديونة لك أكتر';

  @override
  String get loanNetNegative => 'الصافي: أنت مديون أكتر';

  @override
  String get loanOpenCount => 'مفتوحة';

  @override
  String get loanOverdueCount => 'متأخرة';

  @override
  String get loanSettledCount => 'اتسددت';

  @override
  String loanRemainingOf(String remaining, String principal) {
    return '$remaining متبقي من $principal';
  }

  @override
  String loanOfPrincipal(String amount) {
    return 'من $amount';
  }

  @override
  String get loanTapToEdit => 'اضغط لتعديل القرض';

  @override
  String get loanSettledBadge => 'اتسدد';

  @override
  String get loanOverdueBadge => 'متأخر';

  @override
  String get loanEmptyTitle => 'تابع الفلوس اللي سلفتها أو استلفتها';

  @override
  String get loanEmptySubtitle => 'ضيف قرض، سجّل الدفعات، وشوف اللي لسه مستحق.';

  @override
  String get loanFilterAll => 'الكل';

  @override
  String get loanFilterGiven => 'سلفت';

  @override
  String get loanFilterReceived => 'استلفت';

  @override
  String get loanFilterOverdue => 'متأخر';

  @override
  String get loanFilterSettled => 'اتسدد';

  @override
  String get loanFilterEmpty => 'مفيش حاجة في الفلتر ده.';

  @override
  String get loansSectionTitle => 'القروض';

  @override
  String get walletSplitTitle => 'قسّم دفعة';

  @override
  String get walletSplitFabSubtitle => 'دفعت بـ InstaPay أو محفظة — سجّل مين عليه فلوس.';

  @override
  String get walletSplitSubtitle => 'بنسجّل المبلغ كله كمصروف، وبعدين نعمل قرض لكل واحد المفروض يرجعلك.';

  @override
  String get walletSplitWhatFor => 'دفعت على إيه؟';

  @override
  String get walletSplitWhatForHint => 'عشا، سوبرماركت، نزهة…';

  @override
  String get walletSplitYouPaid => 'أنت دفعت';

  @override
  String get walletSplitPaidFromHint => 'InstaPay، فودافون كاش، فيزا، كاش…';

  @override
  String get walletSplitIncludeMe => 'أنا كنت معاكم';

  @override
  String get walletSplitIncludeMeHint => 'نصيبك مش بيتسجل كقرض — بس اللي عليهم فلوس.';

  @override
  String get walletSplitEqualShares => 'تقسيم بالتساوي';

  @override
  String walletSplitYourShare(String amount) {
    return 'نصيبك: $amount';
  }

  @override
  String get walletSplitPeopleSection => 'مين عليه فلوس';

  @override
  String get walletSplitAddPerson => 'ضيف شخص';

  @override
  String get walletSplitPersonHint => 'اسم صاحبك';

  @override
  String get walletSplitNotesHint => 'ملاحظة أو رقم التحويل (اختياري)';

  @override
  String get walletSplitSave => 'حفظ التقسيم';

  @override
  String get walletSplitTitleRequired => 'اكتب دفعت على إيه';

  @override
  String get walletSplitPersonRequired => 'اكتب اسم كل واحد';

  @override
  String get walletSplitAmountsExceedTotal => 'حصص الناس أكبر من اللي دفعته';

  @override
  String get walletSplitAmountsMustMatchTotal => 'حصص الناس لازم تساوي المبلغ كله';

  @override
  String walletSplitSuccess(int count) {
    return 'اتسجل مصروف و$count قرض';
  }

  @override
  String get errorEnterPersonName => 'اكتب اسم الشخص';

  @override
  String get errorEnterLoanAmount => 'اكتب مبلغ قرض صحيح';

  @override
  String get errorRepaidExceedsPrincipal => 'المسدد مش ممكن يزيد عن مبلغ القرض';

  @override
  String get errorEnterPaymentAmount => 'اكتب مبلغ دفعة صحيح';

  @override
  String get errorPaymentExceedsRemaining => 'الدفعة مش ممكن تزيد عن المبلغ المتبقي';

  @override
  String get associationPersonal => 'شخصي';

  @override
  String get currencyEgyptianPound => 'جنيه مصري';

  @override
  String get currencyEgpSymbol => 'ج.م';

  @override
  String get billRemindersTitle => 'تذكيرات الفواتير';

  @override
  String get billRemindersSubtitle => 'هنفكرك قبل مواعيد الفواتير الشهرية';

  @override
  String get billRemindersEmpty => 'مفيش تذكيرات لسه. ضيف كهرباء، إيجار، نت، ومياه.';

  @override
  String get billRemindersAdd => 'تذكير جديد';

  @override
  String get billRemindersEdit => 'تعديل التذكير';

  @override
  String get billRemindersTitleLabel => 'اسم الفاتورة';

  @override
  String get billRemindersTitleHint => 'زي: كهرباء، إيجار، نت';

  @override
  String get billRemindersTitleRequired => 'اكتب اسم الفاتورة';

  @override
  String get billRemindersAmountLabel => 'المبلغ (اختياري)';

  @override
  String get billRemindersTimeLabel => 'وقت التذكير';

  @override
  String get billRemindersDayOfMonth => 'يوم الشهر';

  @override
  String get billRemindersDayOfMonthShortMonthHint => 'في الشهور الأقصر، التذكير هيكون في آخر يوم في الشهر.';

  @override
  String billRemindersDayOfMonthValue(int day) {
    return 'يوم $day';
  }

  @override
  String get billRemindersRemindBefore => 'فكرني';

  @override
  String get billRemindersRemindOnDay => 'يوم الاستحقاق';

  @override
  String get billRemindersRemind1Day => 'قبلها بيوم';

  @override
  String get billRemindersRemind3Days => 'قبلها بـ 3 أيام';

  @override
  String get billRemindersRemind7Days => 'قبلها بـ 7 أيام';

  @override
  String get billRemindersEnabled => 'تذكيرات الفواتير';

  @override
  String get dailyDigestEnabled => 'ملخص يومي';

  @override
  String get dailyDigestSubtitle => 'ملخص مسائي لمصروفات أمس وصافي الشهر لحد دلوقتي';

  @override
  String get dailyDigestTimeLabel => 'وقت الملخص';

  @override
  String get dailyDigestNotificationTitle => 'فلوسك امبارح';

  @override
  String get dailyDigestNotificationEmpty => 'مفيش معاملات اتسجلت امبارح. افتح Pocketly وسجّل مصروفات النهاردة.';

  @override
  String dailyDigestYesterdayExpenses(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مصروفات ($amount)',
      one: 'مصروف واحد ($amount)',
    );
    return '$_temp0';
  }

  @override
  String get dailyDigestYesterdayNoExpenses => 'مفيش مصروفات امبارح';

  @override
  String dailyDigestYesterdayIncomes(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دخل ($amount)',
      one: 'دخل واحد ($amount)',
    );
    return '$_temp0';
  }

  @override
  String get dailyDigestYesterdayNoIncomes => 'مفيش دخل امبارح';

  @override
  String dailyDigestMonthNet(String amount) {
    return 'صافي الشهر: $amount';
  }

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsSubtitle => 'تحكم في تذكيرات الفواتير والملخص اليومي وشوف إيه الجاي.';

  @override
  String get notificationsMessageLabel => 'نص الإشعار';

  @override
  String get notificationsInbox => 'تنبيهات حديثة';

  @override
  String get notificationsUpcoming => 'القادم';

  @override
  String get notificationsUpcomingEmpty => 'مفيش إشعارات مجدولة. فعّل تذكيرات الفواتير أو الملخص اليومي من فوق.';

  @override
  String get notificationsPermissionBanner => 'الإشعارات مقفولة من إعدادات الموبايل. فعّلها عشان تذكيرات الفواتير والملخص اليومي.';

  @override
  String get notificationsOpenSettings => 'فتح الإعدادات';

  @override
  String get notificationsManageBills => 'إدارة الفواتير';

  @override
  String notificationsScheduledBillSubtitle(String when, String due) {
    return '$when · $due';
  }

  @override
  String notificationsScheduledDigestSubtitle(String when) {
    return 'الملخص الجاي · $when';
  }

  @override
  String get billRemindersPermissionDenied => 'فعّل الإشعارات من إعدادات الموبايل عشان التذكيرات تشتغل.';

  @override
  String get billRemindersSaved => 'اتحفظ التذكير';

  @override
  String get billRemindersDeleted => 'اتمسح التذكير';

  @override
  String get recurringTransactionsTitle => 'المعاملات المتكررة';

  @override
  String get recurringTransactionsSubtitle => 'هتتسجل المرتب والإيجار والفواتير لوحدها كل شهر في يوم الاستحقاق';

  @override
  String get recurringTransactionsEmpty => 'مفيش معاملات متكررة لسه. ضيف مرتب، إيجار، نت، وغيره.';

  @override
  String get recurringTransactionsAdd => 'معاملة متكررة';

  @override
  String get recurringTransactionsEdit => 'تعديل المعاملة';

  @override
  String get recurringTransactionsTitleHint => 'زي: مرتب، إيجار، نت';

  @override
  String get recurringTransactionsPostedThisMonth => 'اتنزلت الشهر ده';

  @override
  String get recurringTransactionsDeleted => 'اتمسحت المعاملة المتكررة';

  @override
  String get recurringTransactionsDeleteConfirmTitle => 'تمسح المعاملة المتكررة؟';

  @override
  String get commitmentsTitle => 'الجمعيات والأقساط';

  @override
  String get commitmentsSubtitle => 'تابعي الجمعية والقسط. الدفع يتسجل في المصروفات ويتخصم من مصدر الرصيد، واستلام الجمعية يتضاف للدخل.';

  @override
  String get commitmentsGameyas => 'جمعيات';

  @override
  String get commitmentsInstallments => 'أقساط';

  @override
  String get commitmentsAddGameya => 'جمعية جديدة';

  @override
  String get commitmentsAddInstallment => 'قسط جديد';

  @override
  String get commitmentsEditTitle => 'تعديل';

  @override
  String get commitmentsGameyaHint => 'الجمعية: الكل بيدفع نفس المبلغ كل شهر، وواحد بياخد المبلغ كامل في دوره.';

  @override
  String get commitmentsInstallmentHint => 'القسط: مبلغ ثابت كل شهر لحد ما تخلّصي العدد.';

  @override
  String get commitmentsNameLabel => 'الاسم';

  @override
  String get commitmentsGameyaNameHint => 'زي: جمعية الشغل';

  @override
  String get commitmentsInstallmentNameHint => 'زي: موبايل، عفش';

  @override
  String get commitmentsMonthlyAmount => 'القسط الشهري';

  @override
  String get commitmentsMemberCount => 'عدد الأفراد / الشهور';

  @override
  String get commitmentsInstallmentCount => 'عدد الأقساط';

  @override
  String get commitmentsMyTurn => 'دورِك (شهر كام)';

  @override
  String get commitmentsMyTurnHint => '1 يعني أول شهر';

  @override
  String get commitmentsMembersTitle => 'الناس بترتيب الأدوار';

  @override
  String get commitmentsMembersHint => 'أول اسم بياخد الجمعية أول شهر. اضغطي «أنا» على اسمك.';

  @override
  String get commitmentsMemberHint => 'الاسم';

  @override
  String get commitmentsMemberMe => 'أنا';

  @override
  String get commitmentsAddMember => 'ضيفي حد';

  @override
  String get commitmentsMemberNameRequired => 'اكتبي اسم كل الناس';

  @override
  String get commitmentsMembersMin => 'الجمعية لازم يبقى فيها شخصين على الأقل';

  @override
  String commitmentsTurnIs(String name) {
    return 'الدور على $name';
  }

  @override
  String commitmentsDueDay(int day) {
    return 'الاستحقاق يوم $day';
  }

  @override
  String get commitmentsNotesHint => 'ملاحظة اختيارية';

  @override
  String get commitmentsSave => 'حفظ';

  @override
  String get commitmentsSaved => 'اتحفظ';

  @override
  String get commitmentsNameRequired => 'اكتبي الاسم';

  @override
  String get commitmentsCountRequired => 'اكتبي عدد الشهور';

  @override
  String get commitmentsTurnInvalid => 'دورِك لازم يكون بين 1 وعدد الشهور';

  @override
  String commitmentsDueThisMonth(String amount) {
    return 'لسه مستحق الشهر ده $amount';
  }

  @override
  String get commitmentsEmptyGameya => 'لسه مفيش جمعيات. ضيفي واحدة عشان تتابعي القسط وإمتى تستلمي.';

  @override
  String get commitmentsEmptyInstallment => 'لسه مفيش أقساط. ضيفي خطة عشان تشوفي فاضل كام قسط.';

  @override
  String commitmentsProgress(int paid, int total, String left) {
    return 'اتدفع $paid من $total · فاضل $left';
  }

  @override
  String commitmentsPayout(String amount) {
    return 'هتستلمي $amount في دورِك';
  }

  @override
  String get commitmentsYourTurn => 'الشهر ده دورِك — المفروض تستلمي الجمعية.';

  @override
  String get commitmentsTurnPassed => 'دورِك عدّى.';

  @override
  String commitmentsTurnsLeft(int count) {
    return 'فاضل $count قسط على دورِك';
  }

  @override
  String get commitmentsMarkPaid => 'سجّلي دفع الشهر';

  @override
  String get commitmentsPaidThisMonth => 'اتدفع الشهر ده';

  @override
  String get commitmentsFinished => 'خلصت';

  @override
  String get commitmentsUndo => 'تراجع';

  @override
  String get commitmentsDeleteTitle => 'تمسحي ده؟';

  @override
  String get commitmentsCategoryHint => 'نفس تصنيفات المصروفات، عشان القسط يظهر هناك.';

  @override
  String get commitmentsPayFromHint => 'نفس محافظ الرصيد. قسط الشهر يتسجل في المصروفات ويتخصم من المصدر ده.';

  @override
  String get commitmentsReceiveInto => 'استلام الجمعية في';

  @override
  String get commitmentsReceiveIntoHint => 'في شهر دورِك، المبلغ كامل يتسجل في الدخل على المصدر ده.';

  @override
  String commitmentsFromSource(String source) {
    return 'بتدفعي من $source';
  }

  @override
  String commitmentsPayoutInto(String source) {
    return 'هتستلمي في $source';
  }

  @override
  String get commitmentsConfirmPay => 'سجّلي في المصروفات';

  @override
  String commitmentsTurnPayoutNote(String amount) {
    return 'الشهر ده دورِك. قسطِك يتسجل مصروف، و$amount يتضاف للدخل.';
  }

  @override
  String commitmentsExpenseTitle(String title, int cycle, int total) {
    return '$title ($cycle/$total)';
  }

  @override
  String commitmentsIncomeTitle(String title) {
    return 'استلام $title';
  }

  @override
  String get commitmentsLedgerMissing => 'اتسجل الدفع، بس مش قادرين نربطه. راجعي المصروفات.';

  @override
  String get commitmentsPosted => 'اتسجل في المصروفات';

  @override
  String get billRemindersTestNow => 'جرب دلوقتي';

  @override
  String get billRemindersTestNowSent => 'اتبعت إشعار تجربة — شوف شريط الإشعارات';

  @override
  String billReminderNotificationTitle(String title) {
    return 'فاتورة: $title';
  }

  @override
  String billReminderNotificationDueTodayWithAmount(String amount) {
    return 'النهاردة موعد الدفع — $amount';
  }

  @override
  String get billReminderNotificationDueTodayPlain => 'النهاردة موعد الدفع';

  @override
  String billReminderNotificationDueInDaysWithAmount(int days, String amount) {
    return 'باقي $days يوم على الدفع — $amount';
  }

  @override
  String billReminderNotificationDueInDaysPlain(int days) {
    return 'باقي $days يوم على الدفع';
  }

  @override
  String get billRemindersPresetElectricity => 'كهرباء';

  @override
  String get billRemindersPresetRent => 'إيجار';

  @override
  String get billRemindersPresetInternet => 'نت';

  @override
  String get billRemindersPresetWater => 'مياه';

  @override
  String get associationSelect => 'دفتر';

  @override
  String get associationPickerTitle => 'اختار الدفتر';

  @override
  String get associationPickerSubtitle => 'الشخصي ليك لوحدك. الدفتر المنفصل زي الشغل أو البيت، واللي تدعوه يقدر يضيف. الجمعية المدير هو اللي بيسجّل.';

  @override
  String get associationCreateTitle => 'دفتر جديد';

  @override
  String get associationCreateAction => 'إضافة جمعية';

  @override
  String get associationCreateFamilyTitle => 'دفتر جديد';

  @override
  String get associationCreateFamilyAction => 'إضافة دفتر';

  @override
  String get associationCreateFamilyHint => 'مثال: الشغل، البيت';

  @override
  String get associationCreateFamilySubtitle => 'دفتر منفصل عن الشخصي، للشغل أو أي حاجة تانية. اللي تدعوه يقدر يضيف دخله ومصاريفه.';

  @override
  String get associationFamilyBadge => 'دفتر منفصل';

  @override
  String get associationFamilyBanner => 'دفتر منفصل: كل عضو يقدر يضيف دخله ومصاريفه.';

  @override
  String familyTransactionBy(String name) {
    return 'ضافها $name';
  }

  @override
  String get familyAuthorYou => 'إنت';

  @override
  String get familyAuthorUnknown => 'عضو';

  @override
  String get associationNameHint => 'مثال: شغل، بيت، ادخار';

  @override
  String get associationNameRequired => 'اكتب اسم للدفتر';

  @override
  String associationCreated(String name) {
    return 'اتعمل \"$name\"';
  }

  @override
  String get associationDeleteConfirmTitle => 'تمسح الدفتر؟';

  @override
  String associationDeleteConfirmMessage(String name) {
    return 'تمسح \"$name\" وكل الدخل والمصاريف والميزانيات والخطط اللي فيه؟ مفيش رجوع.';
  }

  @override
  String get associationDeleteAction => 'امسح';

  @override
  String get associationDeletedSnack => 'اتمسح الدفتر';

  @override
  String get associationCannotDeletePersonal => 'الدفتر الشخصي ما ينفعش يتمسح';

  @override
  String get associationInviteTitle => 'دعوة أعضاء';

  @override
  String associationInviteSubtitle(String name) {
    return 'دور على اسم المستخدم وابعت دعوة لـ \"$name\". هو يختار ينضم ولا لأ.';
  }

  @override
  String get associationInviteSearchHint => 'دور بالاسم…';

  @override
  String get associationInviteSearchMinChars => 'اكتب حرفين على الأقل للبحث';

  @override
  String get associationInviteNoResults => 'مفيش مستخدمين';

  @override
  String get associationInviteAction => 'ابعت دعوة';

  @override
  String get associationInviteSentLabel => 'اتبعت';

  @override
  String associationInviteSent(String username) {
    return 'اتبعت دعوة لـ $username';
  }

  @override
  String get associationInviteMembersAction => 'دعوة أعضاء';

  @override
  String get associationInvitePendingTitle => 'دعوات وصلتلك';

  @override
  String associationInvitePendingBody(String username, String name) {
    return '$username دعاك لدفتر \"$name\"';
  }

  @override
  String get associationInviteAccept => 'انضم';

  @override
  String get associationInviteReject => 'ارفض';

  @override
  String get associationInviteAcceptedSnack => 'انضميت للدفتر';

  @override
  String get associationInviteRejectedSnack => 'اترفضت الدعوة';

  @override
  String get associationInviteDisclaimerTitle => 'قبل ما تبعت دعوة';

  @override
  String get associationInviteDisclaimerBody => 'Pocketly بيساعدك تنظم دفاتر مشتركة. إنت المسؤول عن مين تدعو وإزاي الفلوس تتسجّل بينكم. التطبيق ما بيحتفظش بفلوس، مش بنك، ومش مسؤول عن أي خلاف بين الأعضاء. ادعُ بس ناس تثق فيهم.';

  @override
  String get associationInviteDisclaimerAccept => 'فاهم';

  @override
  String get associationInviteLegalNote => 'Pocketly أداة تسجيل بس — مش استشارة مالية ولا ضمان ولا محامي.';

  @override
  String get associationManageTitle => 'إدارة الدفتر';

  @override
  String get associationManageOpen => 'افتح';

  @override
  String get associationManageNotAvailable => 'اختار دفتر جمعية الأول.';

  @override
  String get associationManageSubtitle => 'إنت أمين الصندوق. سجّل هنا كل الدخل والمصاريف والخطط والتواريخ. الأعضاء بس يشوفوا.';

  @override
  String get associationManageIncomeHint => 'ضيف وعدّل الدخل';

  @override
  String get associationManageExpenseHint => 'ضيف وعدّل المصاريف بالتواريخ';

  @override
  String get associationManageBalanceHint => 'شوف الرصيد للدفتر ده';

  @override
  String get associationManageStatsHint => 'رسوم آخر 3 شهور';

  @override
  String get associationManagePlansHint => 'خطط التوفير والأهداف';

  @override
  String get associationManageInviteHint => 'ادعُ ناس تشوف الدفتر';

  @override
  String get associationManageTreasurerNote => 'إنت بس اللي تضيف أو تعدّل الأرقام. اللي اتدعوا يشوفوا بس.';

  @override
  String get associationTreasurerBannerTitle => 'إنت مدير الدفتر';

  @override
  String associationTreasurerBannerBody(String name) {
    return 'كل حاجة في $name بتتسجّل منك.';
  }

  @override
  String associationMemberReadOnlyBanner(String name) {
    return 'عضو مشاهدة في \"$name\". اطلب من المدير يضيف أو يعدّل.';
  }

  @override
  String get associationManageHubAction => 'إدارة الدفتر';

  @override
  String get associationHubTitle => 'إدارة الجمعية';

  @override
  String get associationHubOpen => 'افتح';

  @override
  String get associationHubNotAvailable => 'اختار جمعية مشتركة الأول.';

  @override
  String get associationHubOwnerSubtitle => 'إنت مدير الجمعية: الجمعية بكام، القسط، مين عليه الدور، والأعضاء.';

  @override
  String get associationHubMemberSubtitle => 'مشاهدة بس: شوف المبلغ والقسط ومين عليه الدور.';

  @override
  String get associationHubPayout => 'الجمعية بكام';

  @override
  String get associationHubPayoutHint => '12000';

  @override
  String get associationHubInstallment => 'القسط';

  @override
  String get associationHubInstallmentHint => '1000';

  @override
  String get associationHubMemberCount => 'عدد الحصص';

  @override
  String get associationHubCollectionDay => 'يوم التحصيل';

  @override
  String get associationHubCollectionDayHint => 'يوم في الشهر (1–31)';

  @override
  String get associationHubCollectionDayInvalid => 'يوم التحصيل لازم يكون من 1 لـ 31.';

  @override
  String associationHubDayOfMonth(int day) {
    return 'يوم $day';
  }

  @override
  String get associationHubCurrentTurn => 'عليه الدور';

  @override
  String associationHubTurnNumber(int current, int total) {
    return 'الدور $current من $total';
  }

  @override
  String get associationHubTurnList => 'ترتيب الدور';

  @override
  String get associationHubEmptySetup => 'حدّد الجمعية بكام، القسط، ومين ياخد كل دور.';

  @override
  String get associationHubEmptyTurnList => 'مفيش حصص لسه. اضغط تعديل عشان تضيف الأسماء.';

  @override
  String get associationHubEdit => 'تعديل البيانات';

  @override
  String get associationHubSave => 'احفظ';

  @override
  String get associationHubSaved => 'اتحفظت بيانات الجمعية.';

  @override
  String get associationHubSlotsRequired => 'ضيف اسم واحد على الأقل لترتيب الدور.';

  @override
  String get associationHubFormFixErrors => 'صحّح الحقول اللي عليها خطأ.';

  @override
  String get associationHubPaymentsTitle => 'مدفوعات الأقساط';

  @override
  String get associationHubPaymentsEmpty => 'مفيش مدفوعات مسجّلة لسه.';

  @override
  String associationHubPaymentsTotal(String amount) {
    return 'الإجمالي: $amount';
  }

  @override
  String get associationHubRecordPayment => 'سجّل دفع';

  @override
  String get associationHubPaymentRecorded => 'اتسجّل الدفع.';

  @override
  String get associationHubPaymentPayer => 'مين اللي دفع';

  @override
  String get associationHubPaymentPayerRequired => 'اختار مين اللي دفع.';

  @override
  String get associationHubPaymentAmount => 'دفع قد إيه';

  @override
  String get associationHubPaymentDate => 'تاريخ الدفع';

  @override
  String associationHubPaymentPaidOn(String date) {
    return 'دفع يوم $date';
  }

  @override
  String get associationHubPaymentNote => 'ملاحظة (اختياري)';

  @override
  String get associationHubPaymentNoteHint => 'مثال: قسط مارس';

  @override
  String get associationHubPaymentSave => 'احفظ الدفع';

  @override
  String get associationHubPaymentDeleteTitle => 'تمسح الدفع؟';

  @override
  String associationHubPaymentDeleteMessage(String name) {
    return 'تمسح تسجيل دفع $name؟';
  }

  @override
  String get associationHubPaymentDeleteConfirm => 'امسح';

  @override
  String get associationHubEndGam3eya => 'إنهاء الجمعية';

  @override
  String get associationHubEndGam3eyaTitle => 'إنهاء الجمعية؟';

  @override
  String get associationHubEndGam3eyaMessage => 'الجمعية هتتقفل. تقدروا تشوفوا الدور والمدفوعات بس، من غير تعديل أو دفع جديد.';

  @override
  String get associationHubEndGam3eyaConfirm => 'إنهاء';

  @override
  String get associationHubEndGam3eyaDone => 'اتنهت الجمعية.';

  @override
  String associationHubEndedBanner(String date) {
    return 'الجمعية انتهت يوم $date. مشاهدة بس.';
  }

  @override
  String get associationHubOwnerEndedSubtitle => 'الجمعية خلصت. البيانات للمشاهدة بس.';

  @override
  String get associationHubMemberEndedSubtitle => 'المدير أنهى الجمعية. مشاهدة بس.';

  @override
  String get associationHubAdvanceTurn => 'الدور التالي';

  @override
  String associationHubAdvanceTurnConfirm(String name) {
    return 'نكمّل دور $name وننقل للي بعده؟';
  }

  @override
  String get associationHubReceived => 'استلم';

  @override
  String get associationHubPending => 'لسه';

  @override
  String get associationHubCurrentBadge => 'الدور دلوقتي';

  @override
  String get associationHubInvite => 'دعوة أعضاء';

  @override
  String get associationHubTreasurerNote => 'تسجيل الدخل والمصاريف لسه من المدير في التابات الرئيسية. الصفحة دي لمتابعة الجمعية والدور.';

  @override
  String get associationHubAppMembers => 'أعضاء التطبيق';

  @override
  String get associationHubRoleOwner => 'مدير';

  @override
  String get associationHubRoleAdmin => 'مساعد';

  @override
  String get associationHubRoleMember => 'عضو';

  @override
  String get associationHubAddSlot => 'ضيف حصة';

  @override
  String get associationHubSlotName => 'الاسم';

  @override
  String get associationHubBannerTitle => 'إدارة الجمعية';

  @override
  String associationHubBannerBody(String name) {
    return 'الدور والجمعية والقسط لـ $name.';
  }

  @override
  String get homeWelcomeBack => 'أهلاً بيك تاني';

  @override
  String homeWelcomeUser(String name) {
    return 'أهلاً بيك تاني، $name';
  }

  @override
  String get homeFinanceOverview => 'ملخص فلوسك';

  @override
  String get homeDateFilterTitle => 'فلتر بالتاريخ';

  @override
  String get homeFilterAllMonths => 'كل الشهور';

  @override
  String get homeFilterByMonth => 'شهر';

  @override
  String get homeFilterByDay => 'يوم';

  @override
  String get homeFilterThisMonth => 'الشهر ده';

  @override
  String get homeFilterPickMonth => 'اختار الشهر';

  @override
  String get homeFilterPickDay => 'اختار اليوم';

  @override
  String get homeFilterToday => 'النهاردة';

  @override
  String get homeFilterNoEntries => 'مفيش حاجة في الفترة دي';

  @override
  String get accountSettingsTitle => 'إعدادات الحساب';

  @override
  String get changeUsername => 'غيّر اسم المستخدم';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsTheme => 'المظهر';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeSystem => 'حسب الجهاز';

  @override
  String get appearanceColors => 'لون التطبيق';

  @override
  String get appearanceGradients => 'شكل التدرج';

  @override
  String get appearanceCustom => 'مخصص';

  @override
  String get appearancePickColor => 'اختار لون';

  @override
  String get appearanceCustomPrimary => 'اللون الأساسي';

  @override
  String get appearanceCustomSecondary => 'لون مميز';

  @override
  String get appearanceGradientStops => 'ألوان التدرج';

  @override
  String get appearancePaletteCoral => 'مرجاني';

  @override
  String get appearancePaletteOcean => 'بحري';

  @override
  String get appearancePaletteForest => 'غابة';

  @override
  String get appearancePaletteSunset => 'غروب';

  @override
  String get appearancePaletteGrape => 'بنفسجي';

  @override
  String get appearancePaletteRose => 'وردي';

  @override
  String get appearancePaletteSlate => 'رمادي';

  @override
  String get appearanceGradientDiagonal => 'مائل';

  @override
  String get appearanceGradientSunset => 'غروب';

  @override
  String get appearanceGradientAurora => 'شفق';

  @override
  String get appearanceGradientWave => 'موج';

  @override
  String get appearanceGradientSoft => 'ناعم';

  @override
  String get settingsCalculator => 'الآلة الحاسبة';

  @override
  String get settingsRateApp => 'قيّم على Google Play';

  @override
  String get settingsRateAppFailed => 'ما قدرناش نفتح Google Play. جرّب تاني.';

  @override
  String get calculatorTitle => 'الآلة الحاسبة';

  @override
  String get languageEnglish => 'إنجليزي';

  @override
  String get languageArabic => 'عربي';

  @override
  String get logout => 'خروج';

  @override
  String get deleteAccount => 'امسح الحساب';

  @override
  String get deleteAccountConfirmTitle => 'تمسح الحساب؟';

  @override
  String get deleteAccountConfirmMessage => 'هيتمسح حسابك والدخل والمصاريف والخطط خالص. مفيش رجوع.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get usernameUpdated => 'اتغيّر اسم المستخدم';

  @override
  String get errorEnterUsername => 'اكتب اسم المستخدم';

  @override
  String get errorUsernameTaken => 'اسم المستخدم ده متاخد. اختار اسم تاني.';

  @override
  String get logoutConfirmTitle => 'تخرج؟';

  @override
  String get logoutConfirmMessage => 'هتحتاج تسجّل دخول تاني عشان تستخدم التطبيق.';

  @override
  String get loginWelcomeTitle => 'أهلاً بيك تاني 👋';

  @override
  String get loginWelcomeSubtitle => 'سجّل دخولك عشان تكمل';

  @override
  String get labelEmail => 'الإيميل';

  @override
  String get hintEmail => 'example@gmail.com';

  @override
  String get labelPassword => 'الباسورد';

  @override
  String get hintPasswordDots => '••••••••';

  @override
  String get forgotPasswordQuestion => 'نسيت الباسورد؟';

  @override
  String get loginButton => 'دخول';

  @override
  String get orDivider => 'أو';

  @override
  String get continueWithGoogle => 'كمل بجوجل';

  @override
  String get continueWithFacebook => 'كمل بفيسبوك';

  @override
  String get noAccountPrompt => 'معندكش حساب؟';

  @override
  String get signUpLink => 'اعمل حساب';

  @override
  String get messageEnterEmailPassword => 'اكتب الإيميل والباسورد';

  @override
  String get messageLoginFailed => 'الدخول فشل';

  @override
  String get messageLoginSuccess => 'دخلت بنجاح';

  @override
  String get signupCreateTitle => 'اعمل حساب 🚀';

  @override
  String get signupCreateSubtitle => 'اعمل حسابك عشان تكمل';

  @override
  String get labelFullName => 'الاسم الكامل';

  @override
  String get hintEnterYourName => 'اكتب اسمك';

  @override
  String get labelConfirmPassword => 'أكّد الباسورد';

  @override
  String get createAccountButton => 'اعمل حساب';

  @override
  String get alreadyHaveAccount => 'عندك حساب؟';

  @override
  String get loginLinkShort => 'دخول';

  @override
  String get signupErrorGeneric => 'حصل خطأ';

  @override
  String get signupSuccessful => 'اتعمل الحساب بنجاح';

  @override
  String get forgotPasswordTitle => 'نسيت الباسورد؟';

  @override
  String get forgotPasswordDescription => 'اكتب إيميلك وهنبعتلك كود تعيّن بيه باسورد جديد.';

  @override
  String get sendResetLink => 'ابعت الكود';

  @override
  String get backToLogin => 'رجوع للدخول';

  @override
  String get errorTryAgainGeneric => 'حصل خطأ. جرّب تاني.';

  @override
  String get setNewPasswordTitle => 'باسورد جديد 🔒';

  @override
  String get setNewPasswordSubtitle => 'اكتب كود التحقق واعمل باسورد جديد.';

  @override
  String get labelOtpCode => 'كود التحقق';

  @override
  String get hintOtpCode => 'اكتب كود التحقق';

  @override
  String get labelNewPassword => 'الباسورد الجديد';

  @override
  String get buttonSetNewPassword => 'احفظ الباسورد';

  @override
  String get passwordUpdatedSuccessfully => 'اتغيّر الباسورد بنجاح ✅';

  @override
  String noRouteForName(Object name) {
    return 'مفيش صفحة لـ $name';
  }

  @override
  String get noInternetConnection => 'مفيش نت';

  @override
  String offlineWithPendingTransactions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بدون نت — $count قيود هتتزامن لما النت يرجع',
      one: 'بدون نت — قيد واحد هيتزامن لما النت يرجع',
    );
    return '$_temp0';
  }

  @override
  String get errorGeneric => 'حصل خطأ';

  @override
  String get errorDeleteFailed => 'الحذف ما نجحش. جرّب تاني.';

  @override
  String get errorDeleteAccountFailed => 'ما قدرناش نمسح حسابك. جرّب تاني.';

  @override
  String get errorDeleteAccountRpcRequired => 'مسح الحساب مش متظبط على السيرفر. شغّل supabase/delete_account.sql في مشروع Supabase.';

  @override
  String get addIncome => 'ضيف دخل';

  @override
  String get editIncome => 'عدّل الدخل';

  @override
  String get recentIncomes => 'آخر دخل';

  @override
  String get incomeToolsSectionTitle => 'إجراءات سريعة';

  @override
  String get incomeToolsSectionSubtitle => 'ضيف دخل أسرع بالذكاء الاصطناعي، الاستيراد، يوم الراتب، أو المتكرر.';

  @override
  String get incomeToolsAddForm => 'فورم فاضي';

  @override
  String get incomeToolsRecurring => 'متكرر';

  @override
  String get totalIncome => 'مجموع الدخل';

  @override
  String get addExpense => 'ضيف مصروف';

  @override
  String get editExpense => 'عدّل المصروف';

  @override
  String get recentExpenses => 'آخر مصاريف';

  @override
  String get expenseSortNewest => 'الأحدث';

  @override
  String get expenseSortHighestAmount => 'الأكبر مبلغ';

  @override
  String get expenseDeletedSnack => 'اتمسح المصروف';

  @override
  String get expenseUndoAction => 'تراجع';

  @override
  String get expenseRestoredSnack => 'اترجع المصروف';

  @override
  String get totalExpenses => 'مجموع المصاريف';

  @override
  String get noIncomesTitle => 'لسه مفيش دخل';

  @override
  String get noIncomesSubtitle => 'اضغط الزرار تحت وسجّل أول دخل';

  @override
  String get noExpensesTitle => 'لسه مفيش مصاريف';

  @override
  String get noExpensesSubtitle => 'اضغط الزرار تحت وسجّل أول مصروف';

  @override
  String get titleField => 'العنوان';

  @override
  String get hintExpenseTitle => 'مثال: مشتريات';

  @override
  String get hintIncomeTitle => 'مثال: دفعة مارس';

  @override
  String get incomeSourceField => 'المصدر';

  @override
  String get hintIncomeSource => 'مثال: فيزا، إيجارات، مرتب';

  @override
  String get addIncomeSheetTitleHint => 'زي: مرتب مارس، إيجار شقة';

  @override
  String get addIncomeSheetSourceHint => 'زي: فيزا، فودافون كاش، مرتب، تحويل بنك';

  @override
  String get addExpenseSheetTitleHint => 'زي: سوبر ماركت، أكل بره، أوبر';

  @override
  String get addExpenseSheetPaidFromHint => 'دفعت منين؟ كاش، فيزا، فودافون كاش…';

  @override
  String get addExpenseSheetOtherCategoryHint => 'زي: جيم، اشتراكات، هدايا';

  @override
  String get paymentPresetBankTransfer => 'تحويل بنك';

  @override
  String get paymentPresetVodafoneCash => 'فودافون كاش';

  @override
  String get paymentPresetInstaPay => 'إنستاباي';

  @override
  String get walletUsdLabel => 'محفظة دولار';

  @override
  String get walletEurLabel => 'محفظة يورو';

  @override
  String get salaryDayTitle => 'يوم الراتب';

  @override
  String get salaryDaySubtitle => 'قسّم راتبك على إيجار وفواتير وخطط، والباقي للصرف.';

  @override
  String salaryDayPaydayLabel(int day) {
    return 'يوم الراتب: يوم $day من كل شهر';
  }

  @override
  String get salaryDayAmountLabel => 'مبلغ الراتب';

  @override
  String get salaryDayRentPct => 'إيجار';

  @override
  String get salaryDayBillsPct => 'فواتير';

  @override
  String get salaryDayPlansPct => 'خطط / ادخار';

  @override
  String salaryDayLeftoverPct(String pct) {
    return 'الباقي · $pct%';
  }

  @override
  String get salaryDayPromptToggle => 'افتح ده بعد ما أضيف دخل من نوع راتب';

  @override
  String get salaryDayPreview => 'معاينة التقسيم';

  @override
  String get salaryDayPreviewEmpty => 'اكتب مبلغ الراتب عشان تشوف التقسيم.';

  @override
  String get salaryDayLeftoverHint => 'يفضل في جيب الراتب — مش بيتسجل كمصروف';

  @override
  String get salaryDayApply => 'طبّق التقسيم';

  @override
  String get salaryDaySaveRulesOnly => 'احفظ القواعد بس';

  @override
  String get salaryDayRulesSaved => 'اتحفظت قواعد يوم الراتب';

  @override
  String salaryDaySuccess(int count) {
    return 'اتوزع على $count مصروف';
  }

  @override
  String get yearInReviewTitle => 'مراجعة السنة';

  @override
  String yearInReviewHero(int year) {
    return 'قصة فلوسك في $year';
  }

  @override
  String yearInReviewHeroBody(String income, String expenses) {
    return 'كسبت $income وصرفت $expenses.';
  }

  @override
  String get yearInReviewEmpty => 'مفيش دخل أو مصاريف متسجلة للسنة دي لسه.';

  @override
  String get yearInReviewNet => 'الصافي';

  @override
  String get yearInReviewSavingsRate => 'نسبة الادخار';

  @override
  String get yearInReviewLoansClosed => 'قروض اتسددت';

  @override
  String get yearInReviewLoansOpen => 'قروض مفتوحة';

  @override
  String get yearInReviewBestMonth => 'أحسن شهر';

  @override
  String get yearInReviewToughMonth => 'أصعب شهر';

  @override
  String yearInReviewMonthNet(String month, String amount) {
    return '$month · صافي $amount';
  }

  @override
  String get yearInReviewTopCategories => 'أعلى التصنيفات';

  @override
  String get yearInReviewTopMerchants => 'أعلى التجار';

  @override
  String get yearInReviewIncomeSources => 'مصادر الدخل';

  @override
  String get incomeBySource => 'حسب المصدر';

  @override
  String get balanceRemainingBySource => 'الباقي حسب المصدر';

  @override
  String get balanceWalletTitle => 'الباقي في كل مصدر';

  @override
  String get balanceWalletSubtitle => 'الرصيد الابتدائي + الدخل − المصاريف من كل مصدر في الفترة دي.';

  @override
  String get balanceWalletFilterAll => 'الكل';

  @override
  String get balanceWalletInitial => 'ابتدائي';

  @override
  String get balanceWalletUnassignedHint => 'مصاريف مش مربوطة بمصدر محدد.';

  @override
  String get balanceOpenWallet => 'محفظتي';

  @override
  String get balanceWalletDialogTitle => 'محفظتي';

  @override
  String balanceWalletDialogPeriod(Object period) {
    return 'للفترة: $period';
  }

  @override
  String get balanceWalletDialogTotal => 'إجمالي المحفظة';

  @override
  String get balanceWalletDialogEmpty => 'حدّدي الرصيد الابتدائي لكل مصدر عشان تشوفي المحفظة هنا.';

  @override
  String get paymentMethodAddChip => '+ طريقة دفع';

  @override
  String get paymentMethodAddCancel => 'إلغاء';

  @override
  String get paymentMethodNewLabel => 'اسم الطريقة الجديدة';

  @override
  String get paymentMethodNewHint => 'مثال: فودافون كاش، إنستاباي، فوري';

  @override
  String get paymentMethodSave => 'احفظ الطريقة';

  @override
  String get paymentMethodNameEmpty => 'اكتب اسم طريقة الدفع.';

  @override
  String paymentMethodAdded(String name) {
    return 'اتضافت \"$name\" لطرق الدفع بتاعتك.';
  }

  @override
  String get expensePaidFromField => 'دفعت من';

  @override
  String get expensePaidFromNone => 'من غير';

  @override
  String get incomeUnassignedSpending => 'مصروف مش مربوط بمصدر';

  @override
  String get incomeFilterAllSources => 'كل المصادر';

  @override
  String get incomeFilterNoSourceEntries => 'مفيش دخل من المصدر ده في الفترة اللي اخترتها';

  @override
  String get incomeSourceManageEdit => 'غيّر اسم المصدر';

  @override
  String get incomeSourceManageRemove => 'شيل المصدر';

  @override
  String get incomeSourceRenameTitle => 'غيّر اسم المصدر';

  @override
  String incomeSourceRenameHint(String name) {
    return 'هيتعدّل كل الدخل اللي مصدره \"$name\".';
  }

  @override
  String get incomeSourceNameTaken => 'اسم المصدر ده مستخدم قبل كده';

  @override
  String get incomeSourceUpdatedSuccess => 'اتعدّلت المصادر';

  @override
  String get incomeSourceRemoveTitle => 'شيل المصدر';

  @override
  String incomeSourceRemoveMessage(int count, String name) {
    return 'عايز تعمل إيه بـ $count دخل مصدرهم \"$name\"؟';
  }

  @override
  String get incomeSourceMoveToOther => 'انقل الكل لـ «تاني»';

  @override
  String get incomeSourceDeleteAll => 'امسح كل الدخل بالمصدر ده';

  @override
  String get incomeSourceDeleteConfirmTitle => 'تمسح الدخل؟';

  @override
  String incomeSourceDeleteConfirmMessage(int count) {
    return 'هيتمسح $count دخل خالص. مفيش رجوع.';
  }

  @override
  String get incomeSourceDeleteConfirmAction => 'امسح';

  @override
  String get incomeSourceRents => 'إيجارات';

  @override
  String get incomeSourceVisaCard => 'فيزا';

  @override
  String get incomeSourceCash => 'كاش';

  @override
  String get amountField => 'المبلغ';

  @override
  String get expenseAmountShortcuts => 'مبالغ جاهزة';

  @override
  String get expenseShortcutTransport => 'مواصلات';

  @override
  String get expenseShortcutCoffee => 'قهوة';

  @override
  String get expenseShortcutSnack => 'سناك';

  @override
  String get expenseFabMenuTitle => 'مصروف جديد';

  @override
  String get expenseFabBlankOption => 'فورم فاضي';

  @override
  String get expenseFabFromLastPaste => 'من آخر رسالة اتحلّلت';

  @override
  String get expenseFabFromLastPasteSubtitle => 'بيستخدم آخر رسالة بنك أو محفظة حلّلتها في الاستيراد الذكي';

  @override
  String get expenseLastPasteNotExpense => 'آخر رسالة اتحلّلت شكلها دخل. ضيفها من تبويب الدخل.';

  @override
  String get expenseShortcutsSectionTitle => 'مصاريف بلمسة';

  @override
  String get expenseShortcutsEmptyCta => 'ظبّط اختصارات سريعة';

  @override
  String get expenseShortcutsManageTitle => 'اختصارات المصاريف';

  @override
  String get expenseShortcutsManageSubtitle => 'احفظ اسم الزرار، عنوان المصروف، التصنيف، دفعت من، والمبلغ. المس الشريط في تبويب المصاريف عشان تسجّله على طول.';

  @override
  String get expenseShortcutsEmptyBody => 'لسه مفيش اختصارات. ضيف قهوة، مواصلات، أو أي حاجة بتتكرر.';

  @override
  String get expenseShortcutAddTitle => 'اختصار جديد';

  @override
  String get expenseShortcutEditTitle => 'عدّل الاختصار';

  @override
  String get expenseShortcutChipLabelField => 'اسم الزرار';

  @override
  String get expenseShortcutChipLabelHint => 'مثال: قهوة';

  @override
  String get expenseShortcutExpenseTitleField => 'عنوان المصروف';

  @override
  String get expenseShortcutFormHint => 'بيسجّل المصروف ده النهاردة بلمسة واحدة من غير ما يفتح الفورم.';

  @override
  String get expenseShortcutSave => 'احفظ الاختصار';

  @override
  String get expenseShortcutDelete => 'امسح';

  @override
  String get expenseShortcutDeleteConfirmTitle => 'تمسح الاختصار؟';

  @override
  String expenseShortcutDeleteConfirmMessage(String name) {
    return 'تشيل \"$name\"؟';
  }

  @override
  String expenseShortcutLogged(String name) {
    return 'اتسجّل: $name';
  }

  @override
  String get expenseShortcutErrorLabel => 'اكتب اسم للزرار';

  @override
  String get expenseByCategory => 'حسب التصنيف';

  @override
  String get expenseCategoryEdit => 'عدّل التصنيف';

  @override
  String get expenseCategoryRemove => 'شيل التصنيف';

  @override
  String get expenseCategoryRenameTitle => 'غيّر اسم التصنيف';

  @override
  String expenseCategoryRenameHint(String name) {
    return 'هيتعدّل كل المصاريف في \"$name\".';
  }

  @override
  String get expenseCategoryNameTaken => 'اسم التصنيف ده مستخدم قبل كده';

  @override
  String get expenseCategoryUpdatedSuccess => 'اتعدّل التصنيف';

  @override
  String get expenseCategoryRemoveTitle => 'شيل التصنيف';

  @override
  String expenseCategoryRemoveMessage(int count, String name) {
    return 'عايز تعمل إيه بـ $count مصروف في \"$name\"؟';
  }

  @override
  String get expenseCategoryMoveToOther => 'انقل الكل لـ «تاني»';

  @override
  String get expenseCategoryDeleteAll => 'امسح كل مصاريف التصنيف ده';

  @override
  String get expenseCategoryDeleteConfirmTitle => 'تمسح المصاريف؟';

  @override
  String expenseCategoryDeleteConfirmMessage(int count) {
    return 'هيتمسح $count مصروف خالص. مفيش رجوع.';
  }

  @override
  String get expenseCategoryDeleteConfirmAction => 'امسح';

  @override
  String get expenseFilterAllCategories => 'كل التصنيفات';

  @override
  String get expenseFilterNoCategoryEntries => 'مفيش مصاريف للتصنيف ده في الفترة اللي اخترتها';

  @override
  String get budgetMonthlyTitle => 'ميزانية الشهر';

  @override
  String get budgetSetAction => 'حدّد ميزانية';

  @override
  String get budgetSetTitle => 'ميزانية شهرية';

  @override
  String get budgetEditTitle => 'عدّل ميزانية الشهر';

  @override
  String get budgetSetHint => 'اختار تصنيف وحدّد المبلغ اللي ناوي تصرفه الشهر ده.';

  @override
  String get budgetCustomCategory => 'اسم التصنيف';

  @override
  String get budgetMonthlyLimit => 'حد الشهر';

  @override
  String get budgetSave => 'احفظ الميزانية';

  @override
  String get budgetEmptyHint => 'حدّد سقف لكل تصنيف عشان تعرف صرفت كام من الميزانية.';

  @override
  String get budgetSetFirst => 'اعمل أول ميزانية';

  @override
  String get budgetTotalSpent => 'إجمالي المصروف';

  @override
  String budgetOverBy(String amount) {
    return 'زودت بـ $amount';
  }

  @override
  String get budgetDeleteTitle => 'تمسح الميزانية؟';

  @override
  String budgetDeleteMessage(String category) {
    return 'تمسح ميزانية $category؟';
  }

  @override
  String get budgetDeleteConfirm => 'امسح';

  @override
  String budgetAlertNear(int count) {
    return '$count تصنيف قرب يخلص';
  }

  @override
  String budgetAlertOver(int count) {
    return '$count تصنيف عدّى الميزانية';
  }

  @override
  String budgetAlertOverAndNear(int over, int near) {
    return '$over عدّوا الميزانية، $near قربوا يخلصوا';
  }

  @override
  String get categoryField => 'التصنيف';

  @override
  String get otherCategoryField => 'تصنيف تاني';

  @override
  String get otherCategoryHint => 'اكتب اسم التصنيف';

  @override
  String get saveExpense => 'احفظ المصروف';

  @override
  String get updateExpense => 'حدّث المصروف';

  @override
  String get expenseAddedSuccess => 'اتضاف المصروف';

  @override
  String get expenseUpdatedSuccess => 'اتعدّل المصروف';

  @override
  String get saveIncome => 'احفظ الدخل';

  @override
  String get updateIncome => 'حدّث الدخل';

  @override
  String get incomeAddedSuccess => 'اتضاف الدخل';

  @override
  String get incomeUpdatedSuccess => 'اتعدّل الدخل';

  @override
  String get errorEnterTitle => 'اكتب عنوان';

  @override
  String get errorEnterValidAmount => 'اكتب مبلغ صح';

  @override
  String pocketInsufficientFunds(String amount) {
    return 'مفيش كفاية في المحفظة. المتاح: $amount';
  }

  @override
  String get errorEnterCategoryName => 'اكتب اسم التصنيف';

  @override
  String get errorSavedExceedsTarget => 'المبلغ المحفوظ ما ينفعش يعدّي الهدف';

  @override
  String get expenseCatFood => 'أكل';

  @override
  String get expenseCatRent => 'إيجار';

  @override
  String get expenseCatTransport => 'مواصلات';

  @override
  String get expenseCatShopping => 'تسوق';

  @override
  String get expenseCatBills => 'فواتير';

  @override
  String get expenseCatOther => 'تاني';

  @override
  String get incomeCatWork => 'شغل';

  @override
  String get incomeCatFreelance => 'فريلانس';

  @override
  String get incomeCatBusiness => 'بيزنس';

  @override
  String get incomeCatInvestment => 'استثمار';

  @override
  String get incomeCatOther => 'تاني';

  @override
  String get planCatSavings => 'توفير';

  @override
  String get planCatTravel => 'سفر';

  @override
  String get planCatPurchase => 'شراء';

  @override
  String get planCatEducation => 'تعليم';

  @override
  String get planCatOther => 'تاني';

  @override
  String get planNewFab => 'هدف جديد';

  @override
  String get planEditGoal => 'عدّل الهدف';

  @override
  String get planAddPlan => 'ضيف خطة';

  @override
  String get goalTitleLabel => 'اسم الهدف';

  @override
  String get goalTitleHint => 'مثال: فلوس طوارئ';

  @override
  String get targetAmountLabel => 'المبلغ اللي عايزه';

  @override
  String get amountSavedLabel => 'اللي وفّرته';

  @override
  String get amountSavedHint => 'تقدم مبدئي بس — مش بيتخصم من صافي الرصيد. استخدم «ضيف لهدف» من تبويب الرصيد عشان تحوّل من المحفظة.';

  @override
  String get setDeadlineOptional => 'حدّد موعد (اختياري)';

  @override
  String get savePlan => 'احفظ الخطة';

  @override
  String get updateGoal => 'حدّث الهدف';

  @override
  String get errorEnterGoalTitle => 'اكتب اسم الهدف';

  @override
  String get errorEnterTargetAmount => 'اكتب مبلغ هدف صح';

  @override
  String get errorEnterAmountSaved => 'اكتب المبلغ اللي وفّرته';

  @override
  String get updateSavedTitle => 'حدّث اللي وفّرته';

  @override
  String targetWithAmount(Object amount) {
    return 'الهدف: $amount';
  }

  @override
  String get saveAmountButton => 'احفظ المبلغ';

  @override
  String get errorEnterValidSavedAmount => 'اكتب مبلغ موفّر صح';

  @override
  String get balanceNetBalance => 'صافي الرصيد';

  @override
  String get balanceInitialBalanceTitle => 'الرصيد الابتدائي';

  @override
  String get balanceInitialBalanceHint => 'المبلغ اللي كان معاك لما بدأت تستخدم التطبيق.';

  @override
  String get balanceInitialBalanceAddSource => 'ضيف مصدر تاني';

  @override
  String get balanceInitialBalanceBySource => 'حسب المصدر';

  @override
  String balanceInitialBalanceIncludes(Object amount) {
    return 'يشمل رصيد ابتدائي $amount';
  }

  @override
  String get balanceInitialBalanceSaved => 'اتحدّث الرصيد الابتدائي';

  @override
  String get balanceEditInitialBalance => 'عدّل الرصيد الابتدائي';

  @override
  String get settingsInitialBalance => 'الرصيد الابتدائي';

  @override
  String balanceSavedThisMonth(int percent) {
    return 'وفّرت $percent% الشهر ده';
  }

  @override
  String balanceSavedPercent(int percent) {
    return 'وفّرت $percent%';
  }

  @override
  String get balanceStatIncome => 'الدخل';

  @override
  String get balanceStatExpense => 'المصاريف';

  @override
  String get balanceRecentActivity => 'آخر حركة';

  @override
  String get balanceAddToPlan => 'ضيف لهدف';

  @override
  String get balanceAddToPlanTitle => 'ضيف لهدف توفير';

  @override
  String balanceAddToPlanHint(Object amount) {
    return 'اللي متاح من الرصيد: $amount';
  }

  @override
  String get balanceSelectPlan => 'اختار هدف';

  @override
  String get balanceAmountToAllocate => 'المبلغ اللي هتضيفه';

  @override
  String balancePlanRemaining(Object amount) {
    return 'باقي $amount عشان توصل للهدف';
  }

  @override
  String get balanceAddToPlanSuccess => 'اتضاف المبلغ لهدف التوفير';

  @override
  String get balanceNoSurplusForPlan => 'مفيش صافي رصيد متاح عشان تضيفه لهدف.';

  @override
  String get balancePlanAllocationPaidFromHint => 'اختار المصدر اللي هيتخصم منه المبلغ ده (بيظهر في الرصيد مش كمصروف مش مربوط).';

  @override
  String get planAllocationSelectPaidFrom => 'اختار «دفعت من» عشان تخصّص للهدف';

  @override
  String balancePlanAllocationExpenseTitle(String planTitle) {
    return 'هدف توفير: $planTitle';
  }

  @override
  String get balanceNoPlansForAllocation => 'اعمل هدف توفير من تبويب الخطط الأول.';

  @override
  String get balanceAmountExceedsSurplus => 'المبلغ أكبر من الرصيد المتاح';

  @override
  String itemsCount(int count) {
    return '$count حاجة';
  }

  @override
  String listEntryCount(int count) {
    return '$count سجل';
  }

  @override
  String get clearAllExpenses => 'امسح الكل';

  @override
  String get clearAllIncomes => 'امسح الكل';

  @override
  String get clearAllExpensesConfirmTitle => 'تمسح كل المصاريف؟';

  @override
  String get clearAllIncomesConfirmTitle => 'تمسح كل الدخل؟';

  @override
  String clearAllExpensesConfirmMessage(int count) {
    return 'هيتمسح كل المصاريف ($count) خالص. مفيش رجوع.';
  }

  @override
  String clearAllIncomesConfirmMessage(int count) {
    return 'هيتمسح كل الدخل ($count) خالص. مفيش رجوع.';
  }

  @override
  String get clearAllExpensesSuccess => 'اتمسحت كل المصاريف';

  @override
  String get clearAllIncomesSuccess => 'اتمسح كل الدخل';

  @override
  String get balanceIncomeVsExpenses => 'الدخل والمصاريف';

  @override
  String get balanceFilterAll => 'الكل';

  @override
  String get balanceFilterIncome => 'الدخل';

  @override
  String get balanceFilterExpense => 'المصاريف';

  @override
  String get balanceNoFilteredActivity => 'مفيش حركة بالفلتر ده';

  @override
  String get activityIncome => 'دخل';

  @override
  String get activityExpense => 'مصروف';

  @override
  String get plansActive => 'شغّال';

  @override
  String get plansDone => 'خلص';

  @override
  String get plansRemaining => 'باقي';

  @override
  String get plansSavingsGoalsSection => 'أهداف التوفير';

  @override
  String get plansGoalsOverview => 'نظرة على الأهداف';

  @override
  String plansSavedOfTarget(Object total) {
    return 'من $total موفّر';
  }

  @override
  String get plansDonePercentLabel => 'خلص';

  @override
  String plansGoalsCompletedSummary(int completed, int total) {
    return '$completed من $total أهداف خلصت';
  }

  @override
  String plansMoneyLeft(Object amount) {
    return 'باقي $amount';
  }

  @override
  String ofTargetAmount(Object amount) {
    return 'من $amount';
  }

  @override
  String dueDateLabel(Object date) {
    return 'مستحق $date';
  }

  @override
  String get planGoalCompleted => 'الهدف خلص';

  @override
  String get planTapToEditGoal => 'اضغط عشان تعدّل الهدف';

  @override
  String planCoachMonthly(String amount) {
    return 'وفّر $amount كل شهر عشان تلحق الموعد';
  }

  @override
  String planCoachOverdue(String amount) {
    return 'الموعد عدّى — باقي $amount';
  }

  @override
  String planCoachUrgent(String amount) {
    return 'قرب الموعد — باقي $amount';
  }

  @override
  String planCoachRemaining(String amount) {
    return 'باقي $amount عشان توصل للهدف';
  }

  @override
  String get planCoachTipTitle => 'كمل على الطريق';

  @override
  String planCoachSurplusTip(String amount) {
    return 'عندك $amount متاح. ضيف جزء على هدف عشان تقرب.';
  }

  @override
  String planCoachAddSuggested(String amount) {
    return 'ضيف المقترح $amount';
  }

  @override
  String get planSuggestThisMonth => 'الشهر ده';

  @override
  String get planSuggestHalf => 'النص';

  @override
  String get planSuggestAllAvailable => 'كل المتاح';

  @override
  String get planSuggestFinish => 'كمّل الهدف';

  @override
  String get planTemplateEmergency => 'صندوق طوارئ';

  @override
  String get planTemplateVacation => 'إجازة';

  @override
  String get planTemplateNewPhone => 'موبايل جديد';

  @override
  String get planTemplateEducation => 'تعليم';

  @override
  String get planTemplatesTitle => 'أفكار سريعة';

  @override
  String get planHowItHelps => 'حط هدف ومبلغ، وموعد لو حابب، وبعدين حرّك فلوس من الرصيد بزرار إضافة للهدف.';

  @override
  String get plansEmptyTitle => 'ابدأ أول هدف';

  @override
  String get plansEmptySubtitle => 'حدّد هدف، تابع اللي وفّرته، وشوف تقدّمك.';

  @override
  String get plansCreateGoalButton => 'اعمل هدف';

  @override
  String get demoSalary => 'مرتب';

  @override
  String get demoRent => 'إيجار';

  @override
  String get demoFreelanceProject => 'مشروع فريلانس';

  @override
  String get demoGroceries => 'مشتريات';

  @override
  String get demoGas => 'بنزين';

  @override
  String get demoElectricBill => 'فاتورة كهربا';

  @override
  String get demoUtilities => 'مرافق';

  @override
  String get demoSideBusiness => 'شغل جانبي';

  @override
  String get demoEmergencyFund => 'فلوس طوارئ';

  @override
  String get demoSummerVacation => 'أجازة صيف';

  @override
  String get demoNewLaptop => 'لابتوب جديد';

  @override
  String storedAsBase(Object amount) {
    return 'بيتحفظ كـ $amount (عملة الحساب)';
  }

  @override
  String get smartImportTitle => 'استيراد ذكي';

  @override
  String get smartImportShort => 'استيراد';

  @override
  String get smartImportPasteTab => 'لصق';

  @override
  String get smartImportQuickTab => 'سريع';

  @override
  String get smartImportSmsTab => 'رسائل SMS';

  @override
  String get smartImportQuickHint => 'مفيش رسالة تلصقها؟ اكتب المبلغ، اختار مصروف أو دخل، والتصنيف والمصدر — ضيف بضغطة.';

  @override
  String get smartImportQuickTypeLabel => 'نوع المعاملة';

  @override
  String get smartImportQuickAmountLabel => 'المبلغ';

  @override
  String get smartImportQuickTitleHint => 'قهوة، إيجار، مرتب… (اختياري)';

  @override
  String get smartImportQuickAddNow => 'ضيف دلوقتي';

  @override
  String get smartImportQuickReview => 'راجع في الفورم الكامل';

  @override
  String get smartImportQuickAdded => 'اتضافت المعاملة.';

  @override
  String get magicAddTitle => 'إضافة ذكية';

  @override
  String get magicAddShort => 'ذكاء';

  @override
  String get magicAddTab => 'ذكاء';

  @override
  String get magicAddHint => 'اكتب أو قول اللي حصل — زي «قهوة 50 امبارح» أو «راتب 8000». هنحدد النوع والتصنيف والتاريخ.';

  @override
  String get magicAddFieldLabel => 'حصل إيه؟';

  @override
  String get magicAddFieldHint => 'قهوة 50، أوبر 30 امبارح';

  @override
  String get magicAddListen => 'اتكلم';

  @override
  String get magicAddListening => 'بنسمع…';

  @override
  String get magicAddVoiceUnavailable => 'الإدخال بالصوت مش متاح على الجهاز ده.';

  @override
  String get magicAddVoicePermissionDenied => 'محتاج إذن الميكروفون عشان تضيف بصوتك.';

  @override
  String get magicAddVoicePermanentlyDenied => 'إذن الميكروفون مقفول. فعّله من إعدادات الموبايل وبعدين اضغط اتكلم تاني.';

  @override
  String get magicAddNoAmount => 'ضيف مبلغ، زي: قهوة 50';

  @override
  String get magicAddExampleCoffee => 'coffee 50';

  @override
  String get magicAddExampleUber => 'uber 30 yesterday';

  @override
  String get magicAddExampleSalary => 'راتب 8000';

  @override
  String get magicAddExampleArabic => 'قهوة 45';

  @override
  String get magicAddPreviewTitle => 'جاهز للإضافة';

  @override
  String magicAddAddAll(int count) {
    return 'ضيف $count';
  }

  @override
  String get magicAddAddOne => 'ضيف المعاملة';

  @override
  String get magicAddOpenForm => 'الفورم الكامل';

  @override
  String get expenseFabAiOption => 'اكتب أو اتكلم';

  @override
  String get expenseFabAiOptionSubtitle => 'زي: قهوة 50 امبارح';

  @override
  String get incomeFabMenuTitle => 'دخل جديد';

  @override
  String get smartImportPasteHint => 'الصق رسالة أو أكتر من البنك أو المحفظة. سطر فاضي بين الرسائل، أو الصق كذا رسالة ورا بعض. بنعرف المبلغ ونوع كل رسالة (دخل ولا مصروف).';

  @override
  String get smartImportPasteShareTip => 'نصيحة: من الرسائل → مشاركة → استيراد لـ Pocketly من غير نسخ ولصق.';

  @override
  String get smartImportSharedTextReady => 'اتحمّلت الرسالة اللي اتشاركت. راجعها تحت وضيفها.';

  @override
  String get smartImportScrollToTop => 'فوق';

  @override
  String get smartImportPasteFieldLabel => 'نص الرسالة';

  @override
  String get smartImportPasteFieldHint => 'الصق رسالة أو أكتر (سطر فاضي بين كل رسالة)';

  @override
  String get smartImportPasteFromClipboard => 'لصق من الحافظة';

  @override
  String get smartImportParseMessage => 'حلّل الرسالة';

  @override
  String get smartImportParseMessages => 'حلّل الرسائل';

  @override
  String smartImportPasteFoundCount(int count) {
    return 'لقينا $count رسالة';
  }

  @override
  String smartImportPasteAddedOneRemaining(int count) {
    return 'اتضافت. $count رسالة جاهزة للاستيراد.';
  }

  @override
  String get smartImportPasteProcessing => 'بنقرا الرسالة…';

  @override
  String get smartImportPasteNoData => 'ملقيناش مبلغ في النص. جرّب رسالة البنك كاملة.';

  @override
  String get smartImportPasteEmpty => 'الصق رسالة الأول.';

  @override
  String get smartImportPasteClipboardEmpty => 'الحافظة فاضية. انسخ رسالة بنك أو محفظة الأول.';

  @override
  String get smartImportPasteClear => 'امسح';

  @override
  String get smartImportPasteAddedSuccess => 'اتضافت. تقدر تلصق رسالة تانية دلوقتي.';

  @override
  String get smartImportPasteParseAnother => 'حلّل رسالة تانية';

  @override
  String get smartImportPasteMarkExpense => 'سجّل كمصروف';

  @override
  String get smartImportPasteMarkIncome => 'سجّل كدخل';

  @override
  String get smartImportDefaultBillTitle => 'فاتورة';

  @override
  String get smartImportExtractedData => 'البيانات اللي طلعت';

  @override
  String get smartImportDateField => 'التاريخ';

  @override
  String get smartImportTypeField => 'النوع';

  @override
  String get smartImportAddToApp => 'ضيف للتطبيق';

  @override
  String get smartImportSmsNotSupported => 'قراءة SMS على أندرويد بس.';

  @override
  String get smartImportSmsEmpty => 'ملقيناش رسائل فلوس. ادّي إذن SMS لو طلب منك.';

  @override
  String get smartImportSmsFailed => 'ما قدرناش نقرا رسائل SMS.';

  @override
  String get smartImportReloadSms => 'حمّل تاني';

  @override
  String get smartImportSmsAlreadyAdded => 'اتضافت قبل كده';

  @override
  String get smartImportSmsAddAgain => 'ضيف تاني';

  @override
  String get smartImportSmsClearAllAdded => 'امسح اللي اتضاف';

  @override
  String get smartImportSmsClearAllAddedConfirmTitle => 'تمسح سجل الاستيراد؟';

  @override
  String get smartImportSmsClearAllAddedConfirmMessage => 'كل الرسائل هتظهر تاني كأنها ما اتضافتش وتقدر تستوردها من جديد. المصاريف والدخل اللي في التطبيق مش هيتمسحوا.';

  @override
  String get smartImportSmsClearAllAddedDone => 'اتمسح سجل الاستيراد';

  @override
  String smartImportSmsSkippedDuplicate(int count) {
    return '$count رسالة موجودة في التطبيق أصلاً.';
  }

  @override
  String get smartImportSmsLoadMore => 'حمّل رسائل أكتر';

  @override
  String get smartImportSmsLoading => 'بنقرا رسائل SMS…';

  @override
  String get smartImportSmsLoadingMore => 'بيتحمّل…';

  @override
  String smartImportSmsListCap(int count) {
    return 'آخر $count رسالة فلوس. اسحب للتحديث.';
  }

  @override
  String get smartImportUnknownSender => 'مرسل مش معروف';

  @override
  String get smartImportSmsTitleExpense => 'مصروف بنك';

  @override
  String get smartImportSmsTitleIncome => 'دخل بنك';

  @override
  String get smartImportSmsShowBody => 'اعرض الرسالة كاملة';

  @override
  String get smartImportSmsHideBody => 'اخفي الرسالة';

  @override
  String get smartImportSmsFilterReady => 'جاهز';

  @override
  String get smartImportSmsFilterExpenses => 'مصاريف';

  @override
  String get smartImportSmsFilterIncomes => 'دخل';

  @override
  String get smartImportSmsFilterAdded => 'اتضاف';

  @override
  String get smartImportSmsFilterAll => 'الكل';

  @override
  String smartImportSmsSummary(int ready, int added, int noAmount) {
    return '$ready جاهز · $added اتضاف · $noAmount من غير مبلغ';
  }

  @override
  String get smartImportSmsFilterEmpty => 'مفيش حاجة في الفلتر ده. جرّب فلتر تاني أو اسحب للتحديث.';

  @override
  String get smartImportSmsNoAmount => 'مفيش مبلغ';

  @override
  String get smartImportSmsReviewAdd => 'راجع وضيف';

  @override
  String get smartImportSmsHintSelect => 'المربع للاختيار المتعدد · اضغط الكارت للمراجعة';

  @override
  String get smartImportTapToImport => 'اضغط للمراجعة';

  @override
  String smartImportAddAllExpenses(int count) {
    return 'ضيف كل المصاريف ($count)';
  }

  @override
  String smartImportAddAllIncomes(int count) {
    return 'ضيف كل الدخل ($count)';
  }

  @override
  String smartImportAddSelected(int count) {
    return 'ضيف المحدد ($count)';
  }

  @override
  String get smartImportSelectAll => 'حدّد الكل';

  @override
  String get smartImportClearSelection => 'الغِ التحديد';

  @override
  String get smartImportBulkCategorySheetTitle => 'التصنيف للاستيراد';

  @override
  String get smartImportBulkCategorySheetHint => 'اختار التصنيف والمصدر. بنقترح من الرسالة لما نقدر، وتقدر تغيّر.';

  @override
  String get smartImportBulkExpensePaidFromHint => 'مقترح من الرسالة لو قدرنا — غيّره لو محتاج.';

  @override
  String get smartImportBulkIncomeSourceHint => 'مقترح من الرسالة لو قدرنا — غيّره لو محتاج.';

  @override
  String get smartImportBulkSelectPaidFrom => 'اختار «دفعت من»';

  @override
  String get smartImportBulkSelectIncomeSource => 'اختار مصدر الدخل';

  @override
  String get smartImportBulkExpenseCategory => 'تصنيف المصروف';

  @override
  String get smartImportBulkIncomeSource => 'مصدر الدخل';

  @override
  String get smartImportBulkApplyAndImport => 'استورد';

  @override
  String get smartImportBulkImporting => 'بنستورد الرسائل…';

  @override
  String get smartImportBulkNothingToAdd => 'مفيش رسائل بمبلغ نقدر نستوردها.';

  @override
  String smartImportBulkResult(int incomes, int expenses) {
    return 'اتضاف $incomes دخل و$expenses مصروف.';
  }

  @override
  String smartImportBulkPartialFail(int failed) {
    return 'ما قدرناش نستورد $failed رسالة.';
  }

  @override
  String get settingsAppLock => 'قفل التطبيق';

  @override
  String get settingsAppLockBiometric => 'Face ID / بصمة';

  @override
  String get settingsAppLockChangePin => 'غيّر رمز PIN';

  @override
  String get appLockTitle => 'افتح Pocketly';

  @override
  String get appLockSubtitle => 'اكتب رمز PIN عشان تكمل';

  @override
  String get appLockWrongPin => 'رمز PIN غلط. جرّب تاني.';

  @override
  String get appLockBiometricReason => 'افتح حسابك';

  @override
  String get appLockEnterPinTitle => 'اكتب رمز PIN';

  @override
  String get appLockEnterPinSubtitle => 'أكّد عشان تكمل';

  @override
  String get appLockCreatePinTitle => 'اعمل رمز PIN';

  @override
  String get appLockCreatePinSubtitle => '4 أرقام تفتكرها بسهولة';

  @override
  String get appLockConfirmPinTitle => 'أكّد رمز PIN';

  @override
  String get appLockConfirmPinSubtitle => 'اكتب نفس الرمز تاني';

  @override
  String get appLockPinMismatch => 'رمزين PIN مش متطابقين';

  @override
  String get appLockEnabledSuccess => 'قفل التطبيق اتفعّل';

  @override
  String get appLockDisabledSuccess => 'قفل التطبيق اتقفل';

  @override
  String get appLockEnableFailed => 'ما قدرناش نفعّل قفل التطبيق';

  @override
  String get appLockBiometricPromptTitle => 'تستخدم البصمة؟';

  @override
  String get appLockBiometricPromptMessage => 'افتح التطبيق بسرعة بـ Face ID أو بصمة على الجهاز ده.';

  @override
  String get appLockBiometricFailed => 'ما قدرناش نفعّل البصمة';

  @override
  String get appLockChangePinSuccess => 'اتغيّر رمز PIN';

  @override
  String get appLockChangePinFailed => 'ما قدرناش نغيّر رمز PIN';

  @override
  String get notNow => 'مش دلوقتي';

  @override
  String get enable => 'فعّل';

  @override
  String get monthlyReportTitle => 'تقرير الشهر';

  @override
  String get monthlyReportShort => 'تقرير';

  @override
  String get monthlyReportVsLastMonth => 'مقارنة بالشهر اللي فات';

  @override
  String get monthlyReportBudgetTitle => 'الميزانية واللي صرفته';

  @override
  String get monthlyReportNoBudgets => 'مفيش ميزانيات الشهر ده. ضيف حدود من تبويب المصاريف عشان تتابع صرفك هنا.';

  @override
  String monthlyReportEntrySummary(int incomeCount, int expenseCount) {
    return '$incomeCount مصدر دخل · $expenseCount تصنيف مصاريف';
  }

  @override
  String get globalSearchTitle => 'بحث';

  @override
  String get globalSearchHint => 'العنوان، التصنيف، المصدر، المبلغ…';

  @override
  String get globalSearchAll => 'الكل';

  @override
  String get globalSearchNoResults => 'مفيش نتائج';

  @override
  String get globalSearchAllTime => 'كل الفترات';

  @override
  String get globalSearchCurrentPeriod => 'الفترة الحالية';

  @override
  String get currencyUsDollar => 'دولار أمريكي';

  @override
  String get currencyEuro => 'يورو';

  @override
  String get expenseReceiptLabel => 'صورة الإيصال';

  @override
  String get expenseReceiptAttach => 'إرفاق إيصال';

  @override
  String get expenseReceiptReplace => 'استبدال الصورة';

  @override
  String get expenseReceiptRemove => 'إزالة';

  @override
  String get expenseReceiptUploadFailed => 'تعذّر رفع الإيصال. حاول مرة أخرى.';

  @override
  String get expenseReceiptInvalidType => 'اختر صورة (JPG أو PNG أو WebP). الفيديو غير مدعوم.';

  @override
  String get subscriptionsTitle => 'الاشتراكات';

  @override
  String get subscriptionsAdd => 'ضيف اشتراك';

  @override
  String get subscriptionsEmptyTitle => 'تابع نتفلكس والجيم والفواتير';

  @override
  String get subscriptionsEmptySubtitle => 'ضيف اشتراكات شهرية عشان تشوف اللي مستحق الأسبوع ده وإجمالي الصرف.';

  @override
  String get subscriptionsMonthlyTotal => 'الإجمالي الشهري';

  @override
  String subscriptionsCount(int count) {
    return '$count اشتراك';
  }

  @override
  String get subscriptionsDueThisWeek => 'مستحق الأسبوع ده';

  @override
  String get subscriptionsAll => 'كل الاشتراكات';

  @override
  String subscriptionsDueOn(String date) {
    return 'مستحق $date';
  }

  @override
  String get zakatTitle => 'حاسبة الزكاة';

  @override
  String get zakatDisclaimer => 'تقدير فقط (٢٫٥٪ على صافي المال الزكوي). أدخل الذهب والفضة بالوزن بالجرام؛ القيمة = الجرام × السعر. استشر عالماً لحالتك.';

  @override
  String get zakatFillFromLedger => 'تعبئة من دفتر الحساب';

  @override
  String get zakatFillFromLedgerDone => 'تمت إضافة النقد وخطط الادخار من دفترك';

  @override
  String get zakatPricesSection => 'أسعار السوق (للجرام)';

  @override
  String get zakatPricesHint => 'تُستخدم لتقييم الذهب والفضة وحساب النصاب.';

  @override
  String get zakatPricePerGramSuffix => 'ج.م/جم';

  @override
  String get zakatAssetsSection => 'الأصول الزكوية';

  @override
  String get zakatDeductionsSection => 'الخصوم';

  @override
  String get zakatNisabSection => 'النصاب (الحد الأدنى)';

  @override
  String get zakatCash => 'نقد وبنوك';

  @override
  String get zakatGold => 'وزن الذهب (عيار ٢٤، جرام)';

  @override
  String get zakatSilver => 'وزن الفضة (جرام)';

  @override
  String get zakatInvestments => 'استثمارات وادخار';

  @override
  String get zakatBusinessGoods => 'بضاعة / تجارة';

  @override
  String get zakatReceivables => 'ديون لك عند الغير';

  @override
  String get zakatDebts => 'ديون والتزامات';

  @override
  String get zakatGoldPricePerGram => 'سعر الذهب (عيار ٢٤)';

  @override
  String get zakatSilverPricePerGram => 'سعر الفضة';

  @override
  String get zakatAmountHint => '٠';

  @override
  String get zakatGoldPriceHint => 'مثال: 4500';

  @override
  String get zakatSilverPriceHint => 'مثال: 55';

  @override
  String get zakatGoldWeightHint => 'مثال: 50';

  @override
  String get zakatSilverWeightHint => 'مثال: 200';

  @override
  String zakatComputedValue(String amount) {
    return '≈ $amount';
  }

  @override
  String zakatNisabHint(int goldGrams, int silverGrams) {
    return 'مرجع النصاب: $goldGrams جرام ذهب أو $silverGrams جرام فضة (التطبيق يستخدم $goldGrams ج × سعر الذهب).';
  }

  @override
  String get zakatResultTitle => 'التقدير';

  @override
  String get zakatTotalAssets => 'إجمالي الأصول';

  @override
  String get zakatNetWealth => 'صافي المال';

  @override
  String get zakatNisabThreshold => 'حد النصاب';

  @override
  String get zakatMeetsNisab => 'بلغت النصاب — الزكاة التقديرية:';

  @override
  String get zakatBelowNisab => 'أقل من النصاب — لا زكاة:';

  @override
  String get zakatDueLabel => 'الزكاة التقديرية (٢٫٥٪)';

  @override
  String get zakatRateNote => 'يُفترض حولان الحول على المال. عدّل الأرقام حسب حالتك.';

  @override
  String get homeWidgetTodayExpenses => 'مصروف اليوم';

  @override
  String get homeWidgetSettingsTile => 'ويدجت الشاشة الرئيسية';

  @override
  String get homeWidgetQuickName => 'مصروف سريع';

  @override
  String get homeWidgetQuickSettingsTile => 'ويدجت المصروف السريع';

  @override
  String get homeWidgetPinUnsupported => 'مشغّل الشاشة لا يدعم تثبيت الويدجت. اضغط مطولًا على الشاشة الرئيسية واختر ويدجت، ثم أضف Pocketly.';

  @override
  String get planImageLabel => 'صورة الهدف';

  @override
  String get planImageAttach => 'أضف صورة';

  @override
  String get planImageReplace => 'تغيير الصورة';

  @override
  String get planImageRemove => 'حذف الصورة';

  @override
  String get planImageUploadFailed => 'تعذر رفع الصورة. حاول مرة أخرى.';

  @override
  String get manage => 'إدارة';

  @override
  String get dailyBudget => 'الميزانية اليومية';

  @override
  String get expenseTracking => 'تتبع المصروفات';

  @override
  String get savingsGoal => 'هدف الادخار';

  @override
  String get dailyLimit => 'الميزانية اليومية';

  @override
  String get budgetExceeded => 'لقد تجاوزت ميزانيتك اليومية';

  @override
  String budgetRemaining(String amount) {
    return 'باقي $amount';
  }

  @override
  String get editBudget => 'تعديل الميزانية';

  @override
  String get enterBudget => 'أدخل الميزانية اليومية';

  @override
  String get invalidBudget => 'أدخل مبلغًا صحيحًا أكبر من صفر';

  @override
  String get dailyBudgetTitle => 'ميزانيتك اليومية';

  @override
  String get dailyBudgetSubtitle => 'تابعي مصروفاتك وحد الإنفاق اليومي';

  @override
  String get editDailyBudget => 'تعديل الميزانية اليومية';

  @override
  String get remainingToday => 'المتبقي اليوم';

  @override
  String get expensesToday => 'مصروفات اليوم';

  @override
  String dailyBudgetAmount(String amount) {
    return 'الميزانية: $amount ج.م';
  }

  @override
  String budgetUsedPercent(String percent) {
    return '$percent% مستخدم';
  }

  @override
  String get addExpenseOrIncome => 'إضافة مصروف أو دخل';

  @override
  String get trackBudgetSubtitle => 'سجّلي مصروفك وتابعي ميزانيتك';

  @override
  String dailyBudgetExceededMessage(String amount) {
    return 'تجاوزت ميزانيتك اليومية بمقدار $amount ج.م. حاولي تقليل الإنفاق لبقية اليوم.';
  }

  @override
  String dailyBudgetRemainingMessage(String amount) {
    return 'متبقي لك $amount ج.م من ميزانيتك اليومية.';
  }

  @override
  String get dailyBudgetInputLabel => 'المبلغ اليومي بالجنيه المصري';

  @override
  String egpAmount(String amount) {
    return '$amount ج.م';
  }

  @override
  String get egpCurrency => 'ج.م';

  @override
  String get dailyExpensesSummaryTitle => 'ملخص مصروفات اليوم';

  @override
  String get dailyExpensesTotalLabel => 'إجمالي ما أنفقته اليوم';

  @override
  String get dailyExpensesRecordedMessage => 'إجمالي مصروفاتك المسجلة خلال اليوم.';

  @override
  String get dailyExpensesEmptyMessage => 'لم تسجل أي مصروفات اليوم حتى الآن.';
}
