import 'package:dartz/dartz.dart';
import 'package:imrpo/core/helpers/error_helper.dart';
import 'package:imrpo/features/plans_tab/domain/repositories/plan_repository.dart';

class UpdatePlanUsecase {
  final PlanRepository planRepository;

  UpdatePlanUsecase({required this.planRepository});

  Future<Either<Failure, void>> call(
    String planId,
    String title,
    String category,
    double targetAmount,
    double savedAmount,
    DateTime? deadline, {
    String? imageUrl,
  }) {
    return planRepository.updatePlan(
      planId,
      title,
      category,
      targetAmount,
      savedAmount,
      deadline,
      imageUrl: imageUrl,
    );
  }
}
