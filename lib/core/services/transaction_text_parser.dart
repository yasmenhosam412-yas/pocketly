import 'package:imrpo/core/models/parsed_financial_entry.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/services/merchant_memory_store.dart';
import 'package:imrpo/core/services/service_locator.dart';

/// Extracts amount, title, date, and type from OCR or SMS text (Arabic + English).
class TransactionTextParser {
  /// Stricter expense signals — actual money leaving your account/wallet.
  static const _transactionExpenseSignals = [
    'debited from',
    'debited with',
    'has been debited',
    'been debited with',
    'was debited',
    'debited with egp',
    'debited with le',
    'debited by',
    'debit by',
    'has been debit',
    'is debit by',
    'withdrawn from',
    'withdrawn with',
    'charged to',
    'charged on',
    'paid to',
    'payment of',
    'purchase of',
    'purchase for',
    'purchase at',
    'pos purchase',
    'spent at',
    'spent on',
    'bill payment',
    'transferred to',
    'transfer to',
    'عملية شراء',
    'تم الشراء',
    'مبلغ وقدره',
    'مبلغ وقدرة',
    'تم خصم',
    'تم سحب',
    'تم دفع',
    'تم سداد',
    'خصم مبلغ',
    'سحب مبلغ',
    'دفع مبلغ',
    'خصم من',
    'سحب من',
    'سداد فاتورة',
    'سداد فاتورتك',
    'تم دفع فاتورة',
    'دفع فاتورة',
    'bill payment',
    'payment of bill',
    'cash withdrawal',
    'withdrawn at atm',
    'atm withdrawal',
    'سحب نقدي',
    'سحب من ماكينة',
    'سحب من الصراف',
    'الصراف الآلي',
    'الصراف الالي',
    'تحويل صادر',
    'تحويل من',
    'تم تحويل لحظي',
    'تحويل لحظي',
    'إلى رقم مرجعي',
    'الى رقم مرجعي',
    'trx on your card',
    'you have a trx on your card',
    'you have a trx',
  ];

  /// Stricter income signals — money arriving in your account/wallet (not card).
  static const _transactionIncomeSignals = [
    'credited to your account',
    'credited to your saving',
    'credited to your current',
    'has been credited to your account',
    'has been credited to your saving',
    'was credited to your account',
    'been credited with',
    'credited with egp',
    'credited by',
    'credit by',
    'has been credit',
    'is credit by',
    'deposited to your account',
    'deposited into your account',
    'received in your account',
    'received egp',
    'transfer from',
    'transfer in',
    'instapay',
    'إنستاباي',
    'انستاباي',
    'salary',
    'salary/bonus',
    'payroll',
    'bonus credit',
    'إضافة راتب',
    'اضافة راتب',
    'إضافة حافز',
    'اضافة حافز',
    'راتب/حافز',
    'راتب / حافز',
    'تم إضافة راتب',
    'تم اضافة راتب',
    'تم إيداع',
    'تم ايداع',
    'إيداع مبلغ',
    'ايداع مبلغ',
    'ايداع نقدي',
    'إيداع نقدي',
    'cash deposit',
    'cash deposited',
    'تحويل وارد',
    'استلام مبلغ',
    'تم استلام',
    'تم استلام مبلغ',
    'استلامك',
    'وصلك',
    'وصل مبلغ',
    'تم تحويل مبلغ',
    'تحويل مبلغ',
    'حوالة واردة',
    'تم قبول مبلغ',
    'you have received',
    'received in your wallet',
    'received an amount',
    'credited to your vodafone',
    'vodafone cash wallet',
    'vf-cash',
    'has been credited to your card account',
    'credited to your card account',
    'thank you for sending your payment',
  ];

  /// Broader keywords for OCR / fallback type detection.
  static const _expenseKeywords = [
    'debit',
    'debited',
    'withdraw',
    'withdrawal',
    'charge',
    'charged',
    'paid',
    'purchase',
    'spent',
    'تم خصم',
    'تم سحب',
    'خصم',
    'سحب',
  ];

  static const _incomeKeywords = [
    'deposit',
    'deposited',
    'received',
    'salary',
    'payroll',
    'bonus',
    'راتب',
    'حافز',
    'مرتب',
    'إضافة راتب',
    'راتب/حافز',
    'تم إيداع',
    'تم ايداع',
    'تم استلام',
    'استلام',
    'إيداع',
    'ايداع',
    'تحويل وارد',
  ];

  static const _exclusionPhrases = [
    'otp',
    'one-time password',
    'one time password',
    'verification code',
    'verify your',
    'do not share',
    "don't share",
    'رمز التحقق',
    'رمز التفعيل',
    'كود التفعيل',
    'كلمة السر',
    'كلمة المرور',
    'لا تشارك',
    'promo',
    'promotion',
    'special offer',
    'limited time',
    'عرض خاص',
    'لفترة محدودة',
    'subscribe',
    'unsubscribe',
    'win ',
    'winner',
    'فزت',
    'اربح',
    'احصل على',
    'pre-approved',
    'pre approved',
    'موافقة مبدئية',
    'apply now',
    'قدم الآن',
    'download the app',
    'حمل التطبيق',
    'visit our branch',
    'زور فرع',
    'activate your card',
    'تفعيل البطاقة',
    'statement is ready',
    'statement was issued',
    'statement is issued',
    'card statement',
    'minimum payment',
    'minimum payment of',
    'your card #',
    'شكرا لإرسال دفعتك',
    'شكراً لإرسال دفعتك',
    'كشف الحساب',
    'كشف حساب',
    'كشف البطاقة',
    'بيان البطاقة',
    'تم إصدار كشف',
    'إصدار كشف',
    'survey',
    'استبيان',
    'insurance offer',
    'عرض تأمين',
    'عرض تامين',
    'loan offer',
    'عرض تمويل',
  ];

  static const _balanceOnlyPhrases = [
    'available balance',
    'current balance',
    'account balance is',
    'avl bal',
    'avail bal',
    'available bal',
    'remaining balance',
    'رصيدكم',
    'رصيدك الحالي',
    'رصيدك الحالى',
    'رصيد حسابك',
    'رصيد حسابك فى',
    'رصيد حسابك في',
    'رصيدك هو',
    'الرصيد المتاح',
    'رصيد الحساب',
    'الرصيد الحالي',
    'الرصيد الحالى',
    'رصيد بعد العملية',
  ];

  static final _vfBalanceNotification = RegExp(
    r'رصيد\s*حسابك\s*(?:فى|في)?\s*(?:فودافون\s*)?كاش\s*الحال[يى]\s*[0-9]',
    caseSensitive: false,
  );

  static final _cardStatementNotification = RegExp(
    r'(?:card\s*#?\s*x+\d+|statement\s+was\s+issued|statement\s+is\s+issued|minimum\s+payment)',
    caseSensitive: false,
  );

  /// 1500 / 1,500 / 1,500.00 / 1500.50
  static const _amountNumber =
      r'([0-9]{1,9}(?:[, ][0-9]{3})*(?:[.,][0-9]{1,2})?)';

  static const _maxCapturedAmount = 99_999_999.0;

  /// "EGP 1000.00 has been credited to your card account"
  static final _cardBillPaymentAmount = RegExp(
    r'egp\s*'
    '$_amountNumber'
    r'\s+has\s+been\s+credited\s+to\s+your\s+card',
    caseSensitive: false,
  );

  static final _mobileWalletSender = RegExp(
    r'vodafone|vf[\s-]?cash|vf-cash|vfcash|فودافون|محفظ|^vf$|'
    r'etisalat|e&|اتصالات|flous|ايه\s*اند|'
    r'orange(?:\s*cash)?|اورنج|أورنج|'
    r'we[\s-]?pay|we[\s-]?cash|وي\s*باي|وى\s*كاش|'
    r'bm[\s-]?wallet|محفظة\s*بنك\s*مصر',
    caseSensitive: false,
  );

  static final _amountWithCurrency = RegExp(
    r'(?:EGP|LE|ج\.?\s*م|جم\b|جنيه|جنية|SAR|USD|EUR|GBP|\$|€|£)\s*'
    '$_amountNumber',
    caseSensitive: false,
  );

  static final _amountBeforeCurrency = RegExp(
    '$_amountNumber'
    r'\s*(?:EGP|LE|ج\.?\s*م|جم\b|جنيه|جنية|SAR|USD|EUR|GBP)',
    caseSensitive: false,
  );

  static final _amountAttachedEgp = RegExp(
    '$_amountNumber'
    r'\s*(?:ج\.?م|جم\b)(?!\w)',
    caseSensitive: false,
  );

