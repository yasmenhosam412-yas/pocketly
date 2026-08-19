import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/models/parsed_financial_entry.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/services/sms_bulk_import_service.dart';
import 'package:imrpo/core/widgets/app_toast.dart';
import 'package:imrpo/core/widgets/show_app_bottom_sheet.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/features/expenses_tab/presentation/widgets/add_expense_sheet.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/features/incomes_tab/presentation/widgets/add_income_sheet.dart';
import 'package:imrpo/features/smart_import/presentation/widgets/smart_import_bulk_category_sheet.dart';
import 'package:imrpo/l10n/app_localizations.dart';

bool isSmartImportSheetSuccess(String? result) =>
    result == 'added' || result == 'updated';

String smartImportFallbackTitle(AppLocalizations l10n, String? title) {
  final trimmed = title?.trim();
  if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  return l10n.smartImportDefaultBillTitle;
}

void reloadTransactionTabs(BuildContext context) {
  context.read<ExpensesTabBloc>().add(const LoadExpensesEvent(force: true));
  context.read<IncomesTabBloc>().add(const LoadIncomesEvent(force: true));
}

void showSmartImportSnack(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  if (!context.mounted) return;
  AppToast.show(context, message, error: isError);
}

void showSmartImportBulkFeedback(
  BuildContext context,
  SmsBulkImportResult result, {
  bool includeSkipped = false,
}) {
  final l10n = AppLocalizations.of(context)!;
  if (result.hasAny) {
    showSmartImportSnack(
      context,
      l10n.smartImportBulkResult(result.incomeCount, result.expenseCount),
    );
  } else {
    showSmartImportSnack(
      context,
      l10n.smartImportBulkNothingToAdd,
      isError: true,
    );
  }
  if (result.failed > 0) {
    showSmartImportSnack(
      context,
      l10n.smartImportBulkPartialFail(result.failed),
      isError: true,
    );
  }
  if (includeSkipped && result.skipped > 0) {
    showSmartImportSnack(
      context,
      l10n.smartImportSmsSkippedDuplicate(result.skipped),
    );
  }
}

Future<BulkImportCategories?> requestBulkImportCategories(
  BuildContext context, {
  required bool hasExpense,
  required bool hasIncome,
}) {
  if (!hasExpense && !hasIncome) return Future.value(null);
  return showSmartImportBulkCategorySheet(
    context,
    needsExpenseCategory: hasExpense,
    needsIncomeSource: hasIncome,
  );
}

Future<String?> showSmartImportEntrySheet(
  BuildContext context, {
  required FinancialEntryType type,
  String? title,
  double? amountInBase,
  DateTime? date,
}) async {
  if (!context.mounted) return null;

  final displayAmount = amountInBase != null
      ? getIt<CurrencyPreferences>().displayAmount(amountInBase)
      : null;
  final isExpense = type == FinancialEntryType.expense;

  return showAppBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final sheet = isExpense
          ? AddExpenseSheet(
              initialTitle: title,
              initialAmount: displayAmount,
              initialDate: date,
            )
          : AddIncomeSheet(
              initialTitle: title,
              initialAmount: displayAmount,
              initialDate: date,
            );

      return AnimatedPadding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: isExpense
            ? BlocProvider.value(
                value: context.read<ExpensesTabBloc>(),
                child: sheet,
              )
            : BlocProvider.value(
                value: context.read<IncomesTabBloc>(),
                child: sheet,
              ),
      );
    },
  );
}
