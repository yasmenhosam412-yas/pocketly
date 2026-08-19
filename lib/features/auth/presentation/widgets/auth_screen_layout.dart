import 'package:flutter/material.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/auth/presentation/theme/auth_header_theme.dart';

/// Shared auth shell: gradient header + elevated form card (matches home header).
class AuthScreenLayout extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final VoidCallback? onBack;

  const AuthScreenLayout({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: palette.scaffold,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _AuthGradientHeader(
              icon: icon,
              title: title,
              subtitle: subtitle,
              topPadding: topPadding,
              onBack: onBack,
            ),
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -28),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: palette.card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: palette.border.withValues(
                                alpha: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? 0.65
                                    : 0.35,
                              ),
                              width: AppDecorations.outlineWidth,
                            ),
                            boxShadow: AppDecorations.flatShadow(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.black
                                  : AppColors.stroke,
                            ),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            child: child,
                          ),
                        ),
                      ),
                      if (footer != null) ...[
                        const SizedBox(height: 12),
                        footer!,
                        SizedBox(
                          height: MediaQuery.paddingOf(context).bottom + 8,
                        ),
                      ] else
                        SizedBox(
                          height: MediaQuery.paddingOf(context).bottom + 8,
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

class _AuthGradientHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double topPadding;
  final VoidCallback? onBack;

  const _AuthGradientHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.topPadding,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final header = AuthHeaderTheme.resolve(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: header.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        border: Border(
          bottom: BorderSide(
            color: header.glassBorder.withValues(alpha: 0.5),
            width: AppDecorations.outlineWidth,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: header.shadow,
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, topPadding + 8, 20, 44),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onBack != null)
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: header.foreground,
                style: IconButton.styleFrom(
                  backgroundColor: header.glassFill,
                  padding: const EdgeInsets.all(10),
                ),
              )
            else
              const SizedBox(height: 8),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: header.iconGlassFill,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: header.glassBorder,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: header.shadow,
                        offset: const Offset(0, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/wallet.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        icon,
                        color: header.foreground,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: header.foreground,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.4,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: header.foregroundMuted,
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
