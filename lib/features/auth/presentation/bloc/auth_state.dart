part of 'auth_bloc.dart';

enum AuthStatus {
  initial,
  loadingLogin,
  loadingSignup,
  loadingForgetPassword,
  successLogin,
  successSignup,
  successForgetPassword,
  successVerifySetNewPass,
  errorLogin,
  errorSignup,
  errorForgetPassword,
  errorVerifySetNewPass,
  loadingVerifySetNewPass,
  loadingLogout,
  loadingDeleteAccount,
  loggedOut,
  accountDeleted,
  errorLogout,
  errorDeleteAccount,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final String? errorMessage;
  final SocialAuthProvider? socialProvider;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.socialProvider,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    SocialAuthProvider? socialProvider,
    bool clearSocialProvider = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      socialProvider: clearSocialProvider
          ? null
          : (socialProvider ?? this.socialProvider),
    );
  }

  @override
  List<Object> get props => [status, errorMessage ?? '', socialProvider ?? ''];
}
