import 'package:flutter/material.dart';
import 'package:imrpo/core/utils/app_colors.dart';

class OnboardingPageContent extends StatefulWidget {
  const OnboardingPageContent({
    super.key,
    required this.title,
    required this.body,
    required this.forward,
  });

  final String title;
  final String body;
  final bool forward;

  @override
  State<OnboardingPageContent> createState() => _OnboardingPageContentState();
}

class _OnboardingPageContentState extends State<OnboardingPageContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _titleSlide;
  late Animation<Offset> _bodySlide;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _controller.forward();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    final dx = widget.forward ? 0.18 : -0.18;
    _titleSlide = Tween<Offset>(
      begin: Offset(dx, 0.14),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.75, curve: Curves.easeOutCubic),
    ));
    _bodySlide = Tween<Offset>(
      begin: Offset(dx, 0.22),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.12, 1, curve: Curves.easeOutCubic),
    ));
  }

  @override
  void didUpdateWidget(OnboardingPageContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title ||
        oldWidget.forward != widget.forward) {
      _controller.dispose();
      _setupAnimations();
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: FadeTransition(
        opacity: _fade,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SlideTransition(
              position: _titleSlide,
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SlideTransition(
              position: _bodySlide,
              child: Text(
                widget.body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
