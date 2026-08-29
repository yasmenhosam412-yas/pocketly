import 'package:imrpo/core/helpers/association_datasource_mixin.dart';
import 'package:imrpo/core/helpers/supabase_auth_helper.dart';
import 'package:imrpo/core/helpers/supabase_delete_helper.dart';
import 'package:imrpo/features/loans_tab/data/datasources/loans_datasource.dart';
import 'package:imrpo/features/loans_tab/data/models/loan_model.dart';
import 'package:imrpo/features/loans_tab/domain/entities/loan.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoansDatasourceImpl with AssociationDatasourceMixin
    implements LoansDatasource {
  final SupabaseClient supabaseClient;

  LoansDatasourceImpl({required this.supabaseClient});

  String? _dueDateIso(DateTime? dueDate) {
    if (dueDate == null) return null;
    final y = dueDate.year.toString().padLeft(4, '0');
    final m = dueDate.month.toString().padLeft(2, '0');
    final d = dueDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Future<String> addLoan(
    String personName,
    LoanDirection direction,
    double principal,
    double repaidAmount,
    DateTime? dueDate,
    String notes,
  ) async {
    final row = await supabaseClient
        .from('loans')
        .insert(
          scopedFinancialRow({
            'person_name': personName,
            'direction': direction.name,
            'principal': principal,
            'repaid_amount': repaidAmount,
            'due_date': _dueDateIso(dueDate),
            'notes': notes,
            'user_id': SupabaseAuthHelper.requireUserId(),
          }),
        )
        .select('loan_id')
        .single();
    return row['loan_id'] as String;
  }

  @override
  Future<void> deleteLoan(String loanId) async {
    final userId = SupabaseAuthHelper.requireUserId();

    var deleteQuery = supabaseClient
        .from('loans')
        .delete()
        .eq('loan_id', loanId)
        .eq('user_id', userId);
    deleteQuery = scopeFinancialQuery(deleteQuery);
    final deleted = await deleteQuery.select('loan_id');

    ensureDeleteSucceeded(deleted);
  }

  @override
  Future<List<LoanModel>> getLoans() async {
    final userId = SupabaseAuthHelper.requireUserId();
    var selectQuery =
        supabaseClient.from('loans').select().eq('user_id', userId);
    selectQuery = scopeFinancialQuery(selectQuery);
    final response = await selectQuery;

    return response.map((item) => LoanModel.fromMap(item)).toList();
  }

  @override
  Future<void> updateLoan(
    String loanId,
    String personName,
    LoanDirection direction,
    double principal,
    double repaidAmount,
    DateTime? dueDate,
    String notes,
  ) async {
    var updateQuery = supabaseClient.from('loans').update({
      'person_name': personName,
      'direction': direction.name,
      'principal': principal,
      'repaid_amount': repaidAmount,
      'due_date': _dueDateIso(dueDate),
      'notes': notes,
    }).eq('loan_id', loanId).eq('user_id', SupabaseAuthHelper.requireUserId());
    updateQuery = scopeFinancialQuery(updateQuery);
    await updateQuery;
  }

  @override
  Future<void> updateLoanRepaid(String loanId, double repaidAmount) async {
    var updateQuery = supabaseClient
        .from('loans')
        .update({'repaid_amount': repaidAmount})
        .eq('loan_id', loanId)
        .eq('user_id', SupabaseAuthHelper.requireUserId());
    updateQuery = scopeFinancialQuery(updateQuery);
    await updateQuery;
  }
}
