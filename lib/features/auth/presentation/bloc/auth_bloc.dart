import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:imrpo/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:imrpo/features/auth/domain/usecases/forget_password_usecase.dart';
import 'package:imrpo/core/l10n/l10n_error_tokens.dart';
import 'package:imrpo/features/auth/domain/entities/social_auth_provider.dart';
import 'package:imrpo/features/auth/domain/usecases/login_usecase.dart';
import 'package:imrpo/features/auth/domain/usecases/logout_usecase.dart';
import 'package:imrpo/features/auth/domain/usecases/signup_usecase.dart';
import 'package:imrpo/features/auth/domain/usecases/social_login_usecase.dart';
import 'package:imrpo/features/auth/domain/usecases/verify_set_new_pass_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUsecase loginUsecase;
  final SocialLoginUsecase socialLoginUsecase;
  final SignupUsecase signupUsecase;
  final ForgetPasswordUsecase forgetPasswordUsecase;
  final VerifySetNewPassUsecase verifySetNewPassUsecase;
  final LogoutUsecase logoutUsecase;
  final DeleteAccountUsecase deleteAccountUsecase;

  AuthBloc({
    required this.loginUsecase,
    required this.socialLoginUsecase,
    required this.signupUsecase,
    required this.forgetPasswordUsecase,
    required this.verifySetNewPassUsecase,
    required this.logoutUsecase,
    required this.deleteAccountUsecase,
  }) : super(AuthState()) {
    on<LoginEvent>(_handleLogin);
    on<SocialLoginEvent>(_handleSocialLogin);
    on<SignupEvent>(_handleSignup);
    on<ForgetPasswordEvent>(_handleForgetPassword);
    on<VerifySetNewPassEvent>(_handleVerifySetNewPass);
    on<LogoutEvent>(_handleLogout);
    on<DeleteAccountEvent>(_handleDeleteAccount);
    on<ResetAuthEvent>(_onReset);
  }

  void _onReset(ResetAuthEvent event, Emitter<AuthState> emit) {
    emit(const AuthState());
  }

  Future<void> _handleLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loadingLogin));

    final result = await loginUsecase(event.email, event.password);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.errorLogin,
          errorMessage: failure.error,
        ),
      ),
      (_) => emit(state.copyWith(status: AuthStatus.successLogin)),
    );
  }

  Future<void> _handleSocialLogin(
    SocialLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loadingLogin,
        socialProvider: event.provider,
      ),
    );

    final result = await socialLoginUsecase(event.provider);

    if (emit.isDone) return;

    result.fold(
      (failure) {
        if (state.status != AuthStatus.loadingLogin) return;
        if (failure.error == l10nSocialAuthCancelledToken) {
          emit(const AuthState());
          return;
        }
        emit(
          state.copyWith(
            status: AuthStatus.errorLogin,
            errorMessage: failure.error,
            clearSocialProvider: true,
          ),
        );
      },
      (_) {
        if (emit.isDone) return;
        emit(
          state.copyWith(
            status: AuthStatus.successLogin,
            clearSocialProvider: true,
          ),
        );
      },
    );
  }

  Future<void> _handleSignup(SignupEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loadingSignup));
    final result = await signupUsecase(
      event.username,
      event.email,
      event.password,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.errorSignup,
          errorMessage: failure.error,
        ),
      ),
      (_) => emit(state.copyWith(status: AuthStatus.successSignup)),
    );
  }

  Future<void> _handleForgetPassword(
    ForgetPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loadingForgetPassword));

    final result = await forgetPasswordUsecase(event.email);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.errorForgetPassword,
          errorMessage: failure.error,
        ),
      ),
      (_) => emit(state.copyWith(status: AuthStatus.successForgetPassword)),
    );
  }

  Future<void> _handleVerifySetNewPass(VerifySetNewPassEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loadingVerifySetNewPass));

    final result = await verifySetNewPassUsecase(event.newPassword, event.otp, event.email);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.errorVerifySetNewPass,
          errorMessage: failure.error,
        ),
      ),
      (_) => emit(state.copyWith(status: AuthStatus.successVerifySetNewPass)),
     );
  }

  Future<void> _handleLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loadingLogout));

    final result = await logoutUsecase();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.errorLogout,
          errorMessage: failure.error,
        ),
      ),
      (_) => emit(state.copyWith(status: AuthStatus.loggedOut)),
    );
  }

  Future<void> _handleDeleteAccount(
    DeleteAccountEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loadingDeleteAccount));

    final result = await deleteAccountUsecase();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.errorDeleteAccount,
          errorMessage: failure.error,
        ),
      ),
      (_) => emit(state.copyWith(status: AuthStatus.accountDeleted)),
    );
  }
}
