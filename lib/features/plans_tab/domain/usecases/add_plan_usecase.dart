import 'package:dartz/dartz.dart';
import 'package:imrpo/core/helpers/error_helper.dart';
import 'package:imrpo/features/plans_tab/domain/repositories/plan_repository.dart';

class AddPlanUsecase {
  final PlanRepository planRepository;

  AddPlanUsecase({required this.planRepository});

  Future<Either<Failure, String>> call(
    String title,
    String category,
    double targetAmount,
    double savedAmount,
    DateTime? deadline, {
    String? imageUrl,
  }) {
    return planRepository.addPlan(
      title,
      category,
      targetAmount,
      savedAmount,
      deadline,
      imageUrl: imageUrl,
    );
  }
}