  static final _amountLabeled = RegExp(
    r'(?:مبلغ|amount|value|قيمة|بقيمة|مقدار|و?قدره|و?قدرة)\s*:?\s*'
    '$_amountNumber',
    caseSensitive: false,
  );

  /// "8000جم" / "8000.00جنيه" right after the number
  static final _amountAttachedCurrency = RegExp(
    '$_amountNumber'
    r'\s*(?:جنيه|جنية|ج\.?\s*م|جم\b|egp|le)(?!\w)',
    caseSensitive: false,
  );

  static final _vfReceivedAmount = RegExp(
    r'تم\s*استلام\s*مبلغ\s*'
    '$_amountNumber',
    caseSensitive: false,
  );

  /// "تم سحب 5900.00 جنية" / "تم استلام 6000 جنيه" (without مبلغ)
  static final _vfDirectTxnAmount = RegExp(
    r'تم\s*(?:استلام|خصم|سحب|دفع|سداد)\s*'
    '$_amountNumber'
    r'\s*(?:جنيه|جنية|ج\.?\s*م|جم\b|egp|le)',
    caseSensitive: false,
  );

  static final _vfDebitedAmount = RegExp(
    r'تم\s*(?:خصم|سحب|دفع|سداد)\s*مبلغ\s*'
    '$_amountNumber',
    caseSensitive: false,
  );

  static final _vfTransferInAmount = RegExp(
    r'تم\s*تحويل\s*مبلغ\s*:?\s*'
    '$_amountNumber',
    caseSensitive: false,
  );

  /// "تم تحويل لحظى بمبلغ 200 إلى رقم مرجعى …"
  static final _instantTransferOutAmount = RegExp(
    r'تم\s*تحويل\s*لحظ[يى]\s*بمبلغ\s*'
    '$_amountNumber',
    caseSensitive: false,
  );

  static final _instantTransferReference = RegExp(
    r'رقم\s*مرجع[يى]\s*:?\s*([A-Za-z0-9]+(?:\s+[A-Za-z0-9]+)?)',
    caseSensitive: false,
  );

  static final _arabicInlineDateTime = RegExp(
    r'(?:فى|في|on)\s*(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})\s+(\d{1,2}):(\d{2})',
    caseSensitive: false,
  );

  static final _vfAcceptedAmount = RegExp(
    r'تم\s*قبول\s*مبلغ\s*:?\s*'
    '$_amountNumber',
    caseSensitive: false,
  );

  static final _incomingRemittanceAmount = RegExp(
    r'حوالة\s*واردة\s*بمبلغ\s*:?\s*'
    '$_amountNumber',
    caseSensitive: false,
  );

  static final _walletCreditedAmount = RegExp(
    r'(?:egp|le)\s*'
    '$_amountNumber'
    r'.{0,120}(?:vodafone\s*cash|vf-cash|orange\s*cash|your\s+(?:vodafone\s*)?wallet|محفظتك)',
    caseSensitive: false,
  );

  static final _englishReceivedAmount = RegExp(
    r'(?:you\s+have\s+)?received\s+'
    r'(?:(?:an\s+)?amount\s+of\s*(?:egp|le)?\s*|(?:egp|le)\s*)'
    '$_amountNumber',
    caseSensitive: false,
  );

  static final _txnAmountPhrase = RegExp(
    r'(?:استلام|خصم|سحب|دفع|إيداع|ايداع)\s*مبلغ\s*'
    '$_amountNumber',
    caseSensitive: false,
  );

  /// "EGP 55.00 has been debited" / "debited with EGP 55" / "debit by EGP 1,500"
  static final _bankDebitedAmount = RegExp(
    r'(?:(?:has\s+been\s+)?(?:debited|debit|withdrawn|charged|paid))\s+'
    r'(?:by|with|for|amount\s+of)?\s*(?:egp|le)?\s*'
    '$_amountNumber',
    caseSensitive: false,
  );

  static final _bankCreditedAmount = RegExp(
    r'(?:egp|le)\s*'
    '$_amountNumber'
    r'\s+has\s+been\s+credit(?:ed)?',
    caseSensitive: false,
  );

  static final _nbeDebitByAmount = RegExp(
    r'(?:is\s+)?(?:debit(?:ed)?|credit(?:ed)?)\s+by\s+(?:egp|le)\s*'
    '$_amountNumber',
    caseSensitive: false,
  );

  static final _purchaseOfAmount = RegExp(
    r'(?:purchase|purchased|pos(?:\s+purchase)?|trx|transaction)\s+'
    r'(?:of|for)?\s*(?:egp|le)\s*'
    '$_amountNumber',
    caseSensitive: false,
  );

  static final _arabicPurchaseAmount = RegExp(
    r'(?:عملية\s*شراء|تم\s*الشراء|شراء)\s*(?:بمبلغ\s*)?(?:egp|le)?\s*'
    '$_amountNumber',
    caseSensitive: false,
  );

  /// "تم إيداع EGP 7900" / "تم إيداع مبلغ 5000 جنيه"
  static final _bankArabicDepositAmount = RegExp(
    r'تم\s*(?:إيداع|ايداع)\s*(?:مبلغ\s*)?(?:egp|le)?\s*'
    '$_amountNumber',
    caseSensitive: false,
  );

  /// "تم خصم EGP 500" / "تم سحب مبلغ 500 من الصراف"
  static final _bankArabicDebitAmount = RegExp(
    r'تم\s*(?:خصم|سحب)\s*(?:مبلغ\s*)?(?:و?قدره\s*)?(?:egp|le)?\s*'
    '$_amountNumber',
    caseSensitive: false,
  );

  /// "سداد فاتورة كهرباء بمبلغ 350" / "Bill payment of EGP 200"
  static final _billPaymentAmount = RegExp(
    r'(?:سداد|تم\s*سداد|bill\s+payment)\s*(?:فاتورة|فاتورتك|of)?\s*(?:بمبلغ\s*)?(?:egp|le)?\s*'
    '$_amountNumber',
    caseSensitive: false,
  );

  /// "Cash withdrawal of EGP 500 at ATM" / "تم سحب 500 من الصراف الآلي"
  static final _atmWithdrawalAmount = RegExp(
    r'(?:cash\s+withdrawal|atm\s+withdrawal|withdrawn\s+at\s+atm)\s+(?:of\s+)?(?:egp|le)?\s*'
    '$_amountNumber',
    caseSensitive: false,
  );

  static final _atmWithdrawalArabicAmount = RegExp(
    r'تم\s*سحب\s*(?:مبلغ\s*)?'
    '$_amountNumber'
    r'.{0,80}(?:صراف|atm)',
    caseSensitive: false,
  );

  /// "Cash deposit of EGP 1000" / "إيداع نقدي بمبلغ 2000"
  static final _cashDepositAmount = RegExp(
    r'(?:cash\s+deposit|ايداع\s*نقدي|إيداع\s*نقدي)\s*(?:of\s+)?(?:مبلغ\s*)?(?:egp|le)?\s*'
    '$_amountNumber',
    caseSensitive: false,
  );

  /// CIB / bank: "debited with EGP 1,500.00 at CARREFOUR"
  static final _bankDebitedAtMerchant = RegExp(
    r'(?:debited|charged|debit)\s+(?:with|for|by)\s+(?:egp|le)?\s*'
    '$_amountNumber'
    r'.{0,60}\s+at\s+(.+?)(?:\s+on\s+\d|\s+available|\s+for\s+more|$)',
    caseSensitive: false,
  );

  static final _purchaseAtMerchant = RegExp(
    r'(?:purchase|trx|transaction)\s+(?:of\s+)?(?:egp|le)\s*'
    '$_amountNumber'
    r'.{0,40}\s+(?:at|from)\s+(.+?)(?:\s+on\s+\d|\s+available|\s+for\s+more|\.|$)',
    caseSensitive: false,
  );

  static final _billPaymentMerchant = RegExp(
    r'سداد\s*(?:فاتورة|فاتورتك)\s+(.+?)(?:\s+بمبلغ|\s+بقيمة|\s+بقيمه|\.|$)',
    caseSensitive: false,
  );

  static final _englishAtmLocation = RegExp(
    r'at\s+(?:atm\s+)?(.+?)(?:\s+on\s+\d|\s+available|\.|$)',
    caseSensitive: false,
  );

  static final _bankAccountRef = RegExp(
    r'(?:حساب\s*رقم|account\s*(?:no\.?|#)?)\s*#?([0-9A-Za-z]+)',
    caseSensitive: false,
  );

