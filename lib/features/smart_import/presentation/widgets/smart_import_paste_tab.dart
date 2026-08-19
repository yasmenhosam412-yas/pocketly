import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imrpo/core/models/parsed_financial_entry.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/services/shared_text_import_store.dart';
import 'package:imrpo/core/services/smart_import_draft_store.dart';
import 'package:imrpo/core/services/sms_bulk_import_service.dart';
import 'package:imrpo/core/services/transaction_text_parser.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/features/smart_import/presentation/utils/smart_import_actions.dart';
import 'package:imrpo/features/smart_import/presentation/widgets/smart_import_bulk_actions_bar.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class SmartImportPasteTab extends StatefulWidget {
  final ScrollController scrollController;

  const SmartImportPasteTab({super.key, required this.scrollController});

  @override
  State<SmartImportPasteTab> createState() => _SmartImportPasteTabState();
}

class _SmartImportPasteTabState extends State<SmartImportPasteTab> {
  final _controller = TextEditingController();
  final _bulkImportService = getIt<SmsBulkImportService>();
  final _draftStore = getIt<SmartImportDraftStore>();
  final _sharedTextStore = getIt<SharedTextImportStore>();
  final _currencyPrefs = getIt<CurrencyPreferences>();

  bool _parsing = false;
  bool _bulkImporting = false;
  List<ParsedFinancialEntry> _results = [];
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _sharedTextStore.addListener(_applySharedTextIfAny);
    WidgetsBinding.instance.addPostFrameCallback((_) => _applySharedTextIfAny());
  }

  @override
  void dispose() {
    _sharedTextStore.removeListener(_applySharedTextIfAny);
    _controller.dispose();
    super.dispose();
  }

  List<ParsedFinancialEntry> get _selectedResults => [
        for (var i = 0; i < _results.length; i++)
          if (_selectedIndices.contains(i)) _results[i],
      ];

  List<ParsedFinancialEntry> get _expenseResults => _results
      .where((e) => e.type == FinancialEntryType.expense)
      .toList();

  List<ParsedFinancialEntry> get _incomeResults =>
      _results.where((e) => e.type == FinancialEntryType.income).toList();

  void _applySharedTextIfAny() {
    if (!mounted) return;
    final text = _sharedTextStore.consumePending();
    if (text == null || text.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _controller.text = text;
      _results = [];
      _selectedIndices.clear();
    });
    _parsePastedText();
    showSmartImportSnack(context, l10n.smartImportSharedTextReady);
  }

  void _onTextChanged() {
    setState(() {
      _results = [];
      _selectedIndices.clear();
    });
  }

  void _clearForm() {
    setState(() {
      _controller.clear();
      _results = [];
      _selectedIndices.clear();
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIndices
        ..clear()
        ..addAll(List.generate(_results.length, (i) => i));
    });
  }

  void _clearSelection() => setState(_selectedIndices.clear);

  Future<void> _pasteFromClipboard() async {
    final l10n = AppLocalizations.of(context)!;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      showSmartImportSnack(
        context,
        l10n.smartImportPasteClipboardEmpty,
        isError: true,
      );
      return;
    }
    setState(() {
      _controller.text = text;
      _results = [];
      _selectedIndices.clear();
    });
    _parsePastedText();
  }

  void _swapResultType(int index) {
    if (index < 0 || index >= _results.length) return;
    final current = _results[index];
    if (!current.hasUsableData) return;
    final swapped = current.copyWith(
      type: current.type == FinancialEntryType.expense
          ? FinancialEntryType.income
          : FinancialEntryType.expense,
    );
    setState(() => _results[index] = swapped);
    _draftStore.save(swapped);
  }

  void _reindexSelectionAfterRemove(int removedIndex) {
    final next = <int>{};
    for (final i in _selectedIndices) {
      if (i == removedIndex) continue;
      next.add(i > removedIndex ? i - 1 : i);
    }
    _selectedIndices
      ..clear()
      ..addAll(next);
  }

  Future<void> _addEntry(ParsedFinancialEntry entry, int index) async {
    final l10n = AppLocalizations.of(context)!;
    final sheetResult = await showSmartImportEntrySheet(
      context,
      type: entry.type,
      title: smartImportFallbackTitle(l10n, entry.title),
      amountInBase: entry.amountInBase,
      date: entry.date,
    );

    if (!mounted) return;
    if (!isSmartImportSheetSuccess(sheetResult)) return;

    setState(() {
      if (index >= 0 && index < _results.length) {
        _results.removeAt(index);
        _reindexSelectionAfterRemove(index);
      }
      if (_results.isEmpty) {
        _controller.clear();
        _selectedIndices.clear();
      }
    });
    showSmartImportSnack(
      context,
      _results.isEmpty
          ? l10n.smartImportPasteAddedSuccess
          : l10n.smartImportPasteAddedOneRemaining(_results.length),
    );
  }

  Future<void> _bulkAdd(List<ParsedFinancialEntry> entries) async {
    final l10n = AppLocalizations.of(context)!;
    final importable =
        entries.where((e) => (e.amountInBase ?? 0) > 0).toList();
    if (importable.isEmpty) {
      showSmartImportSnack(
        context,
        l10n.smartImportBulkNothingToAdd,
        isError: true,
      );
      return;
    }

    final categories = await requestBulkImportCategories(
      context,
      hasExpense: importable.any((e) => e.type == FinancialEntryType.expense),
      hasIncome: importable.any((e) => e.type == FinancialEntryType.income),
    );
    if (categories == null || !mounted) return;

    setState(() => _bulkImporting = true);

    try {
      final result = await _bulkImportService.importParsedEntries(
        importable,
        expenseCategory: categories.expenseCategory,
        incomeSource: categories.incomeSource,
        expensePaidFrom: categories.expensePaidFrom,
      );
      if (!mounted) return;

      reloadTransactionTabs(context);

      if (result.hasAny) _clearForm();
      showSmartImportBulkFeedback(context, result);
    } catch (_) {
      if (mounted) {
        showSmartImportSnack(context, l10n.smartImportSmsFailed, isError: true);
      }
    } finally {
      if (mounted) setState(() => _bulkImporting = false);
    }
  }

  void _parsePastedText() {
    final l10n = AppLocalizations.of(context)!;
    final text = _controller.text.trim();
    if (text.isEmpty) {
      showSmartImportSnack(context, l10n.smartImportPasteEmpty, isError: true);
      return;
    }

    setState(() => _parsing = true);

    final parsed = TransactionTextParser.parseMultiplePasted(
      text,
      defaultCurrencyCode: _currencyPrefs.displayCode,
    );

    if (!mounted) return;
    setState(() {
      _parsing = false;
      _results = parsed;
      _selectedIndices
        ..clear()
        ..addAll(List.generate(parsed.length, (i) => i));
    });

    if (parsed.isNotEmpty) {
      _draftStore.save(parsed.first);
    } else {
      showSmartImportSnack(context, l10n.smartImportPasteNoData, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final disabled = _parsing || _bulkImporting;
    final expenseCount = _expenseResults.length;
    final incomeCount = _incomeResults.length;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 88),
      children: [
        _PasteHintCard(message: l10n.smartImportPasteHint),
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...[
          const SizedBox(height: 10),
          _PasteShareTip(message: l10n.smartImportPasteShareTip),
        ],
        const SizedBox(height: 16),
        Text(
          l10n.smartImportPasteFieldLabel,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final hasText = _controller.text.trim().isNotEmpty;
            return TextField(
              controller: _controller,
              onChanged: (_) => _onTextChanged(),
              maxLines: 12,
              minLines: 5,
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 15,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: l10n.smartImportPasteFieldHint,
                hintStyle: TextStyle(
                  color: AppColors.textColor.withValues(alpha: 0.45),
                ),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
                suffixIcon: hasText
                    ? IconButton(
                        onPressed: disabled ? null : _clearForm,
                        tooltip: l10n.smartImportPasteClear,
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.textColor.withValues(alpha: 0.4),
                        ),
                      )
                    : null,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: disabled ? null : _pasteFromClipboard,
                icon: const Icon(Icons.content_paste_rounded, size: 18),
                label: Text(
                  l10n.smartImportPasteFromClipboard,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: disabled ? null : _parsePastedText,
                icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                label: Text(
                  l10n.smartImportParseMessages,
                  overflow: TextOverflow.ellipsis,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.expense,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: disabled ? null : _clearForm,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: Text(l10n.smartImportPasteClear),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textColor.withValues(alpha: 0.7),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (_parsing) ...[
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: AppDecorations.card(),
            child: Column(
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 14),
                Text(
                  l10n.smartImportPasteProcessing,
                  style: TextStyle(
                    color: AppColors.textColor.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_results.isNotEmpty && !_parsing) ...[
          const SizedBox(height: 20),
          Text(
            l10n.smartImportPasteFoundCount(_results.length),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 10),
          if (_results.length > 1) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: AppDecorations.card(borderColor: AppColors.border),
              child: SmartImportBulkActionsBar(
                disabled: disabled,
                expenseCount: expenseCount,
                incomeCount: incomeCount,
                selectedCount: _selectedIndices.length,
                hasSelection: _selectedIndices.isNotEmpty,
                onAddAllExpenses: () => _bulkAdd(_expenseResults),
                onAddAllIncomes: () => _bulkAdd(_incomeResults),
                onAddSelected: () => _bulkAdd(_selectedResults),
                onSelectAll: _selectAll,
                onClearSelection: _clearSelection,
              ),
            ),
            const SizedBox(height: 12),
          ],
          ...List.generate(_results.length, (index) {
            final entry = _results[index];
            final compact = _results.length > 1;
            if (compact) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < _results.length - 1 ? 10 : 0,
                ),
                child: _PasteResultListTile(
                  entry: entry,
                  selected: _selectedIndices.contains(index),
                  disabled: disabled,
                  onToggleSelect: () => _toggleSelection(index),
                  onAdd: () => _addEntry(entry, index),
                  onSwapType: () => _swapResultType(index),
                ),
              );
            }
            return _ParsedEntryCard(
              entry: entry,
              onAdd: () => _addEntry(entry, index),
              onClear: _clearForm,
              onSwapType: () => _swapResultType(index),
            );
          }),
        ],
        if (_bulkImporting) ...[
          const SizedBox(height: 16),
          Center(
            child: Text(
              l10n.smartImportBulkImporting,
              style: TextStyle(
                color: AppColors.textColor.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PasteHintCard extends StatelessWidget {
  final String message;

  const _PasteHintCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.card(
        borderColor: AppColors.primary.withValues(alpha: 0.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.content_paste_search_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.textColor.withValues(alpha: 0.72),
                height: 1.45,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasteShareTip extends StatelessWidget {
  final String message;

  const _PasteShareTip({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.ios_share_rounded,
            size: 18,
            color: AppColors.primary.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textColor.withValues(alpha: 0.72),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasteResultListTile extends StatelessWidget {
  final ParsedFinancialEntry entry;
  final bool selected;
  final bool disabled;
  final VoidCallback onToggleSelect;
  final VoidCallback onAdd;
  final VoidCallback onSwapType;

  const _PasteResultListTile({
    required this.entry,
    required this.selected,
    required this.disabled,
    required this.onToggleSelect,
    required this.onAdd,
    required this.onSwapType,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final isExpense = entry.type == FinancialEntryType.expense;
    final accent = isExpense ? AppColors.expense : AppColors.income;
    final title = smartImportFallbackTitle(l10n, entry.title);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onToggleSelect,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: AppDecorations.card(
            borderColor: selected
                ? AppColors.primary.withValues(alpha: 0.45)
                : accent.withValues(alpha: 0.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: selected,
                    onChanged: disabled ? null : (_) => onToggleSelect(),
                    activeColor: AppColors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (entry.amountInBase != null)
                          ListenableBuilder(
                            listenable: getIt<CurrencyPreferences>(),
                            builder: (context, _) => Text(
                              Money.format(entry.amountInBase!),
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          isExpense ? l10n.tabExpenses : l10n.tabIncomes,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textColor.withValues(alpha: 0.55),
                          ),
                        ),
                        if (entry.date != null)
                          Text(
                            DateFormat.yMMMd(locale).format(entry.date!),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textColor.withValues(alpha: 0.45),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: disabled ? null : onSwapType,
                      icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                      label: Text(
                        isExpense
                            ? l10n.smartImportPasteMarkIncome
                            : l10n.smartImportPasteMarkExpense,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isExpense ? AppColors.income : AppColors.expense,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: disabled ? null : onAdd,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(l10n.smartImportAddToApp),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParsedEntryCard extends StatelessWidget {
  final ParsedFinancialEntry entry;
  final VoidCallback onAdd;
  final VoidCallback? onClear;
  final VoidCallback? onSwapType;

  const _ParsedEntryCard({
    required this.entry,
    required this.onAdd,
    this.onClear,
    this.onSwapType,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final isExpense = entry.type == FinancialEntryType.expense;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(
        borderColor: (isExpense ? AppColors.expense : AppColors.income)
            .withValues(alpha: 0.25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isExpense ? AppColors.expense : AppColors.income)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isExpense
                      ? Icons.north_east_rounded
                      : Icons.south_west_rounded,
                  size: 18,
                  color: isExpense ? AppColors.expense : AppColors.income,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.smartImportExtractedData,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(
            label: l10n.titleField,
            value: smartImportFallbackTitle(l10n, entry.title),
          ),
          if (entry.amountInBase != null)
            ListenableBuilder(
              listenable: getIt<CurrencyPreferences>(),
              builder: (context, _) => _InfoRow(
                label: l10n.amountField,
                value: Money.format(entry.amountInBase!),
              ),
            ),
          if (entry.date != null)
            _InfoRow(
              label: l10n.smartImportDateField,
              value: DateFormat.yMMMd(locale).format(entry.date!),
            ),
          _InfoRow(
            label: l10n.smartImportTypeField,
            value: isExpense ? l10n.tabExpenses : l10n.tabIncomes,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.smartImportAddToApp),
              style: FilledButton.styleFrom(
                backgroundColor:
                    isExpense ? AppColors.expense : AppColors.income,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (onSwapType != null || onClear != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (onSwapType != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onSwapType,
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: Text(
                        isExpense
                            ? l10n.smartImportPasteMarkIncome
                            : l10n.smartImportPasteMarkExpense,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isExpense ? AppColors.income : AppColors.expense,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                if (onSwapType != null && onClear != null)
                  const SizedBox(width: 8),
                if (onClear != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onClear,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(l10n.smartImportPasteParseAnother),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textColor.withValues(alpha: 0.55),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
