import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:imrpo/features/home/domain/entities/user_profile.dart';
import 'package:imrpo/features/home/presentation/bloc/home_bloc.dart';
import 'package:imrpo/features/home/presentation/widgets/user_settings_sheet.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/home_date_filter.dart';
import 'package:imrpo/core/services/initial_balance_store.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/services/theme_preferences.dart';
import 'package:imrpo/core/helpers/supabase_auth_helper.dart';
import 'package:imrpo/core/services/association_context.dart';
import 'package:imrpo/core/session/user_session.dart';
import 'package:imrpo/features/associations/presentation/widgets/association_ledger_banner.dart';
import 'package:imrpo/features/home/presentation/widgets/association_selector.dart';
import 'package:imrpo/features/home/presentation/widgets/home_date_filter_sheet.dart';
import 'package:imrpo/features/home/presentation/theme/home_header_theme.dart';
import 'package:imrpo/features/home/presentation/widgets/home_wallet_header_chip.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/balance_tab/presentation/pages/balance_tab.dart';
import 'package:imrpo/features/expenses_tab/presentation/pages/expenses_tab.dart';
import 'package:imrpo/features/incomes_tab/presentation/pages/incomes_tab.dart';
import 'package:imrpo/features/plans_tab/presentation/pages/plans_tab.dart';
import 'package:imrpo/features/loans_tab/presentation/pages/loans_tab.dart';
import 'package:imrpo/core/config/app_router.dart';
import 'package:imrpo/core/services/notification_inbox_store.dart';
import 'package:imrpo/core/widgets/notification_icon_badge.dart';
import 'package:imrpo/core/services/onboarding_preferences.dart';
import 'package:imrpo/core/widgets/triple_back_to_exit.dart';
import 'package:imrpo/core/widgets/offline_banner.dart';
import 'package:imrpo/features/home/presentation/widgets/home_first_run_guide.dart';
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
    _tabController = TabController(length: 5, vsync: this);
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

  List<_HomeTabItem> _tabs(AppLocalizations l10n) => [
    _HomeTabItem(
      label: l10n.tabIncomes,
      icon: Icons.south_west_rounded,
      color: AppColors.income,
    ),
    _HomeTabItem(
      label: l10n.tabExpenses,
      icon: Icons.north_east_rounded,
      color: AppColors.expense,
    ),
    _HomeTabItem(
      label: l10n.tabBalance,
      icon: Icons.account_balance_wallet_outlined,
      color: AppColors.balance,
    ),
    _HomeTabItem(
      label: l10n.tabLoans,
      icon: Icons.handshake_outlined,
      color: AppColors.loans,
    ),
    _HomeTabItem(
      label: l10n.tabPlans,
      icon: Icons.flag_outlined,
      color: AppColors.plans,
    ),
  ];

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartGuide());
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
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
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
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverToBoxAdapter(
                      child: _HomeHeader(
                        selectedTab: selectedTab,
                        tabController: widget.tabController,
                      ),
                    ),
                    const SliverToBoxAdapter(child: OfflineBanner()),
                    const SliverToBoxAdapter(child: AssociationLedgerBanner()),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: KeyedSubtree(
                          key: HomeGuideTargets.tabs,
                          child: Row(
                            children: List.generate(tabs.length, (index) {
                              final tab = tabs[index];
                              final isSelected = selected == index;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: index == 0 ? 0 : 4,
                                    right: index == tabs.length - 1 ? 0 : 4,
                                  ),
                                  child: _TabChip(
                                    tab: tab,
                                    isSelected: isSelected,
                                    onTap: () =>
                                        widget.tabController.animateTo(index),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ],
                  body: TabBarView(
                    controller: widget.tabController,
                    children: const [
                      IncomesTab(),
                      ExpensesTab(),
                      BalanceTab(),
                      LoansTab(),
                      PlansTab(),
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
  final Color color;

  const _HomeTabItem({
    required this.label,
    required this.icon,
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
                color: headerTheme.isDark
                    ? headerTheme.shadow
                    : AppColors.primary.withValues(alpha: 0.22),
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
                    padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 20),
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
                                  ? () =>
                                        showUserSettingsSheet(context, profile)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _welcomeLine(
                                      l10n,
                                      profile,
                                      isInitialLoading,
                                    ),
                                    style: TextStyle(
                                      color: headerTheme.foregroundMuted,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
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
                                  const SizedBox(height: 6),
                                  _ActiveTabBadge(tab: selectedTab),
                                ],
                              ),
                            ),
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
                                  badgeCount: getIt<NotificationInboxStore>()
                                      .unreadCount,
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.notifications),
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                            if (profile != null && !isInitialLoading)
                              KeyedSubtree(
                                key: HomeGuideTargets.settings,
                                child: _HeaderIconButton(
                                  icon: Icons.settings_outlined,
                                  tooltip: l10n.accountSettingsTitle,
                                  onTap: () =>
                                      showUserSettingsSheet(context, profile),
                                ),
                              ),
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
                              KeyedSubtree(
                                key: HomeGuideTargets.smartImport,
                                child: _HeaderActionChip(
                                  icon: Icons.document_scanner_outlined,
                                  label: l10n.smartImportShort,
                                  trailingIcon: Icons.arrow_forward_rounded,
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.smartImport),
                                ),
                              ),
                              // const SizedBox(width: 8),
                              // _HeaderActionChip(
                              //   icon: Icons.bar_chart_rounded,
                              //   label: l10n.tabStatistics,
                              //   trailingIcon: Icons.arrow_forward_rounded,
                              //   onTap: () => Navigator.of(
                              //     context,
                              //   ).pushNamed(AppRoutes.statistics),
                              // ),
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
          Icon(tab.icon, size: 14, color: theme.foreground),
          const SizedBox(width: 6),
          Text(
            tab.label,
            style: TextStyle(
              color: theme.foreground,
              fontSize: 12,
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

class _TabChip extends StatelessWidget {
  final _HomeTabItem tab;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabChip({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? tab.color : palette.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? palette.stroke.withValues(alpha: 0.18)
                  : palette.stroke.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isSelected ? tab.color : palette.stroke).withValues(
                  alpha: isSelected ? 0.28 : 0.08,
                ),
                blurRadius: 0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.icon,
                size: 20,
                color: isSelected ? Colors.white : tab.color,
              ),
              const SizedBox(height: 6),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