  /// "يوم 06/04/2026 13:24"
  static final _bankOperationDateTime = RegExp(
    r'(?:يوم|on)\s*(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})\s+(\d{1,2}):(\d{2})',
    caseSensitive: false,
  );

  /// "إضافة راتب/حافز بمبلغ 12500" / "اضافة راتب بمبلغ 5000"
  static final _salaryBonusAmount = RegExp(
    r'(?:إضافة|اضافة|تم\s*إضافة|تم\s*اضافة)\s*(?:راتب|مرتب)(?:\s*/\s*حافز)?\s*(?:بمبلغ\s*)?'
    '$_amountNumber',
    caseSensitive: false,
  );

  static final _salaryBonusEgpAmount = RegExp(
    r'(?:egp|le|جنيه|جنية)\s*'
    '$_amountNumber'
    r'.{0,140}(?:راتب|حافز|مرتب|salary|payroll|bonus)',
    caseSensitive: false,
  );

  /// "from Talabat for EGP 204.16" (may include "on 19-May at …" before for EGP)
  static final _cardPurchaseAmount = RegExp(
    r'from\s+(.+?)\s+for\s+egp\s*'
    '$_amountNumber',
    caseSensitive: false,
  );

  static final _cardPurchaseDateTime = RegExp(
    r'on\s+(\d{1,2})-([A-Za-z]{3})(?:-(\d{2,4}))?\s+at\s+(\d{1,2}):(\d{2})',
    caseSensitive: false,
  );

  static final _registeredSenderName = RegExp(
    r'المسجل\s*ب(?:إ|ا|أ)?\s*سم\s+(.+?)(?:\s+على|\s+في\s+رقم|\s+رصيد|\s+تاريخ\s*العملية|\s*\.(?:\s|$)|\n|$)',
    caseSensitive: false,
  );

  static final _vfOperationDateTime = RegExp(
    r'تاريخ\s*العملية\s*:?\s*(\d{1,2}):(\d{2})\s+(\d{1,2})-(\d{1,2})-(\d{2,4})',
    caseSensitive: false,
  );

  static final _plainAmount = RegExp(
    r'(?<![\d.,])$_amountNumber(?![\d.,])',
  );

  static bool isMobileWalletSender(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return false;
    return _mobileWalletSender.hasMatch(trimmed);
  }

  /// Bank hotlines (19123) and phone numbers — not valid transaction titles.
  static bool isPhoneOrHotline(String value) {
    final cleaned = value.replaceAll(RegExp(r'[\s\-+().]'), '');
    if (cleaned.isEmpty || !RegExp(r'^\d+$').hasMatch(cleaned)) {
      return false;
    }
    if (cleaned.length >= 10 && cleaned.startsWith('01')) return true;
    if (cleaned.length >= 4 && cleaned.length <= 6) return true;
    return cleaned.length >= 11;
  }

  /// Maps SMS text to an expense paid-from label (add-expense chips).
  static String? inferExpensePaidFrom({
    required String body,
    String? sender,
  }) {
    final lower = _normalizeSmsText(body).toLowerCase();

    if (_isCardPurchase(lower) ||
        lower.contains('trx on your card') ||
        (lower.contains('card account') &&
            (lower.contains('debited') ||
                lower.contains('charged') ||
                lower.contains('خصم')))) {
      return 'Visa Card';
    }

    if (_isAtmWithdrawal(lower)) return 'Cash';

    if (_mentionsInstaPay(lower) || _isInstantOutgoingTransfer(lower)) {
      return 'InstaPay';
    }

    if (_isVodafoneCashExpense(lower) ||
        _isVodafoneCashMessage(lower) ||
        (sender != null && _senderLooksLikeVodafone(sender))) {
      if (!_isWalletIncomingTransfer(lower) &&
          !_isVodafoneWalletCredit(lower) &&
          !_isEnglishWalletReceive(lower)) {
        return 'Vodafone Cash';
      }
    }

    if (_isEtisalatCashMessage(lower) ||
        _isOrangeCashMessage(lower) ||
        _isWePayMessage(lower) ||
        (_isAnyMobileWalletMessage(lower) &&
            !_isWalletIncomingTransfer(lower) &&
            !_isVodafoneWalletCredit(lower) &&
            !_isEnglishWalletReceive(lower))) {
      return 'Cash';
    }

    if (sender != null &&
        sender.trim().isNotEmpty &&
        isMobileWalletSender(sender) &&
        !_isWalletIncomingTransfer(lower) &&
        !_isVodafoneWalletCredit(lower)) {
      return _senderLooksLikeVodafone(sender) ? 'Vodafone Cash' : 'Cash';
    }

    if (_isBankAccountTransaction(lower) ||
        lower.contains('تحويل') ||
        lower.contains('transfer') ||
        lower.contains('debited from your account')) {
      return 'Bank transfer';
    }

    return null;
  }

  /// Maps merchant / bill keywords in SMS to a preset expense category.
  static String? inferExpenseCategory({
    required String body,
    String? title,
  }) {
    final lower = _normalizeSmsText(body).toLowerCase();
    final haystack = '$lower ${title?.toLowerCase() ?? ''}';

    if (_isBillPayment(lower) ||
        _isCardBillPayment(lower) ||
        lower.contains('فاتورة') ||
        lower.contains('فاتوره')) {
      return 'Bills';
    }

    if (_isAtmWithdrawal(lower)) return 'Other';

    var best = '';
    var bestScore = 0;
    for (final entry in _expenseCategoryKeywords.entries) {
      final score = entry.value.where(haystack.contains).length;
      if (score > bestScore) {
        best = entry.key;
        bestScore = score;
      }
    }
    if (bestScore > 0) return best;
    return null;
  }

  /// Maps incoming SMS to an income-source chip label.
  static String? inferIncomeSource({
    required String body,
    String? sender,
  }) {
    final lower = _normalizeSmsText(body).toLowerCase();

    if (_isSalaryBonusCredit(lower)) return 'Salary';

    if (_mentionsInstaPay(lower)) return 'InstaPay';

    if (_isVodafoneCashIncome(lower) ||
        _isVodafoneWalletCredit(lower) ||
        _isEnglishWalletReceive(lower) ||
        (sender != null && _senderLooksLikeVodafone(sender))) {
      return 'Vodafone Cash';
    }

    if (_isEtisalatCashMessage(lower) ||
        _isOrangeCashMessage(lower) ||
        _isWePayMessage(lower) ||
        _isWalletIncomingTransfer(lower)) {
      return 'Cash';
    }

    if (_isCardBillPayment(lower)) return 'Visa Card';

    if (_isBankAccountTransaction(lower) ||
        lower.contains('credited') ||
        lower.contains('ايداع') ||
        lower.contains('إيداع')) {
      return 'Bank transfer';
    }

    return null;
  }

  static bool _mentionsInstaPay(String lower) {
    return lower.contains('instapay') ||
        lower.contains('insta pay') ||
        lower.contains('انستاباي') ||
        lower.contains('إنستاباي');
  }

  static bool _senderLooksLikeVodafone(String sender) {
    final s = sender.toLowerCase();
    return s.contains('vodafone') ||
        s.contains('vf-cash') ||
        s.contains('vfcash') ||
        s.contains('فودافون');
  }

  static const _expenseCategoryKeywords = <String, List<String>>{
    'Food': [
      'talabat',
      'tawbakh',
      'starbucks',
      'mcdonald',
      'kfc',
      'pizza',
      'burger',
      'restaurant',
      'cafe',
      'café',
      'grocery',
      'supermarket',
      'carrefour',
      'spinneys',
      'كارفور',
      'تالاباط',
      'طلب',
      'مطعم',
      'قهوة',
      'قهوه',
      'سوبرماركت',
      'شاورما',
      'كشري',
    ],
    'Transport': [
      'uber',
      'careem',
      'didi',
      'taxi',
      'metro',
      'parking',
      'petrol',
      'fuel',
      'shell',
      'total energies',
      'أوبر',
      'اوبر',
      'كريم',
      'تاكسي',
      'مترو',
      'بنزين',
      'سولار',
      'مواصلات',
    ],
    'Shopping': [
      'amazon',
      'noon',
      'jumia',
      'ikea',
      'zara',
      'hm.com',
      'mall',
      'btech',
      'راية',
      'نون',
      'أمازون',
      'امازون',
      'جوميا',
      'تسوق',
      'ملابس',
    ],
    'Rent': [
      'rent',
      'rental',
      'إيجار',
      'ايجار',
    ],
    'Bills': [
      'electric',
      'electricity',
      'water',
      'internet',
      'wifi',
      'we internet',
      'orange dsl',
      'vodafone dsl',
      'utility',
      'كهربا',
      'كهرباء',
      'مياه',
      'انترنت',
      'إنترنت',
      'غاز',
    ],
  };

