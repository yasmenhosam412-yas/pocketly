import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/config/app_router.dart';
import 'package:imrpo/core/services/app_lock_service.dart';
import 'package:imrpo/core/services/initial_balance_store.dart';
import 'package:imrpo/core/services/locale_preferences.dart';
import 'package:imrpo/core/services/theme_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/services/pocketly_home_widget.dart';
import 'package:imrpo/core/widgets/app_toast.dart';
import 'package:imrpo/features/home/presentation/widgets/appearance_settings_sheet.dart';
import 'package:imrpo/features/home/presentation/widgets/app_lock_settings.dart';
import 'package:imrpo/core/session/user_session.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/widgets/show_app_bottom_sheet.dart';
import 'package:imrpo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:imrpo/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:imrpo/features/home/domain/entities/user_profile.dart';
import 'package:imrpo/features/home/presentation/bloc/home_bloc.dart';
import 'package:imrpo/features/notifications/presentation/pages/notifications_screen.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/features/plans_tab/presentation/bloc/plans_tab_bloc.dart';
import 'package:imrpo/features/balance_tab/presentation/widgets/edit_initial_balance_sheet.dart';
import 'package:imrpo/features/salary_day/presentation/widgets/salary_day_sheet.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/core/utils/open_play_store.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class UserSettingsSheet extends StatefulWidget {
  final UserProfile profile;

  const UserSettingsSheet({super.key, required this.profile});

  @override
  State<UserSettingsSheet> createState() => _UserSettingsSheetState();
}

class _UserSettingsSheetState extends State<UserSettingsSheet> {
  bool _usernameUpdatedSnackShown = false;
  bool _authNavigationHandled = false;

