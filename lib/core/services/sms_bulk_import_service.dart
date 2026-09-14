import 'package:imrpo/core/models/parsed_financial_entry.dart';
import 'package:imrpo/core/services/merchant_memory_store.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/services/sms_import_service.dart';
import 'package:imrpo/core/services/transaction_text_parser.dart';
import 'package:imrpo/core/services/sms_imported_registry.dart';
import 'package:imrpo/features/expenses_tab/domain/usecases/add_expense_usecase.dart';
import 'package:imrpo/features/incomes_tab/domain/usecases/add_income_usecase.dart';

class SmsBulkImportResult {
  final int expenseCount;
  final int incomeCount;
  final int failed;
  final int skipped;

  const SmsBulkImportResult({
    this.expenseCount = 0,
    this.incomeCount = 0,
    this.failed = 0,
    this.skipped = 0,
  });

  int get added => expenseCount + incomeCount;
  bool get hasAny => added > 0;
}

class SmsBulkImportService {
  static const _expenseCategory = 'Bills';
  static const _incomeCategory = 'Other';

  final AddExpenseUsecase _addExpense;
  final AddIncomeUsecase _addIncome;
  final SmsImportedRegistry _importedRegistry;

  SmsBulkImportService({
    required AddExpenseUsecase addExpenseUsecase,
    required AddIncomeUsecase addIncomeUsecase,
    required SmsImportedRegistry importedRegistry,
  })  : _addExpense = addExpenseUsecase,
        _addIncome = addIncomeUsecase,
        _importedRegistry = importedRegistry;

  bool hasValidAmount(SmsMessageItem item) {
    final base = item.parsed.amountInBase;
    return base != null && base > 0;
  }

  bool canImport(SmsMessageItem item) {
    if (_importedRegistry.isImported(item.id)) return false;
    return hasValidAmount(item);
  }

  bool canReimport(SmsMessageItem item) {
    return _importedRegistry.isImported(item.id) && hasValidAmount(item);
  }

  Future<SmsBulkImportResult> importAll(
    List<SmsMessageItem> items, {
    bool reimport = false,
    String? expenseCategory,
    String? incomeSource,
    String? expensePaidFrom,
  }) async {
    return _import(
      items,
      reimport: reimport,
      expenseCategory: expenseCategory,
      incomeSource: incomeSource,
      expensePaidFrom: expensePaidFrom,
    );
  }

  Future<SmsBulkImportResult> importParsedEntries(
    List<ParsedFinancialEntry> entries, {
    String? expenseCategory,
    String? incomeSource,
    String? expensePaidFrom,
  }) async {
    final resolvedExpenseCategory = expenseCategory ?? _expenseCategory;
    final resolvedIncomeSource = incomeSource ?? _incomeCategory;
    var expenseCount = 0;
    var incomeCount = 0;
    var failed = 0;

    for (final entry in entries) {
      final baseAmount = entry.amountInBase;
      if (baseAmount == null || baseAmount <= 0) {
        failed++;
        continue;
      }

      final title = _resolveParsedTitle(entry);
      final date = entry.date ?? DateTime.now();

      if (entry.type == FinancialEntryType.expense) {
        final category = entry.expenseCategory ?? resolvedExpenseCategory;
        final paidFrom = entry.paidFrom ?? expensePaidFrom;
        final result = await _addExpense(
          title,
          category,
          baseAmount,
          date,
          incomeSource: paidFrom,
        );
        result.fold((_) => failed++, (_) {
          expenseCount++;
          getIt<MerchantMemoryStore>().remember(
            title: title,
            category: category,
            paidFrom: paidFrom,
          );
        });
      } else {
        final result = await _addIncome(
          title,
          baseAmount,
          date,
          entry.incomeSource ?? resolvedIncomeSource,
        );
        result.fold((_) => failed++, (_) => incomeCount++);
      }
    }

    return SmsBulkImportResult(
      expenseCount: expenseCount,
      incomeCount: incomeCount,
      failed: failed,
    );
  }

  String _resolveParsedTitle(ParsedFinancialEntry entry) {
    final t = entry.title?.trim();
    if (t != null && t.isNotEmpty) return t;
    return entry.type == FinancialEntryType.expense
        ? 'Bank expense'
        : 'Bank income';
  }

  Future<SmsBulkImportResult> _import(
    List<SmsMessageItem> items, {
    bool reimport = false,
    String? expenseCategory,
    String? incomeSource,
    String? expensePaidFrom,
  }) async {
    final resolvedExpenseCategory = expenseCategory ?? _expenseCategory;
    final resolvedIncomeSource = incomeSource ?? _incomeCategory;
    var expenseCount = 0;
    var incomeCount = 0;
    var failed = 0;
    var skipped = 0;
    final importedIds = <String>[];

    for (final item in items) {
      final alreadyImported = _importedRegistry.isImported(item.id);
      if (alreadyImported && !reimport) {
        skipped++;
        continue;
      }
      if (!hasValidAmount(item)) {
        failed++;
        continue;
      }

      final baseAmount = item.parsed.amountInBase!;
      final title = _resolveTitle(item);
      final date = item.parsed.date ?? item.date;

      if (item.parsed.type == FinancialEntryType.expense) {
        final category =
            item.parsed.expenseCategory ?? resolvedExpenseCategory;
        final paidFrom = item.parsed.paidFrom ?? expensePaidFrom;
        final result = await _addExpense(
          title,
          category,
          baseAmount,
          date,
          incomeSource: paidFrom,
        );
        result.fold((_) => failed++, (_) {
          expenseCount++;
          importedIds.add(item.id);
          getIt<MerchantMemoryStore>().remember(
            title: title,
            category: category,
            paidFrom: paidFrom,
          );
        });
      } else {
        final result = await _addIncome(
          title,
          baseAmount,
          date,
          item.parsed.incomeSource ?? resolvedIncomeSource,
        );
        result.fold((_) => failed++, (_) {
          incomeCount++;
          importedIds.add(item.id);
        });
      }
    }

    await _importedRegistry.markImportedMany(importedIds);

    return SmsBulkImportResult(
      expenseCount: expenseCount,
      incomeCount: incomeCount,
      failed: failed,
      skipped: skipped,
    );
  }

  String _resolveTitle(SmsMessageItem item) {
    return TransactionTextParser.resolveSmsTitle(
          parsedTitle: item.parsed.title,
          body: item.body,
          sender: item.header,
        ) ??
        (item.parsed.type == FinancialEntryType.expense
            ? 'Bank expense'
            : 'Bank income');
  }
}
