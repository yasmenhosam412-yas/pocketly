part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}


class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class SocialLoginEvent extends AuthEvent {
  final SocialAuthProvider provider;

  const SocialLoginEvent({required this.provider});

  @override
  List<Object> get props => [provider];
}

class SignupEvent extends AuthEvent {
  final String username;
  final String email;
  final String password;

  const SignupEvent({
    required this.username,
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [username, email, password];
}


class ForgetPasswordEvent extends AuthEvent {
  final String email;

  const ForgetPasswordEvent({required this.email});

  @override
  List<Object> get props => [email];
} 

class VerifySetNewPassEvent extends AuthEvent {
  final String newPassword;
  final String otp;
  final String email;

  const VerifySetNewPassEvent({
    required this.newPassword,
    required this.otp,
    required this.email,
  });

  @override
  List<Object> get props => [newPassword, otp, email];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class DeleteAccountEvent extends AuthEvent {
  const DeleteAccountEvent();
}

class ResetAuthEvent extends AuthEvent {
  const ResetAuthEvent();
}