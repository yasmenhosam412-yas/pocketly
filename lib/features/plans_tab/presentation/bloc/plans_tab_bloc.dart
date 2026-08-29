import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:imrpo/features/plans_tab/domain/entities/plan.dart';
import 'package:imrpo/features/plans_tab/domain/usecases/add_plan_usecase.dart';
import 'package:imrpo/features/plans_tab/domain/usecases/delete_plan_usecase.dart';
import 'package:imrpo/features/plans_tab/domain/usecases/get_all_plans_usecase.dart';
import 'package:imrpo/features/plans_tab/domain/usecases/update_plan_saved_usecase.dart';
import 'package:imrpo/features/plans_tab/domain/usecases/update_plan_usecase.dart';
import 'package:imrpo/core/services/receipt_storage_service.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/features/expenses_tab/domain/usecases/add_expense_usecase.dart';

part 'plans_tab_event.dart';
part 'plans_tab_state.dart';

class PlansTabBloc extends Bloc<PlansTabEvent, PlansTabState> {
  /// Expense category recorded when allocating balance to a plan.
  static const planAllocationCategory = 'Savings';

  final GetAllPlansUsecase getAllPlansUsecase;
  final AddPlanUsecase addPlanUsecase;
  final UpdatePlanUsecase updatePlanUsecase;
  final UpdatePlanSavedUsecase updatePlanSavedUsecase;
  final DeletePlanUsecase deletePlanUsecase;
  final AddExpenseUsecase addExpenseUsecase;

  PlansTabBloc({
    required this.getAllPlansUsecase,
    required this.addPlanUsecase,
    required this.updatePlanUsecase,
    required this.updatePlanSavedUsecase,
    required this.deletePlanUsecase,
    required this.addExpenseUsecase,
  }) : super(const PlansTabInitial()) {
    on<LoadPlansEvent>(_onLoad);
    on<ResetPlansTabEvent>(_onReset);
    on<AddPlanEvent>(_onAdd);
    on<UpdatePlanEvent>(_onUpdate);
    on<UpdatePlanSavedEvent>(_onUpdateSaved);
    on<AddAmountToPlanEvent>(_onAddAmount);
    on<DeletePlanEvent>(_onDelete);
  }

  PlansTabLoaded _loadingState() {
    final current = state;
    if (current is PlansTabLoaded) {
      return current.copyWith(status: PlansTabStatus.loading, error: '');
    }
    return const PlansTabLoaded(
      plans: [],
      status: PlansTabStatus.loading,
    );
  }

  void _onReset(ResetPlansTabEvent event, Emitter<PlansTabState> emit) {
    emit(const PlansTabInitial());
  }

  Future<void> _onLoad(
    LoadPlansEvent event,
    Emitter<PlansTabState> emit,
  ) async {
    final current = state;
    if (!event.force &&
        current is PlansTabLoaded &&
        current.status == PlansTabStatus.loading &&
        !current.hasData) {
      return;
    }
    if (current is PlansTabLoaded && current.hasData) {
      emit(current.copyWith(status: PlansTabStatus.loading, error: ''));
    } else {
      emit(_loadingState());
    }

    final result = await getAllPlansUsecase();

    result.fold(
      (failure) {
        final previous = state;
        if (previous is PlansTabLoaded && previous.hasData) {
          emit(
            previous.copyWith(
              status: PlansTabStatus.error,
              error: failure.error,
            ),
          );
        } else {
          emit(
            PlansTabLoaded(
              plans: const [],
              status: PlansTabStatus.error,
              error: failure.error,
            ),
          );
        }
      },
      (plans) {
        emit(
          PlansTabLoaded(
            plans: plans,
            status: PlansTabStatus.loaded,
          ),
        );
      },
    );
  }

  Future<void> _onAdd(
    AddPlanEvent event,
    Emitter<PlansTabState> emit,
  ) async {
    final current = state;
    if (current is PlansTabLoaded) {
      emit(current.copyWith(status: PlansTabStatus.loadingAdd, error: ''));
    }

    final result = await addPlanUsecase(
      event.title,
      event.category,
      event.targetAmount,
      event.savedAmount,
      event.deadline,
      imageUrl: event.imageUrl,
    );

    result.fold(
      (failure) {
        final previous = state;
        if (previous is PlansTabLoaded) {
          emit(
            previous.copyWith(
              status: PlansTabStatus.errorAdd,
              error: failure.error,
            ),
          );
        }
      },
      (_) => add(const LoadPlansEvent()),
    );
  }

  Future<void> _onUpdate(
    UpdatePlanEvent event,
    Emitter<PlansTabState> emit,
  ) async {
    final current = state;
    if (current is! PlansTabLoaded) return;

    Plan? existing;
    for (final p in current.plans) {
      if (p.id == event.id) {
        existing = p;
        break;
      }
    }
    if (existing == null) return;

    emit(current.copyWith(status: PlansTabStatus.loadingUpdate, error: ''));

    final result = await updatePlanUsecase(
      event.id,
      event.title,
      event.category,
      event.targetAmount,
      event.savedAmount,
      event.deadline,
      imageUrl: event.imageUrl,
    );

    result.fold(
      (failure) {
        final previous = state;
        if (previous is PlansTabLoaded) {
          emit(
            previous.copyWith(
              status: PlansTabStatus.errorUpdate,
              error: failure.error,
            ),
          );
        }
      },
      (_) => add(const LoadPlansEvent()),
    );
  }

