import 'package:flutter/material.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/services/association_context.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/session/user_session.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/association_invites/data/association_invite_datasource.dart';
import 'package:imrpo/features/association_invites/domain/entities/association_invite_item.dart';
import 'package:imrpo/l10n/app_localizations.dart';

/// Pending ledger invites for the signed-in user (home banner or picker).
class PendingAssociationInvites extends StatefulWidget {
  const PendingAssociationInvites({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  State<PendingAssociationInvites> createState() =>
      _PendingAssociationInvitesState();
}

class _PendingAssociationInvitesState
    extends State<PendingAssociationInvites> {
  List<AssociationInviteItem> _invites = [];
  final Set<String> _busy = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list =
          await getIt<AssociationInviteDatasource>().listMyPendingInvites();
      if (!mounted) return;
      setState(() {
        _invites = list;
        _loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _invites = [];
        _loaded = true;
      });
    }
  }

  Future<void> _respond(AssociationInviteItem invite, bool accept) async {
    if (_busy.contains(invite.inviteId)) return;
    setState(() => _busy.add(invite.inviteId));
    final l10n = AppLocalizations.of(context)!;
    try {
      await getIt<AssociationInviteDatasource>().respondInvite(
        inviteId: invite.inviteId,
        accept: accept,
      );
      if (!mounted) return;
      setState(() {
        _invites.removeWhere((i) => i.inviteId == invite.inviteId);
        _busy.remove(invite.inviteId);
      });
      if (accept) {
        await getIt<AssociationContext>().load(forceNetwork: true);
        if (!mounted) return;
        await getIt<AssociationContext>().selectAssociation(
          invite.associationId,
        );
        if (!mounted) return;
        UserSession.reloadForAssociationSwitch(context);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? l10n.associationInviteAcceptedSnack
                : l10n.associationInviteRejectedSnack,
          ),
          backgroundColor: accept ? AppColors.success : AppColors.textMuted,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy.remove(invite.inviteId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizeApiError(l10n, e.toString())),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _invites.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: widget.compact
          ? const EdgeInsets.only(bottom: 12)
          : const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.associationInvitePendingTitle,
            style: TextStyle(
              fontSize: widget.compact ? 14 : 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 8),
          ..._invites.map((invite) {
            final busy = _busy.contains(invite.inviteId);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: AppColors.balanceLight.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.associationInvitePendingBody(
                          invite.inviterUsername.isEmpty
                              ? '—'
                              : invite.inviterUsername,
                          invite.associationName,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          color: AppColors.textColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          TextButton(
                            onPressed: busy
                                ? null
                                : () => _respond(invite, false),
                            child: Text(l10n.associationInviteReject),
                          ),
                          const SizedBox(width: 4),
                          FilledButton(
                            onPressed:
                                busy ? null : () => _respond(invite, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                            ),
                            child: busy
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.onPrimary,
                                    ),
                                  )
                                : Text(l10n.associationInviteAccept),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
