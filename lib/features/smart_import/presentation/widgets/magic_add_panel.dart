import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/models/parsed_financial_entry.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/expense_shortcuts_store.dart';
import 'package:imrpo/core/services/magic_history_store.dart';
import 'package:imrpo/core/services/natural_language_transaction_parser.dart';
import 'package:imrpo/core/services/payment_methods_store.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/services/sms_bulk_import_service.dart';
import 'package:imrpo/core/services/voice_permission.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/expenses_tab/domain/entities/expense_shortcut.dart';
import 'package:imrpo/features/expenses_tab/domain/expense_categories.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/features/smart_import/presentation/utils/smart_import_actions.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:imrpo/core/models/magic_add_history_entry.dart';

class MagicAddPanel extends StatefulWidget {
  final ScrollController? scrollController;
  final FinancialEntryType? preferredType;
  final EdgeInsetsGeometry padding;
  final bool popOnSuccess;

  const MagicAddPanel({
    super.key,
    this.scrollController,
    this.preferredType,
    this.padding = const EdgeInsets.fromLTRB(20, 4, 20, 88),
    this.popOnSuccess = false,
  });

  @override
  State<MagicAddPanel> createState() => _MagicAddPanelState();
}

class _MagicAddPanelState extends State<MagicAddPanel> {
  final _controller = TextEditingController();
  final _speech = SpeechToText();
  final _bulkImportService = getIt<SmsBulkImportService>();
  final _currencyPrefs = getIt<CurrencyPreferences>();
  final _shortcutsStore = getIt<ExpenseShortcutsStore>();

  List<ParsedFinancialEntry> _drafts = const [];
  final MagicAddHistoryStore _historyStore = MagicAddHistoryStore();

  bool _saving = false;
  bool _listening = false;
  bool _speechReady = false;
  bool _didPop = false;
  bool _shortcutsLoading = true;

