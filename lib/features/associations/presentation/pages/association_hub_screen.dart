import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/services/locale_preferences.dart';
import 'package:imrpo/core/services/association_context.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/core/widgets/app_toast.dart';
import 'package:imrpo/features/association_invites/presentation/pages/invite_members_screen.dart';
import 'package:imrpo/features/associations/data/association_hub_datasource.dart';
import 'package:imrpo/features/associations/domain/entities/association_hub_data.dart';
import 'package:imrpo/features/associations/presentation/widgets/edit_gom3eya_sheet.dart';
import 'package:imrpo/features/associations/presentation/widgets/record_association_payment_sheet.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Standalone Egyptian-style association hub (gom3eya): turn, payout, installment.
class AssociationHubScreen extends StatefulWidget {
  const AssociationHubScreen({super.key, this.associationId});

  final String? associationId;

  @override
  State<AssociationHubScreen> createState() => _AssociationHubScreenState();
}

class _AssociationHubScreenState extends State<AssociationHubScreen> {
  final _ds = AssociationHubDatasource(Supabase.instance.client);

  AssociationHubData? _hub;
  bool _loading = true;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? get _associationId {
    if (widget.associationId != null) return widget.associationId;
    return getIt<AssociationContext>().activeAssociationId;
  }

  Future<void> _load() async {
    final id = _associationId;
    if (id == null) {
      setState(() {
        _loading = false;
        _error = 'no_association';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final hub = await _ds.loadHub(id);
      if (!mounted) return;
      setState(() {
        _hub = hub;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _editSettings() async {
    final hub = _hub;
    if (hub == null || !hub.canManage) return;

    final result = await showEditGom3eyaSheet(context, initial: hub);
    if (result == null || !mounted) return;

    setState(() => _saving = true);
    try {
      await _ds.saveGom3eya(
        associationId: hub.id,
        payoutAmount: result.payoutAmount,
        installmentAmount: result.installmentAmount,
        collectionDay: result.collectionDay,
        startsOn: result.startsOn,
        endsOn: result.endsOn,
        slots: result.slots,
      );
      if (!mounted) return;
      AppToast.success(
        context,
        AppLocalizations.of(context)!.associationHubSaved,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        localizeApiError(AppLocalizations.of(context)!, e.toString()),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _recordPayment() async {
    final hub = _hub;
    if (hub == null || !hub.canManage) return;

    final result = await showRecordAssociationPaymentSheet(context, hub: hub);
    if (result == null || !mounted) return;

    setState(() => _saving = true);
    try {
      await _ds.addPayment(
        associationId: hub.id,
        payerName: result.payerName,
        amount: result.amount,
        paidAt: result.paidAt,
        turnSlotId: result.turnSlotId,
        note: result.note,
      );
      if (!mounted) return;
      AppToast.success(
        context,
        AppLocalizations.of(context)!.associationHubPaymentRecorded,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        localizeApiError(AppLocalizations.of(context)!, e.toString()),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deletePayment(AssociationInstallmentPayment payment) async {
    final hub = _hub;
    final l10n = AppLocalizations.of(context)!;
    if (hub == null || !hub.canManage) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.associationHubPaymentDeleteTitle),
        content: Text(l10n.associationHubPaymentDeleteMessage(payment.payerName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.associationHubPaymentDeleteConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await _ds.deletePayment(payment.id);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, localizeApiError(l10n, e.toString()));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _advanceTurn() async {
    final hub = _hub;
    final l10n = AppLocalizations.of(context)!;
    if (hub == null || !hub.canManage) return;

    final current = hub.currentSlot;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.associationHubAdvanceTurn),
        content: Text(
          l10n.associationHubAdvanceTurnConfirm(
            current?.joinedNames(l10n.associationHubSharedNames) ?? '—',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.associationHubAdvanceTurn),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await _ds.advanceTurn(hub.id);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, localizeApiError(l10n, e.toString()));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _endGom3eya() async {
    final hub = _hub;
    final l10n = AppLocalizations.of(context)!;
    if (hub == null || !hub.canManage) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.associationHubEndGam3eyaTitle),
        content: Text(l10n.associationHubEndGam3eyaMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.associationHubEndGam3eyaConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await _ds.endGom3eya(hub.id);
      if (!mounted) return;
      AppToast.success(context, l10n.associationHubEndGam3eyaDone);
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, localizeApiError(l10n, e.toString()));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDay(DateTime date) {
    final locale = getIt<LocalePreferences>().locale.toString();
    return DateFormat.yMMMd(locale).format(date);
  }

  String? _personSchedule(AppLocalizations l10n, AssociationTurnPerson person) {
    final parts = <String>[];
    if (person.paymentOn != null) {
      parts.add(l10n.associationHubPaysOn(_formatDay(person.paymentOn!)));
    }
    if (person.collectionOn != null) {
      parts.add(l10n.associationHubCollectsOn(_formatDay(person.collectionOn!)));
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.scaffold,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          l10n.associationHubTitle,
          style: TextStyle(color: AppColors.textColor, fontSize: 18),
        ),
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error == 'no_association') {
      return Center(child: Text(l10n.associationHubNotAvailable));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localizeApiError(l10n, _error!),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                child: Text(l10n.smartImportReloadSms),
              ),
            ],
          ),
        ),
      );
    }

    final hub = _hub!;
    if (hub.isPersonal) {
      return Center(child: Text(l10n.associationHubNotAvailable));
    }

    final current = hub.currentSlot;
    final payout = hub.computedPayout;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            hub.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hub.isEnded
                ? (hub.isOwner
                    ? l10n.associationHubOwnerEndedSubtitle
                    : l10n.associationHubMemberEndedSubtitle)
                : (hub.isOwner
                    ? l10n.associationHubOwnerSubtitle
                    : l10n.associationHubMemberSubtitle),
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
              fontSize: 14,
            ),
          ),
          if (hub.isEnded && hub.gom3eyaEndedAt != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.flag_rounded,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.associationHubEndedBanner(
                        _formatDay(hub.gom3eyaEndedAt!),
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: l10n.associationHubStartDate,
                  value: hub.startsOn != null
                      ? _formatDay(hub.startsOn!)
                      : '—',
                  icon: Icons.event_available_outlined,
                  color: AppColors.plans,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: l10n.associationHubEndDate,
                  value: hub.endsOn != null ? _formatDay(hub.endsOn!) : '—',
                  icon: Icons.event_busy_outlined,
                  color: AppColors.plans,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (hub.slots.isEmpty)
            _EmptySetupCard(onSetup: hub.canManage ? _editSettings : null)
          else ...[
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: l10n.associationHubPayout,
                    value: payout > 0 ? Money.formatEgp(payout) : '—',
                    icon: Icons.savings_outlined,
                    color: AppColors.income,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    label: l10n.associationHubInstallment,
                    value:
                        hub.installmentAmount != null &&
                            hub.installmentAmount! > 0
                        ? Money.formatEgp(hub.installmentAmount!)
                        : '—',
                    icon: Icons.payments_outlined,
                    color: AppColors.primaryInk,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: l10n.associationHubMemberCount,
                    value: '${hub.memberSlots}',
                    icon: Icons.groups_outlined,
                    color: AppColors.balance,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    label: l10n.associationHubCollectionDay,
                    value: hub.collectionDay != null
                        ? l10n.associationHubDayOfMonth(hub.collectionDay!)
                        : '—',
                    icon: Icons.calendar_today_outlined,
                    color: AppColors.plans,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _CurrentTurnCard(
              turnLabel: hub.memberSlots > 0
                  ? l10n.associationHubTurnNumber(
                      hub.turnNumber,
                      hub.memberSlots,
                    )
                  : '—',
              slot: current,
              scheduleFor: (person) => _personSchedule(l10n, person),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            l10n.associationHubTurnList,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.associationHubTurnListHint,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          if (hub.slots.isEmpty)
            Text(
              l10n.associationHubEmptyTurnList,
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            ...hub.slots.map((slot) {
              final isCurrent = slot.slotIndex == hub.currentTurnIndex;
              return _TurnSlotTile(
                slot: slot,
                isCurrent: isCurrent,
                turnNumber: slot.slotIndex + 1,
                scheduleFor: (person) => _personSchedule(l10n, person),
              );
            }),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.associationHubPaymentsTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (hub.payments.isNotEmpty)
                Text(
                  l10n.associationHubPaymentsTotal(Money.formatEgp(hub.totalPaid)),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.incomeDark,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (hub.payments.isEmpty)
            Text(
              l10n.associationHubPaymentsEmpty,
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            ...hub.payments.map(
              (payment) => _PaymentTile(
                payment: payment,
                canDelete: hub.canManage,
                onDelete: () => _deletePayment(payment),
              ),
            ),
          if (hub.canManage) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _saving ? null : _recordPayment,
              icon: const Icon(Icons.payments_outlined),
              label: Text(l10n.associationHubRecordPayment),
            ),
          ],
          if (hub.members.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              l10n.associationHubAppMembers,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...hub.members.map(
              (m) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryInk.withValues(alpha: 0.12),
                  child: Text(
                    (m.username.isNotEmpty ? m.username[0] : '?').toUpperCase(),
                    style: TextStyle(
                      color: AppColors.primaryInk,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  m.username.isNotEmpty ? m.username : m.userId,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(_roleLabel(l10n, m.role)),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (hub.canManage) ...[
            if (hub.slots.isNotEmpty)
              FilledButton.icon(
                onPressed: _saving ? null : _advanceTurn,
                icon: const Icon(Icons.skip_next_rounded),
                label: Text(l10n.associationHubAdvanceTurn),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _saving ? null : _editSettings,
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.associationHubEdit),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _saving
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => InviteMembersScreen(
                            associationId: hub.id,
                            associationName: hub.name,
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: Text(l10n.associationHubInvite),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _saving ? null : _endGom3eya,
              icon: const Icon(Icons.flag_outlined),
              label: Text(l10n.associationHubEndGam3eya),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.plansLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              l10n.associationHubTreasurerNote,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(AppLocalizations l10n, String role) {
    switch (role) {
      case 'owner':
        return l10n.associationHubRoleOwner;
      case 'admin':
        return l10n.associationHubRoleAdmin;
      default:
        return l10n.associationHubRoleMember;
    }
  }
}

class _EmptySetupCard extends StatelessWidget {
  final VoidCallback? onSetup;

  const _EmptySetupCard({this.onSetup});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryInk.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryInk.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.groups_3_outlined,
            size: 48,
            color: AppColors.primaryInk,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.associationHubEmptySetup,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600, height: 1.4),
          ),
          if (onSetup != null) ...[
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onSetup,
              child: Text(l10n.associationHubEdit),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.inkOf(color), size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _CurrentTurnCard extends StatelessWidget {
  final String turnLabel;
  final AssociationTurnSlot? slot;
  final String? Function(AssociationTurnPerson person) scheduleFor;

  const _CurrentTurnCard({
    required this.turnLabel,
    required this.slot,
    required this.scheduleFor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final holderName = slot?.joinedNames(l10n.associationHubSharedNames) ?? '—';
    final lines = <String>[];
    if (slot != null) {
      for (final person in slot!.people) {
        final schedule = scheduleFor(person);
        if (schedule == null) continue;
        lines.add(slot!.isSplit ? '${person.name} · $schedule' : schedule);
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryInk.withValues(alpha: 0.12),
            AppColors.primaryInk.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryInk.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.associationHubCurrentTurn,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            holderName,
            style: TextStyle(
              fontSize: slot?.isSplit == true ? 22 : 26,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            turnLabel,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          for (final line in lines) ...[
            const SizedBox(height: 4),
            Text(
              line,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final AssociationInstallmentPayment payment;
  final bool canDelete;
  final VoidCallback onDelete;

  const _PaymentTile({
    required this.payment,
    required this.canDelete,
    required this.onDelete,
  });

  String _formatDate(BuildContext context) {
    final locale = getIt<LocalePreferences>().locale.toString();
    return DateFormat.yMMMd(locale).add_jm().format(payment.paidAt);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.incomeLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: AppColors.income,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.payerName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Money.formatEgp(payment.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.incomeDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.associationHubPaymentPaidOn(_formatDate(context)),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (payment.note != null && payment.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    payment.note!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textColor.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.errorColor,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _TurnSlotTile extends StatelessWidget {
  final AssociationTurnSlot slot;
  final bool isCurrent;
  final int turnNumber;
  final String? Function(AssociationTurnPerson person) scheduleFor;

  const _TurnSlotTile({
    required this.slot,
    required this.isCurrent,
    required this.turnNumber,
    required this.scheduleFor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.primaryInk.withValues(alpha: 0.08)
            : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? AppColors.primaryInk : AppColors.border,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCurrent ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$turnNumber',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isCurrent
                    ? AppColors.onPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < slot.people.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          slot.people[i].name,
                          style: TextStyle(
                            fontWeight: isCurrent
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (slot.isSplit && i == 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.plans.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            l10n.associationHubSplitBadge,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (scheduleFor(slot.people[i]) != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      scheduleFor(slot.people[i])!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.associationHubCurrentBadge,
                style: TextStyle(
                  color: AppColors.onPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else if (slot.hasReceived)
            Text(
              l10n.associationHubReceived,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.incomeDark,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Text(
              l10n.associationHubPending,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textColor.withValues(alpha: 0.45),
              ),
            ),
        ],
      ),
    );
  }
}
