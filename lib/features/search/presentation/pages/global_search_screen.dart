import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/home_date_filter.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/features/expenses_tab/data/models/expense_model.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/features/expenses_tab/presentation/utils/show_expense_sheet.dart';
import 'package:imrpo/features/expenses_tab/presentation/widgets/add_expense_sheet.dart';
import 'package:imrpo/features/incomes_tab/data/models/income_model.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/features/incomes_tab/presentation/utils/show_income_sheet.dart';
import 'package:imrpo/features/incomes_tab/presentation/widgets/add_income_sheet.dart';
import 'package:imrpo/features/search/domain/global_search_matcher.dart';
import 'package:imrpo/features/search/domain/search_result_item.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _queryController = TextEditingController();
  final _focusNode = FocusNode();
  SearchResultType? _typeFilter;
  bool _searchAllTime = true;

  @override
  void initState() {
    super.initState();
    context.read<IncomesTabBloc>().add(const LoadIncomesEvent());
    context.read<ExpensesTabBloc>().add(const LoadExpensesEvent());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<SearchResultItem> _buildIndex(
    List<IncomeModel> incomes,
    List<ExpenseModel> expenses,
  ) {
    final dateFilter = getIt<HomeDateFilter>();
    final items = <SearchResultItem>[
      ...incomes.map(SearchResultItem.fromIncome),
      ...expenses.map(SearchResultItem.fromExpense),
    ];
    if (_searchAllTime) return items;
    return items.where((item) => dateFilter.matches(item.date)).toList();
  }

  void _openResult(SearchResultItem item, IncomeModel? income, ExpenseModel? expense) {
    if (item.type == SearchResultType.income && income != null) {
      showIncomeSheet(context, sheet: AddIncomeSheet(income: income));
    } else if (expense != null) {
      showExpenseSheet(context, sheet: AddExpenseSheet(expense: expense));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.scaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.globalSearchTitle,
          style: TextStyle(
            color: AppColors.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _queryController,
              focusNode: _focusNode,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: AppColors.textColor),
              decoration: InputDecoration(
                hintText: l10n.globalSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _queryController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _queryController.clear();
                          setState(() {});
                        },
                      ),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: l10n.globalSearchAll,
                  selected: _typeFilter == null,
                  onTap: () => setState(() => _typeFilter = null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l10n.tabIncomes,
                  selected: _typeFilter == SearchResultType.income,
                  color: AppColors.income,
                  onTap: () => setState(
                    () => _typeFilter = SearchResultType.income,
                  ),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l10n.tabExpenses,
                  selected: _typeFilter == SearchResultType.expense,
                  color: AppColors.expense,
                  onTap: () => setState(
                    () => _typeFilter = SearchResultType.expense,
                  ),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _searchAllTime
                      ? l10n.globalSearchAllTime
                      : l10n.globalSearchCurrentPeriod,
                  selected: !_searchAllTime,
                  onTap: () => setState(() => _searchAllTime = !_searchAllTime),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<IncomesTabBloc, IncomesTabState>(
              builder: (context, incomeState) {
                return BlocBuilder<ExpensesTabBloc, ExpensesTabState>(
                  builder: (context, expenseState) {
                    final loading = incomeState.status ==
                            IncomesTabStatus.loadingAll ||
                        expenseState.status == ExpensesTabStatus.loadingAll;

                    if (loading &&
                        incomeState.incomes.isEmpty &&
                        expenseState.expenses.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final index = _buildIndex(
                      incomeState.incomes,
                      expenseState.expenses,
                    );
                    final results = GlobalSearchMatcher.filter(
                      index,
                      l10n,
                      _queryController.text,
                      typeFilter: _typeFilter,
                      displayCode: getIt<CurrencyPreferences>().displayCode,
                    );

                    if (results.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            l10n.globalSearchNoResults,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textColor.withValues(alpha: 0.55),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    }

                    final incomeById = {
                      for (final i in incomeState.incomes) i.id: i,
                    };
                    final expenseById = {
                      for (final e in expenseState.expenses) e.id: e,
                    };

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final item = results[index];
                        return _SearchResultTile(
                          item: item,
                          onTap: () => _openResult(
                            item,
                            incomeById[item.id],
                            expenseById[item.id],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: accent.withValues(alpha: 0.15),
      checkmarkColor: accent,
      labelStyle: TextStyle(
        color: selected ? accent : AppColors.textColor,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final SearchResultItem item;
  final VoidCallback onTap;

  const _SearchResultTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isIncome = item.type == SearchResultType.income;
    final color = isIncome ? AppColors.income : AppColors.expense;
    final categoryLabel = isIncome
        ? localizeIncomeCategory(l10n, item.category)
        : localizeExpenseCategory(l10n, item.category);
    final title = localizeDemoTitle(l10n, item.title);
    final showTitle =
        title.trim().toLowerCase() != categoryLabel.trim().toLowerCase();
    final dateLabel = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(item.date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: AppDecorations.card(
            borderColor: color.withValues(alpha: 0.12),
          ),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isIncome
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      showTitle ? title : categoryLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      showTitle
                          ? '$categoryLabel · $dateLabel'
                          : '${isIncome ? l10n.activityIncome : l10n.activityExpense} · $dateLabel',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textColor.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'}${Money.format(item.amount)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
