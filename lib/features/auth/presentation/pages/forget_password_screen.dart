import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:imrpo/features/auth/presentation/pages/set_new_passwod_screen.dart';
import 'package:imrpo/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:imrpo/features/auth/presentation/widgets/auth_screen_layout.dart';
import 'package:imrpo/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AuthScreenLayout(
      icon: Icons.lock_reset_rounded,
      title: l10n.forgotPasswordTitle,
      subtitle: l10n.forgotPasswordDescription,
      onBack: () => Navigator.pop(context),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.successForgetPassword) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SetNewPasswodScreen(
                  email: _emailController.text.trim(),
                ),
              ),
            );
          }
          if (state.status == AuthStatus.errorForgetPassword) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.errorMessage != null
                      ? localizeApiError(l10n, state.errorMessage)
                      : l10n.errorTryAgainGeneric,
                ),
                backgroundColor: AppColors.error,
              ),
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
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: l10n.sendResetLink,
                isLoading: state.status == AuthStatus.loadingForgetPassword,
                onPressed: _sendResetLink,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                label: Text(l10n.backToLogin),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryInk,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _sendResetLink() {
    if (_emailController.text.trim().isEmpty) return;

    context.read<AuthBloc>().add(
          ForgetPasswordEvent(email: _emailController.text.trim()),
        );
  }
}
