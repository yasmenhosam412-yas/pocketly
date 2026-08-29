import 'package:imrpo/core/services/association_context.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/features/associations/domain/entities/association_item.dart';

/// Who may edit vs view-only for the active ledger.
class AssociationLedgerAccess {
  AssociationLedgerAccess._();

  static AssociationContext get _ctx => getIt<AssociationContext>();

  static AssociationItem? get activeItem => _ctx.activeItem;

  /// Personal, family (any member), or shared-ledger treasurer may add/edit.
  static bool get canEdit => _ctx.canEditActiveLedger;

  static bool get isFamily => activeItem != null && activeItem!.isFamily;

  static bool get isAssociationLedger =>
      activeItem != null && !activeItem!.isPersonal;

  static bool get isTreasurer =>
      activeItem != null && activeItem!.isTreasurer;

  static bool get isMemberViewOnly =>
      activeItem != null && activeItem!.isMemberViewOnly;
}
