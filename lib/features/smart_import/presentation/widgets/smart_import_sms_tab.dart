import 'package:flutter/material.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/models/parsed_financial_entry.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/services/sms_bulk_import_service.dart';
import 'package:imrpo/core/services/sms_import_service.dart';
import 'package:imrpo/core/services/sms_imported_registry.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/core/widgets/tab_refresh_overlay.dart';
import 'package:imrpo/features/smart_import/presentation/utils/smart_import_actions.dart';
import 'package:imrpo/features/smart_import/presentation/widgets/smart_import_bulk_actions_bar.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class SmartImportSmsTab extends StatefulWidget {
  static const tabIndex = 3;

  final ScrollController scrollController;
  final TabController tabController;

  const SmartImportSmsTab({
    super.key,
    required this.scrollController,
    required this.tabController,
  });

  @override
  State<SmartImportSmsTab> createState() => _SmartImportSmsTabState();
}

class _SmartImportSmsTabState extends State<SmartImportSmsTab> {
  final _smsService = getIt<SmsImportService>();
  final _bulkImportService = getIt<SmsBulkImportService>();
  final _importedRegistry = getIt<SmsImportedRegistry>();

  final Set<String> _selectedIds = {};
  bool _loadMoreScheduled = false;
  bool _loadRequested = false;

  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _rawCursor = 0;
  bool _bulkImporting = false;
  List<SmsMessageItem> _messages = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_onTabChanged);
    widget.scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureLoadedIfNeeded();
    });
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onTabChanged() {
    if (widget.tabController.indexIsChanging) return;
    _ensureLoadedIfNeeded();
  }

  void _ensureLoadedIfNeeded() {
    if (widget.tabController.index != SmartImportSmsTab.tabIndex) return;
    if (_loadRequested) return;
    _loadRequested = true;
    _loadSms();
  }

  bool get _listAtCap =>
      _messages.length >= SmsImportService.maxDisplayedMessages;

  List<SmsMessageItem> _trimList(List<SmsMessageItem> items) {
    if (items.length <= SmsImportService.maxDisplayedMessages) return items;
    return items.take(SmsImportService.maxDisplayedMessages).toList();
  }

  bool _hasMoreAfterPage(SmsPageResult page, int listLength) {
    if (listLength >= SmsImportService.maxDisplayedMessages) return false;
    return page.hasMore;
  }

  void _onScroll() {
    if (!_hasMore || _listAtCap || _loadingMore || _loading || _bulkImporting) {
      return;
    }
    final position = widget.scrollController.position;
    if (position.pixels < position.maxScrollExtent - 240) return;
    if (_loadMoreScheduled) return;
    _loadMoreScheduled = true;
    _loadMoreSms();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _loadMoreScheduled = false;
    });
  }

  List<SmsMessageItem> get _importable =>
      _messages.where(_bulkImportService.canImport).toList();

  List<SmsMessageItem> get _expenseItems => _importable
      .where((m) => m.parsed.type == FinancialEntryType.expense)
      .toList();

  List<SmsMessageItem> get _incomeItems => _importable
      .where((m) => m.parsed.type == FinancialEntryType.income)
      .toList();

  List<SmsMessageItem> get _selectedItems => _messages
      .where((m) => _selectedIds.contains(m.id))
      .where(_bulkImportService.canImport)
      .toList();

  void _toggleSelection(SmsMessageItem item) {
    if (!_bulkImportService.canImport(item)) return;
    setState(() {
      if (_selectedIds.contains(item.id)) {
        _selectedIds.remove(item.id);
      } else {
        _selectedIds.add(item.id);
      }
    });
  }

  void _selectAllImportable() {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(_importable.map((m) => m.id));
    });
  }

  void _clearSelection() => setState(_selectedIds.clear);

  void _pruneSelection() {
    _selectedIds.removeWhere((id) => !_messages.any((m) => m.id == id));
  }

  String? _majorityValue(Iterable<String?> values) {
    final counts = <String, int>{};
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) continue;
      counts[trimmed] = (counts[trimmed] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  void _swapType(SmsMessageItem item) {
    final nextType = item.parsed.type == FinancialEntryType.expense
        ? FinancialEntryType.income
        : FinancialEntryType.expense;
    setState(() {
      final index = _messages.indexWhere((m) => m.id == item.id);
      if (index < 0) return;
      _messages[index] = _messages[index].withType(nextType);
    });
  }

  Future<void> _loadSms() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    if (!_smsService.isSupported) {
      setState(() {
        _error = l10n.smartImportSmsNotSupported;
        _messages = [];
        _hasMore = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _rawCursor = 0;
      _hasMore = true;
    });

    try {
      final page = await _smsService.loadInitialFinancialMessages();
      if (!mounted) return;
      final items = _trimList(page.items);
      setState(() {
        _messages = items;
        _rawCursor = page.nextRawStart;
        _hasMore = _hasMoreAfterPage(page, items.length);
        _pruneSelection();
        if (items.isEmpty) {
          _error = l10n.smartImportSmsEmpty;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages = [];
        _hasMore = false;
        _error = l10n.smartImportSmsFailed;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMoreSms() async {
    if (_loading || _loadingMore || !_hasMore || _listAtCap) return;

    final remaining =
        SmsImportService.maxDisplayedMessages - _messages.length;
    if (remaining <= 0) {
      setState(() => _hasMore = false);
      return;
    }

    setState(() => _loadingMore = true);

    try {
      final page = await _smsService.loadFinancialMessagesPage(
        rawStart: _rawCursor,
        pageSize: remaining.clamp(1, SmsImportService.defaultPageSize),
      );
      if (!mounted) return;

      final existingIds = _messages.map((m) => m.id).toSet();
      final novel = page.items.where((m) => !existingIds.contains(m.id));
      final merged = _trimList([..._messages, ...novel]);

      setState(() {
        _messages = merged;
        _rawCursor = page.nextRawStart;
        _hasMore = _hasMoreAfterPage(page, merged.length);
        _pruneSelection();
      });
    } catch (_) {
      if (mounted) {
        showSmartImportSnack(
          context,
          AppLocalizations.of(context)!.smartImportSmsFailed,
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _runBulk(List<SmsMessageItem> items) async {
    if (_bulkImporting || items.isEmpty) return;

    final hasExpense = items.any(
      (m) => m.parsed.type == FinancialEntryType.expense,
    );
    final hasIncome = items.any(
      (m) => m.parsed.type == FinancialEntryType.income,
    );

    final categories = await requestBulkImportCategories(
      context,
      hasExpense: hasExpense,
      hasIncome: hasIncome,
      initialExpenseCategory: _majorityValue(
        items
            .where((m) => m.parsed.type == FinancialEntryType.expense)
            .map((m) => m.parsed.expenseCategory),
      ),
      initialExpensePaidFrom: _majorityValue(
        items
            .where((m) => m.parsed.type == FinancialEntryType.expense)
            .map((m) => m.parsed.paidFrom),
      ),
      initialIncomeSource: _majorityValue(
        items
            .where((m) => m.parsed.type == FinancialEntryType.income)
            .map((m) => m.parsed.incomeSource),
      ),
    );
    if (categories == null || !mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final importable = items.where(_bulkImportService.canImport).toList();
    if (importable.isEmpty) {
      showSmartImportSnack(
        context,
        l10n.smartImportBulkNothingToAdd,
        isError: true,
      );
      return;
    }

    setState(() => _bulkImporting = true);

    try {
      final result = await _bulkImportService.importAll(
        importable,
        expenseCategory: categories.expenseCategory,
        incomeSource: categories.incomeSource,
        expensePaidFrom: categories.expensePaidFrom,
      );
      if (!mounted) return;

      reloadTransactionTabs(context);
      showSmartImportBulkFeedback(context, result, includeSkipped: true);
      setState(_selectedIds.clear);
    } catch (_) {
      if (mounted) {
        showSmartImportSnack(context, l10n.smartImportSmsFailed, isError: true);
      }
    } finally {
      if (mounted) setState(() => _bulkImporting = false);
    }
  }

  Future<void> _confirmClearAllImported() async {
    final l10n = AppLocalizations.of(context)!;
    if (_importedRegistry.importedCount == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.smartImportSmsClearAllAddedConfirmTitle),
        content: Text(l10n.smartImportSmsClearAllAddedConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.smartImportSmsClearAllAdded),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _importedRegistry.clearAll();
    if (!mounted) return;
    showSmartImportSnack(context, l10n.smartImportSmsClearAllAddedDone);
  }

  Future<void> _openPrefilledSheet(
    SmsMessageItem item, {
    bool reimport = false,
  }) async {
    if (!reimport && _importedRegistry.isImported(item.id)) return;

    final l10n = AppLocalizations.of(context)!;
    final fallback = item.parsed.type == FinancialEntryType.expense
        ? l10n.smartImportSmsTitleExpense
        : l10n.smartImportSmsTitleIncome;
    final result = await showSmartImportEntrySheet(
      context,
      type: item.parsed.type,
      title: item.displayTitle(fallback),
      amountInBase: item.parsed.amountInBase,
      date: item.parsed.date ?? item.date,
      expenseCategory: item.parsed.expenseCategory,
      paidFrom: item.parsed.paidFrom,
      incomeSource: item.parsed.incomeSource,
    );

    if (isSmartImportSheetSuccess(result)) {
      await _importedRegistry.markImported(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final disabled = _bulkImporting;

    if (!_smsService.isSupported) {
      return _CenterMessage(
        icon: Icons.phone_iphone_outlined,
        message: l10n.smartImportSmsNotSupported,
      );
    }

    final isInitialLoading = _loading && _messages.isEmpty;
    final isRefreshing = _loading && _messages.isNotEmpty;

    Widget body;
    if (isInitialLoading) {
      body = _SmsLoadingList(message: l10n.smartImportSmsLoading);
    } else if (_messages.isEmpty) {
      body = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          _CenterMessage(
            icon: Icons.sms_failed_outlined,
            message: _error ?? l10n.smartImportSmsEmpty,
            actionLabel: l10n.smartImportReloadSms,
            onAction: _loadSms,
          ),
        ],
      );
    } else {
      body = ListenableBuilder(
        listenable: _importedRegistry,
        builder: (context, _) {
          return CustomScrollView(
            controller: widget.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: AppDecorations.card(
                      borderColor: AppColors.border,
                    ),
                    child: SmartImportBulkActionsBar(
                      disabled: disabled,
                      importedCount: _importedRegistry.importedCount,
                      expenseCount: _expenseItems.length,
                      incomeCount: _incomeItems.length,
                      selectedCount: _selectedItems.length,
                      hasSelection: _selectedIds.isNotEmpty,
                      onAddAllExpenses: () => _runBulk(_expenseItems),
                      onAddAllIncomes: () => _runBulk(_incomeItems),
                      onAddSelected: () => _runBulk(_selectedItems),
                      onSelectAll: _selectAllImportable,
                      onClearSelection: _clearSelection,
                      onClearAllAdded: _confirmClearAllImported,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                sliver: SliverList.separated(
                  itemCount: _messages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _messages[index];
                    final isImported = _importedRegistry.isImported(item.id);
                    final canImport = _bulkImportService.canImport(item);
                    final canReimport =
                        isImported && _bulkImportService.canReimport(item);
                    return _SmsListTile(
                      item: item,
                      isImported: isImported,
                      canImport: canImport,
                      canReimport: canReimport,
                      selected: _selectedIds.contains(item.id),
                      disabled: disabled,
                      onToggleSelect:
                          canImport ? () => _toggleSelection(item) : null,
                      onAdd: () => _openPrefilledSheet(item),
                      onAddAgain: canReimport
                          ? () => _openPrefilledSheet(item, reimport: true)
                          : null,
                      onSwapType: () => _swapType(item),
                    );
                  },
                ),
              ),
              if (_listAtCap)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: _SmsListCapBanner(),
                  ),
                )
              else if (_hasMore || _loadingMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: _SmsPaginationFooter(
                      loading: _loadingMore,
                      onLoadMore: _loadMoreSms,
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }

    return Stack(
      children: [
        TabRefreshOverlay(
          isRefreshing: isRefreshing,
          indicatorColor: AppColors.primaryInk,
          child: RefreshIndicator(
            color: AppColors.primaryInk,
            onRefresh: disabled
                ? () async {}
                : () async {
                    await _loadSms();
                  },
            child: body,
          ),
        ),
        if (_bulkImporting)
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.scaffold.withValues(alpha: 0.85),
              child: Center(
                child: _BulkImportProgressCard(
                  message: l10n.smartImportBulkImporting,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BulkImportProgressCard extends StatelessWidget {
  final String message;

  const _BulkImportProgressCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      decoration: AppDecorations.card(borderColor: AppColors.primary),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryInk.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryInk,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmsLoadingList extends StatelessWidget {
  final String message;

  const _SmsLoadingList({required this.message});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: AppDecorations.card(
                borderColor: AppColors.primaryInk.withValues(alpha: 0.2),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryInk.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primaryInk,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColor.withValues(alpha: 0.75),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList.separated(
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, _) => const _SmsSkeletonTile(),
          ),
        ),
      ],
    );
  }
}

class _SmsSkeletonTile extends StatelessWidget {
  const _SmsSkeletonTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.card(borderColor: AppColors.border),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmsListCapBanner extends StatelessWidget {
  const _SmsListCapBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryInk.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryInk.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        l10n.smartImportSmsListCap(SmsImportService.maxDisplayedMessages),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textColor.withValues(alpha: 0.75),
          height: 1.35,
        ),
      ),
    );
  }
}

class _SmsPaginationFooter extends StatelessWidget {
  final bool loading;
  final VoidCallback onLoadMore;

  const _SmsPaginationFooter({required this.loading, required this.onLoadMore});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryInk,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.smartImportSmsLoadingMore,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onLoadMore,
      icon: const Icon(Icons.expand_more_rounded),
      label: Text(l10n.smartImportSmsLoadMore),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryInk,
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: AppColors.primaryInk),
      ),
    );
  }
}

class _SmsListTile extends StatefulWidget {
  final SmsMessageItem item;
  final bool isImported;
  final bool canImport;
  final bool canReimport;
  final bool selected;
  final bool disabled;
  final VoidCallback? onToggleSelect;
  final VoidCallback onAdd;
  final VoidCallback? onAddAgain;
  final VoidCallback onSwapType;

  const _SmsListTile({
    required this.item,
    required this.isImported,
    required this.canImport,
    required this.canReimport,
    required this.selected,
    required this.disabled,
    required this.onToggleSelect,
    required this.onAdd,
    this.onAddAgain,
    required this.onSwapType,
  });

  @override
  State<_SmsListTile> createState() => _SmsListTileState();
}

class _SmsListTileState extends State<_SmsListTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final item = widget.item;
    final parsed = item.parsed;
    final isExpense = parsed.type == FinancialEntryType.expense;
    final accent = isExpense ? AppColors.expense : AppColors.income;
    final bodyText = item.body.trim().isNotEmpty
        ? item.body.trim()
        : parsed.rawText.trim();
    final metaLabel = isExpense
        ? [
            if (parsed.expenseCategory != null &&
                parsed.expenseCategory!.trim().isNotEmpty)
              localizeExpenseCategory(l10n, parsed.expenseCategory!),
            if (parsed.paidFrom != null && parsed.paidFrom!.trim().isNotEmpty)
              '${l10n.expensePaidFromField}: ${localizeIncomeCategory(l10n, parsed.paidFrom!)}',
          ].join(' · ')
        : (parsed.incomeSource != null &&
                parsed.incomeSource!.trim().isNotEmpty
            ? localizeIncomeCategory(l10n, parsed.incomeSource!)
            : '');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.disabled || widget.isImported
            ? null
            : (widget.onToggleSelect ?? widget.onAdd),
        onLongPress: widget.disabled ||
                !widget.canImport ||
                widget.isImported
            ? null
            : widget.onAdd,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: AppDecorations.card(
            borderColor: widget.isImported
                ? AppColors.border
                : widget.selected
                    ? AppColors.primary
                    : accent.withValues(alpha: 0.18),
          ).copyWith(
            color: widget.isImported
                ? AppColors.surface
                : widget.selected
                    ? AppColors.primaryInk.withValues(alpha: 0.05)
                    : AppColors.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.canImport)
                    Checkbox(
                      value: widget.selected,
                      onChanged: widget.disabled
                          ? null
                          : (_) => widget.onToggleSelect?.call(),
                      activeColor: AppColors.primaryInk,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    )
                  else
                    const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.sms_outlined,
                      size: 20,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.displayTitle(
                            parsed.type == FinancialEntryType.expense
                                ? l10n.smartImportSmsTitleExpense
                                : l10n.smartImportSmsTitleIncome,
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.displaySubtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.displaySubtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textColor.withValues(
                                alpha: 0.45,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          DateFormat.yMMMd(
                            locale,
                          ).add_jm().format(parsed.date ?? item.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textColor.withValues(alpha: 0.5),
                          ),
                        ),
                        if (metaLabel.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            metaLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accent.withValues(alpha: 0.85),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (parsed.amountInBase != null)
                    ListenableBuilder(
                      listenable: getIt<CurrencyPreferences>(),
                      builder: (context, _) => Text(
                        Money.format(parsed.amountInBase!),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ),
                  if (!widget.disabled &&
                      widget.canImport &&
                      !widget.isImported) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: widget.onAdd,
                      icon: const Icon(Icons.open_in_new_rounded),
                      color: AppColors.primaryInk,
                      tooltip: l10n.smartImportTapToImport,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ],
                ],
              ),
              Padding(
                padding: EdgeInsets.only(left: widget.canImport ? 40 : 12),
                child: Row(
                  children: [
                    Icon(
                      isExpense
                          ? Icons.north_east_rounded
                          : Icons.south_west_rounded,
                      size: 14,
                      color: accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isExpense ? l10n.tabExpenses : l10n.tabIncomes,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColor.withValues(alpha: 0.55),
                      ),
                    ),
                    if (widget.isImported) ...[
                      const Spacer(),
                      if (widget.canReimport &&
                          widget.onAddAgain != null &&
                          !widget.disabled)
                        TextButton(
                          onPressed: widget.onAddAgain,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryInk,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            l10n.smartImportSmsAddAgain,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 14,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.smartImportSmsAlreadyAdded,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ] else if (!widget.canImport) ...[
                      const Spacer(),
                      Text(
                        '—',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textColor.withValues(alpha: 0.4),
                        ),
                      ),
                    ] else ...[
                      const Spacer(),
                      Text(
                        l10n.smartImportTapToImport,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textColor.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (bodyText.isNotEmpty) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.only(left: widget.canImport ? 40 : 12),
                  child: Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => setState(() => _expanded = !_expanded),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bodyText,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: AppColors.textColor.withValues(
                                  alpha: 0.78,
                                ),
                              ),
                              maxLines: _expanded ? null : 3,
                              overflow: _expanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  _expanded
                                      ? Icons.expand_less_rounded
                                      : Icons.expand_more_rounded,
                                  size: 18,
                                  color: AppColors.primaryInk,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _expanded
                                      ? l10n.smartImportSmsHideBody
                                      : l10n.smartImportSmsShowBody,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryInk,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.only(left: widget.canImport ? 40 : 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.disabled ? null : widget.onSwapType,
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
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CenterMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: AppDecorations.card(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.textColor.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textColor.withValues(alpha: 0.65),
                height: 1.45,
                fontSize: 14,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
