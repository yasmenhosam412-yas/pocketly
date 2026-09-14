import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/widgets/app_toast.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/features/plans_tab/presentation/bloc/plans_tab_bloc.dart';
import 'package:imrpo/features/salary_day/presentation/widgets/salary_day_sheet.dart';
import 'package:imrpo/l10n/app_localizations.dart';

Future<void> showIncomeSheet(
  BuildContext context, {
  required Widget sheet,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => AnimatedPadding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: BlocProvider.value(
        value: context.read<IncomesTabBloc>(),
        child: sheet,
      ),
    ),
  );

  if (!context.mounted || result == null) return;

  if (result.startsWith('added_salary:')) {
    AppToast.success(context, l10n.incomeAddedSuccess);
    final amount = double.tryParse(result.substring('added_salary:'.length));
    final plans = context.read<PlansTabBloc>();
    final expenses = context.read<ExpensesTabBloc>();
    await showSalaryDaySheet(
      context,
      initialAmountInBase: amount,
      plansBloc: plans,
      expensesBloc: expenses,
    );
    return;
  }

  final message = switch (result) {
    'added' => l10n.incomeAddedSuccess,
    'updated' => l10n.incomeUpdatedSuccess,
    _ => null,
  };
  if (message != null) {
    AppToast.success(context, message);
  }
}

/// Ensures Plans + Expenses blocs exist when opening salary day from incomes.
void ensureSalaryDayBlocs(BuildContext context) {
  // no-op helper kept for call sites that already have root MultiBlocProvider
  context.read<PlansTabBloc>();
  context.read<ExpensesTabBloc>();
}
