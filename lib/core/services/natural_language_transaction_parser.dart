import 'package:imrpo/core/models/parsed_financial_entry.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/services/payment_methods_store.dart';
import 'package:imrpo/core/services/transaction_text_parser.dart';
import 'package:imrpo/features/expenses_tab/domain/expense_categories.dart';

/// Turns casual English/Arabic speech into one or more transactions.
///
/// Examples: `coffee 50 yesterday`, `راتب 8000`, `uber 30 and lunch 80`.
class NaturalLanguageTransactionParser {
  NaturalLanguageTransactionParser._();

  static const _amountNumber =
      r'([0-9]{1,9}(?:[, ][0-9]{3})*(?:[.,][0-9]{1,2})?)';

  static final _amountToken = RegExp(
    r'(?:(?:EGP|LE|USD|EUR|GBP|SAR|ج\.?\s*م|جم\b|جنيه|جنية|\$|€|£)\s*)?'
    '$_amountNumber'
    r'(?:\s*(?:EGP|LE|USD|EUR|GBP|SAR|ج\.?\s*م|جم\b|جنيه|جنية))?',
    caseSensitive: false,
  );

  static const _incomeKeywords = [
    'salary',
    'paycheck',
    'payroll',
    'bonus',
    'freelance',
    'invoice paid',
    'got paid',
    'received',
    'earned',
    'income',
    'deposit',
    'refund',
    'راتب',
    'مرتب',
    'حافز',
    'دخل',
    'قبضت',
    'استلمت',
    'كسبت',
    'فواتير',
    'فريلانس',
    'مرتجع',
  ];

  static const _expenseKeywords = [
    'spent',
    'bought',
    'paid',
    'pay',
    'purchase',
    'bill',
    'cost',
    'اشتريت',
    'دفعت',
    'صرفت',
    'فاتورة',
  ];

  static const _fillerWords = {
    'a',
    'an',
    'the',
    'on',
    'for',
    'of',
    'at',
    'to',
    'from',
    'with',
    'my',
    'i',
    'just',
    'about',
    'around',
    'like',
    'and',
    'then',
    'spent',
    'spend',
    'bought',
    'buy',
    'paid',
    'pay',
    'got',
    'get',
    'added',
    'add',
    'amount',
    'cost',
    'costs',
    'was',
    'is',
    'it',
    'this',
    'that',
    'egp',
    'le',
    'usd',
    'eur',
    'اشتريت',
    'دفعت',
    'صرفت',
    'على',
    'علي',
    'من',
    'في',
    'فى',
    'بـ',
    'ب',
    'بمبلغ',
    'مبلغ',
    'و',
    'يا',
    'انا',
    'أنا',
    'النهاردة',
    'النهارده',
    'اليوم',
    'امبارح',
    'مبارح',
    'أمس',
    'امس',
    'today',
    'yesterday',
    'tonight',
    'morning',
    'evening',
    'last',
    'week',
    'night',
  };

  static const _categoryKeywords = <String, List<String>>{
    'Food': [
      'coffee',
      'cafe',
      'café',
      'starbucks',
      'lunch',
      'dinner',
      'breakfast',
      'brunch',
      'food',
      'eat',
      'eating',
      'grocery',
      'groceries',
      'supermarket',
      'restaurant',
      'pizza',
      'burger',
      'kfc',
      'mcdonald',
      'talabat',
      'snack',
      'drink',
      'juice',
      'shawarma',
      'koshary',
      'قهوة',
      'قهوه',
      'أكل',
      'اكل',
      'غدا',
      'غداً',
      'غداء',
      'عشا',
      'عشاء',
      'فطار',
      'فطور',
      'مطعم',
      'سوبر',
      'سوبرماركت',
      'تالاباط',
      'طلب',
      'وجبة',
      'وجبه',
      'عصير',
      'شاورما',
      'كشري',
    ],
    'Transport': [
      'uber',
      'careem',
      'taxi',
      'bus',
      'metro',
      'fuel',
      'petrol',
      'gas',
      'diesel',
      'parking',
      'fare',
      'ride',
      'بنزين',
      'سولار',
      'أوبر',
      'اوبر',
      'تاكسي',
      'مترو',
      'مواصلات',
      'كريم',
      'كرييم',
      'موقف',
      'microbus',
      'ميكروباص',
    ],
    'Rent': [
      'rent',
      'rental',
      'إيجار',
      'ايجار',
      'ايجاره',
    ],
    'Bills': [
      'bill',
      'electric',
      'electricity',
      'water',
      'internet',
      'wifi',
      'wi-fi',
      'phone',
      'utility',
      'فاتورة',
      'فاتوره',
      'كهربا',
      'كهرباء',
      'مياه',
      'ميه',
      'نت',
      'انترنت',
      'إنترنت',
      'غاز',
    ],
    'Shopping': [
      'shop',
      'shopping',
      'mall',
      'amazon',
      'noon',
      'clothes',
      'clothing',
      'shoes',
      'store',
      'ملابس',
      'تسوق',
      'أمازون',
      'امازون',
      'نون',
      'سوق',
      'حذاء',
    ],
  };

