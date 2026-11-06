import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Pockio'**
  String get appTitle;

  /// No description provided for @exitPressTwiceMore.
  ///
  /// In en, this message translates to:
  /// **'Press back 2 more times to exit'**
  String get exitPressTwiceMore;

  /// No description provided for @exitPressOnceMore.
  ///
  /// In en, this message translates to:
  /// **'Press back once more to exit'**
  String get exitPressOnceMore;

  /// No description provided for @homeGuideNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get homeGuideNext;

  /// No description provided for @homeGuideDone.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get homeGuideDone;

  /// No description provided for @homeGuideTabsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your money tabs'**
  String get homeGuideTabsTitle;

  /// No description provided for @homeGuideTabsBody.
  ///
  /// In en, this message translates to:
  /// **'Switch between Incomes, Expenses, Balance, Loans, Plans, and Gameyas.'**
  String get homeGuideTabsBody;

  /// No description provided for @homeGuideIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first income'**
  String get homeGuideIncomeTitle;

  /// No description provided for @homeGuideIncomeBody.
  ///
  /// In en, this message translates to:
  /// **'Tap Add Income to record a salary, freelance payment, or any money coming in.'**
  String get homeGuideIncomeBody;

  /// No description provided for @homeGuideExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Track spending'**
  String get homeGuideExpenseTitle;

  /// No description provided for @homeGuideExpenseBody.
  ///
  /// In en, this message translates to:
  /// **'Open Expenses and tap Add Expense whenever you spend.'**
  String get homeGuideExpenseBody;

  /// No description provided for @homeGuideImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Add faster with AI'**
  String get homeGuideImportTitle;

  /// No description provided for @homeGuideImportBody.
  ///
  /// In en, this message translates to:
  /// **'Tap AI add and type or speak a transaction. Or use Import for bank SMS and pasted messages.'**
  String get homeGuideImportBody;

  /// No description provided for @homeGuideSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeGuideSettingsTitle;

  /// No description provided for @homeGuideSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Change currency, language, theme, and app lock from here. 3-month charts are in Settings and the Stats chip on Home.'**
  String get homeGuideSettingsBody;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingPage1Title.
  ///
  /// In en, this message translates to:
  /// **'Your money, one place'**
  String get onboardingPage1Title;

  /// No description provided for @onboardingPage1Body.
  ///
  /// In en, this message translates to:
  /// **'Track income and expenses in Egyptian pounds. See your balance and stay on top of spending.'**
  String get onboardingPage1Body;

  /// No description provided for @onboardingPage2Title.
  ///
  /// In en, this message translates to:
  /// **'Ledgers & smart import'**
  String get onboardingPage2Title;

  /// No description provided for @onboardingPage2Body.
  ///
  /// In en, this message translates to:
  /// **'Use personal or shared ledgers. Import transactions from SMS or shared text and add them in seconds.'**
  String get onboardingPage2Body;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In en, this message translates to:
  /// **'Reminders & insights'**
  String get onboardingPage3Title;

  /// No description provided for @onboardingPage3Body.
  ///
  /// In en, this message translates to:
  /// **'Get bill reminders before due dates and view 3-month charts for income, expenses, and categories.'**
  String get onboardingPage3Body;

  /// No description provided for @tabIncomes.
  ///
  /// In en, this message translates to:
  /// **'Incomes'**
  String get tabIncomes;

  /// No description provided for @tabExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get tabExpenses;

  /// No description provided for @tabBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get tabBalance;

  /// No description provided for @tabPlans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get tabPlans;

  /// No description provided for @tabStatistics.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get tabStatistics;

  /// No description provided for @tabLoans.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get tabLoans;

  /// No description provided for @tabCommitments.
  ///
  /// In en, this message translates to:
  /// **'Gameyas'**
  String get tabCommitments;

  /// No description provided for @statisticsLast3Months.
  ///
  /// In en, this message translates to:
  /// **'Last 3 months'**
  String get statisticsLast3Months;

  /// No description provided for @statisticsMonthlyTrend.
  ///
  /// In en, this message translates to:
  /// **'Monthly income vs expenses'**
  String get statisticsMonthlyTrend;

  /// No description provided for @statisticsNetPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Net per month'**
  String get statisticsNetPerMonth;

  /// No description provided for @statisticsTotalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total income'**
  String get statisticsTotalIncome;

  /// No description provided for @statisticsTotalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total expenses'**
  String get statisticsTotalExpenses;

  /// No description provided for @statisticsNet3Months.
  ///
  /// In en, this message translates to:
  /// **'Net (3 months)'**
  String get statisticsNet3Months;

  /// No description provided for @statisticsAvgMonthlyNet.
  ///
  /// In en, this message translates to:
  /// **'Avg. per month: {amount}'**
  String statisticsAvgMonthlyNet(String amount);

  /// No description provided for @statisticsTopExpenses.
  ///
  /// In en, this message translates to:
  /// **'Top expense categories (3 mo)'**
  String get statisticsTopExpenses;

  /// No description provided for @statisticsTopIncomeSources.
  ///
  /// In en, this message translates to:
  /// **'Top income sources (3 mo)'**
  String get statisticsTopIncomeSources;

  /// No description provided for @statisticsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add incomes and expenses to see your 3-month charts.'**
  String get statisticsEmpty;

  /// No description provided for @loanNewFab.
  ///
  /// In en, this message translates to:
  /// **'New loan'**
  String get loanNewFab;

  /// No description provided for @loanAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add loan'**
  String get loanAddTitle;

  /// No description provided for @loanEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit loan'**
  String get loanEditTitle;

  /// No description provided for @loanPersonLabel.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get loanPersonLabel;

  /// No description provided for @loanPersonHint.
  ///
  /// In en, this message translates to:
  /// **'Who is this loan with?'**
  String get loanPersonHint;

  /// No description provided for @loanDirectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get loanDirectionLabel;

  /// No description provided for @loanDirectionGiven.
  ///
  /// In en, this message translates to:
  /// **'I lent'**
  String get loanDirectionGiven;

  /// No description provided for @loanDirectionReceived.
  ///
  /// In en, this message translates to:
  /// **'I borrowed'**
  String get loanDirectionReceived;

  /// No description provided for @loanPrincipalLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get loanPrincipalLabel;

  /// No description provided for @loanRepaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Already repaid'**
  String get loanRepaidLabel;

  /// No description provided for @loanDueDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Due date (optional)'**
  String get loanDueDateOptional;

  /// No description provided for @loanNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get loanNotesOptional;

  /// No description provided for @loanNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Reason, terms, or anything to remember'**
  String get loanNotesHint;

  /// No description provided for @loanSave.
  ///
  /// In en, this message translates to:
  /// **'Save loan'**
  String get loanSave;

  /// No description provided for @loanUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update loan'**
  String get loanUpdate;

  /// No description provided for @loanRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get loanRecordPayment;

  /// No description provided for @loanPaymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Payment amount'**
  String get loanPaymentAmount;

  /// No description provided for @loanPaymentSubmit.
  ///
  /// In en, this message translates to:
  /// **'Save payment'**
  String get loanPaymentSubmit;

  /// No description provided for @loanPaymentPayFromBalance.
  ///
  /// In en, this message translates to:
  /// **'Pay from'**
  String get loanPaymentPayFromBalance;

  /// No description provided for @loanPaymentPayFromBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'Wallet or account this repayment is paid from'**
  String get loanPaymentPayFromBalanceHint;

  /// No description provided for @loanPaymentAddToBalance.
  ///
  /// In en, this message translates to:
  /// **'Add to'**
  String get loanPaymentAddToBalance;

  /// No description provided for @loanPaymentAddToBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'Wallet or account that receives this repayment'**
  String get loanPaymentAddToBalanceHint;

  /// No description provided for @loanPaymentBalanceEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Loan payment · {personName}'**
  String loanPaymentBalanceEntryTitle(String personName);

  /// No description provided for @errorSelectLoanPaymentSource.
  ///
  /// In en, this message translates to:
  /// **'Choose a wallet or payment source'**
  String get errorSelectLoanPaymentSource;

  /// No description provided for @loanOverview.
  ///
  /// In en, this message translates to:
  /// **'Loan position'**
  String get loanOverview;

  /// No description provided for @loanOwedToYou.
  ///
  /// In en, this message translates to:
  /// **'Owed to you'**
  String get loanOwedToYou;

  /// No description provided for @loanYouOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe'**
  String get loanYouOwe;

  /// No description provided for @loanNetPositive.
  ///
  /// In en, this message translates to:
  /// **'Net: people owe you more'**
  String get loanNetPositive;

  /// No description provided for @loanNetNegative.
  ///
  /// In en, this message translates to:
  /// **'Net: you owe more'**
  String get loanNetNegative;

  /// No description provided for @loanOpenCount.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get loanOpenCount;

  /// No description provided for @loanOverdueCount.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get loanOverdueCount;

  /// No description provided for @loanSettledCount.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get loanSettledCount;

  /// No description provided for @loanRemainingOf.
  ///
  /// In en, this message translates to:
  /// **'{remaining} left of {principal}'**
  String loanRemainingOf(String remaining, String principal);

  /// No description provided for @loanOfPrincipal.
  ///
  /// In en, this message translates to:
  /// **'of {amount}'**
  String loanOfPrincipal(String amount);

  /// No description provided for @loanTapToEdit.
  ///
  /// In en, this message translates to:
  /// **'Tap to edit loan'**
  String get loanTapToEdit;

  /// No description provided for @loanSettledBadge.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get loanSettledBadge;

  /// No description provided for @loanOverdueBadge.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get loanOverdueBadge;

  /// No description provided for @loanEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Track money you lent or borrowed'**
  String get loanEmptyTitle;

  /// No description provided for @loanEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a loan, record payments, and see what is still outstanding.'**
  String get loanEmptySubtitle;

  /// No description provided for @loanFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get loanFilterAll;

  /// No description provided for @loanFilterGiven.
  ///
  /// In en, this message translates to:
  /// **'Lent'**
  String get loanFilterGiven;

  /// No description provided for @loanFilterReceived.
  ///
  /// In en, this message translates to:
  /// **'Borrowed'**
  String get loanFilterReceived;

  /// No description provided for @loanFilterOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get loanFilterOverdue;

  /// No description provided for @loanFilterSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get loanFilterSettled;

  /// No description provided for @loanFilterEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this filter yet.'**
  String get loanFilterEmpty;

  /// No description provided for @loansSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get loansSectionTitle;

  /// No description provided for @walletSplitTitle.
  ///
  /// In en, this message translates to:
  /// **'Split a payment'**
  String get walletSplitTitle;

  /// No description provided for @walletSplitFabSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You paid via InstaPay or wallet — track who owes you.'**
  String get walletSplitFabSubtitle;

  /// No description provided for @walletSplitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Logs the full amount as an expense, then creates a loan for each person who should pay you back.'**
  String get walletSplitSubtitle;

  /// No description provided for @walletSplitWhatFor.
  ///
  /// In en, this message translates to:
  /// **'What was it for?'**
  String get walletSplitWhatFor;

  /// No description provided for @walletSplitWhatForHint.
  ///
  /// In en, this message translates to:
  /// **'Dinner, groceries, trip…'**
  String get walletSplitWhatForHint;

  /// No description provided for @walletSplitYouPaid.
  ///
  /// In en, this message translates to:
  /// **'You paid'**
  String get walletSplitYouPaid;

  /// No description provided for @walletSplitPaidFromHint.
  ///
  /// In en, this message translates to:
  /// **'InstaPay, Vodafone Cash, Visa, Cash…'**
  String get walletSplitPaidFromHint;

  /// No description provided for @walletSplitIncludeMe.
  ///
  /// In en, this message translates to:
  /// **'I was part of this'**
  String get walletSplitIncludeMe;

  /// No description provided for @walletSplitIncludeMeHint.
  ///
  /// In en, this message translates to:
  /// **'Your share is not added as a loan — only others who owe you.'**
  String get walletSplitIncludeMeHint;

  /// No description provided for @walletSplitEqualShares.
  ///
  /// In en, this message translates to:
  /// **'Split equally'**
  String get walletSplitEqualShares;

  /// No description provided for @walletSplitYourShare.
  ///
  /// In en, this message translates to:
  /// **'Your share: {amount}'**
  String walletSplitYourShare(String amount);

  /// No description provided for @walletSplitPeopleSection.
  ///
  /// In en, this message translates to:
  /// **'Who owes you'**
  String get walletSplitPeopleSection;

  /// No description provided for @walletSplitAddPerson.
  ///
  /// In en, this message translates to:
  /// **'Add person'**
  String get walletSplitAddPerson;

  /// No description provided for @walletSplitPersonHint.
  ///
  /// In en, this message translates to:
  /// **'Friend’s name'**
  String get walletSplitPersonHint;

  /// No description provided for @walletSplitNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional note or transfer reference'**
  String get walletSplitNotesHint;

  /// No description provided for @walletSplitSave.
  ///
  /// In en, this message translates to:
  /// **'Save split'**
  String get walletSplitSave;

  /// No description provided for @walletSplitTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter what the payment was for'**
  String get walletSplitTitleRequired;

  /// No description provided for @walletSplitPersonRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter each person’s name'**
  String get walletSplitPersonRequired;

  /// No description provided for @walletSplitAmountsExceedTotal.
  ///
  /// In en, this message translates to:
  /// **'People’s shares are more than the total you paid'**
  String get walletSplitAmountsExceedTotal;

  /// No description provided for @walletSplitAmountsMustMatchTotal.
  ///
  /// In en, this message translates to:
  /// **'People’s shares must add up to the total'**
  String get walletSplitAmountsMustMatchTotal;

  /// No description provided for @walletSplitSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved expense and {count} loan(s)'**
  String walletSplitSuccess(int count);

  /// No description provided for @errorEnterPersonName.
  ///
  /// In en, this message translates to:
  /// **'Enter the person\'s name'**
  String get errorEnterPersonName;

  /// No description provided for @errorEnterLoanAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid loan amount'**
  String get errorEnterLoanAmount;

  /// No description provided for @errorRepaidExceedsPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Repaid cannot be more than the loan amount'**
  String get errorRepaidExceedsPrincipal;

  /// No description provided for @errorEnterPaymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid payment amount'**
  String get errorEnterPaymentAmount;

  /// No description provided for @errorPaymentExceedsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Payment cannot be more than the remaining amount'**
  String get errorPaymentExceedsRemaining;

  /// No description provided for @associationPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get associationPersonal;

  /// No description provided for @currencyEgyptianPound.
  ///
  /// In en, this message translates to:
  /// **'Egyptian pound'**
  String get currencyEgyptianPound;

  /// No description provided for @currencyEgpSymbol.
  ///
  /// In en, this message translates to:
  /// **'E£'**
  String get currencyEgpSymbol;

  /// No description provided for @billRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Bill reminders'**
  String get billRemindersTitle;

  /// No description provided for @billRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified before recurring bills are due'**
  String get billRemindersSubtitle;

  /// No description provided for @billRemindersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No bill reminders yet. Add electricity, rent, internet, and more.'**
  String get billRemindersEmpty;

  /// No description provided for @billRemindersAdd.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get billRemindersAdd;

  /// No description provided for @billRemindersEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get billRemindersEdit;

  /// No description provided for @billRemindersTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Bill name'**
  String get billRemindersTitleLabel;

  /// No description provided for @billRemindersTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Electricity, Rent, Internet'**
  String get billRemindersTitleHint;

  /// No description provided for @billRemindersTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for the bill'**
  String get billRemindersTitleRequired;

  /// No description provided for @billRemindersAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (optional)'**
  String get billRemindersAmountLabel;

  /// No description provided for @billRemindersTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Notification time'**
  String get billRemindersTimeLabel;

  /// No description provided for @billRemindersDayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Day of month'**
  String get billRemindersDayOfMonth;

  /// No description provided for @billRemindersDayOfMonthShortMonthHint.
  ///
  /// In en, this message translates to:
  /// **'In shorter months, the reminder uses the last day of that month.'**
  String get billRemindersDayOfMonthShortMonthHint;

  /// No description provided for @billRemindersDayOfMonthValue.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String billRemindersDayOfMonthValue(int day);

  /// No description provided for @billRemindersRemindBefore.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get billRemindersRemindBefore;

  /// No description provided for @billRemindersRemindOnDay.
  ///
  /// In en, this message translates to:
  /// **'On due day'**
  String get billRemindersRemindOnDay;

  /// No description provided for @billRemindersRemind1Day.
  ///
  /// In en, this message translates to:
  /// **'1 day before'**
  String get billRemindersRemind1Day;

  /// No description provided for @billRemindersRemind3Days.
  ///
  /// In en, this message translates to:
  /// **'3 days before'**
  String get billRemindersRemind3Days;

  /// No description provided for @billRemindersRemind7Days.
  ///
  /// In en, this message translates to:
  /// **'7 days before'**
  String get billRemindersRemind7Days;

  /// No description provided for @billRemindersEnabled.
  ///
  /// In en, this message translates to:
  /// **'Bill reminders'**
  String get billRemindersEnabled;

  /// No description provided for @dailyDigestEnabled.
  ///
  /// In en, this message translates to:
  /// **'Daily summary'**
  String get dailyDigestEnabled;

  /// No description provided for @dailyDigestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Evening recap of yesterday\'s spending and your month so far'**
  String get dailyDigestSubtitle;

  /// No description provided for @dailyDigestTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Summary time'**
  String get dailyDigestTimeLabel;

  /// No description provided for @dailyDigestNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Your money yesterday'**
  String get dailyDigestNotificationTitle;

  /// No description provided for @dailyDigestNotificationEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions logged yesterday. Open Pockio to track today\'s spending.'**
  String get dailyDigestNotificationEmpty;

  /// No description provided for @dailyDigestYesterdayExpenses.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 expense ({amount})} other{{count} expenses ({amount})}}'**
  String dailyDigestYesterdayExpenses(int count, String amount);

  /// No description provided for @dailyDigestYesterdayNoExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses yesterday'**
  String get dailyDigestYesterdayNoExpenses;

  /// No description provided for @dailyDigestYesterdayIncomes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 income ({amount})} other{{count} incomes ({amount})}}'**
  String dailyDigestYesterdayIncomes(int count, String amount);

  /// No description provided for @dailyDigestYesterdayNoIncomes.
  ///
  /// In en, this message translates to:
  /// **'No income yesterday'**
  String get dailyDigestYesterdayNoIncomes;

  /// No description provided for @dailyDigestMonthNet.
  ///
  /// In en, this message translates to:
  /// **'Month net: {amount}'**
  String dailyDigestMonthNet(String amount);

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage bill reminders, daily summaries, and see what\'s scheduled next.'**
  String get notificationsSubtitle;

  /// No description provided for @notificationsMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Notification message'**
  String get notificationsMessageLabel;

  /// No description provided for @notificationsInbox.
  ///
  /// In en, this message translates to:
  /// **'Recent alerts'**
  String get notificationsInbox;

  /// No description provided for @notificationsUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get notificationsUpcoming;

  /// No description provided for @notificationsUpcomingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications scheduled. Turn on bill reminders or daily summary above.'**
  String get notificationsUpcomingEmpty;

  /// No description provided for @notificationsPermissionBanner.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off in system settings. Enable them to get bill reminders and your daily summary.'**
  String get notificationsPermissionBanner;

  /// No description provided for @notificationsOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get notificationsOpenSettings;

  /// No description provided for @notificationsManageBills.
  ///
  /// In en, this message translates to:
  /// **'Manage bills'**
  String get notificationsManageBills;

  /// No description provided for @notificationsScheduledBillSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{when} · {due}'**
  String notificationsScheduledBillSubtitle(String when, String due);

  /// No description provided for @notificationsScheduledDigestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Next summary · {when}'**
  String notificationsScheduledDigestSubtitle(String when);

  /// No description provided for @billRemindersPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications in system settings to get bill reminders.'**
  String get billRemindersPermissionDenied;

  /// No description provided for @billRemindersSaved.
  ///
  /// In en, this message translates to:
  /// **'Reminder saved'**
  String get billRemindersSaved;

  /// No description provided for @billRemindersDeleted.
  ///
  /// In en, this message translates to:
  /// **'Reminder deleted'**
  String get billRemindersDeleted;

  /// No description provided for @recurringTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring transactions'**
  String get recurringTransactionsTitle;

  /// No description provided for @recurringTransactionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-add salary, rent, and bills on the due day each month'**
  String get recurringTransactionsSubtitle;

  /// No description provided for @recurringTransactionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recurring transactions yet. Add salary, rent, internet, and more.'**
  String get recurringTransactionsEmpty;

  /// No description provided for @recurringTransactionsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add recurring'**
  String get recurringTransactionsAdd;

  /// No description provided for @recurringTransactionsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit recurring'**
  String get recurringTransactionsEdit;

  /// No description provided for @recurringTransactionsTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Salary, Rent, Internet'**
  String get recurringTransactionsTitleHint;

  /// No description provided for @recurringTransactionsPostedThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Posted this month'**
  String get recurringTransactionsPostedThisMonth;

  /// No description provided for @recurringTransactionsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Recurring transaction deleted'**
  String get recurringTransactionsDeleted;

  /// No description provided for @recurringTransactionsDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this recurring transaction?'**
  String get recurringTransactionsDeleteConfirmTitle;

  /// No description provided for @commitmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Gameyas & installments'**
  String get commitmentsTitle;

  /// No description provided for @commitmentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track gameyas and installments. Each payment is saved in Expenses and taken from a balance source. On your turn, the pot is added to Income.'**
  String get commitmentsSubtitle;

  /// No description provided for @commitmentsGameyas.
  ///
  /// In en, this message translates to:
  /// **'Gameyas'**
  String get commitmentsGameyas;

  /// No description provided for @commitmentsInstallments.
  ///
  /// In en, this message translates to:
  /// **'Installments'**
  String get commitmentsInstallments;

  /// No description provided for @commitmentsAddGameya.
  ///
  /// In en, this message translates to:
  /// **'Add gameya'**
  String get commitmentsAddGameya;

  /// No description provided for @commitmentsAddInstallment.
  ///
  /// In en, this message translates to:
  /// **'Add installment'**
  String get commitmentsAddInstallment;

  /// No description provided for @commitmentsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commitmentsEditTitle;

  /// No description provided for @commitmentsGameyaHint.
  ///
  /// In en, this message translates to:
  /// **'A gameya: everyone pays the same amount each month, and one person receives the full pot on their turn.'**
  String get commitmentsGameyaHint;

  /// No description provided for @commitmentsInstallmentHint.
  ///
  /// In en, this message translates to:
  /// **'An installment plan: a fixed monthly payment until the total is paid off.'**
  String get commitmentsInstallmentHint;

  /// No description provided for @commitmentsNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get commitmentsNameLabel;

  /// No description provided for @commitmentsGameyaNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Work gameya'**
  String get commitmentsGameyaNameHint;

  /// No description provided for @commitmentsInstallmentNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Phone, furniture'**
  String get commitmentsInstallmentNameHint;

  /// No description provided for @commitmentsMonthlyAmount.
  ///
  /// In en, this message translates to:
  /// **'Monthly payment'**
  String get commitmentsMonthlyAmount;

  /// No description provided for @commitmentsMemberCount.
  ///
  /// In en, this message translates to:
  /// **'Number of members / months'**
  String get commitmentsMemberCount;

  /// No description provided for @commitmentsInstallmentCount.
  ///
  /// In en, this message translates to:
  /// **'Number of installments'**
  String get commitmentsInstallmentCount;

  /// No description provided for @commitmentsMyTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn (which month)'**
  String get commitmentsMyTurn;

  /// No description provided for @commitmentsMyTurnHint.
  ///
  /// In en, this message translates to:
  /// **'1 = first month'**
  String get commitmentsMyTurnHint;

  /// No description provided for @commitmentsMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'People, in turn order'**
  String get commitmentsMembersTitle;

  /// No description provided for @commitmentsMembersHint.
  ///
  /// In en, this message translates to:
  /// **'The first name receives the pot in month one. Mark your own name with “Me”.'**
  String get commitmentsMembersHint;

  /// No description provided for @commitmentsMemberHint.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get commitmentsMemberHint;

  /// No description provided for @commitmentsMemberMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get commitmentsMemberMe;

  /// No description provided for @commitmentsAddMember.
  ///
  /// In en, this message translates to:
  /// **'Add a person'**
  String get commitmentsAddMember;

  /// No description provided for @commitmentsMemberNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter every person’s name'**
  String get commitmentsMemberNameRequired;

  /// No description provided for @commitmentsMembersMin.
  ///
  /// In en, this message translates to:
  /// **'A gameya needs at least two people'**
  String get commitmentsMembersMin;

  /// No description provided for @commitmentsTurnIs.
  ///
  /// In en, this message translates to:
  /// **'{name}’s turn'**
  String commitmentsTurnIs(String name);

  /// No description provided for @commitmentsDueDay.
  ///
  /// In en, this message translates to:
  /// **'Due on day {day}'**
  String commitmentsDueDay(int day);

  /// No description provided for @commitmentsNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional note'**
  String get commitmentsNotesHint;

  /// No description provided for @commitmentsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commitmentsSave;

  /// No description provided for @commitmentsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get commitmentsSaved;

  /// No description provided for @commitmentsNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get commitmentsNameRequired;

  /// No description provided for @commitmentsCountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter how many months'**
  String get commitmentsCountRequired;

  /// No description provided for @commitmentsTurnInvalid.
  ///
  /// In en, this message translates to:
  /// **'Your turn must be between 1 and the number of months'**
  String get commitmentsTurnInvalid;

  /// No description provided for @commitmentsDueThisMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount} still due this month'**
  String commitmentsDueThisMonth(String amount);

  /// No description provided for @commitmentsEmptyGameya.
  ///
  /// In en, this message translates to:
  /// **'No gameyas yet. Add one to track your share and when you receive the pot.'**
  String get commitmentsEmptyGameya;

  /// No description provided for @commitmentsEmptyInstallment.
  ///
  /// In en, this message translates to:
  /// **'No installments yet. Add a plan to see how many payments are left.'**
  String get commitmentsEmptyInstallment;

  /// No description provided for @commitmentsProgress.
  ///
  /// In en, this message translates to:
  /// **'{paid} of {total} paid · {left} left'**
  String commitmentsProgress(int paid, int total, String left);

  /// No description provided for @commitmentsPayout.
  ///
  /// In en, this message translates to:
  /// **'You receive {amount} on your turn'**
  String commitmentsPayout(String amount);

  /// No description provided for @commitmentsYourTurn.
  ///
  /// In en, this message translates to:
  /// **'This month is your turn — you should receive the pot.'**
  String get commitmentsYourTurn;

  /// No description provided for @commitmentsTurnPassed.
  ///
  /// In en, this message translates to:
  /// **'Your turn already passed.'**
  String get commitmentsTurnPassed;

  /// No description provided for @commitmentsTurnsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} payment(s) until your turn'**
  String commitmentsTurnsLeft(int count);

  /// No description provided for @commitmentsMarkPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark this month paid'**
  String get commitmentsMarkPaid;

  /// No description provided for @commitmentsPersonPaidAction.
  ///
  /// In en, this message translates to:
  /// **'Mark paid'**
  String get commitmentsPersonPaidAction;

  /// No description provided for @commitmentsPersonPaidDone.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get commitmentsPersonPaidDone;

  /// No description provided for @commitmentsPaidThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Paid this month'**
  String get commitmentsPaidThisMonth;

  /// No description provided for @commitmentsFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get commitmentsFinished;

  /// No description provided for @commitmentsUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commitmentsUndo;

  /// No description provided for @commitmentsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this?'**
  String get commitmentsDeleteTitle;

  /// No description provided for @commitmentsCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Same categories as Expenses, so this payment shows up there.'**
  String get commitmentsCategoryHint;

  /// No description provided for @commitmentsPayFromHint.
  ///
  /// In en, this message translates to:
  /// **'Same wallets as Expenses. This month’s payment is saved there and taken from this source.'**
  String get commitmentsPayFromHint;

  /// No description provided for @commitmentsReceiveInto.
  ///
  /// In en, this message translates to:
  /// **'Add the pot to'**
  String get commitmentsReceiveInto;

  /// No description provided for @commitmentsReceiveIntoHint.
  ///
  /// In en, this message translates to:
  /// **'On your turn, the full amount is saved in Income on this source.'**
  String get commitmentsReceiveIntoHint;

  /// No description provided for @commitmentsFromSource.
  ///
  /// In en, this message translates to:
  /// **'Paid from {source}'**
  String commitmentsFromSource(String source);

  /// No description provided for @commitmentsPayoutInto.
  ///
  /// In en, this message translates to:
  /// **'Pot goes to {source}'**
  String commitmentsPayoutInto(String source);

  /// No description provided for @commitmentsConfirmPay.
  ///
  /// In en, this message translates to:
  /// **'Save to expenses'**
  String get commitmentsConfirmPay;

  /// No description provided for @commitmentsTurnPayoutNote.
  ///
  /// In en, this message translates to:
  /// **'This month is your turn. Your share is an expense, and {amount} is added to income.'**
  String commitmentsTurnPayoutNote(String amount);

  /// No description provided for @commitmentsExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'{title} ({cycle}/{total})'**
  String commitmentsExpenseTitle(String title, int cycle, int total);

  /// No description provided for @commitmentsIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'{title} payout'**
  String commitmentsIncomeTitle(String title);

  /// No description provided for @commitmentsLedgerMissing.
  ///
  /// In en, this message translates to:
  /// **'The payment was saved, but it could not be linked. Check Expenses.'**
  String get commitmentsLedgerMissing;

  /// No description provided for @commitmentsPosted.
  ///
  /// In en, this message translates to:
  /// **'Saved in Expenses'**
  String get commitmentsPosted;

  /// No description provided for @billRemindersTestNow.
  ///
  /// In en, this message translates to:
  /// **'Test now'**
  String get billRemindersTestNow;

  /// No description provided for @billRemindersTestNowSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent — check your notification shade'**
  String get billRemindersTestNowSent;

  /// No description provided for @billReminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Bill: {title}'**
  String billReminderNotificationTitle(String title);

  /// No description provided for @billReminderNotificationDueTodayWithAmount.
  ///
  /// In en, this message translates to:
  /// **'Due today — {amount}'**
  String billReminderNotificationDueTodayWithAmount(String amount);

  /// No description provided for @billReminderNotificationDueTodayPlain.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get billReminderNotificationDueTodayPlain;

  /// No description provided for @billReminderNotificationDueInDaysWithAmount.
  ///
  /// In en, this message translates to:
  /// **'Due in {days} days — {amount}'**
  String billReminderNotificationDueInDaysWithAmount(int days, String amount);

  /// No description provided for @billReminderNotificationDueInDaysPlain.
  ///
  /// In en, this message translates to:
  /// **'Due in {days} days'**
  String billReminderNotificationDueInDaysPlain(int days);

  /// No description provided for @billRemindersPresetElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get billRemindersPresetElectricity;

  /// No description provided for @billRemindersPresetRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get billRemindersPresetRent;

  /// No description provided for @billRemindersPresetInternet.
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get billRemindersPresetInternet;

  /// No description provided for @billRemindersPresetWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get billRemindersPresetWater;

  /// No description provided for @associationSelect.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get associationSelect;

  /// No description provided for @associationPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose ledger'**
  String get associationPickerTitle;

  /// No description provided for @associationPickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Personal is only yours. A separate ledger, like work or home, lets people you invite add their own entries. An association is recorded by the manager.'**
  String get associationPickerSubtitle;

  /// No description provided for @associationCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New ledger'**
  String get associationCreateTitle;

  /// No description provided for @associationCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Add association'**
  String get associationCreateAction;

  /// No description provided for @associationCreateFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'New ledger'**
  String get associationCreateFamilyTitle;

  /// No description provided for @associationCreateFamilyAction.
  ///
  /// In en, this message translates to:
  /// **'Add ledger'**
  String get associationCreateFamilyAction;

  /// No description provided for @associationCreateFamilyHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Work, Home'**
  String get associationCreateFamilyHint;

  /// No description provided for @associationCreateFamilySubtitle.
  ///
  /// In en, this message translates to:
  /// **'A separate ledger from your personal one, for work or anything else. People you invite can add their own income and expenses.'**
  String get associationCreateFamilySubtitle;

  /// No description provided for @associationFamilyBadge.
  ///
  /// In en, this message translates to:
  /// **'Separate'**
  String get associationFamilyBadge;

  /// No description provided for @associationFamilyBanner.
  ///
  /// In en, this message translates to:
  /// **'Separate ledger: everyone can add their own income and expenses.'**
  String get associationFamilyBanner;

  /// No description provided for @familyTransactionBy.
  ///
  /// In en, this message translates to:
  /// **'Added by {name}'**
  String familyTransactionBy(String name);

  /// No description provided for @familyAuthorYou.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get familyAuthorYou;

  /// No description provided for @familyAuthorUnknown.
  ///
  /// In en, this message translates to:
  /// **'a member'**
  String get familyAuthorUnknown;

  /// No description provided for @associationNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Work, Home, Savings'**
  String get associationNameHint;

  /// No description provided for @associationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for the ledger'**
  String get associationNameRequired;

  /// No description provided for @associationCreated.
  ///
  /// In en, this message translates to:
  /// **'Created \"{name}\"'**
  String associationCreated(String name);

  /// No description provided for @associationDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete ledger?'**
  String get associationDeleteConfirmTitle;

  /// No description provided for @associationDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" and all its income, expenses, budgets, and plans? This cannot be undone.'**
  String associationDeleteConfirmMessage(String name);

  /// No description provided for @associationDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get associationDeleteAction;

  /// No description provided for @associationDeletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Ledger deleted'**
  String get associationDeletedSnack;

  /// No description provided for @associationCannotDeletePersonal.
  ///
  /// In en, this message translates to:
  /// **'The personal ledger cannot be deleted'**
  String get associationCannotDeletePersonal;

  /// No description provided for @associationInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite members'**
  String get associationInviteTitle;

  /// No description provided for @associationInviteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search by username and invite people to \"{name}\". They choose whether to join.'**
  String associationInviteSubtitle(String name);

  /// No description provided for @associationInviteSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search username…'**
  String get associationInviteSearchHint;

  /// No description provided for @associationInviteSearchMinChars.
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 characters to search'**
  String get associationInviteSearchMinChars;

  /// No description provided for @associationInviteNoResults.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get associationInviteNoResults;

  /// No description provided for @associationInviteAction.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get associationInviteAction;

  /// No description provided for @associationInviteSentLabel.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get associationInviteSentLabel;

  /// No description provided for @associationInviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent to {username}'**
  String associationInviteSent(String username);

  /// No description provided for @associationInviteMembersAction.
  ///
  /// In en, this message translates to:
  /// **'Invite members'**
  String get associationInviteMembersAction;

  /// No description provided for @associationInvitePendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitations for you'**
  String get associationInvitePendingTitle;

  /// No description provided for @associationInvitePendingBody.
  ///
  /// In en, this message translates to:
  /// **'{username} invited you to \"{name}\"'**
  String associationInvitePendingBody(String username, String name);

  /// No description provided for @associationInviteAccept.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get associationInviteAccept;

  /// No description provided for @associationInviteReject.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get associationInviteReject;

  /// No description provided for @associationInviteAcceptedSnack.
  ///
  /// In en, this message translates to:
  /// **'You joined the ledger'**
  String get associationInviteAcceptedSnack;

  /// No description provided for @associationInviteRejectedSnack.
  ///
  /// In en, this message translates to:
  /// **'Invitation declined'**
  String get associationInviteRejectedSnack;

  /// No description provided for @associationInviteDisclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you invite'**
  String get associationInviteDisclaimerTitle;

  /// No description provided for @associationInviteDisclaimerBody.
  ///
  /// In en, this message translates to:
  /// **'Pockio helps you organize shared ledgers. You are responsible for who you invite and how money is handled between members. The app does not hold funds, is not a bank, and is not liable for disputes between members. Only invite people you trust.'**
  String get associationInviteDisclaimerBody;

  /// No description provided for @associationInviteDisclaimerAccept.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get associationInviteDisclaimerAccept;

  /// No description provided for @associationInviteLegalNote.
  ///
  /// In en, this message translates to:
  /// **'Pockio is a record-keeping tool only — not financial advice, escrow, or legal counsel.'**
  String get associationInviteLegalNote;

  /// No description provided for @associationManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage ledger'**
  String get associationManageTitle;

  /// No description provided for @associationManageOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get associationManageOpen;

  /// No description provided for @associationManageNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Switch to a shared ledger first.'**
  String get associationManageNotAvailable;

  /// No description provided for @associationManageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You are the treasurer. Record all income, expenses, plans, and dates here. Members only view.'**
  String get associationManageSubtitle;

  /// No description provided for @associationManageIncomeHint.
  ///
  /// In en, this message translates to:
  /// **'Add and edit income entries'**
  String get associationManageIncomeHint;

  /// No description provided for @associationManageExpenseHint.
  ///
  /// In en, this message translates to:
  /// **'Add and edit expenses with dates'**
  String get associationManageExpenseHint;

  /// No description provided for @associationManageBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'See balance for this ledger'**
  String get associationManageBalanceHint;

  /// No description provided for @associationManageStatsHint.
  ///
  /// In en, this message translates to:
  /// **'Charts for the last 3 months'**
  String get associationManageStatsHint;

  /// No description provided for @associationManagePlansHint.
  ///
  /// In en, this message translates to:
  /// **'Savings plans and goals'**
  String get associationManagePlansHint;

  /// No description provided for @associationManageInviteHint.
  ///
  /// In en, this message translates to:
  /// **'Invite people to view this ledger'**
  String get associationManageInviteHint;

  /// No description provided for @associationManageTreasurerNote.
  ///
  /// In en, this message translates to:
  /// **'Only you can add or change numbers. Invited members see the same ledger read-only.'**
  String get associationManageTreasurerNote;

  /// No description provided for @associationTreasurerBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'You manage this ledger'**
  String get associationTreasurerBannerTitle;

  /// No description provided for @associationTreasurerBannerBody.
  ///
  /// In en, this message translates to:
  /// **'All entries for {name} are recorded by you.'**
  String associationTreasurerBannerBody(String name);

  /// No description provided for @associationMemberReadOnlyBanner.
  ///
  /// In en, this message translates to:
  /// **'View-only member of \"{name}\". Ask the treasurer to add or edit entries.'**
  String associationMemberReadOnlyBanner(String name);

  /// No description provided for @associationManageHubAction.
  ///
  /// In en, this message translates to:
  /// **'Manage ledger'**
  String get associationManageHubAction;

  /// No description provided for @associationHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Association'**
  String get associationHubTitle;

  /// No description provided for @associationHubOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get associationHubOpen;

  /// No description provided for @associationHubNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Choose a shared association first.'**
  String get associationHubNotAvailable;

  /// No description provided for @associationHubOwnerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You manage this gom3eya: payout, installment, whose turn, and members.'**
  String get associationHubOwnerSubtitle;

  /// No description provided for @associationHubMemberSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View-only: see payout, installment, and whose turn it is.'**
  String get associationHubMemberSubtitle;

  /// No description provided for @associationHubPayout.
  ///
  /// In en, this message translates to:
  /// **'Payout (gom3eya amount)'**
  String get associationHubPayout;

  /// No description provided for @associationHubPayoutHint.
  ///
  /// In en, this message translates to:
  /// **'12000'**
  String get associationHubPayoutHint;

  /// No description provided for @associationHubInstallment.
  ///
  /// In en, this message translates to:
  /// **'Installment'**
  String get associationHubInstallment;

  /// No description provided for @associationHubInstallmentHint.
  ///
  /// In en, this message translates to:
  /// **'1000'**
  String get associationHubInstallmentHint;

  /// No description provided for @associationHubMemberCount.
  ///
  /// In en, this message translates to:
  /// **'Slots'**
  String get associationHubMemberCount;

  /// No description provided for @associationHubCollectionDay.
  ///
  /// In en, this message translates to:
  /// **'Collection day'**
  String get associationHubCollectionDay;

  /// No description provided for @associationHubCollectionDayHint.
  ///
  /// In en, this message translates to:
  /// **'Day of month (1–31)'**
  String get associationHubCollectionDayHint;

  /// No description provided for @associationHubCollectionDayInvalid.
  ///
  /// In en, this message translates to:
  /// **'Collection day must be between 1 and 31.'**
  String get associationHubCollectionDayInvalid;

  /// No description provided for @associationHubDayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String associationHubDayOfMonth(int day);

  /// No description provided for @associationHubCurrentTurn.
  ///
  /// In en, this message translates to:
  /// **'Current turn'**
  String get associationHubCurrentTurn;

  /// No description provided for @associationHubTurnNumber.
  ///
  /// In en, this message translates to:
  /// **'Turn {current} of {total}'**
  String associationHubTurnNumber(int current, int total);

  /// No description provided for @associationHubTurnList.
  ///
  /// In en, this message translates to:
  /// **'Turn order'**
  String get associationHubTurnList;

  /// No description provided for @associationHubEmptySetup.
  ///
  /// In en, this message translates to:
  /// **'Set payout, installment, and who takes each turn.'**
  String get associationHubEmptySetup;

  /// No description provided for @associationHubEmptyTurnList.
  ///
  /// In en, this message translates to:
  /// **'No slots yet. Tap Edit to add names.'**
  String get associationHubEmptyTurnList;

  /// No description provided for @associationHubEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get associationHubEdit;

  /// No description provided for @associationHubSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get associationHubSave;

  /// No description provided for @associationHubSaved.
  ///
  /// In en, this message translates to:
  /// **'Association details saved.'**
  String get associationHubSaved;

  /// No description provided for @associationHubSlotsRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one name for the turn order.'**
  String get associationHubSlotsRequired;

  /// No description provided for @associationHubFormFixErrors.
  ///
  /// In en, this message translates to:
  /// **'Fix the highlighted fields.'**
  String get associationHubFormFixErrors;

  /// No description provided for @associationHubPaymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Installment payments'**
  String get associationHubPaymentsTitle;

  /// No description provided for @associationHubPaymentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded yet.'**
  String get associationHubPaymentsEmpty;

  /// No description provided for @associationHubPaymentsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {amount}'**
  String associationHubPaymentsTotal(String amount);

  /// No description provided for @associationHubRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get associationHubRecordPayment;

  /// No description provided for @associationHubPaymentRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded.'**
  String get associationHubPaymentRecorded;

  /// No description provided for @associationHubPaymentPayer.
  ///
  /// In en, this message translates to:
  /// **'Who paid'**
  String get associationHubPaymentPayer;

  /// No description provided for @associationHubPaymentPayerRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose who paid.'**
  String get associationHubPaymentPayerRequired;

  /// No description provided for @associationHubPaymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount paid'**
  String get associationHubPaymentAmount;

  /// No description provided for @associationHubPaymentDate.
  ///
  /// In en, this message translates to:
  /// **'Payment date'**
  String get associationHubPaymentDate;

  /// No description provided for @associationHubPaymentPaidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid on {date}'**
  String associationHubPaymentPaidOn(String date);

  /// No description provided for @associationHubPaymentNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get associationHubPaymentNote;

  /// No description provided for @associationHubPaymentNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. March installment'**
  String get associationHubPaymentNoteHint;

  /// No description provided for @associationHubPaymentSave.
  ///
  /// In en, this message translates to:
  /// **'Save payment'**
  String get associationHubPaymentSave;

  /// No description provided for @associationHubPaymentDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete payment?'**
  String get associationHubPaymentDeleteTitle;

  /// No description provided for @associationHubPaymentDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove payment record for {name}?'**
  String associationHubPaymentDeleteMessage(String name);

  /// No description provided for @associationHubPaymentDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get associationHubPaymentDeleteConfirm;

  /// No description provided for @associationHubEndGam3eya.
  ///
  /// In en, this message translates to:
  /// **'End gom3eya'**
  String get associationHubEndGam3eya;

  /// No description provided for @associationHubEndGam3eyaTitle.
  ///
  /// In en, this message translates to:
  /// **'End this gom3eya?'**
  String get associationHubEndGam3eyaTitle;

  /// No description provided for @associationHubEndGam3eyaMessage.
  ///
  /// In en, this message translates to:
  /// **'The association will be closed. You can still view turns and payments, but no more edits or new payments.'**
  String get associationHubEndGam3eyaMessage;

  /// No description provided for @associationHubEndGam3eyaConfirm.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get associationHubEndGam3eyaConfirm;

  /// No description provided for @associationHubEndGam3eyaDone.
  ///
  /// In en, this message translates to:
  /// **'Gom3eya ended.'**
  String get associationHubEndGam3eyaDone;

  /// No description provided for @associationHubEndedBanner.
  ///
  /// In en, this message translates to:
  /// **'This gom3eya ended on {date}. View only.'**
  String associationHubEndedBanner(String date);

  /// No description provided for @associationHubOwnerEndedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This gom3eya is finished. Data is view-only.'**
  String get associationHubOwnerEndedSubtitle;

  /// No description provided for @associationHubMemberEndedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The manager ended this gom3eya. View only.'**
  String get associationHubMemberEndedSubtitle;

  /// No description provided for @associationHubAdvanceTurn.
  ///
  /// In en, this message translates to:
  /// **'Next turn'**
  String get associationHubAdvanceTurn;

  /// No description provided for @associationHubAdvanceTurnConfirm.
  ///
  /// In en, this message translates to:
  /// **'Mark turn complete and move to the next person after {name}?'**
  String associationHubAdvanceTurnConfirm(String name);

  /// No description provided for @associationHubReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get associationHubReceived;

  /// No description provided for @associationHubPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get associationHubPending;

  /// No description provided for @associationHubCurrentBadge.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get associationHubCurrentBadge;

  /// No description provided for @associationHubInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite members'**
  String get associationHubInvite;

  /// No description provided for @associationHubTreasurerNote.
  ///
  /// In en, this message translates to:
  /// **'Financial entries (income/expenses) are still recorded by the manager on the home tabs. This page tracks the gom3eya schedule.'**
  String get associationHubTreasurerNote;

  /// No description provided for @associationHubAppMembers.
  ///
  /// In en, this message translates to:
  /// **'App members'**
  String get associationHubAppMembers;

  /// No description provided for @associationHubRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get associationHubRoleOwner;

  /// No description provided for @associationHubRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get associationHubRoleAdmin;

  /// No description provided for @associationHubRoleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get associationHubRoleMember;

  /// No description provided for @associationHubAddSlot.
  ///
  /// In en, this message translates to:
  /// **'Add slot'**
  String get associationHubAddSlot;

  /// No description provided for @associationHubSlotName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get associationHubSlotName;

  /// No description provided for @associationHubStartDate.
  ///
  /// In en, this message translates to:
  /// **'Association start'**
  String get associationHubStartDate;

  /// No description provided for @associationHubEndDate.
  ///
  /// In en, this message translates to:
  /// **'Association end'**
  String get associationHubEndDate;

  /// No description provided for @associationHubDateNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get associationHubDateNotSet;

  /// No description provided for @associationHubClearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get associationHubClearDate;

  /// No description provided for @associationHubEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'End date must be on or after the start date.'**
  String get associationHubEndBeforeStart;

  /// No description provided for @associationHubPersonPaymentDate.
  ///
  /// In en, this message translates to:
  /// **'Payment date'**
  String get associationHubPersonPaymentDate;

  /// No description provided for @associationHubPersonCollectionDate.
  ///
  /// In en, this message translates to:
  /// **'Collection date'**
  String get associationHubPersonCollectionDate;

  /// No description provided for @associationHubSplitTurn.
  ///
  /// In en, this message translates to:
  /// **'Split this turn'**
  String get associationHubSplitTurn;

  /// No description provided for @associationHubRemovePartner.
  ///
  /// In en, this message translates to:
  /// **'Remove partner'**
  String get associationHubRemovePartner;

  /// No description provided for @associationHubPartnerName.
  ///
  /// In en, this message translates to:
  /// **'Partner name'**
  String get associationHubPartnerName;

  /// No description provided for @associationHubPartnerRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the partner\'s name.'**
  String get associationHubPartnerRequired;

  /// No description provided for @associationHubSplitBadge.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get associationHubSplitBadge;

  /// No description provided for @associationHubSplitHint.
  ///
  /// In en, this message translates to:
  /// **'Both people share this turn. Each has a payment date and a collection date.'**
  String get associationHubSplitHint;

  /// No description provided for @associationHubTurnListHint.
  ///
  /// In en, this message translates to:
  /// **'Set each person\'s payment date and collection date. A turn can be shared by two people.'**
  String get associationHubTurnListHint;

  /// No description provided for @associationHubPaysOn.
  ///
  /// In en, this message translates to:
  /// **'Pays {date}'**
  String associationHubPaysOn(String date);

  /// No description provided for @associationHubCollectsOn.
  ///
  /// In en, this message translates to:
  /// **'Collects {date}'**
  String associationHubCollectsOn(String date);

  /// No description provided for @associationHubSharedNames.
  ///
  /// In en, this message translates to:
  /// **'{first} & {second}'**
  String associationHubSharedNames(String first, String second);

  /// No description provided for @associationHubBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage association'**
  String get associationHubBannerTitle;

  /// No description provided for @associationHubBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Turn, payout & installment for {name}.'**
  String associationHubBannerBody(String name);

  /// No description provided for @homeWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get homeWelcomeBack;

  /// No description provided for @homeWelcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String homeWelcomeUser(String name);

  /// No description provided for @homeFinanceOverview.
  ///
  /// In en, this message translates to:
  /// **'Finance Overview'**
  String get homeFinanceOverview;

  /// No description provided for @homeDateFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter by date'**
  String get homeDateFilterTitle;

  /// No description provided for @homeFilterAllMonths.
  ///
  /// In en, this message translates to:
  /// **'All months'**
  String get homeFilterAllMonths;

  /// No description provided for @homeFilterByMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get homeFilterByMonth;

  /// No description provided for @homeFilterByDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get homeFilterByDay;

  /// No description provided for @homeFilterThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get homeFilterThisMonth;

  /// No description provided for @homeFilterPickMonth.
  ///
  /// In en, this message translates to:
  /// **'Pick month'**
  String get homeFilterPickMonth;

  /// No description provided for @homeFilterPickDay.
  ///
  /// In en, this message translates to:
  /// **'Pick day'**
  String get homeFilterPickDay;

  /// No description provided for @homeFilterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeFilterToday;

  /// No description provided for @homeFilterNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries for this period'**
  String get homeFilterNoEntries;

  /// No description provided for @accountSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account settings'**
  String get accountSettingsTitle;

  /// No description provided for @changeUsername.
  ///
  /// In en, this message translates to:
  /// **'Change username'**
  String get changeUsername;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsTheme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @appearanceColors.
  ///
  /// In en, this message translates to:
  /// **'App color'**
  String get appearanceColors;

  /// No description provided for @appearanceGradients.
  ///
  /// In en, this message translates to:
  /// **'Gradient style'**
  String get appearanceGradients;

  /// No description provided for @appearanceCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get appearanceCustom;

  /// No description provided for @appearancePickColor.
  ///
  /// In en, this message translates to:
  /// **'Pick a color'**
  String get appearancePickColor;

  /// No description provided for @appearanceCustomPrimary.
  ///
  /// In en, this message translates to:
  /// **'Main color'**
  String get appearanceCustomPrimary;

  /// No description provided for @appearanceCustomSecondary.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get appearanceCustomSecondary;

  /// No description provided for @appearanceGradientStops.
  ///
  /// In en, this message translates to:
  /// **'Gradient colors'**
  String get appearanceGradientStops;

  /// No description provided for @appearancePaletteCoral.
  ///
  /// In en, this message translates to:
  /// **'Coral'**
  String get appearancePaletteCoral;

  /// No description provided for @appearancePaletteOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get appearancePaletteOcean;

  /// No description provided for @appearancePaletteForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get appearancePaletteForest;

  /// No description provided for @appearancePaletteSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get appearancePaletteSunset;

  /// No description provided for @appearancePaletteGrape.
  ///
  /// In en, this message translates to:
  /// **'Grape'**
  String get appearancePaletteGrape;

  /// No description provided for @appearancePaletteRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get appearancePaletteRose;

  /// No description provided for @appearancePaletteSlate.
  ///
  /// In en, this message translates to:
  /// **'Slate'**
  String get appearancePaletteSlate;

  /// No description provided for @appearanceGradientDiagonal.
  ///
  /// In en, this message translates to:
  /// **'Diagonal'**
  String get appearanceGradientDiagonal;

  /// No description provided for @appearanceGradientSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset sweep'**
  String get appearanceGradientSunset;

  /// No description provided for @appearanceGradientAurora.
  ///
  /// In en, this message translates to:
  /// **'Aurora'**
  String get appearanceGradientAurora;

  /// No description provided for @appearanceGradientWave.
  ///
  /// In en, this message translates to:
  /// **'Wave'**
  String get appearanceGradientWave;

  /// No description provided for @appearanceGradientSoft.
  ///
  /// In en, this message translates to:
  /// **'Soft fade'**
  String get appearanceGradientSoft;

  /// No description provided for @settingsCalculator.
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get settingsCalculator;

  /// No description provided for @settingsRateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate on Google Play'**
  String get settingsRateApp;

  /// No description provided for @settingsRateAppFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open Google Play. Try again later.'**
  String get settingsRateAppFailed;

  /// No description provided for @calculatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get calculatorTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove your profile, incomes, expenses, and plans. This cannot be undone.'**
  String get deleteAccountConfirmMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @usernameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Username updated'**
  String get usernameUpdated;

  /// No description provided for @errorEnterUsername.
  ///
  /// In en, this message translates to:
  /// **'Please enter a username'**
  String get errorEnterUsername;

  /// No description provided for @errorUsernameTaken.
  ///
  /// In en, this message translates to:
  /// **'That username is already taken. Choose another.'**
  String get errorUsernameTaken;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to use the app.'**
  String get logoutConfirmMessage;

  /// No description provided for @loginWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back 👋'**
  String get loginWelcomeTitle;

  /// No description provided for @loginWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Login to continue using your account'**
  String get loginWelcomeSubtitle;

  /// No description provided for @labelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get labelEmail;

  /// No description provided for @hintEmail.
  ///
  /// In en, this message translates to:
  /// **'example@gmail.com'**
  String get hintEmail;

  /// No description provided for @labelPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get labelPassword;

  /// No description provided for @hintPasswordDots.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get hintPasswordDots;

  /// No description provided for @forgotPasswordQuestion.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordQuestion;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orDivider;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithFacebook.
  ///
  /// In en, this message translates to:
  /// **'Continue with Facebook'**
  String get continueWithFacebook;

  /// No description provided for @noAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccountPrompt;

  /// No description provided for @signUpLink.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpLink;

  /// No description provided for @messageEnterEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter email and password'**
  String get messageEnterEmailPassword;

  /// No description provided for @messageLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get messageLoginFailed;

  /// No description provided for @messageLoginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login successfully'**
  String get messageLoginSuccess;

  /// No description provided for @signupCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account 🚀'**
  String get signupCreateTitle;

  /// No description provided for @signupCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account to continue'**
  String get signupCreateSubtitle;

  /// No description provided for @labelFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get labelFullName;

  /// No description provided for @hintEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get hintEnterYourName;

  /// No description provided for @labelConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get labelConfirmPassword;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountButton;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @loginLinkShort.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginLinkShort;

  /// No description provided for @signupErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get signupErrorGeneric;

  /// No description provided for @signupSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Signup successful'**
  String get signupSuccessful;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you a password reset link.'**
  String get forgotPasswordDescription;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset OTP'**
  String get sendResetLink;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @errorTryAgainGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get errorTryAgainGeneric;

  /// No description provided for @setNewPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set New Password 🔒'**
  String get setNewPasswordTitle;

  /// No description provided for @setNewPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the OTP code and create your new password.'**
  String get setNewPasswordSubtitle;

  /// No description provided for @labelOtpCode.
  ///
  /// In en, this message translates to:
  /// **'OTP Code'**
  String get labelOtpCode;

  /// No description provided for @hintOtpCode.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get hintOtpCode;

  /// No description provided for @labelNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get labelNewPassword;

  /// No description provided for @buttonSetNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get buttonSetNewPassword;

  /// No description provided for @passwordUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully ✅'**
  String get passwordUpdatedSuccessfully;

  /// No description provided for @noRouteForName.
  ///
  /// In en, this message translates to:
  /// **'No route defined for {name}'**
  String noRouteForName(Object name);

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @offlineWithPendingTransactions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Offline — 1 entry will sync when you\'re back online} other{Offline — {count} entries will sync when you\'re back online}}'**
  String offlineWithPendingTransactions(int count);

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGeneric;

  /// No description provided for @errorDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete. Please try again.'**
  String get errorDeleteFailed;

  /// No description provided for @errorDeleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete your account. Please try again.'**
  String get errorDeleteAccountFailed;

  /// No description provided for @errorDeleteAccountRpcRequired.
  ///
  /// In en, this message translates to:
  /// **'Account deletion is not set up on the server. Run supabase/delete_account.sql in your Supabase project.'**
  String get errorDeleteAccountRpcRequired;

  /// No description provided for @addIncome.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get addIncome;

  /// No description provided for @editIncome.
  ///
  /// In en, this message translates to:
  /// **'Edit Income'**
  String get editIncome;

  /// No description provided for @recentIncomes.
  ///
  /// In en, this message translates to:
  /// **'Recent Incomes'**
  String get recentIncomes;

  /// No description provided for @incomeToolsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get incomeToolsSectionTitle;

  /// No description provided for @incomeToolsSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add income faster with AI, import, salary day, or recurring.'**
  String get incomeToolsSectionSubtitle;

  /// No description provided for @incomeToolsAddForm.
  ///
  /// In en, this message translates to:
  /// **'Blank form'**
  String get incomeToolsAddForm;

  /// No description provided for @incomeToolsRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get incomeToolsRecurring;

  /// No description provided for @totalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total Income'**
  String get totalIncome;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @editExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get editExpense;

  /// No description provided for @recentExpenses.
  ///
  /// In en, this message translates to:
  /// **'Recent Expenses'**
  String get recentExpenses;

  /// No description provided for @expenseSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get expenseSortNewest;

  /// No description provided for @expenseSortHighestAmount.
  ///
  /// In en, this message translates to:
  /// **'Highest amount'**
  String get expenseSortHighestAmount;

  /// No description provided for @expenseDeletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Expense removed'**
  String get expenseDeletedSnack;

  /// No description provided for @expenseUndoAction.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get expenseUndoAction;

  /// No description provided for @expenseRestoredSnack.
  ///
  /// In en, this message translates to:
  /// **'Expense restored'**
  String get expenseRestoredSnack;

  /// No description provided for @totalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpenses;

  /// No description provided for @noIncomesTitle.
  ///
  /// In en, this message translates to:
  /// **'No incomes yet'**
  String get noIncomesTitle;

  /// No description provided for @noIncomesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to record your first income'**
  String get noIncomesSubtitle;

  /// No description provided for @noExpensesTitle.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get noExpensesTitle;

  /// No description provided for @noExpensesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to record your first expense'**
  String get noExpensesSubtitle;

  /// No description provided for @titleField.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleField;

  /// No description provided for @hintExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'e.g. Groceries'**
  String get hintExpenseTitle;

  /// No description provided for @hintIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'e.g. March payment'**
  String get hintIncomeTitle;

  /// No description provided for @incomeSourceField.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get incomeSourceField;

  /// No description provided for @hintIncomeSource.
  ///
  /// In en, this message translates to:
  /// **'e.g. Visa card, Rents, Salary'**
  String get hintIncomeSource;

  /// No description provided for @addIncomeSheetTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. March salary, apartment rent'**
  String get addIncomeSheetTitleHint;

  /// No description provided for @addIncomeSheetSourceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Visa, Vodafone Cash, salary, bank transfer'**
  String get addIncomeSheetSourceHint;

  /// No description provided for @addExpenseSheetTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. supermarket, eating out, Uber'**
  String get addExpenseSheetTitleHint;

  /// No description provided for @addExpenseSheetPaidFromHint.
  ///
  /// In en, this message translates to:
  /// **'Where you paid from: cash, Visa, Vodafone Cash…'**
  String get addExpenseSheetPaidFromHint;

  /// No description provided for @addExpenseSheetOtherCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. gym, subscriptions, gifts'**
  String get addExpenseSheetOtherCategoryHint;

  /// No description provided for @paymentPresetBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get paymentPresetBankTransfer;

  /// No description provided for @paymentPresetVodafoneCash.
  ///
  /// In en, this message translates to:
  /// **'Vodafone Cash'**
  String get paymentPresetVodafoneCash;

  /// No description provided for @paymentPresetInstaPay.
  ///
  /// In en, this message translates to:
  /// **'InstaPay'**
  String get paymentPresetInstaPay;

  /// No description provided for @walletUsdLabel.
  ///
  /// In en, this message translates to:
  /// **'USD Wallet'**
  String get walletUsdLabel;

  /// No description provided for @walletEurLabel.
  ///
  /// In en, this message translates to:
  /// **'EUR Wallet'**
  String get walletEurLabel;

  /// No description provided for @salaryDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Salary day'**
  String get salaryDayTitle;

  /// No description provided for @salaryDaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Split your paycheck into rent, bills, plans, and leftover spending money.'**
  String get salaryDaySubtitle;

  /// No description provided for @salaryDayPaydayLabel.
  ///
  /// In en, this message translates to:
  /// **'Payday: day {day} of each month'**
  String salaryDayPaydayLabel(int day);

  /// No description provided for @salaryDayAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Salary amount'**
  String get salaryDayAmountLabel;

  /// No description provided for @salaryDayRentPct.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get salaryDayRentPct;

  /// No description provided for @salaryDayBillsPct.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get salaryDayBillsPct;

  /// No description provided for @salaryDayPlansPct.
  ///
  /// In en, this message translates to:
  /// **'Plans / savings'**
  String get salaryDayPlansPct;

  /// No description provided for @salaryDayLeftoverPct.
  ///
  /// In en, this message translates to:
  /// **'Leftover · {pct}%'**
  String salaryDayLeftoverPct(String pct);

  /// No description provided for @salaryDayPromptToggle.
  ///
  /// In en, this message translates to:
  /// **'Open this after I add a Salary income'**
  String get salaryDayPromptToggle;

  /// No description provided for @salaryDayPreview.
  ///
  /// In en, this message translates to:
  /// **'Allocation preview'**
  String get salaryDayPreview;

  /// No description provided for @salaryDayPreviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a salary amount to preview the split.'**
  String get salaryDayPreviewEmpty;

  /// No description provided for @salaryDayLeftoverHint.
  ///
  /// In en, this message translates to:
  /// **'Stays in your Salary pocket — not booked as an expense'**
  String get salaryDayLeftoverHint;

  /// No description provided for @salaryDayApply.
  ///
  /// In en, this message translates to:
  /// **'Apply allocation'**
  String get salaryDayApply;

  /// No description provided for @salaryDaySaveRulesOnly.
  ///
  /// In en, this message translates to:
  /// **'Save rules only'**
  String get salaryDaySaveRulesOnly;

  /// No description provided for @salaryDayRulesSaved.
  ///
  /// In en, this message translates to:
  /// **'Salary day rules saved'**
  String get salaryDayRulesSaved;

  /// No description provided for @salaryDaySuccess.
  ///
  /// In en, this message translates to:
  /// **'Allocated into {count} expense(s)'**
  String salaryDaySuccess(int count);

  /// No description provided for @yearInReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Year in review'**
  String get yearInReviewTitle;

  /// No description provided for @yearInReviewHero.
  ///
  /// In en, this message translates to:
  /// **'Your {year} money story'**
  String yearInReviewHero(int year);

  /// No description provided for @yearInReviewHeroBody.
  ///
  /// In en, this message translates to:
  /// **'You earned {income} and spent {expenses}.'**
  String yearInReviewHeroBody(String income, String expenses);

  /// No description provided for @yearInReviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'No income or expenses logged for this year yet.'**
  String get yearInReviewEmpty;

  /// No description provided for @yearInReviewNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get yearInReviewNet;

  /// No description provided for @yearInReviewSavingsRate.
  ///
  /// In en, this message translates to:
  /// **'Savings rate'**
  String get yearInReviewSavingsRate;

  /// No description provided for @yearInReviewLoansClosed.
  ///
  /// In en, this message translates to:
  /// **'Loans closed'**
  String get yearInReviewLoansClosed;

  /// No description provided for @yearInReviewLoansOpen.
  ///
  /// In en, this message translates to:
  /// **'Loans open'**
  String get yearInReviewLoansOpen;

  /// No description provided for @yearInReviewBestMonth.
  ///
  /// In en, this message translates to:
  /// **'Best month'**
  String get yearInReviewBestMonth;

  /// No description provided for @yearInReviewToughMonth.
  ///
  /// In en, this message translates to:
  /// **'Toughest month'**
  String get yearInReviewToughMonth;

  /// No description provided for @yearInReviewMonthNet.
  ///
  /// In en, this message translates to:
  /// **'{month} · net {amount}'**
  String yearInReviewMonthNet(String month, String amount);

  /// No description provided for @yearInReviewTopCategories.
  ///
  /// In en, this message translates to:
  /// **'Top categories'**
  String get yearInReviewTopCategories;

  /// No description provided for @yearInReviewTopMerchants.
  ///
  /// In en, this message translates to:
  /// **'Top merchants'**
  String get yearInReviewTopMerchants;

  /// No description provided for @yearInReviewIncomeSources.
  ///
  /// In en, this message translates to:
  /// **'Income sources'**
  String get yearInReviewIncomeSources;

  /// No description provided for @incomeBySource.
  ///
  /// In en, this message translates to:
  /// **'By source'**
  String get incomeBySource;

  /// No description provided for @balanceRemainingBySource.
  ///
  /// In en, this message translates to:
  /// **'Remaining by source'**
  String get balanceRemainingBySource;

  /// No description provided for @balanceWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s left per source'**
  String get balanceWalletTitle;

  /// No description provided for @balanceWalletSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Starting balance + income − spending for each source in this period.'**
  String get balanceWalletSubtitle;

  /// No description provided for @balanceWalletFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get balanceWalletFilterAll;

  /// No description provided for @balanceWalletInitial.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get balanceWalletInitial;

  /// No description provided for @balanceWalletUnassignedHint.
  ///
  /// In en, this message translates to:
  /// **'Spending not linked to a specific source.'**
  String get balanceWalletUnassignedHint;

  /// No description provided for @balanceOpenWallet.
  ///
  /// In en, this message translates to:
  /// **'My wallet'**
  String get balanceOpenWallet;

  /// No description provided for @balanceWalletDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'My wallet'**
  String get balanceWalletDialogTitle;

  /// No description provided for @balanceWalletDialogPeriod.
  ///
  /// In en, this message translates to:
  /// **'For {period}'**
  String balanceWalletDialogPeriod(Object period);

  /// No description provided for @balanceWalletDialogTotal.
  ///
  /// In en, this message translates to:
  /// **'Total in wallet'**
  String get balanceWalletDialogTotal;

  /// No description provided for @balanceWalletDialogEmpty.
  ///
  /// In en, this message translates to:
  /// **'Set a starting balance per source to see your wallet here.'**
  String get balanceWalletDialogEmpty;

  /// No description provided for @paymentMethodAddChip.
  ///
  /// In en, this message translates to:
  /// **'+ Add method'**
  String get paymentMethodAddChip;

  /// No description provided for @paymentMethodAddCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get paymentMethodAddCancel;

  /// No description provided for @paymentMethodNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New method name'**
  String get paymentMethodNewLabel;

  /// No description provided for @paymentMethodNewHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Vodafone Cash, InstaPay, Fawry'**
  String get paymentMethodNewHint;

  /// No description provided for @paymentMethodSave.
  ///
  /// In en, this message translates to:
  /// **'Save method'**
  String get paymentMethodSave;

  /// No description provided for @paymentMethodNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for the payment method.'**
  String get paymentMethodNameEmpty;

  /// No description provided for @paymentMethodAdded.
  ///
  /// In en, this message translates to:
  /// **'Added \"{name}\" to your methods.'**
  String paymentMethodAdded(String name);

  /// No description provided for @expensePaidFromField.
  ///
  /// In en, this message translates to:
  /// **'Paid from'**
  String get expensePaidFromField;

  /// No description provided for @expensePaidFromNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get expensePaidFromNone;

  /// No description provided for @incomeUnassignedSpending.
  ///
  /// In en, this message translates to:
  /// **'Unassigned spending'**
  String get incomeUnassignedSpending;

  /// No description provided for @incomeFilterAllSources.
  ///
  /// In en, this message translates to:
  /// **'All sources'**
  String get incomeFilterAllSources;

  /// No description provided for @incomeFilterNoSourceEntries.
  ///
  /// In en, this message translates to:
  /// **'No incomes for this source in the selected period'**
  String get incomeFilterNoSourceEntries;

  /// No description provided for @incomeSourceManageEdit.
  ///
  /// In en, this message translates to:
  /// **'Rename source'**
  String get incomeSourceManageEdit;

  /// No description provided for @incomeSourceManageRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove source'**
  String get incomeSourceManageRemove;

  /// No description provided for @incomeSourceRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename source'**
  String get incomeSourceRenameTitle;

  /// No description provided for @incomeSourceRenameHint.
  ///
  /// In en, this message translates to:
  /// **'Updates all incomes with source \"{name}\".'**
  String incomeSourceRenameHint(String name);

  /// No description provided for @incomeSourceNameTaken.
  ///
  /// In en, this message translates to:
  /// **'That source name is already in use'**
  String get incomeSourceNameTaken;

  /// No description provided for @incomeSourceUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sources updated'**
  String get incomeSourceUpdatedSuccess;

  /// No description provided for @incomeSourceRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove source'**
  String get incomeSourceRemoveTitle;

  /// No description provided for @incomeSourceRemoveMessage.
  ///
  /// In en, this message translates to:
  /// **'What should happen to {count} income(s) with source \"{name}\"?'**
  String incomeSourceRemoveMessage(int count, String name);

  /// No description provided for @incomeSourceMoveToOther.
  ///
  /// In en, this message translates to:
  /// **'Move all to Other'**
  String get incomeSourceMoveToOther;

  /// No description provided for @incomeSourceDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all incomes with this source'**
  String get incomeSourceDeleteAll;

  /// No description provided for @incomeSourceDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete incomes?'**
  String get incomeSourceDeleteConfirmTitle;

  /// No description provided for @incomeSourceDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes {count} income(s). This cannot be undone.'**
  String incomeSourceDeleteConfirmMessage(int count);

  /// No description provided for @incomeSourceDeleteConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get incomeSourceDeleteConfirmAction;

  /// No description provided for @incomeSourceRents.
  ///
  /// In en, this message translates to:
  /// **'Rents'**
  String get incomeSourceRents;

  /// No description provided for @incomeSourceVisaCard.
  ///
  /// In en, this message translates to:
  /// **'Visa card'**
  String get incomeSourceVisaCard;

  /// No description provided for @incomeSourceCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get incomeSourceCash;

  /// No description provided for @amountField.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountField;

  /// No description provided for @expenseAmountShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Quick amounts'**
  String get expenseAmountShortcuts;

  /// No description provided for @expenseShortcutTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get expenseShortcutTransport;

  /// No description provided for @expenseShortcutCoffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get expenseShortcutCoffee;

  /// No description provided for @expenseShortcutSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get expenseShortcutSnack;

  /// No description provided for @expenseFabMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'New expense'**
  String get expenseFabMenuTitle;

  /// No description provided for @expenseFabBlankOption.
  ///
  /// In en, this message translates to:
  /// **'Blank form'**
  String get expenseFabBlankOption;

  /// No description provided for @expenseFabFromLastPaste.
  ///
  /// In en, this message translates to:
  /// **'From last parsed message'**
  String get expenseFabFromLastPaste;

  /// No description provided for @expenseFabFromLastPasteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Uses the last bank or wallet message you parsed in Smart import'**
  String get expenseFabFromLastPasteSubtitle;

  /// No description provided for @expenseLastPasteNotExpense.
  ///
  /// In en, this message translates to:
  /// **'Last parsed message looks like income. Add it from the Incomes tab.'**
  String get expenseLastPasteNotExpense;

  /// No description provided for @expenseShortcutsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'One-tap expenses'**
  String get expenseShortcutsSectionTitle;

  /// No description provided for @expenseShortcutsEmptyCta.
  ///
  /// In en, this message translates to:
  /// **'Set up one-tap shortcuts'**
  String get expenseShortcutsEmptyCta;

  /// No description provided for @expenseShortcutsManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense shortcuts'**
  String get expenseShortcutsManageTitle;

  /// No description provided for @expenseShortcutsManageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save a label, title, category, paid-from, and amount. Tap the chip on the Expenses tab to log instantly.'**
  String get expenseShortcutsManageSubtitle;

  /// No description provided for @expenseShortcutsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'No shortcuts yet. Add your first coffee, transport, or other repeat purchase.'**
  String get expenseShortcutsEmptyBody;

  /// No description provided for @expenseShortcutAddTitle.
  ///
  /// In en, this message translates to:
  /// **'New shortcut'**
  String get expenseShortcutAddTitle;

  /// No description provided for @expenseShortcutEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit shortcut'**
  String get expenseShortcutEditTitle;

  /// No description provided for @expenseShortcutChipLabelField.
  ///
  /// In en, this message translates to:
  /// **'Chip label'**
  String get expenseShortcutChipLabelField;

  /// No description provided for @expenseShortcutChipLabelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Coffee'**
  String get expenseShortcutChipLabelHint;

  /// No description provided for @expenseShortcutExpenseTitleField.
  ///
  /// In en, this message translates to:
  /// **'Expense title'**
  String get expenseShortcutExpenseTitleField;

  /// No description provided for @expenseShortcutFormHint.
  ///
  /// In en, this message translates to:
  /// **'The chip logs this expense for today with one tap — no form.'**
  String get expenseShortcutFormHint;

  /// No description provided for @expenseShortcutSave.
  ///
  /// In en, this message translates to:
  /// **'Save shortcut'**
  String get expenseShortcutSave;

  /// No description provided for @expenseShortcutDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get expenseShortcutDelete;

  /// No description provided for @expenseShortcutDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete shortcut?'**
  String get expenseShortcutDeleteConfirmTitle;

  /// No description provided for @expenseShortcutDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\"?'**
  String expenseShortcutDeleteConfirmMessage(String name);

  /// No description provided for @expenseShortcutLogged.
  ///
  /// In en, this message translates to:
  /// **'Logged: {name}'**
  String expenseShortcutLogged(String name);

  /// No description provided for @expenseShortcutErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter a chip label'**
  String get expenseShortcutErrorLabel;

  /// No description provided for @expenseByCategory.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get expenseByCategory;

  /// No description provided for @expenseCategoryEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get expenseCategoryEdit;

  /// No description provided for @expenseCategoryRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove category'**
  String get expenseCategoryRemove;

  /// No description provided for @expenseCategoryRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename category'**
  String get expenseCategoryRenameTitle;

  /// No description provided for @expenseCategoryRenameHint.
  ///
  /// In en, this message translates to:
  /// **'Updates all expenses in \"{name}\".'**
  String expenseCategoryRenameHint(String name);

  /// No description provided for @expenseCategoryNameTaken.
  ///
  /// In en, this message translates to:
  /// **'That category name is already in use'**
  String get expenseCategoryNameTaken;

  /// No description provided for @expenseCategoryUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Category updated'**
  String get expenseCategoryUpdatedSuccess;

  /// No description provided for @expenseCategoryRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove category'**
  String get expenseCategoryRemoveTitle;

  /// No description provided for @expenseCategoryRemoveMessage.
  ///
  /// In en, this message translates to:
  /// **'What should happen to {count} expense(s) in \"{name}\"?'**
  String expenseCategoryRemoveMessage(int count, String name);

  /// No description provided for @expenseCategoryMoveToOther.
  ///
  /// In en, this message translates to:
  /// **'Move all to Other'**
  String get expenseCategoryMoveToOther;

  /// No description provided for @expenseCategoryDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all expenses in this category'**
  String get expenseCategoryDeleteAll;

  /// No description provided for @expenseCategoryDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete expenses?'**
  String get expenseCategoryDeleteConfirmTitle;

  /// No description provided for @expenseCategoryDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes {count} expense(s). This cannot be undone.'**
  String expenseCategoryDeleteConfirmMessage(int count);

  /// No description provided for @expenseCategoryDeleteConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get expenseCategoryDeleteConfirmAction;

  /// No description provided for @expenseFilterAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get expenseFilterAllCategories;

  /// No description provided for @expenseFilterNoCategoryEntries.
  ///
  /// In en, this message translates to:
  /// **'No expenses for this category in the selected period'**
  String get expenseFilterNoCategoryEntries;

  /// No description provided for @budgetMonthlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly budgets'**
  String get budgetMonthlyTitle;

  /// No description provided for @budgetSetAction.
  ///
  /// In en, this message translates to:
  /// **'Set budget'**
  String get budgetSetAction;

  /// No description provided for @budgetSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set monthly budget'**
  String get budgetSetTitle;

  /// No description provided for @budgetEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit monthly budget'**
  String get budgetEditTitle;

  /// No description provided for @budgetSetHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a category and set how much you plan to spend this month.'**
  String get budgetSetHint;

  /// No description provided for @budgetCustomCategory.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get budgetCustomCategory;

  /// No description provided for @budgetMonthlyLimit.
  ///
  /// In en, this message translates to:
  /// **'Monthly limit'**
  String get budgetMonthlyLimit;

  /// No description provided for @budgetSave.
  ///
  /// In en, this message translates to:
  /// **'Save budget'**
  String get budgetSave;

  /// No description provided for @budgetEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Set a limit per category to see how much of your budget you\'ve used.'**
  String get budgetEmptyHint;

  /// No description provided for @budgetSetFirst.
  ///
  /// In en, this message translates to:
  /// **'Create first budget'**
  String get budgetSetFirst;

  /// No description provided for @budgetTotalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get budgetTotalSpent;

  /// No description provided for @budgetOverBy.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String budgetOverBy(String amount);

  /// No description provided for @budgetDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove budget?'**
  String get budgetDeleteTitle;

  /// No description provided for @budgetDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove the budget for {category}?'**
  String budgetDeleteMessage(String category);

  /// No description provided for @budgetDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get budgetDeleteConfirm;

  /// No description provided for @budgetAlertNear.
  ///
  /// In en, this message translates to:
  /// **'{count} category near the limit'**
  String budgetAlertNear(int count);

  /// No description provided for @budgetAlertOver.
  ///
  /// In en, this message translates to:
  /// **'{count} category over budget'**
  String budgetAlertOver(int count);

  /// No description provided for @budgetAlertOverAndNear.
  ///
  /// In en, this message translates to:
  /// **'{over} over budget, {near} near limit'**
  String budgetAlertOverAndNear(int over, int near);

  /// No description provided for @categoryField.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryField;

  /// No description provided for @otherCategoryField.
  ///
  /// In en, this message translates to:
  /// **'Other category'**
  String get otherCategoryField;

  /// No description provided for @otherCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Enter category name'**
  String get otherCategoryHint;

  /// No description provided for @saveExpense.
  ///
  /// In en, this message translates to:
  /// **'Save Expense'**
  String get saveExpense;

  /// No description provided for @updateExpense.
  ///
  /// In en, this message translates to:
  /// **'Update Expense'**
  String get updateExpense;

  /// No description provided for @expenseAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Expense added successfully'**
  String get expenseAddedSuccess;

  /// No description provided for @expenseUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Expense updated successfully'**
  String get expenseUpdatedSuccess;

  /// No description provided for @saveIncome.
  ///
  /// In en, this message translates to:
  /// **'Save Income'**
  String get saveIncome;

  /// No description provided for @updateIncome.
  ///
  /// In en, this message translates to:
  /// **'Update Income'**
  String get updateIncome;

  /// No description provided for @incomeAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Income added successfully'**
  String get incomeAddedSuccess;

  /// No description provided for @incomeUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Income updated successfully'**
  String get incomeUpdatedSuccess;

  /// No description provided for @errorEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get errorEnterTitle;

  /// No description provided for @errorEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get errorEnterValidAmount;

  /// No description provided for @pocketInsufficientFunds.
  ///
  /// In en, this message translates to:
  /// **'Not enough in your pocket. Available: {amount}'**
  String pocketInsufficientFunds(String amount);

  /// No description provided for @errorEnterCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a category name'**
  String get errorEnterCategoryName;

  /// No description provided for @errorSavedExceedsTarget.
  ///
  /// In en, this message translates to:
  /// **'Saved amount cannot exceed target'**
  String get errorSavedExceedsTarget;

  /// No description provided for @expenseCatFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get expenseCatFood;

  /// No description provided for @expenseCatRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get expenseCatRent;

  /// No description provided for @expenseCatTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get expenseCatTransport;

  /// No description provided for @expenseCatShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get expenseCatShopping;

  /// No description provided for @expenseCatBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get expenseCatBills;

  /// No description provided for @expenseCatOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get expenseCatOther;

  /// No description provided for @incomeCatWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get incomeCatWork;

  /// No description provided for @incomeCatFreelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get incomeCatFreelance;

  /// No description provided for @incomeCatBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get incomeCatBusiness;

  /// No description provided for @incomeCatInvestment.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get incomeCatInvestment;

  /// No description provided for @incomeCatOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get incomeCatOther;

  /// No description provided for @planCatSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get planCatSavings;

  /// No description provided for @planCatTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get planCatTravel;

  /// No description provided for @planCatPurchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get planCatPurchase;

  /// No description provided for @planCatEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get planCatEducation;

  /// No description provided for @planCatOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get planCatOther;

  /// No description provided for @planNewFab.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get planNewFab;

  /// No description provided for @planEditGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit Goal'**
  String get planEditGoal;

  /// No description provided for @planAddPlan.
  ///
  /// In en, this message translates to:
  /// **'Add Plan'**
  String get planAddPlan;

  /// No description provided for @goalTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal title'**
  String get goalTitleLabel;

  /// No description provided for @goalTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Emergency Fund'**
  String get goalTitleHint;

  /// No description provided for @targetAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get targetAmountLabel;

  /// No description provided for @amountSavedLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount saved'**
  String get amountSavedLabel;

  /// No description provided for @amountSavedHint.
  ///
  /// In en, this message translates to:
  /// **'Starting progress only — it does not come out of net balance. Use Add to goal on the Balance tab to move money from your wallet.'**
  String get amountSavedHint;

  /// No description provided for @setDeadlineOptional.
  ///
  /// In en, this message translates to:
  /// **'Set deadline (optional)'**
  String get setDeadlineOptional;

  /// No description provided for @savePlan.
  ///
  /// In en, this message translates to:
  /// **'Save Plan'**
  String get savePlan;

  /// No description provided for @updateGoal.
  ///
  /// In en, this message translates to:
  /// **'Update Goal'**
  String get updateGoal;

  /// No description provided for @errorEnterGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a goal title'**
  String get errorEnterGoalTitle;

  /// No description provided for @errorEnterTargetAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid target amount'**
  String get errorEnterTargetAmount;

  /// No description provided for @errorEnterAmountSaved.
  ///
  /// In en, this message translates to:
  /// **'Please enter amount saved'**
  String get errorEnterAmountSaved;

  /// No description provided for @updateSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Update saved'**
  String get updateSavedTitle;

  /// No description provided for @targetWithAmount.
  ///
  /// In en, this message translates to:
  /// **'Target: {amount}'**
  String targetWithAmount(Object amount);

  /// No description provided for @saveAmountButton.
  ///
  /// In en, this message translates to:
  /// **'Save amount'**
  String get saveAmountButton;

  /// No description provided for @errorEnterValidSavedAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid saved amount'**
  String get errorEnterValidSavedAmount;

  /// No description provided for @balanceNetBalance.
  ///
  /// In en, this message translates to:
  /// **'Net Balance'**
  String get balanceNetBalance;

  /// No description provided for @balanceInitialBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Initial balance'**
  String get balanceInitialBalanceTitle;

  /// No description provided for @balanceInitialBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'How much you had when you started using the app.'**
  String get balanceInitialBalanceHint;

  /// No description provided for @balanceInitialBalanceAddSource.
  ///
  /// In en, this message translates to:
  /// **'Add another source'**
  String get balanceInitialBalanceAddSource;

  /// No description provided for @balanceInitialBalanceBySource.
  ///
  /// In en, this message translates to:
  /// **'By source'**
  String get balanceInitialBalanceBySource;

  /// No description provided for @balanceInitialBalanceIncludes.
  ///
  /// In en, this message translates to:
  /// **'Includes {amount} starting balance'**
  String balanceInitialBalanceIncludes(Object amount);

  /// No description provided for @balanceInitialBalanceSaved.
  ///
  /// In en, this message translates to:
  /// **'Initial balance updated'**
  String get balanceInitialBalanceSaved;

  /// No description provided for @balanceEditInitialBalance.
  ///
  /// In en, this message translates to:
  /// **'Edit initial balance'**
  String get balanceEditInitialBalance;

  /// No description provided for @settingsInitialBalance.
  ///
  /// In en, this message translates to:
  /// **'Initial balance'**
  String get settingsInitialBalance;

  /// No description provided for @balanceSavedThisMonth.
  ///
  /// In en, this message translates to:
  /// **'{percent}% saved this month'**
  String balanceSavedThisMonth(int percent);

  /// No description provided for @balanceSavedPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% saved'**
  String balanceSavedPercent(int percent);

  /// No description provided for @balanceStatIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get balanceStatIncome;

  /// No description provided for @balanceStatExpense.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get balanceStatExpense;

  /// No description provided for @balanceRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get balanceRecentActivity;

  /// No description provided for @balanceAddToPlan.
  ///
  /// In en, this message translates to:
  /// **'Add to goal'**
  String get balanceAddToPlan;

  /// No description provided for @balanceAddToPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to savings goal'**
  String get balanceAddToPlanTitle;

  /// No description provided for @balanceAddToPlanHint.
  ///
  /// In en, this message translates to:
  /// **'Available from balance: {amount}'**
  String balanceAddToPlanHint(Object amount);

  /// No description provided for @balanceSelectPlan.
  ///
  /// In en, this message translates to:
  /// **'Choose a goal'**
  String get balanceSelectPlan;

  /// No description provided for @balanceAmountToAllocate.
  ///
  /// In en, this message translates to:
  /// **'Amount to add'**
  String get balanceAmountToAllocate;

  /// No description provided for @balancePlanRemaining.
  ///
  /// In en, this message translates to:
  /// **'{amount} left to reach target'**
  String balancePlanRemaining(Object amount);

  /// No description provided for @balanceAddToPlanSuccess.
  ///
  /// In en, this message translates to:
  /// **'Amount added to your savings goal'**
  String get balanceAddToPlanSuccess;

  /// No description provided for @balanceNoSurplusForPlan.
  ///
  /// In en, this message translates to:
  /// **'No available net balance to add to a goal.'**
  String get balanceNoSurplusForPlan;

  /// No description provided for @balancePlanAllocationPaidFromHint.
  ///
  /// In en, this message translates to:
  /// **'Choose which source this allocation is paid from (shown on Balance, not unassigned).'**
  String get balancePlanAllocationPaidFromHint;

  /// No description provided for @planAllocationSelectPaidFrom.
  ///
  /// In en, this message translates to:
  /// **'Select paid from for this goal allocation'**
  String get planAllocationSelectPaidFrom;

  /// No description provided for @balancePlanAllocationExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Savings goal: {planTitle}'**
  String balancePlanAllocationExpenseTitle(String planTitle);

  /// No description provided for @balanceNoPlansForAllocation.
  ///
  /// In en, this message translates to:
  /// **'Create a savings goal in the Plans tab first.'**
  String get balanceNoPlansForAllocation;

  /// No description provided for @balanceAmountExceedsSurplus.
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds your available balance'**
  String get balanceAmountExceedsSurplus;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount(int count);

  /// No description provided for @listEntryCount.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String listEntryCount(int count);

  /// No description provided for @clearAllExpenses.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAllExpenses;

  /// No description provided for @clearAllIncomes.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAllIncomes;

  /// No description provided for @clearAllExpensesConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all expenses?'**
  String get clearAllExpensesConfirmTitle;

  /// No description provided for @clearAllIncomesConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all incomes?'**
  String get clearAllIncomesConfirmTitle;

  /// No description provided for @clearAllExpensesConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all {count} expenses. This cannot be undone.'**
  String clearAllExpensesConfirmMessage(int count);

  /// No description provided for @clearAllIncomesConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all {count} incomes. This cannot be undone.'**
  String clearAllIncomesConfirmMessage(int count);

  /// No description provided for @clearAllExpensesSuccess.
  ///
  /// In en, this message translates to:
  /// **'All expenses deleted'**
  String get clearAllExpensesSuccess;

  /// No description provided for @clearAllIncomesSuccess.
  ///
  /// In en, this message translates to:
  /// **'All incomes deleted'**
  String get clearAllIncomesSuccess;

  /// No description provided for @balanceIncomeVsExpenses.
  ///
  /// In en, this message translates to:
  /// **'Income vs Expenses'**
  String get balanceIncomeVsExpenses;

  /// No description provided for @balanceFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get balanceFilterAll;

  /// No description provided for @balanceFilterIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get balanceFilterIncome;

  /// No description provided for @balanceFilterExpense.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get balanceFilterExpense;

  /// No description provided for @balanceNoFilteredActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity matches this filter'**
  String get balanceNoFilteredActivity;

  /// No description provided for @activityIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get activityIncome;

  /// No description provided for @activityExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get activityExpense;

  /// No description provided for @plansActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get plansActive;

  /// No description provided for @plansDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get plansDone;

  /// No description provided for @plansRemaining.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get plansRemaining;

  /// No description provided for @plansSavingsGoalsSection.
  ///
  /// In en, this message translates to:
  /// **'Savings goals'**
  String get plansSavingsGoalsSection;

  /// No description provided for @plansGoalsOverview.
  ///
  /// In en, this message translates to:
  /// **'Goals overview'**
  String get plansGoalsOverview;

  /// No description provided for @plansSavedOfTarget.
  ///
  /// In en, this message translates to:
  /// **'of {total} saved'**
  String plansSavedOfTarget(Object total);

  /// No description provided for @plansDonePercentLabel.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get plansDonePercentLabel;

  /// No description provided for @plansGoalsCompletedSummary.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} goals completed'**
  String plansGoalsCompletedSummary(int completed, int total);

  /// No description provided for @plansMoneyLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String plansMoneyLeft(Object amount);

  /// No description provided for @ofTargetAmount.
  ///
  /// In en, this message translates to:
  /// **'of {amount}'**
  String ofTargetAmount(Object amount);

  /// No description provided for @dueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dueDateLabel(Object date);

  /// No description provided for @planGoalCompleted.
  ///
  /// In en, this message translates to:
  /// **'Goal completed'**
  String get planGoalCompleted;

  /// No description provided for @planTapToEditGoal.
  ///
  /// In en, this message translates to:
  /// **'Tap to edit goal'**
  String get planTapToEditGoal;

  /// No description provided for @planCoachMonthly.
  ///
  /// In en, this message translates to:
  /// **'Save {amount}/month to hit your deadline'**
  String planCoachMonthly(String amount);

  /// No description provided for @planCoachOverdue.
  ///
  /// In en, this message translates to:
  /// **'Deadline passed — {amount} still needed'**
  String planCoachOverdue(String amount);

  /// No description provided for @planCoachUrgent.
  ///
  /// In en, this message translates to:
  /// **'Due soon — {amount} left'**
  String planCoachUrgent(String amount);

  /// No description provided for @planCoachRemaining.
  ///
  /// In en, this message translates to:
  /// **'{amount} left to reach your goal'**
  String planCoachRemaining(String amount);

  /// No description provided for @planCoachTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay on track'**
  String get planCoachTipTitle;

  /// No description provided for @planCoachSurplusTip.
  ///
  /// In en, this message translates to:
  /// **'You have {amount} available. Add some to a goal to get closer.'**
  String planCoachSurplusTip(String amount);

  /// No description provided for @planCoachAddSuggested.
  ///
  /// In en, this message translates to:
  /// **'Add suggested {amount}'**
  String planCoachAddSuggested(String amount);

  /// No description provided for @planSuggestThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get planSuggestThisMonth;

  /// No description provided for @planSuggestHalf.
  ///
  /// In en, this message translates to:
  /// **'Half'**
  String get planSuggestHalf;

  /// No description provided for @planSuggestAllAvailable.
  ///
  /// In en, this message translates to:
  /// **'All available'**
  String get planSuggestAllAvailable;

  /// No description provided for @planSuggestFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish goal'**
  String get planSuggestFinish;

  /// No description provided for @planTemplateEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency fund'**
  String get planTemplateEmergency;

  /// No description provided for @planTemplateVacation.
  ///
  /// In en, this message translates to:
  /// **'Vacation'**
  String get planTemplateVacation;

  /// No description provided for @planTemplateNewPhone.
  ///
  /// In en, this message translates to:
  /// **'New phone'**
  String get planTemplateNewPhone;

  /// No description provided for @planTemplateEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get planTemplateEducation;

  /// No description provided for @planTemplatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick start ideas'**
  String get planTemplatesTitle;

  /// No description provided for @planHowItHelps.
  ///
  /// In en, this message translates to:
  /// **'Set a target, optionally a deadline, then move money from your balance with Add to goal.'**
  String get planHowItHelps;

  /// No description provided for @plansEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Start your first goal'**
  String get plansEmptyTitle;

  /// No description provided for @plansEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set a target, track what you save, and watch your progress grow.'**
  String get plansEmptySubtitle;

  /// No description provided for @plansCreateGoalButton.
  ///
  /// In en, this message translates to:
  /// **'Create goal'**
  String get plansCreateGoalButton;

  /// No description provided for @demoSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get demoSalary;

  /// No description provided for @demoRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get demoRent;

  /// No description provided for @demoFreelanceProject.
  ///
  /// In en, this message translates to:
  /// **'Freelance Project'**
  String get demoFreelanceProject;

  /// No description provided for @demoGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get demoGroceries;

  /// No description provided for @demoGas.
  ///
  /// In en, this message translates to:
  /// **'Gas'**
  String get demoGas;

  /// No description provided for @demoElectricBill.
  ///
  /// In en, this message translates to:
  /// **'Electric Bill'**
  String get demoElectricBill;

  /// No description provided for @demoUtilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get demoUtilities;

  /// No description provided for @demoSideBusiness.
  ///
  /// In en, this message translates to:
  /// **'Side Business'**
  String get demoSideBusiness;

  /// No description provided for @demoEmergencyFund.
  ///
  /// In en, this message translates to:
  /// **'Emergency Fund'**
  String get demoEmergencyFund;

  /// No description provided for @demoSummerVacation.
  ///
  /// In en, this message translates to:
  /// **'Summer Vacation'**
  String get demoSummerVacation;

  /// No description provided for @demoNewLaptop.
  ///
  /// In en, this message translates to:
  /// **'New Laptop'**
  String get demoNewLaptop;

  /// No description provided for @storedAsBase.
  ///
  /// In en, this message translates to:
  /// **'Stored as {amount} base'**
  String storedAsBase(Object amount);

  /// No description provided for @smartImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart import'**
  String get smartImportTitle;

  /// No description provided for @smartImportShort.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get smartImportShort;

  /// No description provided for @smartImportPasteTab.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get smartImportPasteTab;

  /// No description provided for @smartImportQuickTab.
  ///
  /// In en, this message translates to:
  /// **'Quick'**
  String get smartImportQuickTab;

  /// No description provided for @smartImportSmsTab.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get smartImportSmsTab;

  /// No description provided for @smartImportQuickHint.
  ///
  /// In en, this message translates to:
  /// **'No SMS to paste? Enter the amount, pick expense or income, choose category and source — add in one tap.'**
  String get smartImportQuickHint;

  /// No description provided for @smartImportQuickTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Transaction type'**
  String get smartImportQuickTypeLabel;

  /// No description provided for @smartImportQuickAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get smartImportQuickAmountLabel;

  /// No description provided for @smartImportQuickTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Coffee, rent, salary… (optional)'**
  String get smartImportQuickTitleHint;

  /// No description provided for @smartImportQuickAddNow.
  ///
  /// In en, this message translates to:
  /// **'Add now'**
  String get smartImportQuickAddNow;

  /// No description provided for @smartImportQuickReview.
  ///
  /// In en, this message translates to:
  /// **'Review in full form'**
  String get smartImportQuickReview;

  /// No description provided for @smartImportQuickAdded.
  ///
  /// In en, this message translates to:
  /// **'Transaction added.'**
  String get smartImportQuickAdded;

  /// No description provided for @magicAddTitle.
  ///
  /// In en, this message translates to:
  /// **'AI add'**
  String get magicAddTitle;

  /// No description provided for @magicAddShort.
  ///
  /// In en, this message translates to:
  /// **'AI add'**
  String get magicAddShort;

  /// No description provided for @magicAddTab.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get magicAddTab;

  /// No description provided for @magicAddHint.
  ///
  /// In en, this message translates to:
  /// **'Type or say what happened — like “coffee 50 yesterday” or “راتب 8000”. We’ll fill type, category, and date.'**
  String get magicAddHint;

  /// No description provided for @magicAddFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get magicAddFieldLabel;

  /// No description provided for @magicAddFieldHint.
  ///
  /// In en, this message translates to:
  /// **'coffee 50, uber 30 yesterday'**
  String get magicAddFieldHint;

  /// No description provided for @magicAddListen.
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get magicAddListen;

  /// No description provided for @magicAddListening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get magicAddListening;

  /// No description provided for @magicAddVoiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice input isn’t available on this device.'**
  String get magicAddVoiceUnavailable;

  /// No description provided for @magicAddVoicePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is needed to speak a transaction.'**
  String get magicAddVoicePermissionDenied;

  /// No description provided for @magicAddVoicePermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone is blocked. Allow it in system settings, then tap Speak again.'**
  String get magicAddVoicePermanentlyDenied;

  /// No description provided for @magicAddNoAmount.
  ///
  /// In en, this message translates to:
  /// **'Add an amount, e.g. coffee 50'**
  String get magicAddNoAmount;

  /// No description provided for @magicAddExampleCoffee.
  ///
  /// In en, this message translates to:
  /// **'coffee 50'**
  String get magicAddExampleCoffee;

  /// No description provided for @magicAddExampleUber.
  ///
  /// In en, this message translates to:
  /// **'uber 30 yesterday'**
  String get magicAddExampleUber;

  /// No description provided for @magicAddExampleSalary.
  ///
  /// In en, this message translates to:
  /// **'salary 8000'**
  String get magicAddExampleSalary;

  /// No description provided for @magicAddExampleArabic.
  ///
  /// In en, this message translates to:
  /// **'قهوة 45'**
  String get magicAddExampleArabic;

  /// No description provided for @magicAddPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to add'**
  String get magicAddPreviewTitle;

  /// No description provided for @magicAddAddAll.
  ///
  /// In en, this message translates to:
  /// **'Add {count}'**
  String magicAddAddAll(int count);

  /// No description provided for @magicAddAddOne.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get magicAddAddOne;

  /// No description provided for @magicAddOpenForm.
  ///
  /// In en, this message translates to:
  /// **'Use full form'**
  String get magicAddOpenForm;

  /// No description provided for @expenseFabAiOption.
  ///
  /// In en, this message translates to:
  /// **'Type or speak'**
  String get expenseFabAiOption;

  /// No description provided for @expenseFabAiOptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'e.g. coffee 50 yesterday'**
  String get expenseFabAiOptionSubtitle;

  /// No description provided for @incomeFabMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'New income'**
  String get incomeFabMenuTitle;

  /// No description provided for @smartImportPasteHint.
  ///
  /// In en, this message translates to:
  /// **'Paste one or more bank or wallet messages. Put a blank line between messages, or paste several SMS in a row. We detect amounts and income vs expense for each.'**
  String get smartImportPasteHint;

  /// No description provided for @smartImportPasteShareTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: In your SMS app, open a message → Share → Import to Pockio. No copy-paste needed.'**
  String get smartImportPasteShareTip;

  /// No description provided for @smartImportSharedTextReady.
  ///
  /// In en, this message translates to:
  /// **'Shared message loaded. Review below and add.'**
  String get smartImportSharedTextReady;

  /// No description provided for @smartImportScrollToTop.
  ///
  /// In en, this message translates to:
  /// **'Back to top'**
  String get smartImportScrollToTop;

  /// No description provided for @smartImportPasteFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Message text'**
  String get smartImportPasteFieldLabel;

  /// No description provided for @smartImportPasteFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Paste one or more messages (blank line between each)'**
  String get smartImportPasteFieldHint;

  /// No description provided for @smartImportPasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste from clipboard'**
  String get smartImportPasteFromClipboard;

  /// No description provided for @smartImportParseMessage.
  ///
  /// In en, this message translates to:
  /// **'Parse message'**
  String get smartImportParseMessage;

  /// No description provided for @smartImportParseMessages.
  ///
  /// In en, this message translates to:
  /// **'Parse messages'**
  String get smartImportParseMessages;

  /// No description provided for @smartImportPasteFoundCount.
  ///
  /// In en, this message translates to:
  /// **'Found {count} messages'**
  String smartImportPasteFoundCount(int count);

  /// No description provided for @smartImportPasteAddedOneRemaining.
  ///
  /// In en, this message translates to:
  /// **'Added. {count} more ready to import.'**
  String smartImportPasteAddedOneRemaining(int count);

  /// No description provided for @smartImportPasteProcessing.
  ///
  /// In en, this message translates to:
  /// **'Reading message…'**
  String get smartImportPasteProcessing;

  /// No description provided for @smartImportPasteNoData.
  ///
  /// In en, this message translates to:
  /// **'Could not find an amount in this text. Try the full bank message.'**
  String get smartImportPasteNoData;

  /// No description provided for @smartImportPasteEmpty.
  ///
  /// In en, this message translates to:
  /// **'Paste a message first.'**
  String get smartImportPasteEmpty;

  /// No description provided for @smartImportPasteClipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Clipboard is empty. Copy a bank or wallet message first.'**
  String get smartImportPasteClipboardEmpty;

  /// No description provided for @smartImportPasteClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get smartImportPasteClear;

  /// No description provided for @smartImportPasteAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Added. Paste another message anytime.'**
  String get smartImportPasteAddedSuccess;

  /// No description provided for @smartImportPasteParseAnother.
  ///
  /// In en, this message translates to:
  /// **'Parse another'**
  String get smartImportPasteParseAnother;

  /// No description provided for @smartImportPasteMarkExpense.
  ///
  /// In en, this message translates to:
  /// **'Mark as expense'**
  String get smartImportPasteMarkExpense;

  /// No description provided for @smartImportPasteMarkIncome.
  ///
  /// In en, this message translates to:
  /// **'Mark as income'**
  String get smartImportPasteMarkIncome;

  /// No description provided for @smartImportDefaultBillTitle.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get smartImportDefaultBillTitle;

  /// No description provided for @smartImportExtractedData.
  ///
  /// In en, this message translates to:
  /// **'Extracted data'**
  String get smartImportExtractedData;

  /// No description provided for @smartImportDateField.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get smartImportDateField;

  /// No description provided for @smartImportTypeField.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get smartImportTypeField;

  /// No description provided for @smartImportAddToApp.
  ///
  /// In en, this message translates to:
  /// **'Add to app'**
  String get smartImportAddToApp;

  /// No description provided for @smartImportSmsNotSupported.
  ///
  /// In en, this message translates to:
  /// **'SMS import is available on Android only.'**
  String get smartImportSmsNotSupported;

  /// No description provided for @smartImportSmsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No financial SMS messages found. Grant SMS permission if prompted.'**
  String get smartImportSmsEmpty;

  /// No description provided for @smartImportSmsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read SMS messages.'**
  String get smartImportSmsFailed;

  /// No description provided for @smartImportReloadSms.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get smartImportReloadSms;

  /// No description provided for @smartImportSmsAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'Already added'**
  String get smartImportSmsAlreadyAdded;

  /// No description provided for @smartImportSmsAddAgain.
  ///
  /// In en, this message translates to:
  /// **'Add again'**
  String get smartImportSmsAddAgain;

  /// No description provided for @smartImportSmsClearAllAdded.
  ///
  /// In en, this message translates to:
  /// **'Clear all added'**
  String get smartImportSmsClearAllAdded;

  /// No description provided for @smartImportSmsClearAllAddedConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear imported history?'**
  String get smartImportSmsClearAllAddedConfirmTitle;

  /// No description provided for @smartImportSmsClearAllAddedConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'All SMS will show as not added. You can import them again. Your existing expenses and incomes are not deleted.'**
  String get smartImportSmsClearAllAddedConfirmMessage;

  /// No description provided for @smartImportSmsClearAllAddedDone.
  ///
  /// In en, this message translates to:
  /// **'Imported history cleared'**
  String get smartImportSmsClearAllAddedDone;

  /// No description provided for @smartImportSmsSkippedDuplicate.
  ///
  /// In en, this message translates to:
  /// **'{count} message(s) were already in the app.'**
  String smartImportSmsSkippedDuplicate(int count);

  /// No description provided for @smartImportSmsLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more messages'**
  String get smartImportSmsLoadMore;

  /// No description provided for @smartImportSmsLoading.
  ///
  /// In en, this message translates to:
  /// **'Reading your SMS messages…'**
  String get smartImportSmsLoading;

  /// No description provided for @smartImportSmsLoadingMore.
  ///
  /// In en, this message translates to:
  /// **'Loading more…'**
  String get smartImportSmsLoadingMore;

  /// No description provided for @smartImportSmsListCap.
  ///
  /// In en, this message translates to:
  /// **'Showing the latest {count} financial messages. Pull to refresh for a new scan.'**
  String smartImportSmsListCap(int count);

  /// No description provided for @smartImportUnknownSender.
  ///
  /// In en, this message translates to:
  /// **'Unknown sender'**
  String get smartImportUnknownSender;

  /// No description provided for @smartImportSmsTitleExpense.
  ///
  /// In en, this message translates to:
  /// **'Bank expense'**
  String get smartImportSmsTitleExpense;

  /// No description provided for @smartImportSmsTitleIncome.
  ///
  /// In en, this message translates to:
  /// **'Bank income'**
  String get smartImportSmsTitleIncome;

  /// No description provided for @smartImportSmsShowBody.
  ///
  /// In en, this message translates to:
  /// **'Show full message'**
  String get smartImportSmsShowBody;

  /// No description provided for @smartImportSmsHideBody.
  ///
  /// In en, this message translates to:
  /// **'Hide message'**
  String get smartImportSmsHideBody;

  /// No description provided for @smartImportSmsFilterReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get smartImportSmsFilterReady;

  /// No description provided for @smartImportSmsFilterExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get smartImportSmsFilterExpenses;

  /// No description provided for @smartImportSmsFilterIncomes.
  ///
  /// In en, this message translates to:
  /// **'Incomes'**
  String get smartImportSmsFilterIncomes;

  /// No description provided for @smartImportSmsFilterAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get smartImportSmsFilterAdded;

  /// No description provided for @smartImportSmsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get smartImportSmsFilterAll;

  /// No description provided for @smartImportSmsSummary.
  ///
  /// In en, this message translates to:
  /// **'{ready} ready · {added} added · {noAmount} no amount'**
  String smartImportSmsSummary(int ready, int added, int noAmount);

  /// No description provided for @smartImportSmsFilterEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this filter. Try another filter or pull to refresh.'**
  String get smartImportSmsFilterEmpty;

  /// No description provided for @smartImportSmsNoAmount.
  ///
  /// In en, this message translates to:
  /// **'No amount found'**
  String get smartImportSmsNoAmount;

  /// No description provided for @smartImportSmsReviewAdd.
  ///
  /// In en, this message translates to:
  /// **'Review & add'**
  String get smartImportSmsReviewAdd;

  /// No description provided for @smartImportSmsHintSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap checkbox to multi-select · tap card to review'**
  String get smartImportSmsHintSelect;

  /// No description provided for @smartImportTapToImport.
  ///
  /// In en, this message translates to:
  /// **'Tap to review'**
  String get smartImportTapToImport;

  /// No description provided for @smartImportAddAllExpenses.
  ///
  /// In en, this message translates to:
  /// **'Add all expenses ({count})'**
  String smartImportAddAllExpenses(int count);

  /// No description provided for @smartImportAddAllIncomes.
  ///
  /// In en, this message translates to:
  /// **'Add all incomes ({count})'**
  String smartImportAddAllIncomes(int count);

  /// No description provided for @smartImportAddSelected.
  ///
  /// In en, this message translates to:
  /// **'Add selected ({count})'**
  String smartImportAddSelected(int count);

  /// No description provided for @smartImportSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get smartImportSelectAll;

  /// No description provided for @smartImportClearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get smartImportClearSelection;

  /// No description provided for @smartImportBulkCategorySheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Category for import'**
  String get smartImportBulkCategorySheetTitle;

  /// No description provided for @smartImportBulkCategorySheetHint.
  ///
  /// In en, this message translates to:
  /// **'Choose category and source. We suggest values from the message when we can — change if needed.'**
  String get smartImportBulkCategorySheetHint;

  /// No description provided for @smartImportBulkExpensePaidFromHint.
  ///
  /// In en, this message translates to:
  /// **'Suggested from SMS when possible — change if needed.'**
  String get smartImportBulkExpensePaidFromHint;

  /// No description provided for @smartImportBulkIncomeSourceHint.
  ///
  /// In en, this message translates to:
  /// **'Suggested from SMS when possible — change if needed.'**
  String get smartImportBulkIncomeSourceHint;

  /// No description provided for @smartImportBulkSelectPaidFrom.
  ///
  /// In en, this message translates to:
  /// **'Select paid from'**
  String get smartImportBulkSelectPaidFrom;

  /// No description provided for @smartImportBulkSelectIncomeSource.
  ///
  /// In en, this message translates to:
  /// **'Select income source'**
  String get smartImportBulkSelectIncomeSource;

  /// No description provided for @smartImportBulkExpenseCategory.
  ///
  /// In en, this message translates to:
  /// **'Expense category'**
  String get smartImportBulkExpenseCategory;

  /// No description provided for @smartImportBulkIncomeSource.
  ///
  /// In en, this message translates to:
  /// **'Income source'**
  String get smartImportBulkIncomeSource;

  /// No description provided for @smartImportBulkApplyAndImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get smartImportBulkApplyAndImport;

  /// No description provided for @smartImportBulkImporting.
  ///
  /// In en, this message translates to:
  /// **'Importing messages…'**
  String get smartImportBulkImporting;

  /// No description provided for @smartImportBulkNothingToAdd.
  ///
  /// In en, this message translates to:
  /// **'No messages with a valid amount to import.'**
  String get smartImportBulkNothingToAdd;

  /// No description provided for @smartImportBulkResult.
  ///
  /// In en, this message translates to:
  /// **'Added {incomes} incomes and {expenses} expenses.'**
  String smartImportBulkResult(int incomes, int expenses);

  /// No description provided for @smartImportBulkPartialFail.
  ///
  /// In en, this message translates to:
  /// **'{failed} message(s) could not be imported.'**
  String smartImportBulkPartialFail(int failed);

  /// No description provided for @settingsAppLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get settingsAppLock;

  /// No description provided for @settingsAppLockBiometric.
  ///
  /// In en, this message translates to:
  /// **'Face ID / fingerprint'**
  String get settingsAppLockBiometric;

  /// No description provided for @settingsAppLockChangePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get settingsAppLockChangePin;

  /// No description provided for @appLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Pockio'**
  String get appLockTitle;

  /// No description provided for @appLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to continue'**
  String get appLockSubtitle;

  /// No description provided for @appLockWrongPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. Try again.'**
  String get appLockWrongPin;

  /// No description provided for @appLockBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock your finances'**
  String get appLockBiometricReason;

  /// No description provided for @appLockEnterPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get appLockEnterPinTitle;

  /// No description provided for @appLockEnterPinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm to continue'**
  String get appLockEnterPinSubtitle;

  /// No description provided for @appLockCreatePinTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a PIN'**
  String get appLockCreatePinTitle;

  /// No description provided for @appLockCreatePinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use 4 digits you will remember'**
  String get appLockCreatePinSubtitle;

  /// No description provided for @appLockConfirmPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your PIN'**
  String get appLockConfirmPinTitle;

  /// No description provided for @appLockConfirmPinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the same PIN again'**
  String get appLockConfirmPinSubtitle;

  /// No description provided for @appLockPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get appLockPinMismatch;

  /// No description provided for @appLockEnabledSuccess.
  ///
  /// In en, this message translates to:
  /// **'App lock is on'**
  String get appLockEnabledSuccess;

  /// No description provided for @appLockDisabledSuccess.
  ///
  /// In en, this message translates to:
  /// **'App lock is off'**
  String get appLockDisabledSuccess;

  /// No description provided for @appLockEnableFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not enable app lock'**
  String get appLockEnableFailed;

  /// No description provided for @appLockBiometricPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics?'**
  String get appLockBiometricPromptTitle;

  /// No description provided for @appLockBiometricPromptMessage.
  ///
  /// In en, this message translates to:
  /// **'Unlock faster with Face ID or fingerprint on this device.'**
  String get appLockBiometricPromptMessage;

  /// No description provided for @appLockBiometricFailed.
  ///
  /// In en, this message translates to:
  /// **'Biometrics could not be enabled'**
  String get appLockBiometricFailed;

  /// No description provided for @appLockChangePinSuccess.
  ///
  /// In en, this message translates to:
  /// **'PIN updated'**
  String get appLockChangePinSuccess;

  /// No description provided for @appLockChangePinFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update PIN'**
  String get appLockChangePinFailed;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @monthlyReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly report'**
  String get monthlyReportTitle;

  /// No description provided for @monthlyReportShort.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get monthlyReportShort;

  /// No description provided for @monthlyReportVsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Compared to last month'**
  String get monthlyReportVsLastMonth;

  /// No description provided for @monthlyReportBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget vs actual'**
  String get monthlyReportBudgetTitle;

  /// No description provided for @monthlyReportNoBudgets.
  ///
  /// In en, this message translates to:
  /// **'No budgets set for this month. Add limits on the Expenses tab to track spending here.'**
  String get monthlyReportNoBudgets;

  /// No description provided for @monthlyReportEntrySummary.
  ///
  /// In en, this message translates to:
  /// **'{incomeCount} income sources · {expenseCount} expense categories'**
  String monthlyReportEntrySummary(int incomeCount, int expenseCount);

  /// No description provided for @globalSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get globalSearchTitle;

  /// No description provided for @globalSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Title, category, source, amount…'**
  String get globalSearchHint;

  /// No description provided for @globalSearchAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get globalSearchAll;

  /// No description provided for @globalSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching entries'**
  String get globalSearchNoResults;

  /// No description provided for @globalSearchAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get globalSearchAllTime;

  /// No description provided for @globalSearchCurrentPeriod.
  ///
  /// In en, this message translates to:
  /// **'This period'**
  String get globalSearchCurrentPeriod;

  /// No description provided for @currencyUsDollar.
  ///
  /// In en, this message translates to:
  /// **'US Dollar'**
  String get currencyUsDollar;

  /// No description provided for @currencyEuro.
  ///
  /// In en, this message translates to:
  /// **'Euro'**
  String get currencyEuro;

  /// No description provided for @expenseReceiptLabel.
  ///
  /// In en, this message translates to:
  /// **'Receipt photo'**
  String get expenseReceiptLabel;

  /// No description provided for @expenseReceiptAttach.
  ///
  /// In en, this message translates to:
  /// **'Attach receipt'**
  String get expenseReceiptAttach;

  /// No description provided for @expenseReceiptReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace photo'**
  String get expenseReceiptReplace;

  /// No description provided for @expenseReceiptRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get expenseReceiptRemove;

  /// No description provided for @expenseReceiptUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not upload receipt. Try again.'**
  String get expenseReceiptUploadFailed;

  /// No description provided for @expenseReceiptInvalidType.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo (JPG, PNG, or WebP). Videos are not supported.'**
  String get expenseReceiptInvalidType;

  /// No description provided for @subscriptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptionsTitle;

  /// No description provided for @subscriptionsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add subscription'**
  String get subscriptionsAdd;

  /// No description provided for @subscriptionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Track Netflix, gym, and bills'**
  String get subscriptionsEmptyTitle;

  /// No description provided for @subscriptionsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add monthly subscriptions to see what’s due this week and your total spend.'**
  String get subscriptionsEmptySubtitle;

  /// No description provided for @subscriptionsMonthlyTotal.
  ///
  /// In en, this message translates to:
  /// **'Monthly total'**
  String get subscriptionsMonthlyTotal;

  /// No description provided for @subscriptionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} subscriptions'**
  String subscriptionsCount(int count);

  /// No description provided for @subscriptionsDueThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Due this week'**
  String get subscriptionsDueThisWeek;

  /// No description provided for @subscriptionsAll.
  ///
  /// In en, this message translates to:
  /// **'All subscriptions'**
  String get subscriptionsAll;

  /// No description provided for @subscriptionsDueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String subscriptionsDueOn(String date);

  /// No description provided for @zakatTitle.
  ///
  /// In en, this message translates to:
  /// **'Zakat calculator'**
  String get zakatTitle;

  /// No description provided for @zakatDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Estimate only (2.5% on net zakatable wealth). Enter gold and silver by weight in grams; value = grams × price per gram. Consult a scholar for your situation.'**
  String get zakatDisclaimer;

  /// No description provided for @zakatFillFromLedger.
  ///
  /// In en, this message translates to:
  /// **'Fill from this ledger'**
  String get zakatFillFromLedger;

  /// No description provided for @zakatFillFromLedgerDone.
  ///
  /// In en, this message translates to:
  /// **'Cash and savings plans added from your ledger'**
  String get zakatFillFromLedgerDone;

  /// No description provided for @zakatPricesSection.
  ///
  /// In en, this message translates to:
  /// **'Market prices (per gram)'**
  String get zakatPricesSection;

  /// No description provided for @zakatPricesHint.
  ///
  /// In en, this message translates to:
  /// **'Used to value your gold and silver and to calculate nisab.'**
  String get zakatPricesHint;

  /// No description provided for @zakatPricePerGramSuffix.
  ///
  /// In en, this message translates to:
  /// **'EGP/g'**
  String get zakatPricePerGramSuffix;

  /// No description provided for @zakatAssetsSection.
  ///
  /// In en, this message translates to:
  /// **'Zakatable assets'**
  String get zakatAssetsSection;

  /// No description provided for @zakatDeductionsSection.
  ///
  /// In en, this message translates to:
  /// **'Deductions'**
  String get zakatDeductionsSection;

  /// No description provided for @zakatNisabSection.
  ///
  /// In en, this message translates to:
  /// **'Nisab (minimum)'**
  String get zakatNisabSection;

  /// No description provided for @zakatCash.
  ///
  /// In en, this message translates to:
  /// **'Cash & bank balance'**
  String get zakatCash;

  /// No description provided for @zakatGold.
  ///
  /// In en, this message translates to:
  /// **'Gold weight (24k, grams)'**
  String get zakatGold;

  /// No description provided for @zakatSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver weight (grams)'**
  String get zakatSilver;

  /// No description provided for @zakatInvestments.
  ///
  /// In en, this message translates to:
  /// **'Investments & savings'**
  String get zakatInvestments;

  /// No description provided for @zakatBusinessGoods.
  ///
  /// In en, this message translates to:
  /// **'Trade / business goods'**
  String get zakatBusinessGoods;

  /// No description provided for @zakatReceivables.
  ///
  /// In en, this message translates to:
  /// **'Money owed to you'**
  String get zakatReceivables;

  /// No description provided for @zakatDebts.
  ///
  /// In en, this message translates to:
  /// **'Debts & liabilities'**
  String get zakatDebts;

  /// No description provided for @zakatGoldPricePerGram.
  ///
  /// In en, this message translates to:
  /// **'Gold price (24k)'**
  String get zakatGoldPricePerGram;

  /// No description provided for @zakatSilverPricePerGram.
  ///
  /// In en, this message translates to:
  /// **'Silver price'**
  String get zakatSilverPricePerGram;

  /// No description provided for @zakatAmountHint.
  ///
  /// In en, this message translates to:
  /// **'0'**
  String get zakatAmountHint;

  /// No description provided for @zakatGoldPriceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 4500'**
  String get zakatGoldPriceHint;

  /// No description provided for @zakatSilverPriceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 55'**
  String get zakatSilverPriceHint;

  /// No description provided for @zakatGoldWeightHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 50'**
  String get zakatGoldWeightHint;

  /// No description provided for @zakatSilverWeightHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 200'**
  String get zakatSilverWeightHint;

  /// No description provided for @zakatComputedValue.
  ///
  /// In en, this message translates to:
  /// **'≈ {amount}'**
  String zakatComputedValue(String amount);

  /// No description provided for @zakatNisabHint.
  ///
  /// In en, this message translates to:
  /// **'Nisab reference: {goldGrams}g gold or {silverGrams}g silver (this app uses {goldGrams}g gold × gold price).'**
  String zakatNisabHint(int goldGrams, int silverGrams);

  /// No description provided for @zakatResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Your estimate'**
  String get zakatResultTitle;

  /// No description provided for @zakatTotalAssets.
  ///
  /// In en, this message translates to:
  /// **'Total assets'**
  String get zakatTotalAssets;

  /// No description provided for @zakatNetWealth.
  ///
  /// In en, this message translates to:
  /// **'Net wealth'**
  String get zakatNetWealth;

  /// No description provided for @zakatNisabThreshold.
  ///
  /// In en, this message translates to:
  /// **'Nisab threshold'**
  String get zakatNisabThreshold;

  /// No description provided for @zakatMeetsNisab.
  ///
  /// In en, this message translates to:
  /// **'You meet nisab — estimated zakat:'**
  String get zakatMeetsNisab;

  /// No description provided for @zakatBelowNisab.
  ///
  /// In en, this message translates to:
  /// **'Below nisab — no zakat due:'**
  String get zakatBelowNisab;

  /// No description provided for @zakatDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated zakat (2.5%)'**
  String get zakatDueLabel;

  /// No description provided for @zakatRateNote.
  ///
  /// In en, this message translates to:
  /// **'Hawl (one lunar year) on wealth is assumed. Adjust inputs for your case.'**
  String get zakatRateNote;

  /// No description provided for @homeWidgetTodayExpenses.
  ///
  /// In en, this message translates to:
  /// **'Today\'s expenses'**
  String get homeWidgetTodayExpenses;

  /// No description provided for @homeWidgetSettingsTile.
  ///
  /// In en, this message translates to:
  /// **'Home screen widget'**
  String get homeWidgetSettingsTile;

  /// No description provided for @homeWidgetQuickName.
  ///
  /// In en, this message translates to:
  /// **'Quick expense'**
  String get homeWidgetQuickName;

  /// No description provided for @homeWidgetQuickSettingsTile.
  ///
  /// In en, this message translates to:
  /// **'Quick expense widget'**
  String get homeWidgetQuickSettingsTile;

  /// No description provided for @homeWidgetPinUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Your launcher can\'t pin widgets. Long-press the home screen and choose Widgets, then add Pockio.'**
  String get homeWidgetPinUnsupported;

  /// No description provided for @planImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal photo'**
  String get planImageLabel;

  /// No description provided for @planImageAttach.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get planImageAttach;

  /// No description provided for @planImageReplace.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get planImageReplace;

  /// No description provided for @planImageRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get planImageRemove;

  /// No description provided for @planImageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload the photo. Try again.'**
  String get planImageUploadFailed;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @dailyBudget.
  ///
  /// In en, this message translates to:
  /// **'Daily Budget'**
  String get dailyBudget;

  /// No description provided for @expenseTracking.
  ///
  /// In en, this message translates to:
  /// **'Expense Tracking'**
  String get expenseTracking;

  /// No description provided for @savingsGoal.
  ///
  /// In en, this message translates to:
  /// **'Savings Goal'**
  String get savingsGoal;

  /// No description provided for @dailyLimit.
  ///
  /// In en, this message translates to:
  /// **'Daily Budget'**
  String get dailyLimit;

  /// No description provided for @budgetExceeded.
  ///
  /// In en, this message translates to:
  /// **'You\'ve exceeded your daily budget'**
  String get budgetExceeded;

  /// No description provided for @budgetRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining from your daily budget'**
  String budgetRemaining(String amount);

  /// No description provided for @editBudget.
  ///
  /// In en, this message translates to:
  /// **'Edit Budget'**
  String get editBudget;

  /// No description provided for @enterBudget.
  ///
  /// In en, this message translates to:
  /// **'Enter daily budget'**
  String get enterBudget;

  /// No description provided for @invalidBudget.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount greater than zero'**
  String get invalidBudget;

  /// No description provided for @dailyBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Daily Budget'**
  String get dailyBudgetTitle;

  /// No description provided for @dailyBudgetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your expenses and daily spending limit'**
  String get dailyBudgetSubtitle;

  /// No description provided for @editDailyBudget.
  ///
  /// In en, this message translates to:
  /// **'Edit Daily Budget'**
  String get editDailyBudget;

  /// No description provided for @remainingToday.
  ///
  /// In en, this message translates to:
  /// **'Remaining Today'**
  String get remainingToday;

  /// No description provided for @expensesToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Expenses'**
  String get expensesToday;

  /// No description provided for @dailyBudgetAmount.
  ///
  /// In en, this message translates to:
  /// **'Budget: EGP {amount}'**
  String dailyBudgetAmount(String amount);

  /// No description provided for @budgetUsedPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% used'**
  String budgetUsedPercent(String percent);

  /// No description provided for @addExpenseOrIncome.
  ///
  /// In en, this message translates to:
  /// **'Add Expense or Income'**
  String get addExpenseOrIncome;

  /// No description provided for @trackBudgetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record expenses and track your budget'**
  String get trackBudgetSubtitle;

  /// No description provided for @dailyBudgetExceededMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ve exceeded your daily budget by EGP {amount}. Try to reduce spending for the rest of the day.'**
  String dailyBudgetExceededMessage(String amount);

  /// No description provided for @dailyBudgetRemainingMessage.
  ///
  /// In en, this message translates to:
  /// **'You have EGP {amount} remaining from your daily budget.'**
  String dailyBudgetRemainingMessage(String amount);

  /// No description provided for @dailyBudgetInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily amount in Egyptian pounds'**
  String get dailyBudgetInputLabel;

  /// No description provided for @egpAmount.
  ///
  /// In en, this message translates to:
  /// **'EGP {amount}'**
  String egpAmount(String amount);

  /// No description provided for @egpCurrency.
  ///
  /// In en, this message translates to:
  /// **'EGP'**
  String get egpCurrency;

  /// No description provided for @dailyExpensesSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Expenses Summary'**
  String get dailyExpensesSummaryTitle;

  /// No description provided for @dailyExpensesTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Spent Today'**
  String get dailyExpensesTotalLabel;

  /// No description provided for @dailyExpensesRecordedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your total recorded expenses for today.'**
  String get dailyExpensesRecordedMessage;

  /// No description provided for @dailyExpensesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t recorded any expenses today yet.'**
  String get dailyExpensesEmptyMessage;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
