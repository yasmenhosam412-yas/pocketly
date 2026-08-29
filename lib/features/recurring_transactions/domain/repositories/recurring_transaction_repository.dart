import 'package:dartz/dartz.dart';
import 'package:imrpo/core/helpers/error_helper.dart';
import 'package:imrpo/features/recurring_transactions/domain/entities/recurring_transaction.dart';

abstract class RecurringTransactionRepository {
  Future<Either<Failure, List<RecurringTransaction>>> getAll();
  Future<Either<Failure, RecurringTransaction>> save(RecurringTransaction item);
  Future<Either<Failure, void>> delete(String id);
}
