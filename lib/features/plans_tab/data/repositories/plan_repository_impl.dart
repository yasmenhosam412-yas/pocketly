import 'package:dartz/dartz.dart';
import 'package:imrpo/core/helpers/error_helper.dart';
import 'package:imrpo/features/plans_tab/data/datasources/plans_datasource.dart';
import 'package:imrpo/features/plans_tab/data/models/plan_model.dart';
import 'package:imrpo/features/plans_tab/domain/repositories/plan_repository.dart';

class PlanRepositoryImpl implements PlanRepository {
  final PlansDatasource plansDatasource;

  PlanRepositoryImpl({required this.plansDatasource});

  @override
  Future<Either<Failure, String>> addPlan(
    String title,
    String category,
    double targetAmount,
    double savedAmount,
    DateTime? deadline, {
    String? imageUrl,
  }) async {
    try {
      final planId = await plansDatasource.addPlan(
        title,
        category,
        targetAmount,
        savedAmount,
        deadline,
        imageUrl: imageUrl,
      );
      return Right(planId);
    } catch (e) {
      return Left(ErrorHelper.handle(e));
    }
  }

  @override
  Future<Either<Failure, void>> deletePlan(String planId) async {
    try {
      await plansDatasource.deletePlan(planId);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHelper.handle(e));
    }
  }

  @override
  Future<Either<Failure, List<PlanModel>>> getPlans() async {
    try {
      final plans = await plansDatasource.getPlans();
      return Right(plans);
    } catch (e) {
      return Left(ErrorHelper.handle(e));
    }
  }

  @override
  Future<Either<Failure, void>> updatePlan(
    String planId,
    String title,
    String category,
    double targetAmount,
    double savedAmount,
    DateTime? deadline, {
    String? imageUrl,
  }) async {
    try {
      await plansDatasource.updatePlan(
        planId,
        title,
        category,
        targetAmount,
        savedAmount,
        deadline,
        imageUrl: imageUrl,
      );
      return const Right(null);
    } catch (e) {
      return Left(ErrorHelper.handle(e));
    }
  }

  @override
  Future<Either<Failure, void>> updatePlanSaved(
    String planId,
    double savedAmount,
  ) async {
    try {
      await plansDatasource.updatePlanSaved(planId, savedAmount);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHelper.handle(e));
    }
  }
}
