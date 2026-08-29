import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/models/parsed_financial_entry.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/natural_language_transaction_parser.dart';
import 'package:imrpo/core/services/payment_methods_store.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/services/sms_bulk_import_service.dart';
import 'package:imrpo/core/services/voice_permission.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/expenses_tab/domain/expense_categories.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/features/smart_import/presentation/utils/smart_import_actions.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';

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

  List<ParsedFinancialEntry> _drafts = const [];
  bool _saving = false;
  bool _listening = false;
  bool _speechReady = false;
  bool _didPop = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<IncomesTabBloc>().add(const LoadIncomesEvent());
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    if (_speech.isListening) {
      _speech.stop();
    }
    super.dispose();
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

  void _onTextChanged() {
    final drafts = NaturalLanguageTransactionParser.parse(
      _controller.text,
      defaultCurrencyCode: _currencyPrefs.displayCode,
      preferredType: widget.preferredType,
    );
    setState(() => _drafts = drafts);
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
      showSmartImportSnack(context, l10n.magicAddVoiceUnavailable, isError: true);
      return;
    }

    setState(() => _listening = true);
    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          _controller.value = TextEditingValue(
            text: result.recognizedWords,
            selection: TextSelection.collapsed(
              offset: result.recognizedWords.length,
            ),
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

  Future<void> _addDrafts() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context)!;
    final ready = _drafts.where((e) => e.amount != null && e.amount! > 0).toList();
    if (ready.isEmpty) {
      showSmartImportSnack(context, l10n.magicAddNoAmount, isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final result = await _bulkImportService.importParsedEntries(ready);
      if (!mounted) return;
      reloadTransactionTabs(context);
      if (result.hasAny) {
        _closeAfterSuccess(
          () => showSmartImportBulkFeedback(context, result),
        );
      } else {
        showSmartImportSnack(
          context,
          l10n.smartImportBulkNothingToAdd,
          isError: true,
        );
      }
    } catch (_) {
      if (mounted) {
        showSmartImportSnack(context, l10n.smartImportSmsFailed, isError: true);
      }
    } finally {
      if (mounted && !_didPop) setState(() => _saving = false);
    }
  }

  Future<void> _openFullForm() async {
    final l10n = AppLocalizations.of(context)!;
    final draft = _drafts.isEmpty ? null : _drafts.first;
    final type = draft?.type ??
        widget.preferredType ??
        FinancialEntryType.expense;
    final result = await showSmartImportEntrySheet(
      context,
      type: type,
      title: draft == null
          ? null
          : smartImportFallbackTitle(l10n, draft.title),
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
            borderColor: AppColors.primary.withValues(alpha: 0.22),
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
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
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
              color: AppColors.primary,
            ),
            suffixIcon: IconButton(
              tooltip: _listening ? l10n.magicAddListening : l10n.magicAddListen,
              onPressed: _saving ? null : _toggleListen,
              icon: Icon(
                _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: _listening ? AppColors.expense : AppColors.primary,
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
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
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
          children: examples
              .map(
                (example) => ActionChip(
                  label: Text(example),
                  onPressed: _saving ? null : () => _applyExample(example),
                  backgroundColor: AppColors.surface,
                  side: BorderSide(color: AppColors.border),
                  labelStyle: TextStyle(
                    color: AppColors.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              )
              .toList(),
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
              draft: _drafts[i],
              enabled: !_saving,
              onChanged: (updated) => _updateDraft(i, updated),
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

  const _DraftCard({
    required this.draft,
    required this.enabled,
    required this.onChanged,
    required this.onRemove,
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
                              expenseCategory:
                                  draft.expenseCategory ?? 'Food',
                              paidFrom: draft.paidFrom ??
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
