import 'package:imrpo/core/helpers/association_datasource_mixin.dart';
import 'package:imrpo/core/helpers/supabase_auth_helper.dart';
import 'package:imrpo/core/helpers/supabase_delete_helper.dart';
import 'package:imrpo/features/plans_tab/data/datasources/plans_datasource.dart';
import 'package:imrpo/features/plans_tab/data/models/plan_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlansDatasourceImpl with AssociationDatasourceMixin
    implements PlansDatasource {
  final SupabaseClient supabaseClient;

  PlansDatasourceImpl({required this.supabaseClient});

  @override
  Future<String> addPlan(
    String title,
    String category,
    double targetAmount,
    double savedAmount,
    DateTime? deadline, {
    String? imageUrl,
  }) async {
    final row = {
      'title': title,
      'category': category,
      'target_amount': targetAmount,
      'saved_amount': savedAmount,
      'deadline': deadline?.toIso8601String(),
      'user_id': SupabaseAuthHelper.requireUserId(),
      'image_url': _nullableUrl(imageUrl),
    };
    final inserted = await supabaseClient
        .from('plans')
        .insert(scopedFinancialRow(row))
        .select('plan_id')
        .single();
    return inserted['plan_id'] as String;
  }

  @override
  Future<void> deletePlan(String planId) async {
    final userId = SupabaseAuthHelper.requireUserId();

    var deleteQuery = supabaseClient
        .from('plans')
        .delete()
        .eq('plan_id', planId)
        .eq('user_id', userId);
    deleteQuery = scopeFinancialQuery(deleteQuery);
    final deleted = await deleteQuery.select('plan_id');

    ensureDeleteSucceeded(deleted);
  }

  @override
  Future<List<PlanModel>> getPlans() async {
    final userId = SupabaseAuthHelper.requireUserId();
    var selectQuery =
        supabaseClient.from('plans').select();
    selectQuery = scopeOwnUserQuery(selectQuery, userId);
    selectQuery = scopeFinancialQuery(selectQuery);
    final response = await selectQuery;

    return response.map((item) => PlanModel.fromMap(item)).toList();
  }

  @override
  Future<void> updatePlan(
    String planId,
    String title,
    String category,
    double targetAmount,
    double savedAmount,
    DateTime? deadline, {
    String? imageUrl,
  }) async {
    var updateQuery = supabaseClient.from('plans').update({
      'title': title,
      'category': category,
      'target_amount': targetAmount,
      'saved_amount': savedAmount,
      'deadline': deadline?.toIso8601String(),
      'image_url': _nullableUrl(imageUrl),
    }).eq('plan_id', planId).eq('user_id', SupabaseAuthHelper.requireUserId());
    updateQuery = scopeFinancialQuery(updateQuery);
    await updateQuery;
  }

  @override
  Future<void> updatePlanSaved(String planId, double savedAmount) async {
    var updateQuery = supabaseClient
        .from('plans')
        .update({'saved_amount': savedAmount})
        .eq('plan_id', planId)
        .eq('user_id', SupabaseAuthHelper.requireUserId());
    updateQuery = scopeFinancialQuery(updateQuery);
    await updateQuery;
  }

  static String? _nullableUrl(String? url) {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