  void _leaveAppAfterAuthChange(BuildContext context) {
    if (_authNavigationHandled) return;
    _authNavigationHandled = true;
    FocusManager.instance.primaryFocus?.unfocus();
    UserSession.clearAll(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (_) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: getIt<ThemePreferences>(),
      builder: (context, _) => MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              current.status == AuthStatus.loggedOut ||
              current.status == AuthStatus.accountDeleted ||
              current.status == AuthStatus.errorLogout ||
              current.status == AuthStatus.errorDeleteAccount,
          listener: (context, state) {
            if (state.status == AuthStatus.loggedOut ||
                state.status == AuthStatus.accountDeleted) {
              _leaveAppAfterAuthChange(context);
              return;
            }
            if (state.status == AuthStatus.errorLogout ||
                state.status == AuthStatus.errorDeleteAccount) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(localizeApiError(l10n, state.errorMessage)),
                  backgroundColor: AppColors.errorColor,
                ),
              );
            }
          },
        ),
        BlocListener<HomeBloc, HomeState>(
          listenWhen: (prev, curr) =>
              prev.status == HomeStatus.updatingUsername &&
              curr.status == HomeStatus.loaded,
          listener: (context, state) {
            if (_usernameUpdatedSnackShown) return;
            _usernameUpdatedSnackShown = true;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.usernameUpdated)));
          },
        ),
        BlocListener<HomeBloc, HomeState>(
          listenWhen: (_, curr) =>
              curr.status == HomeStatus.errorUpdateUsername,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localizeApiError(l10n, state.error)),
                backgroundColor: AppColors.errorColor,
              ),
            );
          },
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final isLoggingOut =
              authState.status == AuthStatus.loadingLogout;
          final isDeletingAccount =
              authState.status == AuthStatus.loadingDeleteAccount;
          final isAuthBusy = isLoggingOut || isDeletingAccount;

          return BlocBuilder<HomeBloc, HomeState>(
            builder: (context, homeState) {
              final isUpdatingUsername = homeState.isUpdatingUsername;
              final profile = homeState.profile ?? widget.profile;
              final avatarInitial = profile.displayName.isNotEmpty
                  ? profile.displayName[0].toUpperCase()
                  : '?';
              final actionsLocked = isAuthBusy || isUpdatingUsername;
              final palette = context.appPalette;

              return PopScope(
                canPop: !isAuthBusy,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.92,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: palette.textMuted.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.accountSettingsTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primaryInk.withValues(
                            alpha: 0.15,
                          ),
                          child: Text(
                            avatarInitial,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryInk,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.displayName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textColor,
                                ),
                              ),
                              if (profile.email.isNotEmpty)
                                Text(
                                  profile.email,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textColor.withValues(
                                      alpha: 0.55,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ListenableBuilder(
                      listenable: getIt<LocalePreferences>(),
                      builder: (context, _) {
                        final localePrefs = getIt<LocalePreferences>();
                        final currentLang = LocalePreferences.languageLabel(
                          l10n,
                          localePrefs.locale.languageCode,
                        );

                        return _SettingsTile(
                          icon: Icons.language_rounded,
                          label: l10n.settingsLanguage,
                          trailing: Text(
                            currentLang,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textColor.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                          onTap: actionsLocked
                              ? null
                              : () => _showLanguageDialog(context),
                        );
                      },
                    ),
                    ListenableBuilder(
                      listenable: getIt<ThemePreferences>(),
                      builder: (context, _) {
                        final themePrefs = getIt<ThemePreferences>();
                        final currentTheme = themePrefs.appearanceSummary(l10n);

                        return _SettingsTile(
                          icon: Icons.palette_outlined,
                          label: l10n.settingsTheme,
                          trailing: Text(
                            currentTheme,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textColor.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                          onTap: actionsLocked
                              ? null
                              : () => showAppearanceSettingsSheet(context),
                        );
                      },
                    ),
                    ListenableBuilder(
                      listenable: getIt<InitialBalanceStore>(),
                      builder: (context, _) {
                        final store = getIt<InitialBalanceStore>();

                        return _SettingsTile(
                          icon: Icons.account_balance_wallet_outlined,
                          label: l10n.settingsInitialBalance,
                          trailing: Text(
                            Money.format(store.amount),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textColor.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                          onTap: actionsLocked
                              ? null
                              : () => showEditInitialBalanceSheet(context),
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.bar_chart_rounded,
                      label: l10n.tabStatistics,
                      onTap: actionsLocked
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pushNamed(
                                AppRoutes.statistics,
                              );
                            },
                    ),
                    _SettingsTile(
                      icon: Icons.assessment_outlined,
                      label: l10n.monthlyReportTitle,
                      onTap: actionsLocked
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pushNamed(
                                AppRoutes.monthlyReport,
                              );
                            },
                    ),
                    _SettingsTile(
                      icon: Icons.auto_awesome_rounded,
                      label: l10n.yearInReviewTitle,
                      onTap: actionsLocked
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pushNamed(
                                AppRoutes.yearInReview,
                              );
                            },
                    ),
                    _SettingsTile(
                      icon: Icons.payments_outlined,
                      label: l10n.salaryDayTitle,
                      onTap: actionsLocked
                          ? null
                          : () {
                              final plans = context.read<PlansTabBloc>();
                              final expenses = context.read<ExpensesTabBloc>();
                              Navigator.of(context).pop();
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                final host = rootNavigatorKey.currentContext;
                                if (host == null || !host.mounted) return;
                                showSalaryDaySheet(
                                  host,
                                  plansBloc: plans,
                                  expensesBloc: expenses,
                                );
                              });
                            },
                    ),
                    _SettingsTile(
                      icon: Icons.notifications_outlined,
                      label: l10n.notificationsTitle,
                      onTap: actionsLocked
                          ? null
                          : () async {
                              Navigator.of(context).pop();
                              await openNotificationsScreen();
                            },
                    ),
                    if (PocketlyHomeWidget.isAndroid) ...[
                      _SettingsTile(
                        icon: Icons.widgets_outlined,
                        label: l10n.homeWidgetSettingsTile,
                        onTap: actionsLocked
                            ? null
                            : () async {
                                final pinned =
                                    await PocketlyHomeWidget.requestPin();
                                if (!context.mounted) return;
                                if (!pinned) {
                                  AppToast.show(
                                    context,
                                    l10n.homeWidgetPinUnsupported,
                                  );
                                }
                              },
                      ),
                      _SettingsTile(
                        icon: Icons.add_card_outlined,
                        label: l10n.homeWidgetQuickSettingsTile,
                        onTap: actionsLocked
                            ? null
                            : () async {
                                final pinned =
                                    await PocketlyHomeWidget.requestPin(
                                  quickExpense: true,
                                );
                                if (!context.mounted) return;
                                if (!pinned) {
                                  AppToast.show(
                                    context,
                                    l10n.homeWidgetPinUnsupported,
                                  );
                                }
                              },
                      ),
                    ],
                    _SettingsTile(
                      icon: Icons.repeat_rounded,
                      label: l10n.recurringTransactionsTitle,
                      onTap: actionsLocked
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pushNamed(
                                AppRoutes.recurring,
                              );
                            },
                    ),
                    _SettingsTile(
                      icon: Icons.subscriptions_outlined,
                      label: l10n.subscriptionsTitle,
                      onTap: actionsLocked
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pushNamed(
                                AppRoutes.subscriptions,
                              );
                            },
                    ),
                    _SettingsTile(
                      icon: Icons.mosque_outlined,
                      label: l10n.zakatTitle,
                      onTap: actionsLocked
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pushNamed(AppRoutes.zakat);
                            },
                    ),
                    _SettingsTile(
                      icon: Icons.calculate_rounded,
                      label: l10n.settingsCalculator,
                      onTap: actionsLocked
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pushNamed(
                                AppRoutes.calculator,
                              );
                            },
                    ),
                    _SettingsTile(
                      icon: Icons.star_rate_rounded,
                      label: l10n.settingsRateApp,
                      onTap: actionsLocked
                          ? null
                          : () async {
                              Navigator.of(context).pop();
                              final host = rootNavigatorKey.currentContext;
                              final opened =
                                  await openPocketlyPlayStoreListing();
                              if (opened) return;
                              if (host == null || !host.mounted) return;
                              AppToast.show(
                                host,
                                AppLocalizations.of(host)!.settingsRateAppFailed,
                                error: true,
                              );
                            },
                    ),
                    ListenableBuilder(
                      listenable: getIt<AppLockService>(),
                      builder: (context, _) {
                        final lock = getIt<AppLockService>();

                        return Column(
                          children: [
                            _SettingsTile(
                              icon: Icons.lock_outline_rounded,
                              label: l10n.settingsAppLock,
                              trailing: Switch.adaptive(
                                value: lock.isEnabled,
                                activeThumbColor: AppColors.primaryInk,
                                onChanged: actionsLocked
                                    ? null
                                    : (enabled) async {
                                        if (enabled) {
                                          await enableAppLock(context);
                                        } else {
                                          await disableAppLock(context);
                                        }
                                      },
                              ),
                            ),
                            if (lock.isEnabled &&
                                lock.canUseBiometrics) ...[
                              _SettingsTile(
                                icon: lock.supportsFace
                                    ? Icons.face_rounded
                                    : Icons.fingerprint_rounded,
                                label: l10n.settingsAppLockBiometric,
                                trailing: Switch.adaptive(
                                  value: lock.biometricEnabled,
                                  activeThumbColor: AppColors.primaryInk,
                                  onChanged: actionsLocked
                                      ? null
                                      : (enabled) => toggleAppLockBiometric(
                                            context,
                                            enabled: enabled,
                                          ),
                                ),
                              ),
                            ],
                            if (lock.isEnabled)
                              _SettingsTile(
                                icon: Icons.pin_outlined,
                                label: l10n.settingsAppLockChangePin,
                                onTap: actionsLocked
                                    ? null
                                    : () => changeAppLockPin(context),
                              ),
                          ],
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      label: l10n.changeUsername,
                      isLoading: isUpdatingUsername,
                      onTap: actionsLocked
                          ? null
                          : () => _showChangeUsernameDialog(
                              context,
                              profile.username,
                            ),
                    ),
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      label: l10n.logout,
                      isLoading: isLoggingOut,
                      onTap: isAuthBusy
                          ? null
                          : () => _confirmLogout(context),
                    ),
                    _SettingsTile(
                      icon: Icons.delete_outline_rounded,
                      label: l10n.deleteAccount,
                      isDestructive: true,
                      isLoading: isDeletingAccount,
                      onTap: isAuthBusy
                          ? null
                          : () => _confirmDeleteAccount(context),
                    ),
                        SizedBox(
                          height: MediaQuery.paddingOf(context).bottom,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
    );
  }

  Future<void> _showLanguageDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final localePrefs = getIt<LocalePreferences>();
    var selected = localePrefs.locale.languageCode;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return ListenableBuilder(
            listenable: localePrefs,
            builder: (context, _) {
              final isSaving = localePrefs.isSaving;

              return AlertDialog(
                title: Text(l10n.settingsLanguage),
                content: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'en',
                      label: Text(l10n.languageEnglish),
                    ),
                    ButtonSegment(
                      value: 'ar',
                      label: Text(l10n.languageArabic),
                    ),
                  ],
                  selected: {selected},
                  onSelectionChanged: isSaving
                      ? null
                      : (value) {
                          setDialogState(() => selected = value.first);
                        },
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            await localePrefs.setLocale(Locale(selected));
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          },
                    child: isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : Text(l10n.save),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showChangeUsernameDialog(
    BuildContext context,
    String currentUsername,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentUsername);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.changeUsername),
        content: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.2,
          child: CustomFormField(
            label: l10n.labelFullName,
            hint: l10n.hintEnterYourName,
            controller: controller,
            obscure: false,
            icon: Icons.person_outline,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (saved != true || !context.mounted) return;

    final username = controller.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorEnterUsername),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    _usernameUpdatedSnackShown = false;
    context.read<HomeBloc>().add(UpdateUsernameEvent(username));
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(const LogoutEvent());
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAccountConfirmTitle),
        content: Text(l10n.deleteAccountConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorColor,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(const DeleteAccountEvent());
    }
  }

}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool isLoading;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.errorColor : AppColors.textColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, color: color.withValues(alpha: 0.85)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              ?trailing,
              if (isLoading)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryInk,
                  ),
                )
              else if (trailing == null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textColor.withValues(alpha: 0.35),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

void showUserSettingsSheet(BuildContext context, UserProfile profile) {
  showAppBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<HomeBloc>()),
        BlocProvider.value(value: context.read<AuthBloc>()),
        BlocProvider.value(value: context.read<IncomesTabBloc>()),
      ],
      child: UserSettingsSheet(profile: profile),
    ),
  );
}
