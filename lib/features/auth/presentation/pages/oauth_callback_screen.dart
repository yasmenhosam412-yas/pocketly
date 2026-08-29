import 'package:flutter/material.dart';
import 'package:imrpo/core/config/oauth_config.dart';
import 'package:imrpo/core/helpers/supabase_auth_helper.dart';
import 'package:imrpo/core/services/app_lock_service.dart';
import 'package:imrpo/core/services/onboarding_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/auth/presentation/pages/login_screen.dart';
import 'package:imrpo/features/home/presentation/pages/home_screen.dart';
import 'package:imrpo/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Finishes Google/Facebook OAuth when Flutter delivers the callback as a route.
class OAuthCallbackScreen extends StatefulWidget {
  final String? routeName;

  const OAuthCallbackScreen({super.key, this.routeName});

  @override
  State<OAuthCallbackScreen> createState() => _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends State<OAuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _complete());
  }

  Future<void> _complete() async {
    final raw = widget.routeName ?? ModalRoute.of(context)?.settings.name;
    final uri = OAuthConfig.uriFromRouteName(raw);
    if (uri != null) {
      try {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      } catch (_) {}
    }

    if (!mounted) return;

    final Widget next;
    if (!getIt<OnboardingPreferences>().completed) {
      next = const OnboardingScreen();
    } else if (SupabaseAuthHelper.isSignedIn) {
      getIt<AppLockService>().onAuthenticated();
      next = const HomeScreen();
    } else {
      next = const LoginScreen();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => next),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appPalette.scaffold,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
