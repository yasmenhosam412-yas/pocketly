import 'package:flutter/material.dart';
import 'package:imrpo/core/helpers/supabase_auth_helper.dart';
import 'package:imrpo/core/services/onboarding_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/auth/presentation/pages/login_screen.dart';
import 'package:imrpo/features/home/presentation/pages/home_screen.dart';
import 'package:imrpo/features/onboarding/presentation/widgets/onboarding_page_content.dart';
import 'package:imrpo/features/onboarding/presentation/widgets/onboarding_pinned_icon.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _pageIndex = 0;
  bool _forward = true;
  static const _pageCount = 3;

  late final AnimationController _footerController;
  late final Animation<double> _footerFade;
  late final Animation<Offset> _footerSlide;

  @override
  void initState() {
    super.initState();
    _footerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _footerFade = CurvedAnimation(
      parent: _footerController,
      curve: Curves.easeOut,
    );
    _footerSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _footerController,
            curve: Curves.easeOutCubic,
          ),
        );
    _footerController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await getIt<OnboardingPreferences>().setCompleted();
    if (!mounted) return;

    final next = SupabaseAuthHelper.isSignedIn
        ? const HomeScreen()
        : const LoginScreen();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => next));
  }

  void _goToPage(int index) {
    if (index == _pageIndex) return;
    setState(() {
      _forward = index > _pageIndex;
      _pageIndex = index;
    });
  }

  void _onNext() {
    if (_pageIndex >= _pageCount - 1) {
      _finish();
      return;
    }
    setState(() => _forward = true);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  List<({String title, String body})> _pages(AppLocalizations l10n) => [
    (title: l10n.onboardingPage1Title, body: l10n.onboardingPage1Body),
    (title: l10n.onboardingPage2Title, body: l10n.onboardingPage2Body),
    (title: l10n.onboardingPage3Title, body: l10n.onboardingPage3Body),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = _pages(l10n);
    final isLast = _pageIndex >= _pageCount - 1;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    l10n.onboardingSkip,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 28),
                  OnboardingPinnedIcon(pageIndex: _pageIndex),
                  const SizedBox(height: 28),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pageCount,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (i) => _goToPage(i),
                      itemBuilder: (context, index) {
                        final p = pages[index];
                        return OnboardingPageContent(
                          key: ValueKey('${_pageIndex}_$index'),
                          title: p.title,
                          body: p.body,
                          forward: _forward,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            FadeTransition(
              opacity: _footerFade,
              child: SlideTransition(
                position: _footerSlide,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(28, 0, 28, 20 + bottomInset),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pageCount, (i) {
                          final active = i == _pageIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            width: active ? 22 : 7,
                            height: active ? 7 : 7,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: active
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: _onNext,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onWarm,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.35),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              isLast
                                  ? l10n.onboardingGetStarted
                                  : l10n.onboardingNext,
                              key: ValueKey(isLast),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
