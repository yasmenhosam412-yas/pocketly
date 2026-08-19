// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'imrpo';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get onboardingPage1Title => 'Your money, one place';

  @override
  String get onboardingPage1Body => 'Track income and expenses in Egyptian pounds. See your balance and stay on top of spending.';

  @override
  String get onboardingPage2Title => 'Ledgers & smart import';

  @override
  String get onboardingPage2Body => 'Use personal or shared ledgers. Import transactions from SMS or shared text and add them in seconds.';

  @override
  String get onboardingPage3Title => 'Reminders & insights';

  @override
  String get onboardingPage3Body => 'Get bill reminders before due dates and view 3-month charts for income, expenses, and categories.';

  @override
  String get tabIncomes => 'Incomes';

  @override
  String get tabExpenses => 'Expenses';

  @override
  String get tabBalance => 'Balance';

  @override
  String get tabPlans => 'Plans';

  @override
  String get tabStatistics => 'Stats';

  @override
  String get statisticsLast3Months => 'Last 3 months';

  @override
  String get statisticsMonthlyTrend => 'Monthly income vs expenses';

  @override
  String get statisticsNetPerMonth => 'Net per month';

  @override
  String get statisticsTotalIncome => 'Total income';

  @override
  String get statisticsTotalExpenses => 'Total expenses';

  @override
  String get statisticsNet3Months => 'Net (3 months)';

  @override
  String statisticsAvgMonthlyNet(String amount) {
    return 'Avg. per month: $amount';
  }

  @override
  String get statisticsTopExpenses => 'Top expense categories (3 mo)';

  @override
  String get statisticsTopIncomeSources => 'Top income sources (3 mo)';

  @override
  String get statisticsEmpty => 'Add incomes and expenses to see your 3-month charts.';

  @override
  String get associationPersonal => 'Personal';

  @override
  String get currencyEgyptianPound => 'Egyptian pound';

  @override
  String get currencyEgpSymbol => 'E£';

  @override
  String get billRemindersTitle => 'Bill reminders';

  @override
  String get billRemindersSubtitle => 'Get notified before recurring bills are due';

  @override
  String get billRemindersEmpty => 'No bill reminders yet. Add electricity, rent, internet, and more.';

  @override
  String get billRemindersAdd => 'Add reminder';

  @override
  String get billRemindersEdit => 'Edit reminder';

  @override
  String get billRemindersTitleLabel => 'Bill name';

  @override
  String get billRemindersTitleHint => 'e.g. Electricity, Rent, Internet';

  @override
  String get billRemindersTitleRequired => 'Enter a name for the bill';

  @override
  String get billRemindersAmountLabel => 'Amount (optional)';

  @override
  String get billRemindersTimeLabel => 'Notification time';

  @override
  String get billRemindersDayOfMonth => 'Day of month';

  @override
  String get billRemindersDayOfMonthShortMonthHint => 'In shorter months, the reminder uses the last day of that month.';

  @override
  String billRemindersDayOfMonthValue(int day) {
    return 'Day $day';
  }

  @override
  String get billRemindersRemindBefore => 'Remind me';

  @override
  String get billRemindersRemindOnDay => 'On due day';

  @override
  String get billRemindersRemind1Day => '1 day before';

  @override
  String get billRemindersRemind3Days => '3 days before';

  @override
  String get billRemindersRemind7Days => '7 days before';

  @override
  String get billRemindersEnabled => 'Bill reminders';

  @override
  String get dailyDigestEnabled => 'Daily summary';

  @override
  String get dailyDigestSubtitle => 'Evening recap of yesterday\'s spending and your month so far';

  @override
  String get dailyDigestTimeLabel => 'Summary time';

  @override
  String get dailyDigestNotificationTitle => 'Your money yesterday';

  @override
  String get dailyDigestNotificationEmpty => 'No transactions logged yesterday. Open Pocketly to track today\'s spending.';

  @override
  String dailyDigestYesterdayExpenses(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses ($amount)',
      one: '1 expense ($amount)',
    );
    return '$_temp0';
  }

  @override
  String get dailyDigestYesterdayNoExpenses => 'No expenses yesterday';

  @override
  String dailyDigestYesterdayIncomes(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count incomes ($amount)',
      one: '1 income ($amount)',
    );
    return '$_temp0';
  }

  @override
  String get dailyDigestYesterdayNoIncomes => 'No income yesterday';

  @override
  String dailyDigestMonthNet(String amount) {
    return 'Month net: $amount';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsSubtitle => 'Manage bill reminders, daily summaries, and see what\'s scheduled next.';

  @override
  String get notificationsMessageLabel => 'Notification message';

  @override
  String get notificationsInbox => 'Recent alerts';

  @override
  String get notificationsUpcoming => 'Upcoming';

  @override
  String get notificationsUpcomingEmpty => 'No notifications scheduled. Turn on bill reminders or daily summary above.';

  @override
  String get notificationsPermissionBanner => 'Notifications are off in system settings. Enable them to get bill reminders and your daily summary.';

  @override
  String get notificationsOpenSettings => 'Open settings';

  @override
  String get notificationsManageBills => 'Manage bills';

  @override
  String notificationsScheduledBillSubtitle(String when, String due) {
    return '$when · $due';
  }

  @override
  String notificationsScheduledDigestSubtitle(String when) {
    return 'Next summary · $when';
  }

  @override
  String get billRemindersPermissionDenied => 'Allow notifications in system settings to get bill reminders.';

  @override
  String get billRemindersSaved => 'Reminder saved';

  @override
  String get billRemindersDeleted => 'Reminder deleted';

  @override
  String get billRemindersTestNow => 'Test now';

  @override
  String get billRemindersTestNowSent => 'Test notification sent — check your notification shade';

  @override
  String billReminderNotificationTitle(String title) {
    return 'Bill: $title';
  }

  @override
  String billReminderNotificationDueTodayWithAmount(String amount) {
    return 'Due today — $amount';
  }

  @override
  String get billReminderNotificationDueTodayPlain => 'Due today';

  @override
  String billReminderNotificationDueInDaysWithAmount(int days, String amount) {
    return 'Due in $days days — $amount';
  }

  @override
  String billReminderNotificationDueInDaysPlain(int days) {
    return 'Due in $days days';
  }

  @override
  String get billRemindersPresetElectricity => 'Electricity';

  @override
  String get billRemindersPresetRent => 'Rent';

  @override
  String get billRemindersPresetInternet => 'Internet';

  @override
  String get billRemindersPresetWater => 'Water';

  @override
  String get associationSelect => 'Ledger';

  @override
  String get associationPickerTitle => 'Choose ledger';

  @override
  String get associationPickerSubtitle => 'Each ledger has its own income, expenses, budgets, and plans.';

  @override
  String get associationCreateTitle => 'New ledger';

  @override
  String get associationCreateAction => 'Add ledger';

  @override
  String get associationNameHint => 'e.g. Work, Home, Savings';

  @override
  String get associationNameRequired => 'Enter a name for the ledger';

  @override
  String associationCreated(String name) {
    return 'Created \"$name\"';
  }

  @override
  String get associationDeleteConfirmTitle => 'Delete ledger?';

  @override
  String associationDeleteConfirmMessage(String name) {
    return 'Delete \"$name\" and all its income, expenses, budgets, and plans? This cannot be undone.';
  }

  @override
  String get associationDeleteAction => 'Delete';

  @override
  String get associationDeletedSnack => 'Ledger deleted';

  @override
  String get associationCannotDeletePersonal => 'The personal ledger cannot be deleted';

  @override
  String get associationInviteTitle => 'Invite members';

  @override
  String associationInviteSubtitle(String name) {
    return 'Search by username and invite people to \"$name\". They choose whether to join.';
  }

  @override
  String get associationInviteSearchHint => 'Search username…';

  @override
  String get associationInviteSearchMinChars => 'Type at least 2 characters to search';

  @override
  String get associationInviteNoResults => 'No users found';

  @override
  String get associationInviteAction => 'Invite';

  @override
  String get associationInviteSentLabel => 'Invited';

  @override
  String associationInviteSent(String username) {
    return 'Invitation sent to $username';
  }

  @override
  String get associationInviteMembersAction => 'Invite members';

  @override
  String get associationInvitePendingTitle => 'Invitations for you';

  @override
  String get associationInviteAccept => 'Join';

  @override
  String get associationInviteReject => 'Decline';

  @override
  String get associationInviteAcceptedSnack => 'You joined the ledger';

  @override
  String get associationInviteRejectedSnack => 'Invitation declined';

  @override
  String get associationInviteDisclaimerTitle => 'Before you invite';

  @override
  String get associationInviteDisclaimerBody => 'Pocketly helps you organize shared ledgers. You are responsible for who you invite and how money is handled between members. The app does not hold funds, is not a bank, and is not liable for disputes between members. Only invite people you trust.';

  @override
  String get associationInviteDisclaimerAccept => 'I understand';

  @override
  String get associationInviteLegalNote => 'Pocketly is a record-keeping tool only — not financial advice, escrow, or legal counsel.';

  @override
  String get associationManageTitle => 'Manage ledger';

  @override
  String get associationManageOpen => 'Open';

  @override
  String get associationManageNotAvailable => 'Switch to a shared ledger first.';

  @override
  String get associationManageSubtitle => 'You are the treasurer. Record all income, expenses, plans, and dates here. Members only view.';

  @override
  String get associationManageIncomeHint => 'Add and edit income entries';

  @override
  String get associationManageExpenseHint => 'Add and edit expenses with dates';

  @override
  String get associationManageBalanceHint => 'See balance for this ledger';

  @override
  String get associationManageStatsHint => 'Charts for the last 3 months';

  @override
  String get associationManagePlansHint => 'Savings plans and goals';

  @override
  String get associationManageInviteHint => 'Invite people to view this ledger';

  @override
  String get associationManageTreasurerNote => 'Only you can add or change numbers. Invited members see the same ledger read-only.';

  @override
  String get associationTreasurerBannerTitle => 'You manage this ledger';

  @override
  String associationTreasurerBannerBody(String name) {
    return 'All entries for $name are recorded by you.';
  }

  @override
  String associationMemberReadOnlyBanner(String name) {
    return 'View-only member of \"$name\". Ask the treasurer to add or edit entries.';
  }

  @override
  String get associationManageHubAction => 'Manage ledger';

  @override
  String get associationHubTitle => 'Association';

  @override
  String get associationHubOpen => 'Open';

  @override
  String get associationHubNotAvailable => 'Choose a shared association first.';

  @override
  String get associationHubOwnerSubtitle => 'You manage this gom3eya: payout, installment, whose turn, and members.';

  @override
  String get associationHubMemberSubtitle => 'View-only: see payout, installment, and whose turn it is.';

  @override
  String get associationHubPayout => 'Payout (gom3eya amount)';

  @override
  String get associationHubPayoutHint => '12000';

  @override
  String get associationHubInstallment => 'Installment';

  @override
  String get associationHubInstallmentHint => '1000';

  @override
  String get associationHubMemberCount => 'Slots';

  @override
  String get associationHubCollectionDay => 'Collection day';

  @override
  String get associationHubCollectionDayHint => 'Day of month (1–31)';

  @override
  String get associationHubCollectionDayInvalid => 'Collection day must be between 1 and 31.';

  @override
  String associationHubDayOfMonth(int day) {
    return 'Day $day';
  }

  @override
  String get associationHubCurrentTurn => 'Current turn';

  @override
  String associationHubTurnNumber(int current, int total) {
    return 'Turn $current of $total';
  }

  @override
  String get associationHubTurnList => 'Turn order';

  @override
  String get associationHubEmptySetup => 'Set payout, installment, and who takes each turn.';

  @override
  String get associationHubEmptyTurnList => 'No slots yet. Tap Edit to add names.';

  @override
  String get associationHubEdit => 'Edit details';

  @override
  String get associationHubSave => 'Save';

  @override
  String get associationHubSaved => 'Association details saved.';

  @override
  String get associationHubSlotsRequired => 'Add at least one name for the turn order.';

  @override
  String get associationHubFormFixErrors => 'Fix the highlighted fields.';

  @override
  String get associationHubPaymentsTitle => 'Installment payments';

  @override
  String get associationHubPaymentsEmpty => 'No payments recorded yet.';

  @override
  String associationHubPaymentsTotal(String amount) {
    return 'Total: $amount';
  }

  @override
  String get associationHubRecordPayment => 'Record payment';

  @override
  String get associationHubPaymentRecorded => 'Payment recorded.';

  @override
  String get associationHubPaymentPayer => 'Who paid';

  @override
  String get associationHubPaymentPayerRequired => 'Choose who paid.';

  @override
  String get associationHubPaymentAmount => 'Amount paid';

  @override
  String get associationHubPaymentDate => 'Payment date';

  @override
  String associationHubPaymentPaidOn(String date) {
    return 'Paid on $date';
  }

  @override
  String get associationHubPaymentNote => 'Note (optional)';

  @override
  String get associationHubPaymentNoteHint => 'e.g. March installment';

  @override
  String get associationHubPaymentSave => 'Save payment';

  @override
  String get associationHubPaymentDeleteTitle => 'Delete payment?';

  @override
  String associationHubPaymentDeleteMessage(String name) {
    return 'Remove payment record for $name?';
  }

  @override
  String get associationHubPaymentDeleteConfirm => 'Delete';

  @override
  String get associationHubEndGam3eya => 'End gom3eya';

  @override
  String get associationHubEndGam3eyaTitle => 'End this gom3eya?';

  @override
  String get associationHubEndGam3eyaMessage => 'The association will be closed. You can still view turns and payments, but no more edits or new payments.';

  @override
  String get associationHubEndGam3eyaConfirm => 'End';

  @override
  String get associationHubEndGam3eyaDone => 'Gom3eya ended.';

  @override
  String associationHubEndedBanner(String date) {
    return 'This gom3eya ended on $date. View only.';
  }

  @override
  String get associationHubOwnerEndedSubtitle => 'This gom3eya is finished. Data is view-only.';

  @override
  String get associationHubMemberEndedSubtitle => 'The manager ended this gom3eya. View only.';

  @override
  String get associationHubAdvanceTurn => 'Next turn';

  @override
  String associationHubAdvanceTurnConfirm(String name) {
    return 'Mark turn complete and move to the next person after $name?';
  }

  @override
  String get associationHubReceived => 'Received';

  @override
  String get associationHubPending => 'Waiting';

  @override
  String get associationHubCurrentBadge => 'Current';

  @override
  String get associationHubInvite => 'Invite members';

  @override
  String get associationHubTreasurerNote => 'Financial entries (income/expenses) are still recorded by the manager on the home tabs. This page tracks the gom3eya schedule.';

  @override
  String get associationHubAppMembers => 'App members';

  @override
  String get associationHubRoleOwner => 'Manager';

  @override
  String get associationHubRoleAdmin => 'Admin';

  @override
  String get associationHubRoleMember => 'Member';

  @override
  String get associationHubAddSlot => 'Add slot';

  @override
  String get associationHubSlotName => 'Name';

  @override
  String get associationHubBannerTitle => 'Manage association';

  @override
  String associationHubBannerBody(String name) {
    return 'Turn, payout & installment for $name.';
  }

  @override
  String get homeWelcomeBack => 'Welcome back';

  @override
  String homeWelcomeUser(String name) {
    return 'Welcome back, $name';
  }

  @override
  String get homeFinanceOverview => 'Finance Overview';

  @override
  String get homeDateFilterTitle => 'Filter by date';

  @override
  String get homeFilterAllMonths => 'All months';

  @override
  String get homeFilterByMonth => 'Month';

  @override
  String get homeFilterByDay => 'Day';

  @override
  String get homeFilterThisMonth => 'This month';

  @override
  String get homeFilterPickMonth => 'Pick month';

  @override
  String get homeFilterPickDay => 'Pick day';

  @override
  String get homeFilterToday => 'Today';

  @override
  String get homeFilterNoEntries => 'No entries for this period';

  @override
  String get accountSettingsTitle => 'Account settings';

  @override
  String get changeUsername => 'Change username';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get settingsCalculator => 'Calculator';

  @override
  String get calculatorTitle => 'Calculator';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get logout => 'Log out';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirmTitle => 'Delete account?';

  @override
  String get deleteAccountConfirmMessage => 'This will permanently remove your profile, incomes, expenses, and plans. This cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get usernameUpdated => 'Username updated';

  @override
  String get errorEnterUsername => 'Please enter a username';

  @override
  String get logoutConfirmTitle => 'Log out?';

  @override
  String get logoutConfirmMessage => 'You will need to sign in again to use the app.';

  @override
  String get loginWelcomeTitle => 'Welcome Back 👋';

  @override
  String get loginWelcomeSubtitle => 'Login to continue using your account';

  @override
  String get labelEmail => 'Email';

  @override
  String get hintEmail => 'example@gmail.com';

  @override
  String get labelPassword => 'Password';

  @override
  String get hintPasswordDots => '••••••••';

  @override
  String get forgotPasswordQuestion => 'Forgot Password?';

  @override
  String get loginButton => 'Login';

  @override
  String get orDivider => 'OR';

  @override
  String get noAccountPrompt => 'Don\'t have an account?';

  @override
  String get signUpLink => 'Sign Up';

  @override
  String get messageEnterEmailPassword => 'Enter email and password';

  @override
  String get messageLoginFailed => 'Login failed';

  @override
  String get messageLoginSuccess => 'Login successfully';

  @override
  String get signupCreateTitle => 'Create Account 🚀';

  @override
  String get signupCreateSubtitle => 'Create your account to continue';

  @override
  String get labelFullName => 'Full Name';

  @override
  String get hintEnterYourName => 'Enter your name';

  @override
  String get labelConfirmPassword => 'Confirm Password';

  @override
  String get createAccountButton => 'Create Account';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get loginLinkShort => 'Login';

  @override
  String get signupErrorGeneric => 'An error occurred';

  @override
  String get signupSuccessful => 'Signup successful';

  @override
  String get forgotPasswordTitle => 'Forgot Password?';

  @override
  String get forgotPasswordDescription => 'Enter your email address and we\'ll send you a password reset link.';

  @override
  String get sendResetLink => 'Send Reset OTP';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get errorTryAgainGeneric => 'An error occurred. Please try again.';

  @override
  String get setNewPasswordTitle => 'Set New Password 🔒';

  @override
  String get setNewPasswordSubtitle => 'Enter the OTP code and create your new password.';

  @override
  String get labelOtpCode => 'OTP Code';

  @override
  String get hintOtpCode => 'Enter verification code';

  @override
  String get labelNewPassword => 'New Password';

  @override
  String get buttonSetNewPassword => 'Set New Password';

  @override
  String get passwordUpdatedSuccessfully => 'Password updated successfully ✅';

  @override
  String noRouteForName(Object name) {
    return 'No route defined for $name';
  }

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String offlineWithPendingTransactions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Offline — $count entries will sync when you\'re back online',
      one: 'Offline — 1 entry will sync when you\'re back online',
    );
    return '$_temp0';
  }

  @override
  String get errorGeneric => 'Something went wrong';

  @override
  String get errorDeleteFailed => 'Could not delete. Please try again.';

  @override
  String get errorDeleteAccountFailed => 'Could not delete your account. Please try again.';

  @override
  String get errorDeleteAccountRpcRequired => 'Account deletion is not set up on the server. Run supabase/delete_account.sql in your Supabase project.';

  @override
  String get addIncome => 'Add Income';

  @override
  String get editIncome => 'Edit Income';

  @override
  String get recentIncomes => 'Recent Incomes';

  @override
  String get totalIncome => 'Total Income';

  @override
  String get addExpense => 'Add Expense';

  @override
  String get editExpense => 'Edit Expense';

  @override
  String get recentExpenses => 'Recent Expenses';

  @override
  String get expenseSortNewest => 'Newest';

  @override
  String get expenseSortHighestAmount => 'Highest amount';

  @override
  String get expenseDeletedSnack => 'Expense removed';

  @override
  String get expenseUndoAction => 'Undo';

  @override
  String get expenseRestoredSnack => 'Expense restored';

  @override
  String get totalExpenses => 'Total Expenses';

  @override
  String get noIncomesTitle => 'No incomes yet';

  @override
  String get noIncomesSubtitle => 'Tap the button below to record your first income';

  @override
  String get noExpensesTitle => 'No expenses yet';

  @override
  String get noExpensesSubtitle => 'Tap the button below to record your first expense';

  @override
  String get titleField => 'Title';

  @override
  String get hintExpenseTitle => 'e.g. Groceries';

  @override
  String get hintIncomeTitle => 'e.g. March payment';

  @override
  String get incomeSourceField => 'Source';

  @override
  String get hintIncomeSource => 'e.g. Visa card, Rents, Salary';

  @override
  String get addIncomeSheetTitleHint => 'e.g. March salary, apartment rent';

  @override
  String get addIncomeSheetSourceHint => 'e.g. Visa, Vodafone Cash, salary, bank transfer';

  @override
  String get addExpenseSheetTitleHint => 'e.g. supermarket, eating out, Uber';

  @override
  String get addExpenseSheetPaidFromHint => 'Where you paid from: cash, Visa, Vodafone Cash…';

  @override
  String get addExpenseSheetOtherCategoryHint => 'e.g. gym, subscriptions, gifts';

  @override
  String get paymentPresetBankTransfer => 'Bank transfer';

  @override
  String get paymentPresetVodafoneCash => 'Vodafone Cash';

  @override
  String get paymentPresetInstaPay => 'InstaPay';

  @override
  String get incomeBySource => 'By source';

  @override
  String get balanceRemainingBySource => 'Remaining by source';

  @override
  String get balanceWalletTitle => 'What\'s left per source';

  @override
  String get balanceWalletSubtitle => 'Starting balance + income − spending for each source in this period.';

  @override
  String get balanceWalletFilterAll => 'All';

  @override
  String get balanceWalletInitial => 'Starting';

  @override
  String get balanceWalletUnassignedHint => 'Spending not linked to a specific source.';

  @override
  String get balanceOpenWallet => 'My wallet';

  @override
  String get balanceWalletDialogTitle => 'My wallet';

  @override
  String balanceWalletDialogPeriod(Object period) {
    return 'For $period';
  }

  @override
  String get balanceWalletDialogTotal => 'Total in wallet';

  @override
  String get balanceWalletDialogEmpty => 'Set a starting balance per source to see your wallet here.';

  @override
  String get paymentMethodAddChip => '+ Add method';

  @override
  String get paymentMethodAddCancel => 'Cancel';

  @override
  String get paymentMethodNewLabel => 'New method name';

  @override
  String get paymentMethodNewHint => 'e.g. Vodafone Cash, InstaPay, Fawry';

  @override
  String get paymentMethodSave => 'Save method';

  @override
  String get paymentMethodNameEmpty => 'Enter a name for the payment method.';

  @override
  String paymentMethodAdded(String name) {
    return 'Added \"$name\" to your methods.';
  }

  @override
  String get expensePaidFromField => 'Paid from';

  @override
  String get expensePaidFromNone => 'Not set';

  @override
  String get incomeUnassignedSpending => 'Unassigned spending';

  @override
  String get incomeFilterAllSources => 'All sources';

  @override
  String get incomeFilterNoSourceEntries => 'No incomes for this source in the selected period';

  @override
  String get incomeSourceManageEdit => 'Rename source';

  @override
  String get incomeSourceManageRemove => 'Remove source';

  @override
  String get incomeSourceRenameTitle => 'Rename source';

  @override
  String incomeSourceRenameHint(String name) {
    return 'Updates all incomes with source \"$name\".';
  }

  @override
  String get incomeSourceNameTaken => 'That source name is already in use';

  @override
  String get incomeSourceUpdatedSuccess => 'Sources updated';

  @override
  String get incomeSourceRemoveTitle => 'Remove source';

  @override
  String incomeSourceRemoveMessage(int count, String name) {
    return 'What should happen to $count income(s) with source \"$name\"?';
  }

  @override
  String get incomeSourceMoveToOther => 'Move all to Other';

  @override
  String get incomeSourceDeleteAll => 'Delete all incomes with this source';

  @override
  String get incomeSourceDeleteConfirmTitle => 'Delete incomes?';

  @override
  String incomeSourceDeleteConfirmMessage(int count) {
    return 'This permanently deletes $count income(s). This cannot be undone.';
  }

  @override
  String get incomeSourceDeleteConfirmAction => 'Delete';

  @override
  String get incomeSourceRents => 'Rents';

  @override
  String get incomeSourceVisaCard => 'Visa card';

  @override
  String get incomeSourceCash => 'Cash';

  @override
  String get amountField => 'Amount';

  @override
  String get expenseAmountShortcuts => 'Quick amounts';

  @override
  String get expenseShortcutTransport => 'Transport';

  @override
  String get expenseShortcutCoffee => 'Coffee';

  @override
  String get expenseShortcutSnack => 'Snack';

  @override
  String get expenseFabMenuTitle => 'New expense';

  @override
  String get expenseFabBlankOption => 'Blank form';

  @override
  String get expenseFabFromLastPaste => 'From last parsed message';

  @override
  String get expenseFabFromLastPasteSubtitle => 'Uses the last bank or wallet message you parsed in Smart import';

  @override
  String get expenseLastPasteNotExpense => 'Last parsed message looks like income. Add it from the Incomes tab.';

  @override
  String get expenseShortcutsSectionTitle => 'One-tap expenses';

  @override
  String get expenseShortcutsEmptyCta => 'Set up one-tap shortcuts';

  @override
  String get expenseShortcutsManageTitle => 'Expense shortcuts';

  @override
  String get expenseShortcutsManageSubtitle => 'Save a label, title, category, paid-from, and amount. Tap the chip on the Expenses tab to log instantly.';

  @override
  String get expenseShortcutsEmptyBody => 'No shortcuts yet. Add your first coffee, transport, or other repeat purchase.';

  @override
  String get expenseShortcutAddTitle => 'New shortcut';

  @override
  String get expenseShortcutEditTitle => 'Edit shortcut';

  @override
  String get expenseShortcutChipLabelField => 'Chip label';

  @override
  String get expenseShortcutChipLabelHint => 'e.g. Coffee';

  @override
  String get expenseShortcutExpenseTitleField => 'Expense title';

  @override
  String get expenseShortcutFormHint => 'The chip logs this expense for today with one tap — no form.';

  @override
  String get expenseShortcutSave => 'Save shortcut';

  @override
  String get expenseShortcutDelete => 'Delete';

  @override
  String get expenseShortcutDeleteConfirmTitle => 'Delete shortcut?';

  @override
  String expenseShortcutDeleteConfirmMessage(String name) {
    return 'Remove \"$name\"?';
  }

  @override
  String expenseShortcutLogged(String name) {
    return 'Logged: $name';
  }

  @override
  String get expenseShortcutErrorLabel => 'Enter a chip label';

  @override
  String get expenseByCategory => 'By category';

  @override
  String get expenseCategoryEdit => 'Edit category';

  @override
  String get expenseCategoryRemove => 'Remove category';

  @override
  String get expenseCategoryRenameTitle => 'Rename category';

  @override
  String expenseCategoryRenameHint(String name) {
    return 'Updates all expenses in \"$name\".';
  }

  @override
  String get expenseCategoryNameTaken => 'That category name is already in use';

  @override
  String get expenseCategoryUpdatedSuccess => 'Category updated';

  @override
  String get expenseCategoryRemoveTitle => 'Remove category';

  @override
  String expenseCategoryRemoveMessage(int count, String name) {
    return 'What should happen to $count expense(s) in \"$name\"?';
  }

  @override
  String get expenseCategoryMoveToOther => 'Move all to Other';

  @override
  String get expenseCategoryDeleteAll => 'Delete all expenses in this category';

  @override
  String get expenseCategoryDeleteConfirmTitle => 'Delete expenses?';

  @override
  String expenseCategoryDeleteConfirmMessage(int count) {
    return 'This permanently deletes $count expense(s). This cannot be undone.';
  }

  @override
  String get expenseCategoryDeleteConfirmAction => 'Delete';

  @override
  String get expenseFilterAllCategories => 'All categories';

  @override
  String get expenseFilterNoCategoryEntries => 'No expenses for this category in the selected period';

  @override
  String get budgetMonthlyTitle => 'Monthly budgets';

  @override
  String get budgetSetAction => 'Set budget';

  @override
  String get budgetSetTitle => 'Set monthly budget';

  @override
  String get budgetEditTitle => 'Edit monthly budget';

  @override
  String get budgetSetHint => 'Pick a category and set how much you plan to spend this month.';

  @override
  String get budgetCustomCategory => 'Category name';

  @override
  String get budgetMonthlyLimit => 'Monthly limit';

  @override
  String get budgetSave => 'Save budget';

  @override
  String get budgetEmptyHint => 'Set a limit per category to see how much of your budget you\'ve used.';

  @override
  String get budgetSetFirst => 'Create first budget';

  @override
  String get budgetTotalSpent => 'Total spent';

  @override
  String budgetRemaining(String amount) {
    return '$amount left';
  }

  @override
  String budgetOverBy(String amount) {
    return 'Over by $amount';
  }

  @override
  String get budgetDeleteTitle => 'Remove budget?';

  @override
  String budgetDeleteMessage(String category) {
    return 'Remove the budget for $category?';
  }

  @override
  String get budgetDeleteConfirm => 'Remove';

  @override
  String budgetAlertNear(int count) {
    return '$count category near the limit';
  }

  @override
  String budgetAlertOver(int count) {
    return '$count category over budget';
  }

  @override
  String budgetAlertOverAndNear(int over, int near) {
    return '$over over budget, $near near limit';
  }

  @override
  String get categoryField => 'Category';

  @override
  String get otherCategoryField => 'Other category';

  @override
  String get otherCategoryHint => 'Enter category name';

  @override
  String get saveExpense => 'Save Expense';

  @override
  String get updateExpense => 'Update Expense';

  @override
  String get expenseAddedSuccess => 'Expense added successfully';

  @override
  String get expenseUpdatedSuccess => 'Expense updated successfully';

  @override
  String get saveIncome => 'Save Income';

  @override
  String get updateIncome => 'Update Income';

  @override
  String get incomeAddedSuccess => 'Income added successfully';

  @override
  String get incomeUpdatedSuccess => 'Income updated successfully';

  @override
  String get errorEnterTitle => 'Please enter a title';

  @override
  String get errorEnterValidAmount => 'Please enter a valid amount';

  @override
  String get errorEnterCategoryName => 'Please enter a category name';

  @override
  String get errorSavedExceedsTarget => 'Saved amount cannot exceed target';

  @override
  String get expenseCatFood => 'Food';

  @override
  String get expenseCatRent => 'Rent';

  @override
  String get expenseCatTransport => 'Transport';

  @override
  String get expenseCatShopping => 'Shopping';

  @override
  String get expenseCatBills => 'Bills';

  @override
  String get expenseCatOther => 'Other';

  @override
  String get incomeCatWork => 'Work';

  @override
  String get incomeCatFreelance => 'Freelance';

  @override
  String get incomeCatBusiness => 'Business';

  @override
  String get incomeCatInvestment => 'Investment';

  @override
  String get incomeCatOther => 'Other';

  @override
  String get planCatSavings => 'Savings';

  @override
  String get planCatTravel => 'Travel';

  @override
  String get planCatPurchase => 'Purchase';

  @override
  String get planCatEducation => 'Education';

  @override
  String get planCatOther => 'Other';

  @override
  String get planNewFab => 'New goal';

  @override
  String get planEditGoal => 'Edit Goal';

  @override
  String get planAddPlan => 'Add Plan';

  @override
  String get goalTitleLabel => 'Goal title';

  @override
  String get goalTitleHint => 'e.g. Emergency Fund';

  @override
  String get targetAmountLabel => 'Target amount';

  @override
  String get amountSavedLabel => 'Amount saved';

  @override
  String get setDeadlineOptional => 'Set deadline (optional)';

  @override
  String get savePlan => 'Save Plan';

  @override
  String get updateGoal => 'Update Goal';

  @override
  String get errorEnterGoalTitle => 'Please enter a goal title';

  @override
  String get errorEnterTargetAmount => 'Please enter a valid target amount';

  @override
  String get errorEnterAmountSaved => 'Please enter amount saved';

  @override
  String get updateSavedTitle => 'Update saved';

  @override
  String targetWithAmount(Object amount) {
    return 'Target: $amount';
  }

  @override
  String get saveAmountButton => 'Save amount';

  @override
  String get errorEnterValidSavedAmount => 'Please enter a valid saved amount';

  @override
  String get balanceNetBalance => 'Net Balance';

  @override
  String get balanceInitialBalanceTitle => 'Initial balance';

  @override
  String get balanceInitialBalanceHint => 'How much you had when you started using the app.';

  @override
  String get balanceInitialBalanceAddSource => 'Add another source';

  @override
  String get balanceInitialBalanceBySource => 'By source';

  @override
  String balanceInitialBalanceIncludes(Object amount) {
    return 'Includes $amount starting balance';
  }

  @override
  String get balanceInitialBalanceSaved => 'Initial balance updated';

  @override
  String get balanceEditInitialBalance => 'Edit initial balance';

  @override
  String get settingsInitialBalance => 'Initial balance';

  @override
  String balanceSavedThisMonth(int percent) {
    return '$percent% saved this month';
  }

  @override
  String balanceSavedPercent(int percent) {
    return '$percent% saved';
  }

  @override
  String get balanceStatIncome => 'Income';

  @override
  String get balanceStatExpense => 'Expenses';

  @override
  String get balanceRecentActivity => 'Recent Activity';

  @override
  String get balanceAddToPlan => 'Add to goal';

  @override
  String get balanceAddToPlanTitle => 'Add to savings goal';

  @override
  String balanceAddToPlanHint(Object amount) {
    return 'Available from balance: $amount';
  }

  @override
  String get balanceSelectPlan => 'Choose a goal';

  @override
  String get balanceAmountToAllocate => 'Amount to add';

  @override
  String balancePlanRemaining(Object amount) {
    return '$amount left to reach target';
  }

  @override
  String get balanceAddToPlanSuccess => 'Amount added to your savings goal';

  @override
  String get balancePlanAllocationPaidFromHint => 'Choose which source this allocation is paid from (shown on Balance, not unassigned).';

  @override
  String get planAllocationSelectPaidFrom => 'Select paid from for this goal allocation';

  @override
  String balancePlanAllocationExpenseTitle(String planTitle) {
    return 'Savings goal: $planTitle';
  }

  @override
  String get balanceNoPlansForAllocation => 'Create a savings goal in the Plans tab first.';

  @override
  String get balanceAmountExceedsSurplus => 'Amount exceeds your available balance';

  @override
  String itemsCount(int count) {
    return '$count items';
  }

  @override
  String listEntryCount(int count) {
    return '$count entries';
  }

  @override
  String get clearAllExpenses => 'Clear all';

  @override
  String get clearAllIncomes => 'Clear all';

  @override
  String get clearAllExpensesConfirmTitle => 'Delete all expenses?';

  @override
  String get clearAllIncomesConfirmTitle => 'Delete all incomes?';

  @override
  String clearAllExpensesConfirmMessage(int count) {
    return 'This will permanently delete all $count expenses. This cannot be undone.';
  }

  @override
  String clearAllIncomesConfirmMessage(int count) {
    return 'This will permanently delete all $count incomes. This cannot be undone.';
  }

  @override
  String get clearAllExpensesSuccess => 'All expenses deleted';

  @override
  String get clearAllIncomesSuccess => 'All incomes deleted';

  @override
  String get balanceIncomeVsExpenses => 'Income vs Expenses';

  @override
  String get balanceFilterAll => 'All';

  @override
  String get balanceFilterIncome => 'Income';

  @override
  String get balanceFilterExpense => 'Expenses';

  @override
  String get balanceNoFilteredActivity => 'No activity matches this filter';

  @override
  String get activityIncome => 'Income';

  @override
  String get activityExpense => 'Expense';

  @override
  String get plansActive => 'Active';

  @override
  String get plansDone => 'Done';

  @override
  String get plansRemaining => 'Left';

  @override
  String get plansSavingsGoalsSection => 'Savings goals';

  @override
  String get plansGoalsOverview => 'Goals overview';

  @override
  String plansSavedOfTarget(Object total) {
    return 'of $total saved';
  }

  @override
  String get plansDonePercentLabel => 'done';

  @override
  String plansGoalsCompletedSummary(int completed, int total) {
    return '$completed of $total goals completed';
  }

  @override
  String plansMoneyLeft(Object amount) {
    return '$amount left';
  }

  @override
  String ofTargetAmount(Object amount) {
    return 'of $amount';
  }

  @override
  String dueDateLabel(Object date) {
    return 'Due $date';
  }

  @override
  String get planGoalCompleted => 'Goal completed';

  @override
  String get planTapToEditGoal => 'Tap to edit goal';

  @override
  String get plansEmptyTitle => 'Start your first goal';

  @override
  String get plansEmptySubtitle => 'Set a target, track what you save, and watch your progress grow.';

  @override
  String get plansCreateGoalButton => 'Create goal';

  @override
  String get demoSalary => 'Salary';

  @override
  String get demoRent => 'Rent';

  @override
  String get demoFreelanceProject => 'Freelance Project';

  @override
  String get demoGroceries => 'Groceries';

  @override
  String get demoGas => 'Gas';

  @override
  String get demoElectricBill => 'Electric Bill';

  @override
  String get demoUtilities => 'Utilities';

  @override
  String get demoSideBusiness => 'Side Business';

  @override
  String get demoEmergencyFund => 'Emergency Fund';

  @override
  String get demoSummerVacation => 'Summer Vacation';

  @override
  String get demoNewLaptop => 'New Laptop';

  @override
  String storedAsBase(Object amount) {
    return 'Stored as $amount base';
  }

  @override
  String get smartImportTitle => 'Smart import';

  @override
  String get smartImportShort => 'Import';

  @override
  String get smartImportPasteTab => 'Paste';

  @override
  String get smartImportQuickTab => 'Quick';

  @override
  String get smartImportSmsTab => 'SMS';

  @override
  String get smartImportQuickHint => 'No SMS to paste? Enter the amount, pick expense or income, choose category and source — add in one tap.';

  @override
  String get smartImportQuickTypeLabel => 'Transaction type';

  @override
  String get smartImportQuickAmountLabel => 'Amount';

  @override
  String get smartImportQuickTitleHint => 'Coffee, rent, salary… (optional)';

  @override
  String get smartImportQuickAddNow => 'Add now';

  @override
  String get smartImportQuickReview => 'Review in full form';

  @override
  String get smartImportQuickAdded => 'Transaction added.';

  @override
  String get smartImportPasteHint => 'Paste one or more bank or wallet messages. Put a blank line between messages, or paste several SMS in a row. We detect amounts and income vs expense for each.';

  @override
  String get smartImportPasteShareTip => 'Tip: In your SMS app, open a message → Share → Import to Pocketly. No copy-paste needed.';

  @override
  String get smartImportSharedTextReady => 'Shared message loaded. Review below and add.';

  @override
  String get smartImportScrollToTop => 'Back to top';

  @override
  String get smartImportPasteFieldLabel => 'Message text';

  @override
  String get smartImportPasteFieldHint => 'Paste one or more messages (blank line between each)';

  @override
  String get smartImportPasteFromClipboard => 'Paste from clipboard';

  @override
  String get smartImportParseMessage => 'Parse message';

  @override
  String get smartImportParseMessages => 'Parse messages';

  @override
  String smartImportPasteFoundCount(int count) {
    return 'Found $count messages';
  }

  @override
  String smartImportPasteAddedOneRemaining(int count) {
    return 'Added. $count more ready to import.';
  }

  @override
  String get smartImportPasteProcessing => 'Reading message…';

  @override
  String get smartImportPasteNoData => 'Could not find an amount in this text. Try the full bank message.';

  @override
  String get smartImportPasteEmpty => 'Paste a message first.';

  @override
  String get smartImportPasteClipboardEmpty => 'Clipboard is empty. Copy a bank or wallet message first.';

  @override
  String get smartImportPasteClear => 'Clear';

  @override
  String get smartImportPasteAddedSuccess => 'Added. Paste another message anytime.';

  @override
  String get smartImportPasteParseAnother => 'Parse another';

  @override
  String get smartImportPasteMarkExpense => 'Mark as expense';

  @override
  String get smartImportPasteMarkIncome => 'Mark as income';

  @override
  String get smartImportDefaultBillTitle => 'Bill';

  @override
  String get smartImportExtractedData => 'Extracted data';

  @override
  String get smartImportDateField => 'Date';

  @override
  String get smartImportTypeField => 'Type';

  @override
  String get smartImportAddToApp => 'Add to app';

  @override
  String get smartImportSmsNotSupported => 'SMS import is available on Android only.';

  @override
  String get smartImportSmsEmpty => 'No financial SMS messages found. Grant SMS permission if prompted.';

  @override
  String get smartImportSmsFailed => 'Could not read SMS messages.';

  @override
  String get smartImportReloadSms => 'Reload';

  @override
  String get smartImportSmsAlreadyAdded => 'Already added';

  @override
  String get smartImportSmsAddAgain => 'Add again';

  @override
  String get smartImportSmsClearAllAdded => 'Clear all added';

  @override
  String get smartImportSmsClearAllAddedConfirmTitle => 'Clear imported history?';

  @override
  String get smartImportSmsClearAllAddedConfirmMessage => 'All SMS will show as not added. You can import them again. Your existing expenses and incomes are not deleted.';

  @override
  String get smartImportSmsClearAllAddedDone => 'Imported history cleared';

  @override
  String smartImportSmsSkippedDuplicate(int count) {
    return '$count message(s) were already in the app.';
  }

  @override
  String get smartImportSmsLoadMore => 'Load more messages';

  @override
  String get smartImportSmsLoading => 'Reading your SMS messages…';

  @override
  String get smartImportSmsLoadingMore => 'Loading more…';

  @override
  String smartImportSmsListCap(int count) {
    return 'Showing the latest $count financial messages. Pull to refresh for a new scan.';
  }

  @override
  String get smartImportUnknownSender => 'Unknown sender';

  @override
  String get smartImportSmsTitleExpense => 'Bank expense';

  @override
  String get smartImportSmsTitleIncome => 'Bank income';

  @override
  String get smartImportTapToImport => 'Tap to import';

  @override
  String smartImportAddAllExpenses(int count) {
    return 'Add all expenses ($count)';
  }

  @override
  String smartImportAddAllIncomes(int count) {
    return 'Add all incomes ($count)';
  }

  @override
  String smartImportAddSelected(int count) {
    return 'Add selected ($count)';
  }

  @override
  String get smartImportSelectAll => 'Select all';

  @override
  String get smartImportClearSelection => 'Clear';

  @override
  String get smartImportBulkCategorySheetTitle => 'Category for import';

  @override
  String get smartImportBulkCategorySheetHint => 'Choose category and source here. SMS text is only used for titles, not for income source or paid-from.';

  @override
  String get smartImportBulkExpensePaidFromHint => 'Tap a source for imported expenses (not read from SMS).';

  @override
  String get smartImportBulkIncomeSourceHint => 'Tap a source for imported incomes (not read from SMS).';

  @override
  String get smartImportBulkSelectPaidFrom => 'Select paid from';

  @override
  String get smartImportBulkSelectIncomeSource => 'Select income source';

  @override
  String get smartImportBulkExpenseCategory => 'Expense category';

  @override
  String get smartImportBulkIncomeSource => 'Income source';

  @override
  String get smartImportBulkApplyAndImport => 'Import';

  @override
  String get smartImportBulkImporting => 'Importing messages…';

  @override
  String get smartImportBulkNothingToAdd => 'No messages with a valid amount to import.';

  @override
  String smartImportBulkResult(int incomes, int expenses) {
    return 'Added $incomes incomes and $expenses expenses.';
  }

  @override
  String smartImportBulkPartialFail(int failed) {
    return '$failed message(s) could not be imported.';
  }

  @override
  String get settingsAutoSmsImport => 'Auto-import from SMS';

  @override
  String get settingsAutoSmsImportSubtitle => 'When the app opens, new bank SMS are detected and added as income or expense using your chosen category and source.';

  @override
  String get settingsAutoSmsImportDefaults => 'Auto-import categories';

  @override
  String get settingsAutoSmsImportDefaultsTitle => 'Defaults for auto-import';

  @override
  String get settingsAutoSmsImportDefaultsHint => 'Used for every automatic import. SMS text is only used for titles.';

  @override
  String get settingsAutoSmsImportPermissionDenied => 'SMS permission is required for auto-import.';

  @override
  String get settingsAutoSmsImportEnabled => 'Auto-import is on. New financial SMS will be added when you open the app.';

  @override
  String autoSmsImportAddedSnack(int incomes, int expenses) {
    return 'Auto-imported $incomes incomes and $expenses expenses.';
  }

  @override
  String get settingsAppLock => 'App lock';

  @override
  String get settingsAppLockBiometric => 'Face ID / fingerprint';

  @override
  String get settingsAppLockChangePin => 'Change PIN';

  @override
  String get appLockTitle => 'Unlock Pocketly';

  @override
  String get appLockSubtitle => 'Enter your PIN to continue';

  @override
  String get appLockWrongPin => 'Incorrect PIN. Try again.';

  @override
  String get appLockBiometricReason => 'Unlock your finances';

  @override
  String get appLockEnterPinTitle => 'Enter your PIN';

  @override
  String get appLockEnterPinSubtitle => 'Confirm to continue';

  @override
  String get appLockCreatePinTitle => 'Create a PIN';

  @override
  String get appLockCreatePinSubtitle => 'Use 4 digits you will remember';

  @override
  String get appLockConfirmPinTitle => 'Confirm your PIN';

  @override
  String get appLockConfirmPinSubtitle => 'Enter the same PIN again';

  @override
  String get appLockPinMismatch => 'PINs do not match';

  @override
  String get appLockEnabledSuccess => 'App lock is on';

  @override
  String get appLockDisabledSuccess => 'App lock is off';

  @override
  String get appLockEnableFailed => 'Could not enable app lock';

  @override
  String get appLockBiometricPromptTitle => 'Use biometrics?';

  @override
  String get appLockBiometricPromptMessage => 'Unlock faster with Face ID or fingerprint on this device.';

  @override
  String get appLockBiometricFailed => 'Biometrics could not be enabled';

  @override
  String get appLockChangePinSuccess => 'PIN updated';

  @override
  String get appLockChangePinFailed => 'Could not update PIN';

  @override
  String get notNow => 'Not now';

  @override
  String get enable => 'Enable';

  @override
  String get monthlyReportTitle => 'Monthly report';

  @override
  String get monthlyReportShort => 'Report';

  @override
  String get monthlyReportVsLastMonth => 'Compared to last month';

  @override
  String get monthlyReportBudgetTitle => 'Budget vs actual';

  @override
  String get monthlyReportNoBudgets => 'No budgets set for this month. Add limits on the Expenses tab to track spending here.';

  @override
  String monthlyReportEntrySummary(int incomeCount, int expenseCount) {
    return '$incomeCount income sources · $expenseCount expense categories';
  }

  @override
  String get globalSearchTitle => 'Search';

  @override
  String get globalSearchHint => 'Title, category, source, amount…';

  @override
  String get globalSearchAll => 'All';

  @override
  String get globalSearchNoResults => 'No matching entries';

  @override
  String get globalSearchAllTime => 'All time';

  @override
  String get globalSearchCurrentPeriod => 'This period';

  @override
  String get currencyUsDollar => 'US Dollar';

  @override
  String get currencyEuro => 'Euro';

  @override
  String get expenseReceiptLabel => 'Receipt photo';

  @override
  String get expenseReceiptAttach => 'Attach receipt';

  @override
  String get expenseReceiptReplace => 'Replace photo';

  @override
  String get expenseReceiptRemove => 'Remove';

  @override
  String get expenseReceiptUploadFailed => 'Could not upload receipt. Try again.';

  @override
  String get expenseReceiptInvalidType => 'Choose a photo (JPG, PNG, or WebP). Videos are not supported.';

  @override
  String get csvImportTitle => 'Import from CSV';

  @override
  String get csvImportPickHint => 'Import expenses and incomes from a spreadsheet export. Map columns on the next step.';

  @override
  String get csvImportPickFile => 'Choose CSV file';

  @override
  String csvImportFileSelected(String name) {
    return 'Selected: $name';
  }

  @override
  String get csvImportEmpty => 'The file has no rows to import.';

  @override
  String get csvImportParseFailed => 'Could not read this CSV file.';

  @override
  String get csvImportFirstRowHeader => 'First row is column headers';

  @override
  String get csvImportCurrencyHint => 'Amounts in file are in:';

  @override
  String get csvImportMapColumns => 'Map columns';

  @override
  String get csvImportFieldSkip => 'Skip';

  @override
  String get csvImportFieldType => 'Income or expense';

  @override
  String get csvImportBack => 'Back';

  @override
  String get csvImportPreview => 'Preview';

  @override
  String csvImportPreviewSummary(int total, int expenses, int incomes) {
    return '$total rows ready ($expenses expenses, $incomes incomes)';
  }

  @override
  String get csvImportTypeExpense => 'Expense';

  @override
  String get csvImportTypeIncome => 'Income';

  @override
  String csvImportMoreRows(int count) {
    return '+ $count more rows';
  }

  @override
  String get csvImportRun => 'Import all';

  @override
  String get csvImportProgress => 'Importing…';

  @override
  String csvImportSuccess(int count) {
    return 'Imported $count transactions';
  }

  @override
  String csvImportPartial(int ok, int failed) {
    return 'Imported $ok, $failed failed';
  }

  @override
  String get zakatTitle => 'Zakat calculator';

  @override
  String get zakatDisclaimer => 'Estimate only (2.5% on net zakatable wealth). Enter gold and silver by weight in grams; value = grams × price per gram. Consult a scholar for your situation.';

  @override
  String get zakatFillFromLedger => 'Fill from this ledger';

  @override
  String get zakatFillFromLedgerDone => 'Cash and savings plans added from your ledger';

  @override
  String get zakatPricesSection => 'Market prices (per gram)';

  @override
  String get zakatPricesHint => 'Used to value your gold and silver and to calculate nisab.';

  @override
  String get zakatPricePerGramSuffix => 'EGP/g';

  @override
  String get zakatAssetsSection => 'Zakatable assets';

  @override
  String get zakatDeductionsSection => 'Deductions';

  @override
  String get zakatNisabSection => 'Nisab (minimum)';

  @override
  String get zakatCash => 'Cash & bank balance';

  @override
  String get zakatGold => 'Gold weight (24k, grams)';

  @override
  String get zakatSilver => 'Silver weight (grams)';

  @override
  String get zakatInvestments => 'Investments & savings';

  @override
  String get zakatBusinessGoods => 'Trade / business goods';

  @override
  String get zakatReceivables => 'Money owed to you';

  @override
  String get zakatDebts => 'Debts & liabilities';

  @override
  String get zakatGoldPricePerGram => 'Gold price (24k)';

  @override
  String get zakatSilverPricePerGram => 'Silver price';

  @override
  String get zakatAmountHint => '0';

  @override
  String get zakatGoldPriceHint => 'e.g. 4500';

  @override
  String get zakatSilverPriceHint => 'e.g. 55';

  @override
  String get zakatGoldWeightHint => 'e.g. 50';

  @override
  String get zakatSilverWeightHint => 'e.g. 200';

  @override
  String zakatComputedValue(String amount) {
    return '≈ $amount';
  }

  @override
  String zakatNisabHint(int goldGrams, int silverGrams) {
    return 'Nisab reference: ${goldGrams}g gold or ${silverGrams}g silver (this app uses ${goldGrams}g gold × gold price).';
  }

  @override
  String get zakatResultTitle => 'Your estimate';

  @override
  String get zakatTotalAssets => 'Total assets';

  @override
  String get zakatNetWealth => 'Net wealth';

  @override
  String get zakatNisabThreshold => 'Nisab threshold';

  @override
  String get zakatMeetsNisab => 'You meet nisab — estimated zakat:';

  @override
  String get zakatBelowNisab => 'Below nisab — no zakat due:';

  @override
  String get zakatDueLabel => 'Estimated zakat (2.5%)';

  @override
  String get zakatRateNote => 'Hawl (one lunar year) on wealth is assumed. Adjust inputs for your case.';
}