  static const _paymentKeywords = <String, String>{
    'visa': 'Visa Card',
    'card': 'Visa Card',
    'credit': 'Visa Card',
    'فيزا': 'Visa Card',
    'فيزه': 'Visa Card',
    'بطاقة': 'Visa Card',
    'كارد': 'Visa Card',
    'cash': 'Cash',
    'كاش': 'Cash',
    'نقدي': 'Cash',
    'نقدى': 'Cash',
    'vodafone': 'Vodafone Cash',
    'vf cash': 'Vodafone Cash',
    'vfcash': 'Vodafone Cash',
    'فودافون': 'Vodafone Cash',
    'instapay': 'InstaPay',
    'insta pay': 'InstaPay',
    'انستاباي': 'InstaPay',
    'إنستاباي': 'InstaPay',
    'bank': 'Bank transfer',
    'transfer': 'Bank transfer',
    'تحويل': 'Bank transfer',
    'بنك': 'Bank transfer',
  };

  static const _incomeSourceKeywords = <String, String>{
    'salary': 'Salary',
    'paycheck': 'Salary',
    'payroll': 'Salary',
    'راتب': 'Salary',
    'مرتب': 'Salary',
    'freelance': 'Freelance',
    'فريلانس': 'Freelance',
    'bonus': 'Salary',
    'حافز': 'Salary',
    'rent': 'Rents',
    'rents': 'Rents',
    'ايجار': 'Rents',
    'إيجار': 'Rents',
    'business': 'Business',
    'بيزنس': 'Business',
    'investment': 'Investment',
    'استثمار': 'Investment',
  };

  /// Parse typed or spoken text. Falls back to bank-SMS parsing when the
  /// text looks like a wallet/bank notification.
  static List<ParsedFinancialEntry> parse(
    String text, {
    String defaultCurrencyCode = CurrencyConverter.defaultDisplayCode,
    DateTime? now,
    FinancialEntryType? preferredType,
  }) {
    final reference = now ?? DateTime.now();
    final normalized = _normalize(text);
    if (normalized.isEmpty) return const [];

    final sms = TransactionTextParser.parseSms(
      text,
      defaultCurrencyCode: defaultCurrencyCode,
      smsReceivedAt: reference,
    );
    if (sms != null && sms.amount != null && sms.amount! > 0) {
      return [_withInferredMeta(sms, preferredType: preferredType)];
    }

    final pasted = TransactionTextParser.parseMultiplePasted(
      text,
      defaultCurrencyCode: defaultCurrencyCode,
    );
    if (pasted.length > 1) {
      return pasted
          .map((e) => _withInferredMeta(e, preferredType: preferredType))
          .toList();
    }

    return _parseNatural(
      normalized,
      defaultCurrencyCode: defaultCurrencyCode,
      reference: reference,
      preferredType: preferredType,
    );
  }

