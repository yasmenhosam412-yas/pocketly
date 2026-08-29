class AssociationItem {
  final String id;
  final String name;
  final bool isPersonal;
  final String role;
  /// `personal`, `family`, or `shared` (gom3eya / treasurer).
  final String kind;

  const AssociationItem({
    required this.id,
    required this.name,
    required this.isPersonal,
    required this.role,
    this.kind = 'shared',
  });

  bool get isFamily => !isPersonal && kind == 'family';

  /// Single treasurer: only the owner records income, expenses, plans, and dates.
  bool get isTreasurer => !isPersonal && !isFamily && role == 'owner';

  bool get isMemberViewOnly =>
      !isPersonal && !isFamily && role == 'member';

  /// Personal, family (any member), or shared-ledger owner.
  bool get canEditLedger => isPersonal || isFamily || isTreasurer;

  bool get canManageInvites =>
      !isPersonal && (role == 'owner' || role == 'admin');
}
