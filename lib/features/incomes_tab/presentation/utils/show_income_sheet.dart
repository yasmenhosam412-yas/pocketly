import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/widgets/app_toast.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
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

  final message = switch (result) {
    'added' => l10n.incomeAddedSuccess,
    'updated' => l10n.incomeUpdatedSuccess,
    _ => null,
  };
  if (message != null) {
    AppToast.success(context, message);
  }
}