  static List<ParsedFinancialEntry> _parseNatural(
    String text, {
    required String defaultCurrencyCode,
    required DateTime reference,
    FinancialEntryType? preferredType,
  }) {
    final globalDate = _extractRelativeDate(text, reference) ?? reference;
    final globalPayment = _extractPaymentMethod(text);
    final globalIncomeSource = _extractIncomeSource(text);

    final hits = _amountHits(text);
    if (hits.isEmpty) return const [];

    final drafts = <ParsedFinancialEntry>[];
    for (var i = 0; i < hits.length; i++) {
      final hit = hits[i];
      final titleStart = i == 0 ? 0 : hits[i - 1].end;
      var leftover = '';
      if (i == hits.length - 1 && hit.end < text.length) {
        leftover = text.substring(hit.end);
      }
      final rawTitle = '${text.substring(titleStart, hit.start)} $leftover';
      final title = _cleanTitle(rawTitle);
      final segment = text.substring(titleStart, hit.end) + leftover;
      final type = _detectType(segment, preferredType: preferredType);
      final currency = hit.currency ??
          _extractCurrency(segment) ??
          defaultCurrencyCode;

      drafts.add(
        ParsedFinancialEntry(
          title: title.isEmpty ? null : title,
          amount: hit.value,
          currencyCode: currency,
          date: globalDate,
          type: type,
          rawText: segment.trim(),
          expenseCategory: type == FinancialEntryType.expense
              ? _inferExpenseCategory(segment, title)
              : null,
          paidFrom: type == FinancialEntryType.expense
              ? (globalPayment ??
                  _extractPaymentMethod(segment) ??
                  PaymentMethodsStore.defaultPresets.first)
              : null,
          incomeSource: type == FinancialEntryType.income
              ? (globalIncomeSource ??
                  _extractIncomeSource(segment) ??
                  _defaultIncomeSource(title, segment))
              : null,
        ),
      );
    }
    return drafts;
  }

  static ParsedFinancialEntry _withInferredMeta(
    ParsedFinancialEntry entry, {
    FinancialEntryType? preferredType,
  }) {
    final type = preferredType ?? entry.type;
    final title = entry.title;
    return entry.copyWith(
      type: type,
      expenseCategory: type == FinancialEntryType.expense
          ? (entry.expenseCategory ??
              _inferExpenseCategory(entry.rawText, title))
          : null,
      paidFrom: type == FinancialEntryType.expense
          ? (entry.paidFrom ??
              _extractPaymentMethod(entry.rawText) ??
              PaymentMethodsStore.defaultPresets.first)
          : null,
      incomeSource: type == FinancialEntryType.income
          ? (entry.incomeSource ??
              _extractIncomeSource(entry.rawText) ??
              _defaultIncomeSource(title, entry.rawText))
          : null,
    );
  }

