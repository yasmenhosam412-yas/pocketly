import 'package:flutter/material.dart';
import 'package:imrpo/core/utils/app_colors.dart';

/// Fixed wallet art: idle float, glow pulse, entrance, and bounce on page change.
class OnboardingPinnedIcon extends StatefulWidget {
  const OnboardingPinnedIcon({super.key, required this.pageIndex});

  final int pageIndex;

  @override
  State<OnboardingPinnedIcon> createState() => _OnboardingPinnedIconState();
}

class _OnboardingPinnedIconState extends State<OnboardingPinnedIcon>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _bounceController;
  late final AnimationController _entryController;
  late final AnimationController _glowController;

  late final Animation<double> _floatY;
  late final Animation<double> _floatTilt;
  late final Animation<double> _bounceScale;
  late final Animation<double> _bounceTilt;
  late final Animation<double> _entryScale;
  late final Animation<double> _entryOpacity;
  late final Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _floatY = Tween<double>(begin: -14, end: 14).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _floatTilt = Tween<double>(begin: -0.04, end: 0.04).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowOpacity = Tween<double>(begin: 0.12, end: 0.32).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _entryScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.elasticOut),
    );
    _entryOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0, 0.55, curve: Curves.easeOut),
      ),
    );
    _entryController.forward();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    _bounceScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.14), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.14, end: 0.96), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0), weight: 40),
    ]).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOut),
    );
    _bounceTilt = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.08), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: -0.05), weight: 35),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.0), weight: 30),
    ]).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(OnboardingPinnedIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageIndex != widget.pageIndex) {
      _bounceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _bounceController.dispose();
    _entryController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _floatController,
        _bounceController,
        _entryController,
        _glowController,
      ]),
      builder: (context, child) {
        final tilt = _floatTilt.value + _bounceTilt.value;
        final scale = _entryScale.value * _bounceScale.value;

        return Opacity(
          opacity: _entryOpacity.value,
          child: Transform.translate(
            offset: Offset(0, _floatY.value),
            child: Transform.rotate(
              angle: tilt,
              child: Transform.scale(
                scale: scale,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryInk
                                .withValues(alpha: _glowOpacity.value),
                            blurRadius: 48,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    child!,
                  ],
                ),
              ),
            ),
          ),
        );
      },
      child: Image.asset(
        'assets/wallet.png',
        height: 200,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
