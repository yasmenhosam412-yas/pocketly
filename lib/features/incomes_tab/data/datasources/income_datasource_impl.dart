import 'package:imrpo/core/helpers/association_datasource_mixin.dart';
import 'package:imrpo/core/helpers/supabase_auth_helper.dart';
import 'package:imrpo/core/helpers/supabase_delete_helper.dart';
import 'package:imrpo/core/models/transaction_entry_meta.dart';
import 'package:imrpo/features/incomes_tab/data/datasources/income_datasource.dart';
import 'package:imrpo/features/incomes_tab/data/models/income_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IncomeDatasourceImpl extends IncomeDatasource
    with AssociationDatasourceMixin {
  final SupabaseClient supabaseClient;

  IncomeDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> addIncome(
    String title,
    double amount,
    DateTime date,
    String category, {
    TransactionEntryMeta? entryMeta,
    String? associationIdOverride,
  }) async {
    final row = scopedFinancialRow({
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'user_id': SupabaseAuthHelper.requireUserId(),
    });
    if (entryMeta != null) {
      row.addAll(entryMeta.toRowFields());
    }
    final override = associationIdOverride?.trim();
    if (override != null && override.isNotEmpty) {
      row['association_id'] = override;
    }
    await supabaseClient.from('incomes').insert(row);
  }

  @override
  Future<void> deleteIncome(String incomeId) async {
    final userId = SupabaseAuthHelper.requireUserId();

    var deleteQuery = supabaseClient
        .from('incomes')
        .delete()
        .eq('income_id', incomeId)
        .eq('user_id', userId);
    deleteQuery = scopeFinancialQuery(deleteQuery);
    final deleted = await deleteQuery.select('income_id');

    ensureDeleteSucceeded(deleted);
  }

  @override
  Future<void> deleteAllIncomes() async {
    final userId = SupabaseAuthHelper.requireUserId();

    var deleteQuery =
        supabaseClient.from('incomes').delete().eq('user_id', userId);
    deleteQuery = scopeFinancialQuery(deleteQuery);
    await deleteQuery;
  }

  @override
  Future<List<IncomeModel>> getIncomes() async {
    final userId = SupabaseAuthHelper.requireUserId();
    var selectQuery =
        supabaseClient.from('incomes').select();
    selectQuery = scopeOwnUserQuery(selectQuery, userId);
    selectQuery = scopeFinancialQuery(selectQuery);
    final response = await selectQuery;
    return response.map((item) => IncomeModel.fromMap(item)).toList();
  }

  @override
  Future<void> updateIncome(
    String incomeId,
    String title,
    double amount,
    DateTime date,
    String category, {
    TransactionEntryMeta? entryMeta,
  }) async {
    final update = <String, dynamic>{
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
    };
    if (entryMeta != null) {
      update.addAll(entryMeta.toRowFields());
    }
    var updateQuery = supabaseClient
        .from('incomes')
        .update(update)
        .eq('income_id', incomeId)
        .eq('user_id', SupabaseAuthHelper.requireUserId());
    updateQuery = scopeFinancialQuery(updateQuery);
    await updateQuery;
  }

  @override
  Future<int> renameCategory(String fromCategory, String toCategory) async {
    final userId = SupabaseAuthHelper.requireUserId();
    var updateQuery = supabaseClient
        .from('incomes')
        .update({'category': toCategory})
        .eq('user_id', userId)
        .eq('category', fromCategory);
    updateQuery = scopeFinancialQuery(updateQuery);
    final updated = await updateQuery.select('income_id');

    return (updated as List).length;
  }

  @override
  Future<int> deleteByCategory(String category) async {
    final userId = SupabaseAuthHelper.requireUserId();
    var deleteQuery = supabaseClient
        .from('incomes')
        .delete()
        .eq('user_id', userId)
        .eq('category', category);
    deleteQuery = scopeFinancialQuery(deleteQuery);
    final deleted = await deleteQuery.select('income_id');

    return (deleted as List).length;
  }
}
