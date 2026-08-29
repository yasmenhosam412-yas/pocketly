import 'package:flutter/material.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/auth/domain/entities/social_auth_provider.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class AuthSocialButtons extends StatelessWidget {
  final bool isBusy;
  final SocialAuthProvider? loadingProvider;
  final ValueChanged<SocialAuthProvider> onPressed;

  const AuthSocialButtons({
    super.key,
    required this.isBusy,
    required this.loadingProvider,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.appPalette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: palette.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l10n.orDivider,
                style: TextStyle(
                  color: palette.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            Expanded(child: Divider(color: palette.border)),
          ],
        ),
        const SizedBox(height: 16),
        _SocialLoginButton(
          label: l10n.continueWithGoogle,
          background: palette.surface,
          foreground: palette.textPrimary,
          borderColor: palette.border,
          icon: const _GoogleMark(),
          isLoading: loadingProvider == SocialAuthProvider.google,
          enabled: !isBusy,
          onPressed: () => onPressed(SocialAuthProvider.google),
        ),
        const SizedBox(height: 12),
        _SocialLoginButton(
          label: l10n.continueWithFacebook,
          background: const Color(0xFF1877F2),
          foreground: Colors.white,
          borderColor: const Color(0xFF1877F2),
          icon: const _FacebookMark(),
          isLoading: loadingProvider == SocialAuthProvider.facebook,
          enabled: !isBusy,
          onPressed: () => onPressed(SocialAuthProvider.facebook),
        ),
      ],
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Color borderColor;
  final Widget icon;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onPressed;

  const _SocialLoginButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.borderColor,
    required this.icon,
    required this.isLoading,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: enabled && !isLoading ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: 0.7),
          disabledForegroundColor: foreground.withValues(alpha: 0.7),
          side: BorderSide(color: borderColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: foreground,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(
      size.width * 0.12,
      size.height * 0.12,
      size.width * 0.76,
      size.height * 0.76,
    );

    stroke.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.2, 1.7, false, stroke);
    stroke.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 1.5, 0.9, false, stroke);
    stroke.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.4, 0.8, false, stroke);
    stroke.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.2, 1.1, false, stroke);

    final bar = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.48,
        size.height * 0.44,
        size.width * 0.4,
        size.height * 0.16,
      ),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FacebookMark extends StatelessWidget {
  const _FacebookMark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'f',
      style: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1,
      ),
    );
  }
}