  static String _normalize(String text) {
    var t = text.replaceAll('\r', ' ').replaceAll('\n', ', ');
    t = t.replaceAll(RegExp(r'[\u0000\u00AD\u200B-\u200F\uFEFF]'), '');
    t = t.replaceAll('\u066C', ',');
    t = t.replaceAll('\u066B', '.');
    t = _westernizeDigits(t);
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
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

  static List<_AmountHit> _amountHits(String text) {
    final hits = <_AmountHit>[];
    for (final match in _amountToken.allMatches(text)) {
      if (_isDateOrPhoneContext(text, match.start, match.group(1))) continue;
      final raw = match.group(1);
      if (raw == null) continue;
      final value = _parseNumber(raw);
      if (value <= 0 || value > 99_999_999) continue;
      hits.add(
        _AmountHit(
          value: value,
          currency: _extractCurrency(match.group(0) ?? ''),
          start: match.start,
          end: match.end,
        ),
      );
    }
    return hits;
  }

  static bool _isDateOrPhoneContext(String text, int start, String? captured) {
    final digits = captured?.replaceAll(RegExp(r'[^\d]'), '') ?? '';
    if (digits.length >= 10) return true;
    final aroundStart = start > 8 ? start - 8 : 0;
    final aroundEnd =
        start + 12 < text.length ? start + 12 : text.length;
    final snippet = text.substring(aroundStart, aroundEnd);
    if (RegExp(r'\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4}').hasMatch(snippet)) {
      return true;
    }
    return false;
  }

  static double _parseNumber(String raw) {
    final trimmed = raw.trim();
    if (RegExp(r'^\d{1,6},\d{2}$').hasMatch(trimmed)) {
      return double.tryParse(trimmed.replaceFirst(',', '.')) ?? 0;
    }
    final cleaned = trimmed.replaceAll(RegExp(r'[\s,]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  static String? _extractCurrency(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'usd|\$').hasMatch(lower)) return 'USD';
    if (RegExp(r'eur|€').hasMatch(lower)) return 'EUR';
    if (RegExp(r'egp|\ble\b|ج\.?\s*م|جم\b|جنيه|جنية').hasMatch(lower)) {
      return CurrencyConverter.defaultDisplayCode;
    }
    return null;
  }

  static FinancialEntryType _detectType(
    String text, {
    FinancialEntryType? preferredType,
  }) {
    final lower = text.toLowerCase();
    final incomeHits = _incomeKeywords.where(lower.contains).length;
    final expenseHits = _expenseKeywords.where(lower.contains).length;
    if (incomeHits > expenseHits) return FinancialEntryType.income;
    if (expenseHits > incomeHits) return FinancialEntryType.expense;
    if (preferredType != null) return preferredType;
    return FinancialEntryType.expense;
  }

  static String _inferExpenseCategory(String text, String? title) {
    final haystack = '${text.toLowerCase()} ${title ?? ''}'.toLowerCase();
    var best = ExpenseCategories.other;
    var bestScore = 0;
    for (final entry in _categoryKeywords.entries) {
      final score = entry.value.where(haystack.contains).length;
      if (score > bestScore) {
        best = entry.key;
        bestScore = score;
      }
    }
    return bestScore > 0 ? best : ExpenseCategories.other;
  }

  static String? _extractPaymentMethod(String text) {
    final lower = text.toLowerCase();
    for (final entry in _paymentKeywords.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static String? _extractIncomeSource(String text) {
    final lower = text.toLowerCase();
    for (final entry in _incomeSourceKeywords.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static String _defaultIncomeSource(String? title, String text) {
    return _extractIncomeSource('$title $text') ??
        'Salary';
  }

  static DateTime? _extractRelativeDate(String text, DateTime reference) {
    final lower = text.toLowerCase();
    if (RegExp(
      r'\b(yesterday|last night)\b|امبارح|مبارح|أمس|امس',
    ).hasMatch(lower)) {
      final d = reference.subtract(const Duration(days: 1));
      return DateTime(d.year, d.month, d.day);
    }
    if (RegExp(
      r'\b(day before yesterday|2 days ago)\b|أول امبارح|اول امبارح|أول أمس',
    ).hasMatch(lower)) {
      final d = reference.subtract(const Duration(days: 2));
      return DateTime(d.year, d.month, d.day);
    }
    if (RegExp(
      r'\b(last week|a week ago)\b|الأسبوع اللي فات|الاسبوع اللي فات',
    ).hasMatch(lower)) {
      return reference.subtract(const Duration(days: 7));
    }
    if (RegExp(
      r'\b(today|tonight)\b|النهارده|النهاردة|اليوم',
    ).hasMatch(lower)) {
      return DateTime(reference.year, reference.month, reference.day);
    }
    return null;
  }

  static String _cleanTitle(String raw) {
    var t = raw.trim();
    t = t.replaceAll(RegExp(r'[,;|/]+'), ' ');
    t = t.replaceAll(RegExp(r'\b(and|&)\b', caseSensitive: false), ' ');
    t = t.replaceAll(RegExp(r'\s+و\s+'), ' ');
    final words = t
        .split(RegExp(r'\s+'))
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .where((w) => !_isFiller(w))
        .where((w) => !_amountToken.hasMatch(w))
        .toList();
    var title = words.join(' ').trim();
    title = title.replaceAll(RegExp(r'^[\-–—,.:]+|[\-–—,.:]+$'), '').trim();
    if (title.length > 48) title = title.substring(0, 48).trim();
    return title;
  }

  static bool _isFiller(String word) {
    final lower = word.toLowerCase().replaceAll(RegExp(r'[^\w\u0600-\u06FF]'), '');
    if (lower.isEmpty) return true;
    if (_fillerWords.contains(lower)) return true;
    if (_paymentKeywords.containsKey(lower)) return true;
    if (_incomeSourceKeywords.containsKey(lower)) return false;
    return false;
  }
}

class _AmountHit {
  final double value;
  final String? currency;
  final int start;
  final int end;

  const _AmountHit({
    required this.value,
    required this.currency,
    required this.start,
    required this.end,
  });
}
