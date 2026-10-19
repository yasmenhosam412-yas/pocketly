import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/features/home/presentation/widgets/scroll_hint.dart';
import 'package:imrpo/features/manage_tab/presentation/pages/manage_tab.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:imrpo/features/home/domain/entities/user_profile.dart';
import 'package:imrpo/features/home/presentation/bloc/home_bloc.dart';
import 'package:imrpo/features/home/presentation/widgets/user_settings_sheet.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/home_date_filter.dart';
import 'package:imrpo/core/services/initial_balance_store.dart';
import 'package:imrpo/core/services/pocketly_home_widget.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/services/theme_preferences.dart';
import 'package:imrpo/core/helpers/supabase_auth_helper.dart';
import 'package:imrpo/core/services/association_context.dart';
import 'package:imrpo/core/services/association_member_names.dart';
import 'package:imrpo/core/session/user_session.dart';
import 'package:imrpo/features/associations/presentation/widgets/association_ledger_banner.dart';
import 'package:imrpo/features/association_invites/presentation/widgets/pending_association_invites.dart';
import 'package:imrpo/features/home/presentation/widgets/association_selector.dart';
import 'package:imrpo/features/home/presentation/widgets/home_date_filter_sheet.dart';
import 'package:imrpo/features/home/presentation/theme/home_header_theme.dart';
import 'package:imrpo/features/home/presentation/widgets/home_wallet_header_chip.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/balance_tab/presentation/pages/balance_tab.dart';
import 'package:imrpo/features/expenses_tab/presentation/pages/expenses_tab.dart';
import 'package:imrpo/features/expenses_tab/presentation/utils/show_expense_sheet.dart';
import 'package:imrpo/features/expenses_tab/presentation/widgets/add_expense_sheet.dart';
import 'package:imrpo/features/incomes_tab/presentation/pages/incomes_tab.dart';
import 'package:imrpo/features/commitments/presentation/pages/commitments_screen.dart';
import 'package:imrpo/features/plans_tab/presentation/pages/plans_tab.dart';
import 'package:imrpo/features/loans_tab/presentation/pages/loans_tab.dart';
import 'package:imrpo/core/config/app_router.dart';
import 'package:imrpo/core/services/notification_inbox_store.dart';
import 'package:imrpo/core/widgets/notification_icon_badge.dart';
import 'package:imrpo/core/services/onboarding_preferences.dart';
import 'package:imrpo/core/widgets/triple_back_to_exit.dart';
import 'package:imrpo/core/widgets/offline_banner.dart';
import 'package:imrpo/features/home/presentation/widgets/home_first_run_guide.dart';
import 'package:imrpo/core/helpers/association_ledger_access.dart';
import 'package:imrpo/features/smart_import/presentation/widgets/smart_import_ai_tab.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  bool _tabsLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 7, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapSession());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _retryAfterOffline();
    }
  }

  Future<void> _bootstrapSession() async {
    try {
      if (SupabaseAuthHelper.isSignedIn) {
        final associations = getIt<AssociationContext>();
        if (!associations.isLoaded) {
          await associations.load();
        }
        await getIt<AssociationMemberNames>().refresh();
        await getIt<InitialBalanceStore>().load();
      }
    } catch (_) {
      // Ledger/auth hiccups must not crash Home.
    }
    if (!mounted) return;
    if (!getIt<AssociationContext>().isOffline) {
      context.read<HomeBloc>().add(const LoadUserProfileEvent());
    }
    if (!mounted || _tabsLoaded) return;
    _tabsLoaded = true;
    UserSession.loadAll(context);
  }

  Future<void> _retryAfterOffline() async {
    if (!SupabaseAuthHelper.isSignedIn || !mounted) return;
    final associations = getIt<AssociationContext>();
    if (!associations.isOffline) return;
    try {
      await associations.load(forceNetwork: true);
    } catch (_) {
      return;
    }
    if (!mounted || associations.isOffline) return;
    context.read<HomeBloc>().add(const LoadUserProfileEvent());
    await UserSession.syncOfflineTransactionsAndReload(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _HomeTabBody(tabController: _tabController);
  }
}

