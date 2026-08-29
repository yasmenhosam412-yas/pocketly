import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:imrpo/features/auth/presentation/widgets/auth_footer_link.dart';
import 'package:imrpo/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:imrpo/features/auth/presentation/widgets/auth_screen_layout.dart';
import 'package:imrpo/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passController;
  late final TextEditingController _confirmPassController;
  late final FocusNode _nameFocus;
  late final FocusNode _emailFocus;
  late final FocusNode _passwordFocus;
  late final FocusNode _confirmPasswordFocus;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passController = TextEditingController();
    _confirmPassController = TextEditingController();
    _nameFocus = FocusNode();
    _emailFocus = FocusNode();
    _passwordFocus = FocusNode();
    _confirmPasswordFocus = FocusNode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AuthScreenLayout(
      icon: Icons.person_add_alt_1_rounded,
      title: l10n.signupCreateTitle,
      subtitle: l10n.signupCreateSubtitle,
      onBack: () => Navigator.pop(context),
      footer: AuthFooterLink(
        prompt: l10n.alreadyHaveAccount,
        actionLabel: l10n.loginLinkShort,
        onTap: () => Navigator.pop(context),
      ),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.errorSignup) {
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
          if (state.status == AuthStatus.successSignup) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.signupSuccessful),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          return AutofillGroup(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomFormField(
                label: l10n.labelFullName,
                hint: l10n.hintEnterYourName,
                controller: _nameController,
                focusNode: _nameFocus,
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                onFieldSubmitted: (_) => _emailFocus.requestFocus(),
              ),
              const SizedBox(height: 18),
              CustomFormField(
                label: l10n.labelEmail,
                hint: l10n.hintEmail,
                controller: _emailController,
                focusNode: _emailFocus,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                enableSuggestions: false,
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: 18),
              CustomFormField(
                label: l10n.labelPassword,
                hint: l10n.hintPasswordDots,
                controller: _passController,
                focusNode: _passwordFocus,
                obscure: _obscurePassword,
                icon: Icons.lock_outline_rounded,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                autocorrect: false,
                enableSuggestions: false,
                onFieldSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
                suffixIcon: CustomFormField.visibilityToggle(
                  context: context,
                  obscure: _obscurePassword,
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 18),
              CustomFormField(
                label: l10n.labelConfirmPassword,
                hint: l10n.hintPasswordDots,
                controller: _confirmPassController,
                focusNode: _confirmPasswordFocus,
                obscure: _obscureConfirmPassword,
                icon: Icons.lock_outline_rounded,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                autocorrect: false,
                enableSuggestions: false,
                onFieldSubmitted: (_) => _onSignup(),
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
                label: l10n.createAccountButton,
                isLoading: state.status == AuthStatus.loadingSignup,
                onPressed: _onSignup,
              ),
            ],
            ),
          );
        },
      ),
    );
  }

  void _onSignup() {
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.messageEnterEmailPassword),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_passController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.signupErrorGeneric),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
          SignupEvent(
            username: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passController.text,
          ),
        );
  }
}
