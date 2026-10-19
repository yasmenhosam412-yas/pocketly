/// User-defined one-tap financial template.
/// amountBase is stored in the app's base currency.
class ExpenseShortcut {
  final String id;

  /// Text displayed on the saved shortcut chip.
  final String displayLabel;

  /// Original text entered by the user, e.g. "قهوة 80".
  final String originalText;

  /// Saved transaction title.
  final String expenseTitle;

  /// Expense category or income category/source.
  final String category;

  /// Transaction type: "expense" or "income".
  final String type;

  /// Payment method for expenses, e.g. Cash or Card.
  final String? paidFrom;

  /// Income source for income transactions.
  final String? incomeSource;

  /// Amount stored in app base currency.
  final double amountBase;

  const ExpenseShortcut({
    required this.id,
    required this.displayLabel,
    required this.expenseTitle,
    required this.category,
    required this.amountBase,
    this.originalText = '',
    this.type = 'expense',
    this.paidFrom,
    this.incomeSource,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayLabel': displayLabel,
    'originalText': originalText,
    'expenseTitle': expenseTitle,
    'category': category,
    'type': type,
    'paidFrom': paidFrom,
    'incomeSource': incomeSource,
    'amountBase': amountBase,
  };

  factory ExpenseShortcut.fromJson(Map<String, dynamic> json) {
    return ExpenseShortcut(
      id: json['id'] as String,
      displayLabel:
          json['displayLabel'] as String? ??
          json['expenseTitle'] as String? ??
          json['title'] as String? ??
          '',
      originalText: json['originalText'] as String? ?? '',
      expenseTitle:
          json['expenseTitle'] as String? ?? json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'Other',
      type: json['type'] as String? ?? 'expense',
      paidFrom: json['paidFrom'] as String?,
      incomeSource: json['incomeSource'] as String?,
      amountBase: (json['amountBase'] as num?)?.toDouble() ?? 0.0,
    );
  }

  ExpenseShortcut copyWith({
    String? id,
    String? displayLabel,
    String? originalText,
    String? expenseTitle,
    String? category,
    String? type,
    String? paidFrom,
    String? incomeSource,
    double? amountBase,
  }) {
    return ExpenseShortcut(
      id: id ?? this.id,
      displayLabel: displayLabel ?? this.displayLabel,
      originalText: originalText ?? this.originalText,
      expenseTitle: expenseTitle ?? this.expenseTitle,
      category: category ?? this.category,
      type: type ?? this.type,
      paidFrom: paidFrom ?? this.paidFrom,
      incomeSource: incomeSource ?? this.incomeSource,
      amountBase: amountBase ?? this.amountBase,
    );
  }
}