class _HomeTabBody extends StatefulWidget {
  final TabController tabController;

  const _HomeTabBody({required this.tabController});

  @override
  State<_HomeTabBody> createState() => _HomeTabBodyState();
}

class _HomeTabBodyState extends State<_HomeTabBody> {
  bool _showGuide = false;
  bool _openingExpenseFromWidget = false;
  int _displayedTabIndex = 0;

  List<_HomeTabItem> _tabs(AppLocalizations l10n) => [
    _HomeTabItem(
      label: l10n.manage,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      color: AppColors.balance,
    ),
    _HomeTabItem(
      label: l10n.tabIncomes,
      icon: Icons.trending_up_rounded,
      selectedIcon: Icons.trending_up_rounded,
      color: AppColors.income,
    ),
    _HomeTabItem(
      label: l10n.tabExpenses,
      icon: Icons.trending_down_rounded,
      selectedIcon: Icons.trending_down_rounded,
      color: AppColors.expense,
    ),
    _HomeTabItem(
      label: l10n.tabBalance,
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet_rounded,
      color: AppColors.balance,
    ),
    _HomeTabItem(
      label: l10n.tabLoans,
      icon: Icons.handshake_outlined,
      selectedIcon: Icons.handshake_rounded,
      color: AppColors.loans,
    ),
    _HomeTabItem(
      label: l10n.tabPlans,
      icon: Icons.flag_outlined,
      selectedIcon: Icons.flag_rounded,
      color: AppColors.plans,
    ),
    _HomeTabItem(
      label: l10n.tabCommitments,
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups_rounded,
      color: const Color(0xFF6B5B95),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _displayedTabIndex = widget.tabController.index;
    widget.tabController.addListener(_onTabChanged);
    PocketlyHomeWidget.addExpenseLaunch.addListener(_onAddExpenseLaunch);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeStartGuide();
      _onAddExpenseLaunch();
    });
  }

  Future<void> _maybeStartGuide() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    if (getIt<OnboardingPreferences>().homeGuideCompleted) return;
    setState(() => _showGuide = true);
  }

  Future<void> _finishGuide() async {
    await getIt<OnboardingPreferences>().setHomeGuideCompleted();
    if (!mounted) return;
    setState(() => _showGuide = false);
    _onAddExpenseLaunch();
  }

  void _onAddExpenseLaunch() {
    if (!PocketlyHomeWidget.addExpenseLaunch.value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_openAddExpenseFromWidget());
    });
  }

  Future<void> _openAddExpenseFromWidget() async {
    if (!mounted) return;
    if (!PocketlyHomeWidget.addExpenseLaunch.value) return;
    if (_openingExpenseFromWidget) {
      PocketlyHomeWidget.takeAddExpenseLaunch();
      return;
    }
    if (_showGuide) return;

    PocketlyHomeWidget.takeAddExpenseLaunch();
    widget.tabController.animateTo(1);
    if (!AssociationLedgerAccess.canEdit) return;

    _openingExpenseFromWidget = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 280));
      if (!mounted) return;
      await showExpenseSheet(context, sheet: const AddExpenseSheet());
    } finally {
      _openingExpenseFromWidget = false;
    }
  }

  @override
  void dispose() {
    PocketlyHomeWidget.addExpenseLaunch.removeListener(_onAddExpenseLaunch);
    widget.tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (!mounted) return;
    final index = widget.tabController.index;
    if (index == _displayedTabIndex) return;
    _displayedTabIndex = index;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tabs = _tabs(l10n);
    final selected = widget.tabController.index;
    final selectedTab = tabs[selected];

    return ListenableBuilder(
      listenable: Listenable.merge([
        getIt<CurrencyPreferences>(),
        getIt<ThemePreferences>(),
      ]),
      builder: (context, _) {
        final palette = context.appPalette;
        return TripleBackToExit(
          child: Stack(
            children: [
              Scaffold(
                backgroundColor: palette.scaffold,
                body: NestedScrollView(
                  physics: const ClampingScrollPhysics(),
                  headerSliverBuilder: (context, _) => [
                    SliverToBoxAdapter(
                      child: _HomeHeader(
                        selectedTab: selectedTab,
                        tabController: widget.tabController,
                      ),
                    ),
                    const SliverToBoxAdapter(child: OfflineBanner()),
                    const SliverToBoxAdapter(
                      child: PendingAssociationInvites(),
                    ),
                    const SliverToBoxAdapter(child: AssociationLedgerBanner()),
                    const SliverToBoxAdapter(child: _HomeQuickTools()),
                    SliverToBoxAdapter(
                      child: KeyedSubtree(
                        key: HomeGuideTargets.tabs,
                        child: _HomeTabStrip(
                          tabs: tabs,
                          selected: selected,
                          onTap: widget.tabController.animateTo,
                        ),
                      ),
                    ),
                  ],
                  body: TabBarView(
                    controller: widget.tabController,
                    children: const [
                      ManageTab(),
                      IncomesTab(),
                      ExpensesTab(),
                      BalanceTab(),
                      LoansTab(),
                      PlansTab(),
                      CommitmentsScreen(embedded: true),
                    ],
                  ),
                ),
              ),
              if (_showGuide)
                Positioned.fill(
                  child: HomeFirstRunGuide(
                    tabController: widget.tabController,
                    onFinished: _finishGuide,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeTabItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Color color;

  const _HomeTabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.color,
  });
}

class _HomeHeader extends StatelessWidget {
  final _HomeTabItem selectedTab;
  final TabController tabController;

  const _HomeHeader({required this.selectedTab, required this.tabController});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.paddingOf(context).top;
    final dateFilter = getIt<HomeDateFilter>();
    final accent = selectedTab.color;

    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, homeState) {
        final profile = homeState.profile;
        final isInitialLoading = homeState.isInitialLoading;
        final isRefreshingProfile =
            homeState.isRefreshingProfile || homeState.isUpdatingUsername;
        final headerTheme = HomeHeaderTheme.resolve(context, accent);

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: headerTheme.gradientColors,
              begin: headerTheme.gradientBegin,
              end: headerTheme.gradientEnd,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
            border: Border(
              bottom: BorderSide(
                color: headerTheme.isDark
                    ? headerTheme.glassBorder
                    : AppColors.stroke.withValues(alpha: 0.08),
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: headerTheme.shadow,
                blurRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
            child: HomeHeaderScope(
              theme: headerTheme,
              child: IconTheme(
                data: IconThemeData(color: headerTheme.foreground),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: headerTheme.foreground),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -40,
                        right: -20,
                        child: _HeaderDecorCircle(
                          size: 140,
                          color: headerTheme.decorSoft,
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -24,
                        child: _HeaderDecorCircle(
                          size: 110,
                          color: accent.withValues(
                            alpha: headerTheme.isDark ? 0.18 : 0.22,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          topPadding + 14,
                          20,
                          20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _UserAvatar(
                                  profile: profile,
                                  isInitialLoading: isInitialLoading,
                                  isRefreshing: isRefreshingProfile,
                                  onTap: profile != null && !isInitialLoading
                                      ? () => showUserSettingsSheet(
                                          context,
                                          profile,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _welcomeLine(
                                          l10n,
                                          profile,
                                          isInitialLoading,
                                        ),
                                        style: TextStyle(
                                          color: headerTheme.foreground,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l10n.homeFinanceOverview,
                                        style: TextStyle(
                                          color: headerTheme.foreground,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.4,
                                          height: 1.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _ActiveTabBadge(tab: selectedTab),
                                const Spacer(),
                                _HeaderIconButton(
                                  icon: Icons.search_rounded,
                                  tooltip: l10n.globalSearchTitle,
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.search),
                                ),
                                const SizedBox(width: 4),
                                ListenableBuilder(
                                  listenable: getIt<NotificationInboxStore>(),
                                  builder: (context, _) {
                                    return _HeaderIconButton(
                                      icon: Icons.notifications_outlined,
                                      tooltip: l10n.notificationsTitle,
                                      badgeCount:
                                          getIt<NotificationInboxStore>()
                                              .unreadCount,
                                      onTap: () => Navigator.of(
                                        context,
                                      ).pushNamed(AppRoutes.notifications),
                                    );
                                  },
                                ),
                                if (profile != null && !isInitialLoading) ...[
                                  const SizedBox(width: 4),
                                  KeyedSubtree(
                                    key: HomeGuideTargets.settings,
                                    child: _HeaderIconButton(
                                      icon: Icons.settings_outlined,
                                      tooltip: l10n.accountSettingsTitle,
                                      onTap: () => showUserSettingsSheet(
                                        context,
                                        profile,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  AssociationSelector(
                                    lightStyle: !headerTheme.isDark,
                                  ),
                                  const SizedBox(width: 8),
                                  const HomeWalletHeaderButton(),
                                  const SizedBox(width: 8),
                                  ListenableBuilder(
                                    listenable: dateFilter,
                                    builder: (context, _) {
                                      return _HeaderActionChip(
                                        icon: dateFilter.isAllMode
                                            ? Icons.date_range_outlined
                                            : dateFilter.isDayMode
                                            ? Icons.today_outlined
                                            : Icons.calendar_month_outlined,
                                        label: dateFilter.headerLabel(context),
                                        isHighlighted: dateFilter.isFiltered,
                                        trailingIcon: Icons.expand_more_rounded,
                                        onTap: () =>
                                            showHomeDateFilterSheet(context),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ListenableBuilder(
                                    listenable: getIt<AssociationContext>(),
                                    builder: (context, _) {
                                      final canEdit =
                                          AssociationLedgerAccess.canEdit;
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (canEdit) ...[
                                            KeyedSubtree(
                                              key: HomeGuideTargets.smartImport,
                                              child: _HeaderActionChip(
                                                icon:
                                                    Icons.auto_awesome_rounded,
                                                label: l10n.magicAddShort,
                                                onTap: () =>
                                                    showMagicAddSheet(context),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          KeyedSubtree(
                                            key: canEdit
                                                ? const ValueKey(
                                                    'home-import-chip',
                                                  )
                                                : HomeGuideTargets.smartImport,
                                            child: _HeaderActionChip(
                                              icon: Icons
                                                  .document_scanner_outlined,
                                              label: l10n.smartImportShort,
                                              trailingIcon:
                                                  Icons.arrow_forward_rounded,
                                              onTap: () => Navigator.of(context)
                                                  .pushNamed(
                                                    AppRoutes.smartImport,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isRefreshingProfile)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: LinearProgressIndicator(
                            minHeight: 2,
                            color: headerTheme.foreground,
                            backgroundColor: headerTheme.foreground.withValues(
                              alpha: 0.24,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _welcomeLine(
    AppLocalizations l10n,
    UserProfile? profile,
    bool isInitialLoading,
  ) {
    if (isInitialLoading) return l10n.homeWelcomeBack;
    if (profile != null && profile.displayName.isNotEmpty) {
      return l10n.homeWelcomeUser(profile.displayName);
    }
    return l10n.homeWelcomeBack;
  }
}

class _HeaderDecorCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _HeaderDecorCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _ActiveTabBadge extends StatelessWidget {
  final _HomeTabItem tab;

  const _ActiveTabBadge({required this.tab});

  @override
  Widget build(BuildContext context) {
    final theme = HomeHeaderScope.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.chipFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.chipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tab.icon, size: 16, color: theme.foreground),
          const SizedBox(width: 6),
          Text(
            tab.label,
            style: TextStyle(
              color: theme.foreground,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int badgeCount;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = HomeHeaderScope.of(context);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: theme.chipFill,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.chipBorder),
                ),
                child: Icon(icon, color: theme.foreground, size: 20),
              ),
              NotificationIconBadge(count: badgeCount),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isHighlighted;
  final IconData? trailingIcon;

  const _HeaderActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isHighlighted = false,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = HomeHeaderScope.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isHighlighted ? theme.chipFillHighlighted : theme.chipFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHighlighted
                  ? theme.chipBorderHighlighted
                  : theme.chipBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: theme.foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: theme.foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 2),
                Icon(trailingIcon, size: 18, color: theme.foregroundMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final UserProfile? profile;
  final bool isInitialLoading;
  final bool isRefreshing;
  final VoidCallback? onTap;

  const _UserAvatar({
    required this.profile,
    required this.isInitialLoading,
    this.isRefreshing = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = _initial(profile);
    final theme = HomeHeaderScope.of(context);

    final avatar = Container(
      height: 52,
      width: 52,
      decoration: BoxDecoration(
        color: theme.chipFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.chipBorder),
      ),
      child: isInitialLoading
          ? Skeletonizer(
              enabled: true,
              ignoreContainers: true,
              child: Center(
                child: Text(
                  initial ?? '?',
                  style: TextStyle(
                    color: theme.foreground,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: initial != null
                      ? Text(
                          initial,
                          style: TextStyle(
                            color: theme.foreground,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Icon(
                          Icons.pie_chart_outline_rounded,
                          color: theme.foreground,
                          size: 28,
                        ),
                ),
                if (isRefreshing)
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Skeletonizer(
                      enabled: true,
                      child: Icon(
                        Icons.sync_rounded,
                        size: 14,
                        color: theme.foreground,
                      ),
                    ),
                  ),
              ],
            ),
    );

    if (onTap == null) return avatar;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: avatar,
      ),
    );
  }

  String? _initial(UserProfile? profile) {
    if (profile == null || profile.displayName.isEmpty) return null;
    return profile.displayName[0].toUpperCase();
  }
}

class _HomeTabStrip extends StatefulWidget {
  final List<_HomeTabItem> tabs;
  final int selected;
  final ValueChanged<int> onTap;

  const _HomeTabStrip({
    required this.tabs,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_HomeTabStrip> createState() => _HomeTabStripState();
}

class _HomeTabStripState extends State<_HomeTabStrip> {
  late final ScrollController _scrollController;
  bool _canScrollMore = false;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _scrollController.addListener(_updateScrollHint);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollHint();
    });
  }

  @override
  void didUpdateWidget(covariant _HomeTabStrip oldWidget) {
    super.didUpdateWidget(oldWidget);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollHint();
    });
  }

  void _updateScrollHint() {
    if (!mounted || !_scrollController.hasClients) return;

    final position = _scrollController.position;
    final canScroll = position.maxScrollExtent - position.pixels > 2;

    if (_canScrollMore != canScroll) {
      setState(() => _canScrollMore = canScroll);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollHint);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SizedBox(
        height: 48,
        child: Stack(
          children: [
            ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsetsDirectional.only(end: _canScrollMore ? 26 : 0),
              itemCount: widget.tabs.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tab = widget.tabs[index];
                final isSelected = widget.selected == index;
                final isDark = Theme.of(context).brightness == Brightness.dark;

                return Material(
                  color: isSelected
                      ? tab.color.withValues(alpha: isDark ? 0.22 : 0.11)
                      : palette.card,
                  borderRadius: BorderRadius.circular(15),
                  child: InkWell(
                    onTap: () => widget.onTap(index),
                    borderRadius: BorderRadius.circular(15),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected
                              ? tab.color.withValues(alpha: 0.55)
                              : palette.stroke.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? tab.selectedIcon : tab.icon,
                            size: 18,
                            color: isSelected ? tab.color : palette.textMuted,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            tab.label,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? palette.textPrimary
                                  : palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            PositionedDirectional(
              end: 0,
              top: 0,
              bottom: 0,
              child: AnimatedOpacity(
                opacity: _canScrollMore ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.centerStart,
                      end: AlignmentDirectional.centerEnd,
                      colors: [
                        palette.scaffold.withValues(alpha: 0),
                        palette.scaffold.withValues(alpha: 0.96),
                      ],
                    ),
                  ),
                  child: HorizontalScrollHint(
                    color: palette.textMuted,
                    size: 18,
                    onTap: () {
                      if (!_scrollController.hasClients) return;

                      final position = _scrollController.position;
                      final isAtEnd =
                          position.maxScrollExtent - position.pixels <= 2;

                      _scrollController.animateTo(
                        isAtEnd ? 0 : position.maxScrollExtent,
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeInOutCubic,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeQuickTools extends StatefulWidget {
  const _HomeQuickTools();

  @override
  State<_HomeQuickTools> createState() => _HomeQuickToolsState();
}

class _HomeQuickToolsState extends State<_HomeQuickTools> {
  late final ScrollController _scrollController;
  bool _canScrollMore = false;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _scrollController.addListener(_updateScrollHint);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollHint();
    });
  }

  void _updateScrollHint() {
    if (!mounted || !_scrollController.hasClients) return;

    final position = _scrollController.position;
    final canScroll = position.maxScrollExtent - position.pixels > 2;

    if (_canScrollMore != canScroll) {
      setState(() => _canScrollMore = canScroll);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollHint);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.appPalette;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final tools = <_QuickToolItem>[
      _QuickToolItem(
        title: l10n.tabStatistics,
        icon: Icons.bar_chart_rounded,
        route: AppRoutes.statistics,
      ),
      _QuickToolItem(
        title: l10n.monthlyReportTitle,
        icon: Icons.calendar_month_rounded,
        route: AppRoutes.monthlyReport,
      ),
      _QuickToolItem(
        title: l10n.recurringTransactionsTitle,
        icon: Icons.repeat_rounded,
        route: AppRoutes.recurring,
      ),
      _QuickToolItem(
        title: l10n.subscriptionsTitle,
        icon: Icons.subscriptions_outlined,
        route: AppRoutes.subscriptions,
      ),
      _QuickToolItem(
        title: l10n.settingsCalculator,
        icon: Icons.calculate_rounded,
        route: AppRoutes.calculator,
      ),
      _QuickToolItem(
        title: l10n.zakatTitle,
        icon: Icons.mosque_outlined,
        route: AppRoutes.zakat,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: palette.textMuted, size: 18),
              const SizedBox(width: 5),
              Text(
                isArabic ? 'أدوات سريعة' : 'Quick tools',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(width: 5),
              AnimatedOpacity(
                opacity: _canScrollMore ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: HorizontalScrollHint(
                  color: palette.textMuted,
                  size: 18,
                  onTap: () {
                    if (!_scrollController.hasClients) return;

                    final position = _scrollController.position;
                    final isAtEnd =
                        position.maxScrollExtent - position.pixels <= 2;

                    _scrollController.animateTo(
                      isAtEnd ? 0 : position.maxScrollExtent,
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeInOutCubic,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.only(end: 8),
              itemCount: tools.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tool = tools[index];

                return Material(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pushNamed(tool.route);
                    },
                    borderRadius: BorderRadius.circular(13),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: palette.stroke.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tool.icon, size: 17, color: palette.textPrimary),
                          const SizedBox(width: 6),
                          Text(
                            tool.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: palette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickToolItem {
  final String title;
  final IconData icon;
  final String route;

  const _QuickToolItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}