  Future<void> _onUpdateSaved(
    UpdatePlanSavedEvent event,
    Emitter<PlansTabState> emit,
  ) async {
    final current = state;
    if (current is PlansTabLoaded) {
      emit(
        current.copyWith(status: PlansTabStatus.loadingUpdateSaved, error: ''),
      );
    }

    final result = await updatePlanSavedUsecase(event.id, event.savedAmount);

    result.fold(
      (failure) {
        final previous = state;
        if (previous is PlansTabLoaded) {
          emit(
            previous.copyWith(
              status: PlansTabStatus.errorUpdateSaved,
              error: failure.error,
            ),
          );
        }
      },
      (_) => add(const LoadPlansEvent()),
    );
  }

  Future<void> _onAddAmount(
    AddAmountToPlanEvent event,
    Emitter<PlansTabState> emit,
  ) async {
    final current = state;
    if (current is! PlansTabLoaded) return;

    Plan? plan;
    for (final candidate in current.plans) {
      if (candidate.id == event.id) {
        plan = candidate;
        break;
      }
    }
    if (plan == null) return;
    final targetPlan = plan;

    if (event.amountToAdd <= 0) {
      emit(
        current.copyWith(
          status: PlansTabStatus.errorUpdateSaved,
          error: 'Invalid amount',
        ),
      );
      return;
    }

    final remainingOnPlan = targetPlan.targetAmount - targetPlan.savedAmount;
    final addAmount = event.amountToAdd > remainingOnPlan
        ? remainingOnPlan
        : event.amountToAdd;
    if (addAmount <= 0) return;

    emit(
      current.copyWith(status: PlansTabStatus.loadingUpdateSaved, error: ''),
    );

    final expenseResult = await addExpenseUsecase(
      event.expenseTitle,
      planAllocationCategory,
      addAmount,
      DateTime.now(),
      incomeSource: event.expensePaidFrom,
    );

    final expenseFailed = expenseResult.fold(
      (failure) {
        final previous = state;
        if (previous is PlansTabLoaded) {
          emit(
            previous.copyWith(
              status: PlansTabStatus.errorUpdateSaved,
              error: failure.error,
            ),
          );
        }
        return true;
      },
      (_) => false,
    );
    if (expenseFailed) return;

    final newSaved = targetPlan.savedAmount + addAmount;
    final result = await updatePlanSavedUsecase(targetPlan.id, newSaved);

    result.fold(
      (failure) {
        final previous = state;
        if (previous is PlansTabLoaded) {
          emit(
            previous.copyWith(
              status: PlansTabStatus.errorUpdateSaved,
              error: failure.error,
            ),
          );
        }
      },
      (_) {
        final previous = state;
        if (previous is! PlansTabLoaded) return;
        final updatedPlans = previous.plans
            .map(
              (p) => p.id == targetPlan.id
                  ? Plan(
                      id: p.id,
                      title: p.title,
                      category: p.category,
                      targetAmount: p.targetAmount,
                      savedAmount: newSaved,
                      deadline: p.deadline,
                      userId: p.userId,
                      imageUrl: p.imageUrl,
                    )
                  : p,
            )
            .toList();
        emit(
          previous.copyWith(
            plans: updatedPlans,
            status: PlansTabStatus.loaded,
          ),
        );
      },
    );
  }

  Future<void> _onDelete(
    DeletePlanEvent event,
    Emitter<PlansTabState> emit,
  ) async {
    final current = state;
    String? imageUrl;
    if (current is PlansTabLoaded) {
      for (final plan in current.plans) {
        if (plan.id == event.id) {
          imageUrl = plan.imageUrl;
          break;
        }
      }
      emit(
        current.copyWith(
          status: PlansTabStatus.loadingDelete,
          deletingPlanId: event.id,
          error: '',
        ),
      );
    }

    final result = await deletePlanUsecase(event.id);
    if (emit.isDone) return;

    if (result.isLeft()) {
      final failure = result.fold((l) => l, (_) => throw StateError('unreachable'));
      final previous = state;
      if (previous is PlansTabLoaded) {
        emit(
          previous.copyWith(
            status: PlansTabStatus.errorDelete,
            error: failure.error,
            deletingPlanId: null,
          ),
        );
      }
      return;
    }

    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      await getIt<ReceiptStorageService>().deleteByPublicUrl(imageUrl);
    }

    if (current is PlansTabLoaded) {
      final updatedPlans =
          current.plans.where((plan) => plan.id != event.id).toList();
      emit(
        current.copyWith(
          plans: updatedPlans,
          status: PlansTabStatus.loaded,
          deletingPlanId: null,
          error: '',
        ),
      );
    }

    add(const LoadPlansEvent(force: true));
  }
}
