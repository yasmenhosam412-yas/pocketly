import 'package:dartz/dartz.dart';
import 'package:imrpo/core/helpers/error_helper.dart';
import 'package:imrpo/features/auth/data/datasources/auth_datasource.dart';
import 'package:imrpo/features/auth/domain/entities/social_auth_provider.dart';
import 'package:imrpo/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl extends AuthRepository {
  final AuthDatasource authDatasource;

  AuthRepositoryImpl({ required this.authDatasource});
  @override
  Future<Either<Failure, void>> forgetPassword(String email) async {
    try {
      await authDatasource.forgetPassword(email);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHelper.handle(e));
    }
  }

  @override
  Future<Either<Failure, void>> login(String email, String password) async {
    try {
      await authDatasource.login(email, password);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHelper.handle(e));
    }
  }

  @override
  Future<Either<Failure, void>> loginWithSocial(
    SocialAuthProvider provider,
  ) async {
    try {
      await authDatasource.loginWithSocial(provider);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHelper.handle(e));
    }
  }

  @override
  Future<Either<Failure, void>> signup(
    String username,
    String email,
    String password,
  ) async {
    try {
      await authDatasource.signup(username, email, password);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHelper.handle(e));
    }
  }
  
  @override
  Future<Either<Failure, void>> verifyOTP(String newPassword, String otp, String email) async {
     try {
      await authDatasource.verifyOTP(newPassword, otp, email);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHelper.handle(e));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await authDatasource.logout();
      return const Right(null);
    } catch (e) {
      return Left(ErrorHelper.handle(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      await authDatasource.deleteAccount();
      return const Right(null);
    } catch (e) {
      return Left(ErrorHelper.handle(e));
    }
  }
}