  /// Best title for lists/forms — never a call-center short code.
  static String? resolveSmsTitle({
    String? parsedTitle,
    required String body,
    String? sender,
  }) {
    final title = _sanitizeMerchantTitle(parsedTitle);
    if (title != null && _isValidSmsTitle(title)) {
      return title;
    }

    final fromBody = resolveTitleFromBody(body);
    if (fromBody != null && _isValidSmsTitle(fromBody)) return fromBody;

    final fromSender = sender?.trim();
    if (fromSender != null &&
        fromSender.isNotEmpty &&
        !isPhoneOrHotline(fromSender)) {
      return fromSender;
    }

    return null;
  }

  static String? resolveTitleFromBody(String body) {
    if (_isCardBillPayment(body.toLowerCase())) {
      return _extractCardBillPaymentTitle(body);
    }
    return _extractCardMerchant(body) ??
        _extractSenderName(body) ??
        _extractBillPaymentMerchant(body) ??
        _extractInstantTransferReference(body) ??
        _extractBankDebitMerchant(body) ??
        _extractAtmTitle(body) ??
        _extractBankAccountTitle(body) ??
        _extractSalaryTitle(body) ??
        _extractWalletTitle(body);
  }

  static String? _extractInstantTransferReference(String text) {
    if (!_isInstantOutgoingTransfer(text.toLowerCase())) return null;
    final match = _instantTransferReference.firstMatch(text);
    if (match == null) return null;
    final ref = match.group(1)?.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (ref == null || ref.isEmpty) return null;
    return 'Ref $ref';
  }

  static bool _isInstantOutgoingTransfer(String lower) {
    if (!lower.contains('تحويل لحظ')) return false;
    if (_isWalletIncomingTransfer(lower)) return false;
    if (lower.contains('رقم مرجع') ||
        lower.contains('الى رقم') ||
        lower.contains('إلى رقم')) {
      return true;
    }
    return lower.contains('بمبلغ') &&
        (lower.contains('الى') || lower.contains('إلى')) &&
        !lower.contains('لمحفظ') &&
        !lower.contains('ل محفظ');
  }

  static bool _isBankAccountTransaction(String lower) {
    return lower.contains('حساب رقم') ||
        lower.contains('إلى حساب') ||
        lower.contains('الى حساب') ||
        lower.contains('to your account') ||
        lower.contains('credited to your account') ||
        lower.contains('debited from your account');
  }

  static String? _extractBankAccountTitle(String text) {
    final lower = text.toLowerCase();
    if (_isAnyMobileWalletMessage(lower)) return null;
    if (_isAtmWithdrawal(lower)) return null;
    if (_isBillPayment(lower)) return null;
    final isArabicBankLine = _isBankAccountTransaction(lower) ||
        ((lower.contains('تم إيداع') ||
                lower.contains('تم ايداع') ||
                lower.contains('تم خصم') ||
                lower.contains('تم سحب')) &&
            (lower.contains('egp') ||
                lower.contains('جنيه') ||
                lower.contains('جم')) &&
            lower.contains('حساب'));
    if (!isArabicBankLine) return null;
    final account = _bankAccountRef.firstMatch(text);
    if (account != null) {
      return 'Account #${account.group(1)}';
    }
    if (lower.contains('تم إيداع') ||
        lower.contains('تم ايداع') ||
        _isCashDeposit(lower)) {
      return 'Bank deposit';
    }
    if (lower.contains('تم خصم') || lower.contains('تم سحب')) {
      return 'Bank withdrawal';
    }
    return null;
  }

  static String? _extractBillPaymentMerchant(String text) {
    if (!_isBillPayment(text.toLowerCase())) return null;
    final match = _billPaymentMerchant.firstMatch(text);
    if (match != null) {
      final name = _sanitizeMerchantTitle(match.group(1));
      if (name != null) return name;
    }
    return 'Bill payment';
  }

  static String? _extractBankDebitMerchant(String text) {
    final lower = text.toLowerCase();
    if (_isAnyMobileWalletMessage(lower)) return null;
    final match = _bankDebitedAtMerchant.firstMatch(text);
    if (match != null) {
      return _sanitizeMerchantTitle(match.group(2));
    }
    if (_isCibMessage(lower) &&
        (lower.contains('تم خصم') || lower.contains('debited'))) {
      return 'CIB';
    }
    return null;
  }

  static String? _extractAtmTitle(String text) {
    final lower = text.toLowerCase();
    if (!_isAtmWithdrawal(lower)) return null;

    if (lower.contains('atm withdrawal') ||
        lower.contains('cash withdrawal') ||
        lower.contains('withdrawn at atm')) {
      final match = _englishAtmLocation.firstMatch(text);
      if (match != null) {
        final location = _sanitizeMerchantTitle(match.group(1));
        if (location != null &&
            !RegExp(r'^atm\b', caseSensitive: false).hasMatch(location)) {
          return 'ATM · $location';
        }
      }
    }
    return 'ATM withdrawal';
  }

  static String? _extractSalaryTitle(String text) {
    if (!_isSalaryBonusCredit(text.toLowerCase())) return null;
    final lower = text.toLowerCase();
    final hasSalary = lower.contains('راتب') ||
        lower.contains('مرتب') ||
        lower.contains('salary') ||
        lower.contains('payroll');
    final hasBonus =
        lower.contains('حافز') || lower.contains('bonus') || lower.contains('incentive');
    if (lower.contains('راتب/حافز') ||
        lower.contains('راتب / حافز') ||
        (hasSalary && hasBonus)) {
      return 'Salary / Bonus';
    }
    if (hasSalary) return 'Salary';
    if (hasBonus) return 'Bonus';
    return 'Salary / Bonus';
  }

  static bool _isSalaryBonusCredit(String lower) {
    if (lower.contains('راتب/حافز') || lower.contains('راتب / حافز')) {
      return true;
    }
    if (lower.contains('إضافة راتب') ||
        lower.contains('اضافة راتب') ||
        lower.contains('إضافة حافز') ||
        lower.contains('اضافة حافز')) {
      return true;
    }
    if (lower.contains('salary/bonus') || lower.contains('salary / bonus')) {
      return true;
    }
    if (lower.contains('payroll') &&
        (lower.contains('credited') ||
            lower.contains('credit') ||
            lower.contains('إضافة') ||
            lower.contains('اضافة') ||
            lower.contains('إيداع'))) {
      return true;
    }
    return false;
  }

  static bool _isVodafoneCashMessage(String lower) {
    if (_isEtisalatCashMessage(lower) ||
        _isOrangeCashMessage(lower) ||
        _isWePayMessage(lower)) {
      return false;
    }
    return lower.contains('فودافون') ||
        lower.contains('vodafone') ||
        lower.contains('vf-cash') ||
        lower.contains('vf.eg') ||
        lower.contains('vfcash') ||
        (lower.contains('محفظتك') &&
            !lower.contains('اتصالات') &&
            !lower.contains('cib'));
  }

  static bool _isEtisalatCashMessage(String lower) {
    return lower.contains('etisalat') ||
        lower.contains('اتصالات') ||
        lower.contains('e& money') ||
        lower.contains('e& cash') ||
        lower.contains('flous') ||
        lower.contains('محفظة اتصالات') ||
        lower.contains('ايه اند');
  }

  static bool _isOrangeCashMessage(String lower) {
    return lower.contains('orange cash') ||
        lower.contains('orangecash') ||
        lower.contains('اورنج كاش') ||
        lower.contains('محفظة اورنج') ||
        (lower.contains('اورنج') && lower.contains('محفظ'));
  }

  static bool _isWePayMessage(String lower) {
    return lower.contains('we pay') ||
        lower.contains('we cash') ||
        lower.contains('wepay') ||
        lower.contains('وي باي') ||
        lower.contains('وى كاش');
  }

  static bool _isAnyMobileWalletMessage(String lower) {
    return _isVodafoneCashMessage(lower) ||
        _isEtisalatCashMessage(lower) ||
        _isOrangeCashMessage(lower) ||
        _isWePayMessage(lower);
  }

  static bool _isCibMessage(String lower) {
    return lower.contains('cib') ||
        lower.contains('بنك cib') ||
        lower.contains('commercial international');
  }

