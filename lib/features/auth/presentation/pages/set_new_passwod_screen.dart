import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:imrpo/features/auth/presentation/pages/login_screen.dart';
import 'package:imrpo/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:imrpo/features/auth/presentation/widgets/auth_screen_layout.dart';
import 'package:imrpo/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class SetNewPasswodScreen extends StatefulWidget {
  final String email;

  const SetNewPasswodScreen({super.key, required this.email});

  @override
  State<SetNewPasswodScreen> createState() => _SetNewPasswodScreenState();
}

class _SetNewPasswodScreenState extends State<SetNewPasswodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AuthScreenLayout(
      icon: Icons.verified_user_outlined,
      title: l10n.setNewPasswordTitle,
      subtitle: l10n.setNewPasswordSubtitle,
      onBack: () => Navigator.pop(context),
      child: Form(
        key: _formKey,
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.successVerifySetNewPass) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.passwordUpdatedSuccessfully),
                  backgroundColor: AppColors.success,
                ),
              );
            }
            if (state.status == AuthStatus.errorVerifySetNewPass) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.errorMessage != null
                        ? localizeApiError(l10n, state.errorMessage)
                        : l10n.signupErrorGeneric,
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
                  controller: _otpController,
                  label: l10n.labelOtpCode,
                  hint: l10n.hintOtpCode,
                  icon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 18),
                CustomFormField(
                  controller: _passwordController,
                  label: l10n.labelNewPassword,
                  hint: l10n.hintPasswordDots,
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscurePassword,
                  suffixIcon: CustomFormField.visibilityToggle(
                    context: context,
                    obscure: _obscurePassword,
                    onToggle: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 18),
                CustomFormField(
                  controller: _confirmPasswordController,
                  label: l10n.labelConfirmPassword,
                  hint: l10n.hintPasswordDots,
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscureConfirmPassword,
                  suffixIcon: CustomFormField.visibilityToggle(
                    context: context,
                    obscure: _obscureConfirmPassword,
                    onToggle: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AuthPrimaryButton(
                  label: l10n.buttonSetNewPassword,
                  isLoading: state.status == AuthStatus.loadingVerifySetNewPass,
                  onPressed: _submit,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) return;

    context.read<AuthBloc>().add(
          VerifySetNewPassEvent(
            otp: _otpController.text.trim(),
            newPassword: _passwordController.text,
            email: widget.email,
          ),
        );
  }
}
