import 'package:dartz/dartz.dart';
import 'package:imrpo/core/helpers/error_helper.dart';
import 'package:imrpo/features/plans_tab/data/models/plan_model.dart';

abstract class PlanRepository {
  Future<Either<Failure, String>> addPlan(
    String title,
    String category,
    double targetAmount,
    double savedAmount,
    DateTime? deadline, {
    String? imageUrl,
  });

  Future<Either<Failure, void>> updatePlan(
    String planId,
    String title,
    String category,
    double targetAmount,
    double savedAmount,
    DateTime? deadline, {
    String? imageUrl,
  });

  Future<Either<Failure, void>> updatePlanSaved(
    String planId,
    double savedAmount,
  );

  Future<Either<Failure, void>> deletePlan(String planId);

  Future<Either<Failure, List<PlanModel>>> getPlans();
}
