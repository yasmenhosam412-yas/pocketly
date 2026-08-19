import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:imrpo/features/auth/presentation/pages/forget_password_screen.dart';
import 'package:imrpo/features/auth/presentation/pages/signup_screen.dart';
import 'package:imrpo/features/auth/presentation/widgets/auth_footer_link.dart';
import 'package:imrpo/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:imrpo/features/auth/presentation/widgets/auth_screen_layout.dart';
import 'package:imrpo/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:imrpo/core/services/app_lock_service.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/features/home/presentation/pages/home_screen.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AuthScreenLayout(
      icon: Icons.account_balance_wallet_rounded,
      title: l10n.loginWelcomeTitle,
      subtitle: l10n.loginWelcomeSubtitle,
      footer: AuthFooterLink(
        prompt: l10n.noAccountPrompt,
        actionLabel: l10n.signUpLink,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SignupScreen()),
        ),
      ),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.errorLogin) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.errorMessage != null
                      ? localizeApiError(l10n, state.errorMessage)
                      : l10n.messageLoginFailed,
                ),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state.status == AuthStatus.successLogin) {
            getIt<AppLockService>().onAuthenticated();
            if (!context.mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
        },
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomFormField(
                label: l10n.labelEmail,
                hint: l10n.hintEmail,
                controller: _emailController,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),
              CustomFormField(
                label: l10n.labelPassword,
                hint: l10n.hintPasswordDots,
                controller: _passController,
                obscure: _obscurePassword,
                icon: Icons.lock_outline_rounded,
                suffixIcon: CustomFormField.visibilityToggle(
                  context: context,
                  obscure: _obscurePassword,
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgetPasswordScreen(),
                    ),
                  ),
                  child: Text(
                    l10n.forgotPasswordQuestion,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AuthPrimaryButton(
                label: l10n.loginButton,
                isLoading:
                    state.status == AuthStatus.loadingLogin ||
                    state.status == AuthStatus.successLogin,
                onPressed: _onLogin,
              ),
            ],
          );
        },
      ),
    );
  }

  void _onLogin() {
    final l10n = AppLocalizations.of(context)!;
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.messageEnterEmailPassword),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
      LoginEvent(
        email: _emailController.text.trim(),
        password: _passController.text,
      ),
    );
  }
}
