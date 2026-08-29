import 'package:flutter/material.dart';
import 'package:imrpo/core/helpers/association_ledger_access.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class HomeGuideTargets {
  static final tabs = GlobalKey();
  static final addIncome = GlobalKey();
  static final addExpense = GlobalKey();
  static final smartImport = GlobalKey();
  static final settings = GlobalKey();
}

class _GuideStep {
  final GlobalKey target;
  final int? tabIndex;
  final String title;
  final String body;

  const _GuideStep({
    required this.target,
    required this.title,
    required this.body,
    this.tabIndex,
  });
}

/// Spotlight walkthrough of the actions a new user needs on Home.
class HomeFirstRunGuide extends StatefulWidget {
  final TabController tabController;
  final VoidCallback onFinished;

  const HomeFirstRunGuide({
    super.key,
    required this.tabController,
    required this.onFinished,
  });

  @override
  State<HomeFirstRunGuide> createState() => _HomeFirstRunGuideState();
}

class _HomeFirstRunGuideState extends State<HomeFirstRunGuide> {
  int _index = 0;
  Rect? _hole;

  List<_GuideStep> _steps(AppLocalizations l10n) {
    return [
      _GuideStep(
        target: HomeGuideTargets.tabs,
        tabIndex: 0,
        title: l10n.homeGuideTabsTitle,
        body: l10n.homeGuideTabsBody,
      ),
      if (AssociationLedgerAccess.canEdit) ...[
        _GuideStep(
          target: HomeGuideTargets.addIncome,
          tabIndex: 0,
          title: l10n.homeGuideIncomeTitle,
          body: l10n.homeGuideIncomeBody,
        ),
        _GuideStep(
          target: HomeGuideTargets.addExpense,
          tabIndex: 1,
          title: l10n.homeGuideExpenseTitle,
          body: l10n.homeGuideExpenseBody,
        ),
      ],
      _GuideStep(
        target: HomeGuideTargets.smartImport,
        title: l10n.homeGuideImportTitle,
        body: l10n.homeGuideImportBody,
      ),
      _GuideStep(
        target: HomeGuideTargets.settings,
        title: l10n.homeGuideSettingsTitle,
        body: l10n.homeGuideSettingsBody,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareStep());
  }

  Future<void> _prepareStep() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final steps = _steps(l10n);
    if (steps.isEmpty) {
      widget.onFinished();
      return;
    }
    final step = steps[_index];
    if (step.tabIndex != null && widget.tabController.index != step.tabIndex) {
      widget.tabController.animateTo(step.tabIndex!);
      await Future<void>.delayed(const Duration(milliseconds: 380));
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    setState(() => _hole = _rectFor(step.target));
  }

  Rect? _rectFor(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    final overlayBox = context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return null;
    final global = box.localToGlobal(Offset.zero);
    final local = overlayBox.globalToLocal(global);
    return (local & box.size).inflate(8);
  }

  void _next(int stepCount) {
    if (_index >= stepCount - 1) {
      widget.onFinished();
      return;
    }
    setState(() {
      _index++;
      _hole = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareStep());
  }

  void _back() {
    if (_index == 0) {
      widget.onFinished();
      return;
    }
    setState(() {
      _index--;
      _hole = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareStep());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final steps = _steps(l10n);
    if (steps.isEmpty) return const SizedBox.shrink();
    final step = steps[_index];
    final isLast = _index >= steps.length - 1;
    final media = MediaQuery.of(context);
    final hole = _hole;

    final cardOnTop = hole != null && hole.center.dy > media.size.height * 0.52;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _back();
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _SpotlightPainter(
                  hole: hole,
                  dimColor: Colors.black.withValues(alpha: 0.62),
                ),
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _next(steps.length),
                child: const SizedBox.expand(),
              ),
            ),
            _GuideCard(
              title: step.title,
              body: step.body,
              stepLabel: '${_index + 1} / ${steps.length}',
              primaryLabel: isLast ? l10n.homeGuideDone : l10n.homeGuideNext,
              skipLabel: l10n.onboardingSkip,
              onPrimary: () => _next(steps.length),
              onSkip: widget.onFinished,
              preferTop: cardOnTop,
              hole: hole,
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final String title;
  final String body;
  final String stepLabel;
  final String primaryLabel;
  final String skipLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSkip;
  final bool preferTop;
  final Rect? hole;

  const _GuideCard({
    required this.title,
    required this.body,
    required this.stepLabel,
    required this.primaryLabel,
    required this.skipLabel,
    required this.onPrimary,
    required this.onSkip,
    required this.preferTop,
    required this.hole,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: AppDecorations.card(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                stepLabel,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(onPressed: onSkip, child: Text(skipLabel)),
            ],
          ),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: onPrimary,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                primaryLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    double top;
    if (hole == null) {
      top = media.size.height * 0.32;
    } else if (preferTop) {
      top = (hole!.top - 220).clamp(media.padding.top + 12, hole!.top - 16);
    } else {
      top = (hole!.bottom + 16).clamp(
        media.padding.top + 12,
        media.size.height - media.padding.bottom - 240,
      );
    }

    return Positioned(
      left: 0,
      right: 0,
      top: top,
      child: GestureDetector(
        onTap: () {},
        child: card,
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? hole;
  final Color dimColor;

  _SpotlightPainter({required this.hole, required this.dimColor});

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()..addRect(Offset.zero & size);
    if (hole != null) {
      overlay
        ..addRRect(RRect.fromRectAndRadius(hole!, const Radius.circular(18)))
        ..fillType = PathFillType.evenOdd;
    }
    canvas.drawPath(overlay, Paint()..color = dimColor);
    if (hole != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(hole!, const Radius.circular(18)),
        Paint()
          ..color = AppColors.primaryInk
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole || oldDelegate.dimColor != dimColor;
}