  static bool _isAtmWithdrawal(String lower) {
    if (_isWalletIncomingTransfer(lower)) return false;
    return lower.contains('صراف آلي') ||
        lower.contains('صراف الالي') ||
        lower.contains('الصراف الآلي') ||
        lower.contains('الصراف الالي') ||
        lower.contains('atm withdrawal') ||
        lower.contains('withdrawn at atm') ||
        lower.contains('cash withdrawal') ||
        lower.contains('سحب من ماكينة') ||
        lower.contains('سحب نقدي') ||
        (lower.contains('تم سحب') &&
            (lower.contains('صراف') || lower.contains('atm')));
  }

  static bool _isBillPayment(String lower) {
    return lower.contains('سداد فاتورة') ||
        lower.contains('سداد فاتورتك') ||
        lower.contains('تم دفع فاتورة') ||
        lower.contains('دفع فاتورة') ||
        (lower.contains('تم سداد') && lower.contains('فاتورة')) ||
        lower.contains('bill payment') ||
        lower.contains('payment of bill');
  }

  static bool _isCashDeposit(String lower) {
    if (_isAtmWithdrawal(lower) || _isBillPayment(lower)) return false;
    return lower.contains('ايداع نقدي') ||
        lower.contains('إيداع نقدي') ||
        lower.contains('cash deposit') ||
        lower.contains('cash deposited');
  }

  static bool _isWalletIncomingTransfer(String lower) {
    if (!lower.contains('تحويل') || !lower.contains('مبلغ')) return false;
    return lower.contains('لمحفظتك') ||
        lower.contains('ل محفظتك') ||
        lower.contains('الى محفظ') ||
        lower.contains('إلى محفظ');
  }

  static bool _isVodafoneWalletCredit(String lower) {
    if (!lower.contains('credited')) return false;
    if (lower.contains('card account') ||
        lower.contains('card no') ||
        lower.contains('your card')) {
      return false;
    }
    return _isVodafoneCashMessage(lower);
  }

  static bool _isEnglishWalletReceive(String lower) {
    if (!lower.contains('received')) return false;
    return _isVodafoneCashMessage(lower) ||
        lower.contains('wallet') ||
        lower.contains('amount of');
  }

  static String? _extractWalletTitle(String text) {
    final lower = text.toLowerCase();
    if (_isEtisalatCashMessage(lower)) return 'Etisalat Cash';
    if (_isOrangeCashMessage(lower)) return 'Orange Cash';
    if (_isWePayMessage(lower)) return 'WE Pay';
    if (_isVodafoneCashMessage(lower)) return 'Vodafone Cash';
    return null;
  }

  static String? _extractCardBillPaymentTitle(String text) {
    return 'Card payment';
  }

  static final _datePatterns = [
    RegExp(r'(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})'),
    RegExp(r'(\d{4})[/.-](\d{1,2})[/.-](\d{1,2})'),
  ];

  /// True when the SMS is a real income or expense transaction.
  static bool looksFinancial(String text, {String? sender}) {
    return parseSms(text, sender: sender) != null;
  }

  static final _invisibleSmsChars = RegExp(
    r'[\u0000\u00AD\u200B-\u200F\u202A-\u202E\u2060\u2066-\u2069\uFEFF\u0640]',
  );

  static final _smsNbsp = RegExp(r'[\u00A0\u202F\u2007]');

  /// Normalize Arabic digits, hidden chars, and common SMS spelling variants.
  static String _normalizeSmsText(String text) {
    var t = text.replaceAll('\r', '').replaceAll('\n', ' ');
    t = t.replaceAll(_invisibleSmsChars, '');
    t = t.replaceAll(_smsNbsp, ' ');
    t = t.replaceAll('\u066C', ',');
    t = t.replaceAll('\u066B', '.');
    t = _westernizeDigits(t);
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    const replacements = <String, String>{
      'إستلام': 'استلام',
      'أستلام': 'استلام',
      'إيداع': 'ايداع',
      'أيداع': 'ايداع',
      'إضافة': 'اضافة',
      'لحظى': 'لحظي',
      'مرجعى': 'مرجعي',
      'فى': 'في',
      'إلى': 'الى',
      'ج.م.': 'جم',
      'ج.م': 'جم',
      'أورنج': 'اورنج',
      'إنستاباي': 'انستاباي',
    };
    for (final entry in replacements.entries) {
      t = t.replaceAll(entry.key, entry.value);
    }
    return t;
  }

  static String _westernizeDigits(String input) {
    final buf = StringBuffer();
    for (final unit in input.codeUnits) {
      if (unit >= 0x0660 && unit <= 0x0669) {
        buf.writeCharCode(0x30 + (unit - 0x0660));
      } else if (unit >= 0x06F0 && unit <= 0x06F9) {
        buf.writeCharCode(0x30 + (unit - 0x06F0));
      } else {
        buf.writeCharCode(unit);
      }
    }
    return buf.toString();
  }

  /// Parse bank/wallet SMS into an entry, or null if not a transaction.
  static ParsedFinancialEntry? parseSms(
    String text, {
    String defaultCurrencyCode = CurrencyConverter.defaultDisplayCode,
    DateTime? smsReceivedAt,
    String? sender,
  }) {
    final normalized = _normalizeSmsText(text);
    if (normalized.isEmpty) return null;
    if (_shouldExcludeSms(normalized, sender: sender)) return null;

    final reference = smsReceivedAt ?? DateTime.now();
    final lower = normalized.toLowerCase();
    var type = _detectTransactionType(lower);
    type ??= _inferTypeFromWalletSender(sender, lower);
    if (type == null) return null;

    final amount = _extractAmount(normalized);
    if (amount == null || amount <= 0) return null;

    final title = resolveSmsTitle(
      parsedTitle: resolveTitleFromBody(normalized),
      body: normalized,
      sender: sender,
    );

    String? expenseCategory;
    String? paidFrom;
    String? incomeSource;
    if (type == FinancialEntryType.expense) {
      final memory = _merchantMemoryLookup(title);
      expenseCategory =
          memory?.category ?? inferExpenseCategory(body: normalized, title: title);
      paidFrom = memory?.paidFrom ??
          inferExpensePaidFrom(body: normalized, sender: sender);
    } else {
      incomeSource = inferIncomeSource(body: normalized, sender: sender);
    }

    return ParsedFinancialEntry(
      title: title,
      amount: amount,
      currencyCode: _extractCurrency(normalized) ?? defaultCurrencyCode,
      date: _extractDate(normalized, reference: reference) ?? reference,
      type: type,
      rawText: normalized,
      expenseCategory: expenseCategory,
      paidFrom: paidFrom,
      incomeSource: incomeSource,
    );
  }

  static MerchantMemoryEntry? _merchantMemoryLookup(String? title) {
    try {
      return getIt<MerchantMemoryStore>().lookup(title);
    } catch (_) {
      return null;
    }
  }

  /// OCR / invoice parsing (broader than SMS).
  static ParsedFinancialEntry parse(
    String text, {
    String defaultCurrencyCode = CurrencyConverter.defaultDisplayCode,
  }) {
    final normalized = text.replaceAll('\r', '').trim();
    final lower = normalized.toLowerCase();

    final type = _detectType(lower);
    final amount = _extractAmount(normalized);
    final currencyCode =
        _extractCurrency(normalized) ?? defaultCurrencyCode;
    final date = _extractDate(normalized, reference: DateTime.now()) ??
        DateTime.now();
    final title = _extractSenderName(normalized) ?? _extractTitle(normalized);

    return ParsedFinancialEntry(
      title: title,
      amount: amount,
      currencyCode: currencyCode,
      date: date,
      type: type,
      rawText: normalized,
    );
  }

  /// Splits pasted text into blocks and parses each financial message.
  static List<ParsedFinancialEntry> parseMultiplePasted(
    String text, {
    String defaultCurrencyCode = CurrencyConverter.defaultDisplayCode,
  }) {
    final chunks = _splitPastedMessageChunks(text);
    final results = <ParsedFinancialEntry>[];
    final seen = <String>{};

    for (final chunk in chunks) {
      final parsed = parseSms(
            chunk,
            defaultCurrencyCode: defaultCurrencyCode,
          ) ??
          () {
            final fallback = parse(
              chunk,
              defaultCurrencyCode: defaultCurrencyCode,
            );
            return fallback.hasUsableData ? fallback : null;
          }();
      if (parsed == null || !parsed.hasUsableData) continue;
      final key = parsed.rawText.trim();
      if (seen.contains(key)) continue;
      seen.add(key);
      results.add(parsed);
    }

    return results;
  }

