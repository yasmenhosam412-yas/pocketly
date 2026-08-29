import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/csv_import/domain/csv_column_field.dart';
import 'package:imrpo/features/csv_import/domain/csv_import_parser.dart';
import 'package:imrpo/features/expenses_tab/domain/usecases/add_expense_usecase.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/features/incomes_tab/domain/usecases/add_income_usecase.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class CsvImportScreen extends StatefulWidget {
  const CsvImportScreen({super.key});

  @override
  State<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends State<CsvImportScreen> {
  int _step = 0;
  String? _fileName;
  List<List<String>> _rows = [];
  List<String> _headers = [];
  List<CsvColumnField> _mappings = [];
  bool _firstRowHeader = true;
  String _currencyCode = CurrencyConverter.defaultDisplayCode;
  List<CsvParsedRow> _preview = [];
  bool _importing = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.csvImportTitle,
          style: TextStyle(color: AppColors.textColor, fontSize: 18),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textColor,
      ),
      body: _importing
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryInk),
                  const SizedBox(height: 16),
                  Text(l10n.csvImportProgress),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(color: AppColors.errorColor),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_step == 0) _buildPickFile(l10n),
                if (_step == 1) _buildMapping(l10n),
                if (_step == 2) _buildPreview(l10n),
              ],
            ),
    );
  }

  Widget _buildPickFile(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.csvImportPickHint,
          style: TextStyle(
            color: AppColors.textColor.withValues(alpha: 0.7),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _pickCsv,
          icon: const Icon(Icons.upload_file_rounded),
          label: Text(l10n.csvImportPickFile),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        if (_fileName != null) ...[
          const SizedBox(height: 16),
          Text(
            l10n.csvImportFileSelected(_fileName!),
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }

  Widget _buildMapping(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.csvImportFirstRowHeader),
          value: _firstRowHeader,
          onChanged: (v) => setState(() {
            _firstRowHeader = v;
            _refreshPreview();
          }),
        ),
        const SizedBox(height: 8),
        Text(l10n.csvImportCurrencyHint),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _currencyCode,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: CurrencyConverter.entryCurrencies
              .map((c) => DropdownMenuItem(value: c.code, child: Text(c.code)))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _currencyCode = v;
              _refreshPreview();
            });
          },
        ),
        const SizedBox(height: 20),
        Text(
          l10n.csvImportMapColumns,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...List.generate(_headers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    _headers[index],
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<CsvColumnField>(
                    initialValue: _mappings[index],
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: CsvColumnField.values
                        .map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(_fieldLabel(l10n, f)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _mappings[index] = v;
                        _refreshPreview();
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = 0),
                child: Text(l10n.csvImportBack),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _canContinueMapping
                    ? () => setState(() => _step = 2)
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: Text(l10n.csvImportPreview),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreview(AppLocalizations l10n) {
    final expenseCount = _preview.where((r) => r.isExpense).length;
    final incomeCount = _preview.length - expenseCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.csvImportPreviewSummary(
            _preview.length,
            expenseCount,
            incomeCount,
          ),
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ..._preview
            .take(8)
            .map(
              (row) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  row.isExpense
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: row.isExpense ? AppColors.expense : AppColors.income,
                ),
                title: Text(row.title),
                subtitle: Text(
                  '${row.isExpense ? l10n.csvImportTypeExpense : l10n.csvImportTypeIncome} · ${row.category}',
                ),
              ),
            ),
        if (_preview.length > 8)
          Text(l10n.csvImportMoreRows(_preview.length - 8)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = 1),
                child: Text(l10n.csvImportBack),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _preview.isEmpty ? null : _runImport,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: Text(l10n.csvImportRun),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool get _canContinueMapping {
    final hasTitle = _mappings.contains(CsvColumnField.title);
    final hasAmount = _mappings.contains(CsvColumnField.amount);
    final hasType = _mappings.contains(CsvColumnField.type);
    return hasTitle && hasAmount && hasType && _preview.isNotEmpty;
  }

  String _fieldLabel(AppLocalizations l10n, CsvColumnField field) {
    switch (field) {
      case CsvColumnField.skip:
        return l10n.csvImportFieldSkip;
      case CsvColumnField.title:
        return l10n.titleField;
      case CsvColumnField.amount:
        return l10n.amountField;
      case CsvColumnField.date:
        return l10n.smartImportDateField;
      case CsvColumnField.category:
        return l10n.categoryField;
      case CsvColumnField.type:
        return l10n.csvImportFieldType;
      case CsvColumnField.paidFrom:
        return l10n.expensePaidFromField;
    }
  }

  Future<void> _pickCsv() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;

    try {
      final content = await File(path).readAsString();
      final rows = CsvImportParser.parseRaw(content);
      if (rows.isEmpty) {
        setState(() => _error = AppLocalizations.of(context)!.csvImportEmpty);
        return;
      }
      final headers = rows.first;
      setState(() {
        _fileName = result.files.single.name;
        _rows = rows;
        _headers = headers;
        _mappings = CsvImportParser.guessMappings(headers);
        _error = null;
        _step = 1;
        _refreshPreview();
      });
    } catch (_) {
      setState(
        () => _error = AppLocalizations.of(context)!.csvImportParseFailed,
      );
    }
  }

  void _refreshPreview() {
    _preview = CsvImportParser.buildRows(
      rows: _rows,
      mappings: _mappings,
      firstRowIsHeader: _firstRowHeader,
      defaultCurrencyCode: _currencyCode,
    );
  }

  Future<void> _runImport() async {
    setState(() => _importing = true);
    final addExpense = getIt<AddExpenseUsecase>();
    final addIncome = getIt<AddIncomeUsecase>();
    var failed = 0;

    for (final row in _preview) {
      if (row.isExpense) {
        final result = await addExpense(
          row.title,
          row.category,
          row.amountBase,
          row.date,
          incomeSource: row.paidFrom,
        );
        if (result.isLeft()) failed++;
      } else {
        final result = await addIncome(
          row.title,
          row.amountBase,
          row.date,
          row.category,
        );
        if (result.isLeft()) failed++;
      }
    }

    if (!mounted) return;
    context.read<ExpensesTabBloc>().add(const LoadExpensesEvent(force: true));
    context.read<IncomesTabBloc>().add(const LoadIncomesEvent(force: true));

    setState(() => _importing = false);
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failed == 0
              ? l10n.csvImportSuccess(_preview.length)
              : l10n.csvImportPartial(_preview.length - failed, failed),
        ),
      ),
    );
    Navigator.of(context).pop();
  }
}