  @override
  void initState() {
    super.initState();

    _controller.addListener(_onTextChanged);
    _shortcutsStore.addListener(_onShortcutsChanged);

    _loadShortcuts();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<IncomesTabBloc>().add(const LoadIncomesEvent());
    });
  }

  Future<void> _loadShortcuts() async {
    try {
      await _shortcutsStore.load();
    } finally {
      if (mounted) {
        setState(() => _shortcutsLoading = false);
      }
    }
  }

  void _onShortcutsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _shortcutsStore.removeListener(_onShortcutsChanged);
    _controller.dispose();

    if (_speech.isListening) {
      _speech.stop();
    }

    super.dispose();
  }

  void _onTextChanged() {
    final drafts = NaturalLanguageTransactionParser.parse(
      _controller.text,
      defaultCurrencyCode: _currencyPrefs.displayCode,
      preferredType: widget.preferredType,
    );

    if (!mounted) return;
    setState(() => _drafts = drafts);
  }

  Future<void> _initSpeech() async {
    try {
      final ready = await _speech.initialize(
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
        onStatus: (status) {
          if (!mounted) return;

          if (status == 'done' || status == 'notListening') {
            setState(() => _listening = false);
          }
        },
      );

      if (mounted) setState(() => _speechReady = ready);
    } catch (_) {
      if (mounted) setState(() => _speechReady = false);
    }
  }

  void _reuseHistoryEntry(MagicAddHistoryEntry entry) {
    if (_saving) return;

    FocusManager.instance.primaryFocus?.unfocus();

    final preferredType = entry.type;

    _controller.value = TextEditingValue(
      text: entry.originalText,
      selection: TextSelection.collapsed(offset: entry.originalText.length),
    );

    final parsed = NaturalLanguageTransactionParser.parse(
      entry.originalText,
      defaultCurrencyCode: _currencyPrefs.displayCode,
      preferredType: preferredType,
    );

    if (parsed.isEmpty) {
      showSmartImportSnack(
        context,
        'تعذر تحليل المعاملة. عدّلي النص وحاولي مرة أخرى.',
        isError: true,
      );
      return;
    }

    final restored = parsed.map((draft) {
      final isExpense = preferredType == FinancialEntryType.expense;

      return draft.copyWith(
        title: entry.title.isNotEmpty ? entry.title : draft.title,
        type: preferredType,
        expenseCategory: isExpense
            ? entry.expenseCategory ?? 'Food'
            : draft.expenseCategory,
        paidFrom: isExpense
            ? entry.paidFrom ?? PaymentMethodsStore.defaultPresets.first
            : draft.paidFrom,
        incomeSource: isExpense
            ? draft.incomeSource
            : entry.incomeSource ?? 'Salary',
      );
    }).toList();

    setState(() {
      _drafts = restored;
    });
  }

  Future<void> _toggleListen() async {
    final l10n = AppLocalizations.of(context)!;

    final localeId = Localizations.localeOf(context).languageCode == 'ar'
        ? 'ar_EG'
        : 'en_US';

    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    final permission = await VoicePermission.request();
    if (!mounted) return;

    if (permission == VoicePermissionResult.permanentlyDenied) {
      _showPermissionSnack(
        l10n.magicAddVoicePermanentlyDenied,
        actionLabel: l10n.notificationsOpenSettings,
        onAction: VoicePermission.openSettings,
      );
      await VoicePermission.openSettings();
      return;
    }

    if (permission != VoicePermissionResult.granted) {
      showSmartImportSnack(
        context,
        l10n.magicAddVoicePermissionDenied,
        isError: true,
      );
      return;
    }

    if (!_speechReady) {
      await _initSpeech();
    }

    if (!mounted) return;

    if (!_speechReady) {
      showSmartImportSnack(
        context,
        l10n.magicAddVoiceUnavailable,
        isError: true,
      );
      return;
    }

    setState(() => _listening = true);

    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;

          final text = result.recognizedWords;

          _controller.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
        },
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          listenFor: const Duration(seconds: 20),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() => _listening = false);

      showSmartImportSnack(
        context,
        l10n.magicAddVoicePermissionDenied,
        isError: true,
      );
    }
  }

  void _showPermissionSnack(
    String message, {
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: actionLabel,
          textColor: Colors.white,
          onPressed: onAction,
        ),
      ),
    );
  }

  void _applyExample(String example) {
    _controller.value = TextEditingValue(
      text: example,
      selection: TextSelection.collapsed(offset: example.length),
    );
  }

  void _updateDraft(int index, ParsedFinancialEntry draft) {
    final next = [..._drafts];
    next[index] = draft;
    setState(() => _drafts = next);
  }

  // Saves the original text together with the user's final selections.
  Future<void> _saveDraftShortcut(ParsedFinancialEntry draft) async {
    if (_saving) return;

    final originalText = _controller.text.trim();
    final amountBase = draft.amountInBase;

    if (originalText.isEmpty) {
      showSmartImportSnack(
        context,
        'Write a transaction before saving an example.',
        isError: true,
      );
      return;
    }

    if (amountBase == null || amountBase <= 0) {
      showSmartImportSnack(
        context,
        AppLocalizations.of(context)!.magicAddNoAmount,
        isError: true,
      );
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    final initialLabel = draft.title?.trim().isNotEmpty == true
        ? draft.title!.trim()
        : smartImportFallbackTitle(l10n, draft.title);

    final labelController = TextEditingController(text: initialLabel);

    String? label;

    try {
      label = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Save example'),
            content: TextField(
              controller: labelController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Example name',
                hintText: 'e.g. Morning coffee',
              ),
              onSubmitted: (value) {
                Navigator.of(dialogContext).pop(value.trim());
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(labelController.text.trim());
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    } finally {
      labelController.dispose();
    }

    if (!mounted || label == null || label.trim().isEmpty) return;

    final isExpense = draft.type == FinancialEntryType.expense;

    final shortcut = ExpenseShortcut(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      displayLabel: label.trim(),
      originalText: originalText,
      expenseTitle: draft.title?.trim().isNotEmpty == true
          ? draft.title!.trim()
          : label.trim(),
      category: isExpense
          ? draft.expenseCategory ?? 'Food'
          : draft.incomeSource ?? 'Salary',
      type: isExpense ? 'expense' : 'income',
      paidFrom: isExpense
          ? draft.paidFrom ?? PaymentMethodsStore.defaultPresets.first
          : null,
      incomeSource: isExpense ? null : draft.incomeSource ?? 'Salary',
      amountBase: amountBase,
    );

    try {
      await _shortcutsStore.upsert(shortcut);

      if (!mounted) return;

      showSmartImportSnack(context, 'Example saved successfully');
    } catch (_) {
      if (!mounted) return;

      showSmartImportSnack(
        context,
        'Could not save example. Please try again.',
        isError: true,
      );
    }
  }

  // Restores the original text and the selections saved by the user.
  void _applySavedShortcut(ExpenseShortcut shortcut) {
    final text = shortcut.originalText.trim();

    if (text.isEmpty) {
      showSmartImportSnack(
        context,
        'This saved example has no original text. Please create it again.',
        isError: true,
      );
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

    final preferredType = shortcut.type == 'income'
        ? FinancialEntryType.income
        : FinancialEntryType.expense;

    final parsed = NaturalLanguageTransactionParser.parse(
      text,
      defaultCurrencyCode: _currencyPrefs.displayCode,
      preferredType: preferredType,
    );

    if (parsed.isEmpty) {
      showSmartImportSnack(
        context,
        'Could not parse this example. Please edit the text.',
        isError: true,
      );
      return;
    }

    final restored = parsed.map((draft) {
      final isExpense = preferredType == FinancialEntryType.expense;

      return draft.copyWith(
        title: shortcut.expenseTitle,
        type: preferredType,
        expenseCategory: isExpense ? shortcut.category : draft.expenseCategory,
        paidFrom: isExpense
            ? shortcut.paidFrom ?? PaymentMethodsStore.defaultPresets.first
            : draft.paidFrom,
        incomeSource: isExpense
            ? draft.incomeSource
            : shortcut.incomeSource ?? shortcut.category,
      );
    }).toList();

    setState(() => _drafts = restored);
  }

  Future<void> _deleteShortcut(ExpenseShortcut shortcut) async {
    try {
      await _shortcutsStore.remove(shortcut.id);
    } catch (_) {
      if (!mounted) return;

      showSmartImportSnack(context, 'Could not delete example.', isError: true);
    }
  }

  Future<void> _addDrafts() async {
    if (_saving) return;

    final l10n = AppLocalizations.of(context)!;

    final ready = _drafts
        .where((entry) => entry.amount != null && entry.amount! > 0)
        .toList();

    if (ready.isEmpty) {
      showSmartImportSnack(context, l10n.magicAddNoAmount, isError: true);
      return;
    }

    setState(() => _saving = true);

    try {
      final result = await _bulkImportService.importParsedEntries(ready);

      if (!mounted) return;

      if (!result.hasAny) {
        showSmartImportSnack(
          context,
          l10n.smartImportBulkNothingToAdd,
          isError: true,
        );
        return;
      }

      // يحفظ النص الأصلي والاختيارات النهائية للمعاملات الجاهزة.
      await _historyStore.saveEntries(ready);

      if (!mounted) return;

      reloadTransactionTabs(context);

      _closeAfterSuccess(() => showSmartImportBulkFeedback(context, result));
    } catch (_) {
      if (mounted) {
        showSmartImportSnack(context, l10n.smartImportSmsFailed, isError: true);
      }
    } finally {
      if (mounted && !_didPop) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _openFullForm() async {
    final l10n = AppLocalizations.of(context)!;

    final draft = _drafts.isEmpty ? null : _drafts.first;

    final type =
        draft?.type ?? widget.preferredType ?? FinancialEntryType.expense;

    final result = await showSmartImportEntrySheet(
      context,
      type: type,
      title: draft == null ? null : smartImportFallbackTitle(l10n, draft.title),
      amountInBase: draft?.amountInBase,
      date: draft?.date,
    );

    if (!mounted) return;

    if (isSmartImportSheetSuccess(result)) {
      reloadTransactionTabs(context);

      _closeAfterSuccess(
        () => showSmartImportSnack(context, l10n.smartImportQuickAdded),
      );
    }
  }

  void _closeAfterSuccess(VoidCallback showFeedback) {
    if (_didPop) return;

    FocusManager.instance.primaryFocus?.unfocus();

    if (_speech.isListening) {
      _speech.stop();
    }

    showFeedback();

    if (!widget.popOnSuccess) {
      _controller.clear();

      setState(() {
        _drafts = const [];
        _saving = false;
        _listening = false;
      });

      return;
    }

    _didPop = true;

    final navigator = Navigator.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!navigator.canPop()) return;
      navigator.pop('added');
    });
  }

  Widget _buildSavedShortcuts() {
    final shortcuts = _shortcutsStore.items;

    if (_shortcutsLoading || shortcuts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Row(
          children: [
            Icon(
              Icons.bookmarks_outlined,
              size: 19,
              color: AppColors.primaryInk,
            ),
            const SizedBox(width: 8),
            Text(
              'Saved examples',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: shortcuts.map((shortcut) {
            final isIncome = shortcut.type == 'income';

            return InputChip(
              avatar: Icon(
                isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
                size: 17,
                color: isIncome ? AppColors.income : AppColors.expense,
              ),
              label: Text(shortcut.displayLabel),
              onPressed: _saving ? null : () => _applySavedShortcut(shortcut),
              onDeleted: _saving ? null : () => _deleteShortcut(shortcut),
              deleteIcon: const Icon(Icons.close_rounded, size: 16),
              backgroundColor: AppColors.surface,
              side: BorderSide(color: AppColors.border),
              labelStyle: TextStyle(
                color: AppColors.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    final examples = locale.languageCode == 'ar'
        ? [
            l10n.magicAddExampleArabic,
            l10n.magicAddExampleSalary,
            l10n.magicAddExampleUber,
          ]
        : [
            l10n.magicAddExampleCoffee,
            l10n.magicAddExampleUber,
            l10n.magicAddExampleSalary,
          ];

    return ListView(
      controller: widget.scrollController,
      padding: widget.padding,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: AppDecorations.card(
            borderColor: AppColors.primaryInk.withValues(alpha: 0.22),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryInk.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primaryInk,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  l10n.magicAddHint,
                  style: TextStyle(
                    color: AppColors.textColor.withValues(alpha: 0.72),
                    height: 1.45,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.magicAddFieldLabel,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          enabled: !_saving,
          style: TextStyle(fontSize: 16, color: AppColors.textColor),
          decoration: InputDecoration(
            hintText: l10n.magicAddFieldHint,
            hintStyle: TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surface,
            prefixIcon: Icon(
              Icons.edit_note_rounded,
              color: AppColors.primaryInk,
            ),
            suffixIcon: IconButton(
              tooltip: _listening
                  ? l10n.magicAddListening
                  : l10n.magicAddListen,
              onPressed: _saving ? null : _toggleListen,
              icon: Icon(
                _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: _listening ? AppColors.expense : AppColors.primaryInk,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primaryInk, width: 1.5),
            ),
          ),
        ),
        if (_listening) ...[
          const SizedBox(height: 8),
          Text(
            l10n.magicAddListening,
            style: TextStyle(
              color: AppColors.expense,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: examples.map((example) {
            return ActionChip(
              label: Text(example),
              onPressed: _saving ? null : () => _applyExample(example),
              backgroundColor: AppColors.surface,
              side: BorderSide(color: AppColors.border),
              labelStyle: TextStyle(
                color: AppColors.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            );
          }).toList(),
        ),

        _buildSavedShortcuts(),

        MagicAddHistoryList(
          key: const ValueKey('magic_add_history'),
          onReuse: _reuseHistoryEntry,
        ),

        if (_drafts.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text(
            l10n.magicAddPreviewTitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < _drafts.length; i++)
            _DraftCard(
              key: ValueKey('${_drafts[i].rawText}_$i'),
              draft: _drafts[i],
              enabled: !_saving,
              onChanged: (updated) => _updateDraft(i, updated),
              onSave: () => _saveDraftShortcut(_drafts[i]),
              onRemove: () {
                final next = [..._drafts]..removeAt(i);
                setState(() => _drafts = next);
              },
            ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _saving ? null : _addDrafts,
          icon: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_rounded),
          label: Text(
            _drafts.length > 1
                ? l10n.magicAddAddAll(_drafts.length)
                : l10n.magicAddAddOne,
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _saving ? null : _openFullForm,
          icon: const Icon(Icons.edit_note_rounded, size: 20),
          label: Text(l10n.magicAddOpenForm),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

class _DraftCard extends StatelessWidget {
  final ParsedFinancialEntry draft;
  final bool enabled;
  final ValueChanged<ParsedFinancialEntry> onChanged;
  final VoidCallback onRemove;
  final VoidCallback? onSave;

  const _DraftCard({
    super.key,
    required this.draft,
    required this.enabled,
    required this.onChanged,
    required this.onRemove,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    final isExpense = draft.type == FinancialEntryType.expense;
    final accent = isExpense ? AppColors.expense : AppColors.income;

    final amount = draft.amount;

    final amountLabel = amount == null
        ? '—'
        : getIt<CurrencyPreferences>().formatDisplayAmount(amount);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.card(
        borderColor: accent.withValues(alpha: 0.28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  draft.title?.trim().isNotEmpty == true
                      ? draft.title!.trim()
                      : smartImportFallbackTitle(l10n, draft.title),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textColor,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Save example',
                onPressed: enabled ? onSave : null,
                icon: const Icon(Icons.bookmark_add_outlined, size: 21),
                color: AppColors.primaryInk,
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: enabled ? onRemove : null,
                icon: const Icon(Icons.close_rounded, size: 20),
                color: AppColors.textMuted,
              ),
            ],
          ),
          Text(
            amountLabel,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat.yMMMd(locale).format(draft.date ?? DateTime.now()),
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textColor.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TypeChip(
                  label: l10n.tabExpenses,
                  color: AppColors.expense,
                  selected: isExpense,
                  onTap: enabled
                      ? () => onChanged(
                          draft.copyWith(
                            type: FinancialEntryType.expense,
                            expenseCategory: draft.expenseCategory ?? 'Food',
                            paidFrom:
                                draft.paidFrom ??
                                PaymentMethodsStore.defaultPresets.first,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TypeChip(
                  label: l10n.tabIncomes,
                  color: AppColors.income,
                  selected: !isExpense,
                  onTap: enabled
                      ? () => onChanged(
                          draft.copyWith(
                            type: FinancialEntryType.income,
                            incomeSource: draft.incomeSource ?? 'Salary',
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
          if (isExpense) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ExpenseCategories.presets.map((cat) {
                final selected = (draft.expenseCategory ?? 'Food') == cat;

                return ChoiceChip(
                  label: Text(localizeExpenseCategory(l10n, cat)),
                  selected: selected,
                  onSelected: enabled
                      ? (_) => onChanged(draft.copyWith(expenseCategory: cat))
                      : null,
                  selectedColor: AppColors.expense,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  backgroundColor: AppColors.surface,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PaymentMethodsStore.defaultPresets.map((src) {
              final selected = isExpense
                  ? (draft.paidFrom ??
                            PaymentMethodsStore.defaultPresets.first) ==
                        src
                  : (draft.incomeSource ?? 'Salary') == src;

              return ChoiceChip(
                label: Text(localizeIncomeCategory(l10n, src)),
                selected: selected,
                onSelected: enabled
                    ? (_) => onChanged(
                        isExpense
                            ? draft.copyWith(paidFrom: src)
                            : draft.copyWith(incomeSource: src),
                      )
                    : null,
                selectedColor: accent,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                backgroundColor: AppColors.surface,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  const _TypeChip({
    required this.label,
    required this.color,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.14) : AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? color : AppColors.textColor,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class MagicAddHistoryList extends StatefulWidget {
  final ValueChanged<MagicAddHistoryEntry>? onReuse;

  const MagicAddHistoryList({super.key, this.onReuse});

  @override
  State<MagicAddHistoryList> createState() => _MagicAddHistoryListState();
}

class _MagicAddHistoryListState extends State<MagicAddHistoryList> {
  final MagicAddHistoryStore _store = MagicAddHistoryStore();

  List<MagicAddHistoryEntry> _entries = [];
  bool _loading = true;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final entries = await _store.load();

      if (!mounted) return;

      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('مسح السجل'),
        content: const Text('هل تريدين حذف سجل المعاملات المحفوظة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('مسح'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _clearing = true);

    try {
      await _store.clear();

      if (!mounted) return;

      setState(() => _entries.clear());
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر مسح السجل. حاولي مرة أخرى.')),
      );
    } finally {
      if (mounted) {
        setState(() => _clearing = false);
      }
    }
  }

  Future<void> _deleteHistoryEntry(MagicAddHistoryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف المعاملة'),
        content: Text('هل تريدين حذف "${entry.originalText}" من السجل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _store.removeEntry(entry.id);

      if (!mounted) return;

      setState(() {
        _entries.removeWhere((item) => item.id == entry.id);
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حذف المعاملة. حاولي مرة أخرى.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(Icons.history_rounded),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'سجل المعاملات النصية',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            if (_entries.isNotEmpty)
              TextButton.icon(
                onPressed: _clearing ? null : _clearHistory,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('مسح السجل'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_entries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('لا توجد معاملات محفوظة حتى الآن'),
          )
        else
          ..._entries.map((entry) {
            final isExpense = entry.type == FinancialEntryType.expense;

            final details = <String>[
              if (isExpense && entry.expenseCategory?.isNotEmpty == true)
                entry.expenseCategory!,
              if (isExpense && entry.paidFrom?.isNotEmpty == true)
                entry.paidFrom!,
              if (!isExpense && entry.incomeSource?.isNotEmpty == true)
                entry.incomeSource!,
            ];

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    isExpense
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                  ),
                ),
                title: Text(
                  entry.originalText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.title.isNotEmpty) Text(entry.title),
                    if (details.isNotEmpty) Text(details.join(' • ')),
                    Text(DateFormat('yyyy/MM/dd HH:mm').format(entry.savedAt)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'إضافة المعاملة مرة أخرى',
                      icon: const Icon(Icons.replay_rounded),
                      onPressed: widget.onReuse == null
                          ? null
                          : () => widget.onReuse!(entry),
                    ),
                    IconButton(
                      tooltip: 'حذف المعاملة من السجل',
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                      ),
                      onPressed: _clearing
                          ? null
                          : () => _deleteHistoryEntry(entry),
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          }),
      ],
    );
  }
}