  /// Blank lines, `---` lines, or common SMS starters split multiple messages.
  static List<String> _splitPastedMessageChunks(String text) {
    final normalized = text.replaceAll('\r', '').trim();
    if (normalized.isEmpty) return [];

    var chunks = normalized
        .split(RegExp(r'\n\s*\n+|\n\s*[-=*]{3,}\s*\n'))
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    if (chunks.length <= 1) {
      final bySmsStart = normalized
          .split(
            RegExp(
              r'(?=\n(?:(?:تم\s)|(?:Dear\s)|(?:تمت\s)|(?:You\s(?:have\s)?(?:received|paid|sent|transferred))))',
              caseSensitive: false,
            ),
          )
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();
      if (bySmsStart.length > 1) chunks = bySmsStart;
    }

    if (chunks.isEmpty) return [normalized];
    return chunks;
  }

  static bool _shouldExcludeSms(String text, {String? sender}) {
    final lower = text.toLowerCase();
    if (_exclusionPhrases.any(lower.contains)) return true;
    if (_isStatementNotification(text)) return true;

    final isTransaction = _isCardPurchase(lower) ||
        _detectTransactionType(lower) != null ||
        _inferTypeFromWalletSender(sender, lower) != null;

    // Marketing / app footers — only when this is not a transaction SMS.
    if (!isTransaction) {
      if (_isBalanceNotification(lower)) return true;
      if (lower.contains('تابع كل مصروفاتك') ||
          lower.contains('أبلكيشن أنا فودافون') ||
          lower.contains('اشترك') ||
          lower.contains('كلم *9*')) {
        return true;
      }
    }
    return false;
  }

  static bool _isStatementNotification(String text) {
    final lower = text.toLowerCase();
    if (_cardStatementNotification.hasMatch(lower)) return true;
    if (lower.contains('statement') &&
        (lower.contains('issued') || lower.contains('ready'))) {
      return true;
    }
    return false;
  }

  /// Card bill paid: "Thank you for sending your payment … credited to your card"
  static bool _isCardBillPayment(String lower) {
    return lower.contains('thank you for sending your payment') ||
        (lower.contains('sending your payment') &&
            lower.contains('credited to your card'));
  }

  static bool _isBalanceNotification(String lower) {
    if (_detectTransactionType(lower) != null) return false;
    if (_vfBalanceNotification.hasMatch(lower)) return true;
    if (_balanceOnlyPhrases.any(lower.contains)) return true;
    if (lower.contains('رقم العملية') &&
        (lower.contains('رصيد') || lower.contains('الحال'))) {
      return true;
    }
    return false;
  }

  static bool _isVodafoneCashIncome(String lower) {
    if (_isBankAccountTransaction(lower)) return false;
    if (lower.contains('تم سحب') ||
        lower.contains('تم خصم') ||
        lower.contains('سحب مبلغ') ||
        lower.contains('خصم مبلغ')) {
      return false;
    }
    return lower.contains('تم استلام') ||
        lower.contains('استلام مبلغ') ||
        lower.contains('استلامك') ||
        lower.contains('وصلك') ||
        lower.contains('تم ايداع') ||
        lower.contains('تم إيداع') ||
        lower.contains('إيداع مبلغ') ||
        lower.contains('ايداع مبلغ') ||
        lower.contains('حوالة واردة') ||
        lower.contains('تم قبول مبلغ') ||
        _isWalletIncomingTransfer(lower);
  }

  static bool _isVodafoneCashExpense(String lower) {
    return lower.contains('تم سحب') ||
        lower.contains('تم خصم') ||
        lower.contains('تم دفع') ||
        lower.contains('تم سداد') ||
        lower.contains('سحب مبلغ') ||
        lower.contains('خصم مبلغ');
  }

  static FinancialEntryType? _inferTypeFromWalletSender(
    String? sender,
    String lower,
  ) {
    if (sender != null &&
        sender.trim().isNotEmpty &&
        isMobileWalletSender(sender)) {
      if (_isVodafoneCashIncome(lower)) return FinancialEntryType.income;
      if (_isVodafoneCashExpense(lower)) return FinancialEntryType.expense;
    }
    if (_isAnyMobileWalletMessage(lower)) {
      if (_isVodafoneCashIncome(lower)) return FinancialEntryType.income;
      if (_isVodafoneCashExpense(lower)) return FinancialEntryType.expense;
    }
    return null;
  }

  static FinancialEntryType? _detectTransactionType(String lower) {
    if (_isCardPurchase(lower)) return FinancialEntryType.expense;
    if (_isInstantOutgoingTransfer(lower)) {
      return FinancialEntryType.expense;
    }
    if (_isAtmWithdrawal(lower)) return FinancialEntryType.expense;
    if (_isBillPayment(lower)) return FinancialEntryType.expense;
    if (_isCashDeposit(lower)) return FinancialEntryType.income;
    if (_isCardBillPayment(lower)) return FinancialEntryType.income;
    if (_isSalaryBonusCredit(lower)) return FinancialEntryType.income;
    if (_isVodafoneCashIncome(lower)) return FinancialEntryType.income;
    if (_isVodafoneCashExpense(lower)) return FinancialEntryType.expense;
    if (_isVodafoneWalletCredit(lower)) return FinancialEntryType.income;
    if (_isWalletIncomingTransfer(lower)) return FinancialEntryType.income;
    if (_isEnglishWalletReceive(lower)) return FinancialEntryType.income;
    if (lower.contains('حوالة واردة') || lower.contains('تم قبول مبلغ')) {
      return FinancialEntryType.income;
    }

    var expenseScore = 0;
    var incomeScore = 0;

    for (final signal in _transactionExpenseSignals) {
      if (_matchesExpenseSignal(lower, signal)) expenseScore++;
    }
    for (final signal in _transactionIncomeSignals) {
      if (_matchesIncomeSignal(lower, signal)) incomeScore++;
    }

    if (expenseScore == 0 && incomeScore == 0) return null;
    if (expenseScore > 0 && incomeScore == 0) {
      return FinancialEntryType.expense;
    }
    if (incomeScore > 0 && expenseScore == 0) {
      return FinancialEntryType.income;
    }

    // Both matched — use explicit Arabic/English anchors.
    const incomeAnchors = [
      'تم استلام',
      'تم تحويل مبلغ',
      'حوالة واردة',
      'تم قبول مبلغ',
      'تم إيداع',
      'تم ايداع',
      'ايداع نقدي',
      'cash deposit',
      'تحويل وارد',
      'إضافة راتب',
      'اضافة راتب',
      'راتب/حافز',
      'credited to your account',
      'has been credited to your account',
      'credit by',
      'has been credit',
    ];
    const expenseAnchors = [
      'تم خصم',
      'تم سحب',
      'تم دفع',
      'تم سداد',
      'سداد فاتورة',
      'تم تحويل لحظي',
      'رقم مرجعي',
      'صراف آلي',
      'atm withdrawal',
      'cash withdrawal',
      'bill payment',
      'debited from',
      'has been debited',
      'withdrawn from',
      'trx on your card',
      'you have a trx',
      'purchase of',
      'debit by',
      'has been debit',
    ];

    final hasIncomeAnchor = incomeAnchors.any(lower.contains);
    final hasExpenseAnchor = expenseAnchors.any(lower.contains);

    if (hasIncomeAnchor && !hasExpenseAnchor) {
      return FinancialEntryType.income;
    }
    if (hasExpenseAnchor && !hasIncomeAnchor) {
      return FinancialEntryType.expense;
    }

    if (incomeScore > expenseScore) return FinancialEntryType.income;
    if (expenseScore > incomeScore) return FinancialEntryType.expense;
    if (_isVodafoneCashIncome(lower)) return FinancialEntryType.income;
    if (_isVodafoneCashExpense(lower)) return FinancialEntryType.expense;

    return null;
  }

  static bool _matchesIncomeSignal(String lower, String signal) {
    if (!lower.contains(signal)) return false;
    return true;
  }

  static bool _matchesExpenseSignal(String lower, String signal) {
    if (!lower.contains(signal)) return false;
    if (signal == 'payment of' && lower.contains('minimum payment')) {
      return false;
    }
    return true;
  }

