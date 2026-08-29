import 'package:imrpo/core/helpers/association_scope_helper.dart';
import 'package:imrpo/core/services/association_context.dart';
import 'package:imrpo/core/services/service_locator.dart';

/// Shared association scoping for Supabase financial datasources.
mixin AssociationDatasourceMixin {
  bool get useAssociationScope {
    final ctx = getIt<AssociationContext>();
    return ctx.isAvailable &&
        ctx.isLoaded &&
        ctx.activeAssociationId != null &&
        ctx.activeAssociationId!.isNotEmpty;
  }

  /// Shared/family ledgers list everyone's rows; personal stays own-user only.
  bool get listSharedLedgerRows {
    if (!useAssociationScope) return false;
    final item = getIt<AssociationContext>().activeItem;
    return item != null && !item.isPersonal;
  }

  bool get isFamilyLedger {
    if (!useAssociationScope) return false;
    return getIt<AssociationContext>().activeItem?.isFamily ?? false;
  }

  Map<String, dynamic> scopedFinancialRow(Map<String, dynamic> row) {
    if (!useAssociationScope) return row;
    return {...row, 'association_id': requireAssociationId()};
  }

  T scopeFinancialQuery<T>(T query) {
    if (!useAssociationScope) return query;
    return (query as dynamic).eq('association_id', requireAssociationId()) as T;
  }

  T scopeOwnUserQuery<T>(T query, String userId) {
    if (listSharedLedgerRows) return query;
    return (query as dynamic).eq('user_id', userId) as T;
  }

  /// Family budgets are ledger-wide; skip own-user on write.
  T scopeOwnUserUnlessFamily<T>(T query, String userId) {
    if (isFamilyLedger) return query;
    return (query as dynamic).eq('user_id', userId) as T;
  }
}
