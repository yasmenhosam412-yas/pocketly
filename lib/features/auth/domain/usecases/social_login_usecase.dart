import 'package:dartz/dartz.dart';
import 'package:imrpo/core/helpers/error_helper.dart';
import 'package:imrpo/features/auth/domain/entities/social_auth_provider.dart';
import 'package:imrpo/features/auth/domain/repositories/auth_repository.dart';

class SocialLoginUsecase {
  final AuthRepository authRepository;

  SocialLoginUsecase({required this.authRepository});

  Future<Either<Failure, void>> call(SocialAuthProvider provider) {
    return authRepository.loginWithSocial(provider);
  }
}
