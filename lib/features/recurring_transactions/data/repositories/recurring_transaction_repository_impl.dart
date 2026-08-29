import 'package:dartz/dartz.dart';
import 'package:imrpo/core/helpers/error_helper.dart';
import 'package:imrpo/core/helpers/supabase_auth_helper.dart';
import 'package:imrpo/features/recurring_transactions/data/recurring_transaction_store.dart';
import 'package:imrpo/features/recurring_transactions/domain/entities/recurring_transaction.dart';
import 'package:imrpo/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';

class RecurringTransactionRepositoryImpl
    implements RecurringTransactionRepository {
  final RecurringTransactionStore store;

  RecurringTransactionRepositoryImpl({required this.store});

  Future<List<RecurringTransaction>> _load() async {
    final userId = SupabaseAuthHelper.requireUserId();
    return store.loadAll(userId);
  }

  Future<void> _persist(List<RecurringTransaction> items) async {
    final userId = SupabaseAuthHelper.requireUserId();
    await store.saveAll(userId, items);
  }

  @override
  Future<Either<Failure, List<RecurringTransaction>>> getAll() async {
    try {
      if (!SupabaseAuthHelper.isSignedIn) return const Right([]);
      return Right(await _load());
    } catch (e) {
      return Left(ErrorHelper.handle(e));
    }
  }

  @override
  Future<Either<Failure, RecurringTransaction>> save(
    RecurringTransaction item,
  ) async {
    try {
      final list = await _load();
      final index = list.indexWhere((r) => r.id == item.id);
      final updated = List<RecurringTransaction>.from(list);
      if (index >= 0) {
        updated[index] = item;
      } else {
        updated.add(item);
      }
      await _persist(updated);
      return Right(item);
    } catch (e) {
      return Left(ErrorHelper.handle(e));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      final list = await _load();
      await _persist(list.where((r) => r.id != id).toList());
      return const Right(null);
    } catch (e) {
      return Left(ErrorHelper.handle(e));
    }
  }
}