  static String? _extractCurrency(String text) {
    const patterns = [
      r'EGP',
      r'\bLE\b',
      r'ج\.?\s*م',
      r'جم\b',
      r'جنيه',
      r'جنية',
      r'جميه',
    ];

    for (final pattern in patterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(text)) {
        return CurrencyConverter.defaultDisplayCode;
      }
    }
    return null;
  }

  static FinancialEntryType _detectType(String lower) {
    final expenseScore =
        _expenseKeywords.where((k) => lower.contains(k)).length;
    final incomeScore = _incomeKeywords.where((k) => lower.contains(k)).length;
    if (incomeScore > expenseScore) return FinancialEntryType.income;
    return FinancialEntryType.expense;
  }

  static bool _isCardTrx(String lower) {
    return lower.contains('trx on your card') ||
        lower.contains('you have a trx');
  }

  static bool _isCardPurchase(String lower) {
    return _isCardTrx(lower) ||
        lower.contains('purchase of egp') ||
        lower.contains('purchase of le') ||
        lower.contains('pos purchase');
  }

  static String? _extractCardMerchant(String text) {
    final fromFor = _cardPurchaseAmount.firstMatch(text);
    if (fromFor != null) {
      return _sanitizeMerchantTitle(fromFor.group(1));
    }
    final atMerchant = _purchaseAtMerchant.firstMatch(text);
    if (atMerchant != null) {
      return _sanitizeMerchantTitle(atMerchant.group(2));
    }
    return _extractBankDebitMerchant(text);
  }

  static String? _sanitizeMerchantTitle(String? raw) {
    if (raw == null) return null;
    var name = raw.trim();
    if (name.isEmpty) return null;

    name = name.replaceAll(
      RegExp(r'\s+on\s+\d{1,2}-[A-Za-z]{3}.*$', caseSensitive: false),
      '',
    );
    name = name.replaceAll(
      RegExp(r'\s+at\s+\d{1,2}:\d{2}.*$', caseSensitive: false),
      '',
    );
    name = name.replaceAll(RegExp(r'\s+for\s+egp.*$', caseSensitive: false), '');
    name = name.replaceAll(RegExp(r'\s+\d{1,2}[-/].*$'), '');
    final isAccountOrRef = RegExp(
      r'^(account|bank\s+deposit|bank\s+withdrawal|#)',
      caseSensitive: false,
    ).hasMatch(name);
    if (!isAccountOrRef) {
      name = name.replaceAll(RegExp(r'\s+\d+([.,]\d+)?\s*$'), '');
    }
    name = name.trim();

    if (name.isEmpty) return null;
    return name;
  }

  static bool _isValidSmsTitle(String title) {
    if (title.length < 2 || title.length > 50) return false;
    if (isPhoneOrHotline(title)) return false;

    final lower = title.toLowerCase();
    const blocked = [
      'you have a trx',
      'trx on your',
      'card no',
      'available balance',
      'please call',
      'for more info',
      'xxxx',
      'gmt',
    ];
    if (blocked.any(lower.contains)) return false;
    if (RegExp(r'\d{1,2}-[a-z]{3}', caseSensitive: false).hasMatch(title)) {
      return false;
    }
    if (RegExp(r'^\d+([.,]\d+)?$').hasMatch(title.replaceAll(' ', ''))) {
      return false;
    }
    return true;
  }

  static double? _extractAmount(String text) {
    final lower = text.toLowerCase();

    if (_isCardTrx(lower)) {
      final cardPurchase = _validAmount(
        _cardPurchaseAmount.firstMatch(text),
        group: 2,
      );
      if (cardPurchase != null) return cardPurchase;
      final purchaseOf = _validAmount(_purchaseOfAmount.firstMatch(text));
      if (purchaseOf != null) return purchaseOf;
      final atMerchant = _validAmount(_purchaseAtMerchant.firstMatch(text));
      if (atMerchant != null) return atMerchant;
      final withCurrency = _firstCurrencyAmount(text);
      if (withCurrency != null) return withCurrency;
      return null;
    }

    final fromMerchantFor = _validAmount(
      _cardPurchaseAmount.firstMatch(text),
      group: 2,
    );
    if (fromMerchantFor != null) return fromMerchantFor;

    for (final pattern in [
      _cardBillPaymentAmount,
      _instantTransferOutAmount,
      _billPaymentAmount,
      _atmWithdrawalAmount,
      _atmWithdrawalArabicAmount,
      _cashDepositAmount,
      _bankDebitedAtMerchant,
      _purchaseAtMerchant,
      _purchaseOfAmount,
      _arabicPurchaseAmount,
      _nbeDebitByAmount,
      _bankArabicDepositAmount,
      _bankArabicDebitAmount,
      _salaryBonusAmount,
      _salaryBonusEgpAmount,
      _walletCreditedAmount,
      _englishReceivedAmount,
      _incomingRemittanceAmount,
      _vfTransferInAmount,
      _vfAcceptedAmount,
      _vfDirectTxnAmount,
      _vfReceivedAmount,
      _vfDebitedAmount,
      _txnAmountPhrase,
      _amountAttachedCurrency,
      _bankDebitedAmount,
      _bankCreditedAmount,
      _amountLabeled,
    ]) {
      final value = _validAmount(pattern.firstMatch(text));
      if (value != null) return value;
    }

    final candidates = <double>[];

    void addFromMatches(Iterable<RegExpMatch> matches) {
      for (final match in matches) {
        if (_isBalanceContext(text, match.start)) continue;
        if (_isPhoneNumberContext(text, match.start, match.group(1))) {
          continue;
        }
        if (_isDateFragmentContext(text, match.start)) continue;
        final value = _validAmount(match);
        if (value != null) candidates.add(value);
      }
    }

    addFromMatches(_amountWithCurrency.allMatches(text));
    addFromMatches(_amountBeforeCurrency.allMatches(text));
    addFromMatches(_amountAttachedEgp.allMatches(text));

    if (candidates.isEmpty && _hasCurrencyAmount(text)) {
      addFromMatches(_plainAmount.allMatches(text));
    }

    if (candidates.isEmpty) return null;
    return _pickTransactionAmount(candidates);
  }

  static double? _firstCurrencyAmount(String text) {
    final candidates = <double>[];
    for (final match in [
      ..._amountWithCurrency.allMatches(text),
      ..._amountBeforeCurrency.allMatches(text),
      ..._amountAttachedEgp.allMatches(text),
    ]) {
      if (_isBalanceContext(text, match.start)) continue;
      if (_isPhoneNumberContext(text, match.start, match.group(1))) continue;
      if (_isDateFragmentContext(text, match.start)) continue;
      final value = _validAmount(match);
      if (value != null) candidates.add(value);
    }
    if (candidates.isEmpty) return null;
    return _pickTransactionAmount(candidates);
  }

  static double? _validAmount(RegExpMatch? match, {int group = 1}) {
    if (match == null) return null;
    final raw = match.group(group);
    if (raw == null) return null;
    final value = _parseNumber(raw);
    if (value <= 0 || value > _maxCapturedAmount) return null;
    return value;
  }

  /// Transaction amount is written before the remaining balance in bank SMS.
  static double _pickTransactionAmount(List<double> candidates) {
    if (candidates.length == 1) return candidates.first;
    final unique = candidates.toSet().toList()..sort();
    if (unique.length >= 2) {
      final small = unique.first;
      final large = unique.last;
      if (large >= small * 5 && large >= 1000) return small;
    }
    return candidates.first;
  }

  static bool _hasCurrencyAmount(String text) {
    return _amountWithCurrency.hasMatch(text) ||
        _amountBeforeCurrency.hasMatch(text) ||
        _amountAttachedEgp.hasMatch(text) ||
        _amountLabeled.hasMatch(text);
  }

  static bool _isDateFragmentContext(String text, int matchStart) {
    final start = matchStart > 12 ? matchStart - 12 : 0;
    final end = matchStart + 12 < text.length ? matchStart + 12 : text.length;
    final snippet = text.substring(start, end);
    if (RegExp(r'\d{1,2}-[A-Za-z]{3}').hasMatch(snippet)) return true;
    if (RegExp(r'on\s+\d{1,2}\b', caseSensitive: false).hasMatch(snippet)) {
      return true;
    }
    return false;
  }

  static bool _isPhoneNumberContext(
    String text,
    int matchStart, [
    String? captured,
  ]) {
    if (captured != null) {
      final digits = captured.replaceAll(RegExp(r'[^\d]'), '');
      if (digits.length >= 10) return true;
      if (digits.length >= 4 &&
          digits.length <= 6 &&
          !captured.contains('.') &&
          !captured.contains(',')) {
        final aroundStart = matchStart > 24 ? matchStart - 24 : 0;
        final around = text.substring(aroundStart, matchStart).toLowerCase();
        if (around.contains('call') || around.contains('اتصل')) return true;
      }
    }
    final start = matchStart > 40 ? matchStart - 40 : 0;
    final end = matchStart + 24 < text.length ? matchStart + 24 : text.length;
    final snippet = text.substring(start, end).toLowerCase();
    const nearPhone = [
      'please call',
      'for more info',
      'for more information',
      'اتصل ب',
      'للمزيد',
      'من رقم',
      'على رقم',
      'phone',
    ];
    if (!nearPhone.any(snippet.contains)) return false;
    final digits = captured?.replaceAll(RegExp(r'[^\d]'), '') ?? '';
    return digits.length >= 8 || snippet.contains('call') || snippet.contains('اتصل');
  }

  static bool _isBalanceContext(String text, int matchStart) {
    final start = matchStart > 70 ? matchStart - 70 : 0;
    final end = matchStart + 40 < text.length ? matchStart + 40 : text.length;
    final snippet = text.substring(start, end).toLowerCase();
    const nearBalance = [
      'available balance is',
      'available balance',
      'your available balance',
      'current balance is',
      'avl bal',
      'avail bal',
      'available bal',
      'remaining balance',
      'رصيدك الحالي',
      'رصيد حسابك الحالي',
      'الرصيد المتاح',
      'رصيد الحساب',
      'رصيد بعد',
      'المتاح',
    ];
    return nearBalance.any(snippet.contains);
  }

  static String? _extractSenderName(String text) {
    final match = _registeredSenderName.firstMatch(text);
    if (match == null) return null;
    var name = match.group(1)?.trim();
    if (name == null || name.isEmpty) return null;
    // Stop before balance / date if the regex captured too much.
    name = name.split(RegExp(r'\s+رصيد|\s+تاريخ')).first.trim();
    if (name.isEmpty || !_isValidSmsTitle(name)) return null;
    return name;
  }

  static double _parseNumber(String raw) {
    final trimmed = raw.trim();
    if (RegExp(r'^\d{1,6},\d{2}$').hasMatch(trimmed)) {
      return double.tryParse(trimmed.replaceFirst(',', '.')) ?? 0;
    }
    final cleaned = trimmed.replaceAll(RegExp(r'[\s,]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  static const _monthNames = <String, int>{
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  static DateTime? _extractDate(String text, {required DateTime reference}) {
    final cardDt = _cardPurchaseDateTime.firstMatch(text);
    if (cardDt != null) {
      try {
        final day = int.parse(cardDt.group(1)!);
        final month = _monthNames[cardDt.group(2)!.toLowerCase()];
        final yearRaw = cardDt.group(3);
        final hour = int.parse(cardDt.group(4)!);
        final minute = int.parse(cardDt.group(5)!);
        if (month != null) {
          return _resolveTransactionDateTime(
            day: day,
            month: month,
            year: yearRaw == null
                ? null
                : (int.parse(yearRaw) < 100
                    ? 2000 + int.parse(yearRaw)
                    : int.parse(yearRaw)),
            hour: hour,
            minute: minute,
            reference: reference,
          );
        }
      } catch (_) {
        // fall through
      }
    }

    final bankDt = _bankOperationDateTime.firstMatch(text);
    if (bankDt != null) {
      try {
        final day = int.parse(bankDt.group(1)!);
        final month = int.parse(bankDt.group(2)!);
        final year = int.parse(bankDt.group(3)!);
        final hour = int.parse(bankDt.group(4)!);
        final minute = int.parse(bankDt.group(5)!);
        final fullYear = year < 100 ? 2000 + year : year;
        return DateTime(fullYear, month, day, hour, minute);
      } catch (_) {
        // fall through
      }
    }

    final inlineDt = _arabicInlineDateTime.firstMatch(text);
    if (inlineDt != null) {
      try {
        final day = int.parse(inlineDt.group(1)!);
        final month = int.parse(inlineDt.group(2)!);
        final year = int.parse(inlineDt.group(3)!);
        final hour = int.parse(inlineDt.group(4)!);
        final minute = int.parse(inlineDt.group(5)!);
        final fullYear = year < 100 ? 2000 + year : year;
        return DateTime(fullYear, month, day, hour, minute);
      } catch (_) {
        // fall through
      }
    }

    final vf = _vfOperationDateTime.firstMatch(text);
    if (vf != null) {
      final parsed = _parseVfOperationDate(vf, reference);
      if (parsed != null) return parsed;
    }

    for (final pattern in _datePatterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;

      try {
        if (match.groupCount == 3) {
          final a = int.parse(match.group(1)!);
          final b = int.parse(match.group(2)!);
          final c = int.parse(match.group(3)!);
          final parsed = _parseDateTriplet(a, b, c, reference);
          if (parsed != null) return parsed;
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static DateTime? _parseVfOperationDate(RegExpMatch vf, DateTime reference) {
    try {
      final hour = int.parse(vf.group(1)!);
      final minute = int.parse(vf.group(2)!);
      final a = int.parse(vf.group(3)!);
      final b = int.parse(vf.group(4)!);
      final c = int.parse(vf.group(5)!);
      return _parseDateTriplet(a, b, c, reference, hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parseDateTriplet(
    int a,
    int b,
    int c,
    DateTime reference, {
    int hour = 0,
    int minute = 0,
  }) {
    if (a > 99) {
      return DateTime(a, b, c.clamp(1, 31), hour, minute);
    }

    final candidates = <DateTime>[];

    if (c >= 100) {
      candidates.add(DateTime(c, b, a.clamp(1, 31), hour, minute));
    } else {
      if (a >= 1 && a <= 31 && b >= 1 && b <= 12) {
        candidates.add(
          _resolveTransactionDateTime(
            day: a,
            month: b,
            year: _resolveCenturyYear(c, reference),
            hour: hour,
            minute: minute,
            reference: reference,
          ),
        );
      }
      if (a >= 20 && a <= 99 && b >= 1 && b <= 12 && c >= 1 && c <= 31) {
        candidates.add(
          DateTime(
            _resolveCenturyYear(a, reference),
            b,
            c.clamp(1, 31),
            hour,
            minute,
          ),
        );
      }
    }

    return _pickClosestDate(candidates, reference);
  }

  static int _resolveCenturyYear(int twoDigitYear, DateTime reference) {
    final y2000 = 2000 + twoDigitYear;
    final y1900 = 1900 + twoDigitYear;
    final d2000 = (y2000 - reference.year).abs();
    final d1900 = (y1900 - reference.year).abs();
    var year = d2000 <= d1900 ? y2000 : y1900;
    if (year > reference.year + 1) year -= 100;
    if (year < reference.year - 10) year += 100;
    return year;
  }

  static DateTime _resolveTransactionDateTime({
    required int day,
    required int month,
    int? year,
    int hour = 0,
    int minute = 0,
    required DateTime reference,
  }) {
    year ??= reference.year;
    DateTime at(int y) {
      final lastDay = DateTime(y, month + 1, 0).day;
      final safeDay = day.clamp(1, lastDay);
      return DateTime(y, month, safeDay, hour, minute);
    }

    var dt = at(year);
    if (dt.isAfter(reference.add(const Duration(days: 3)))) {
      dt = at(year - 1);
    }
    if (dt.isBefore(reference.subtract(const Duration(days: 400)))) {
      dt = at(year + 1);
    }
    return dt;
  }

  static DateTime? _pickClosestDate(
    List<DateTime> candidates,
    DateTime reference,
  ) {
    if (candidates.isEmpty) return null;

    DateTime? best;
    int? bestDiffDays;

    for (final candidate in candidates) {
      final diffDays = candidate.difference(reference).inDays.abs();
      if (diffDays > 800) continue;
      if (bestDiffDays == null || diffDays < bestDiffDays) {
        best = candidate;
        bestDiffDays = diffDays;
      }
    }

    return best ?? candidates.first;
  }

  static String? _extractTitle(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    for (final line in lines) {
      if (_looksLikeTitleLine(line)) return _cleanTitle(line);
    }

    if (lines.isNotEmpty) return _cleanTitle(lines.first);
    return null;
  }

  static bool _looksLikeTitleLine(String line) {
    final lower = line.toLowerCase();
    if (lower.contains('رصيدك') ||
        lower.contains('تاريخ العملية') ||
        lower.contains('رقم العملية') ||
        lower.contains('http')) {
      return false;
    }
    if (_amountWithCurrency.hasMatch(line)) return false;
    if (_plainAmount.hasMatch(line) && line.length < 24) return false;
    if (lower.contains('total') ||
        lower.contains('المجموع') ||
        lower.contains('اجمالي')) {
      return true;
    }
    if (line.length >= 3 && line.length <= 80) return true;
    return false;
  }

  static String _cleanTitle(String line) {
    return line
        .replaceAll(
          RegExp(
            r'^(merchant|from|at|من|لدى)\s*:?\s*',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }
}
