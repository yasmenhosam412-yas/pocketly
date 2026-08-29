import 'package:imrpo/features/auth/domain/entities/social_auth_provider.dart';

abstract class AuthDatasource {
  Future<void> signup(String username, String email, String password);

  Future<void> login(String email, String password);
  Future<void> loginWithSocial(SocialAuthProvider provider);
  Future<void> forgetPassword(String email);
  Future<void> verifyOTP(String newPassword, String otp, String email);

  Future<void> logout();

  Future<void> deleteAccount();
}
