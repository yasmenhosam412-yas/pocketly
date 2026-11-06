import 'package:imrpo/features/associations/domain/entities/association_hub_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssociationHubDatasource {
  final SupabaseClient _client;

  AssociationHubDatasource(this._client);

  Future<AssociationHubData> loadHub(String associationId) async {
    final raw = await _client.rpc(
      'get_association_hub',
      params: {'p_association_id': associationId},
    );
    final map = Map<String, dynamic>.from(raw as Map);
    return _parseHub(map);
  }

  Future<void> saveGom3eya({
    required String associationId,
    required double? payoutAmount,
    required double? installmentAmount,
    required int? collectionDay,
    required DateTime? startsOn,
    required DateTime? endsOn,
    required List<AssociationTurnSlot> slots,
  }) async {
    final payload = slots
        .map(
          (s) => {
            'id': s.id,
            'slot_index': s.slotIndex,
            'holder_name': s.holderName,
            'payment_on': _formatDateOnly(s.paymentOn),
            'collection_on': _formatDateOnly(s.collectionOn),
            'co_holder_name': s.isSplit ? s.coHolderName!.trim() : null,
            'co_payment_on': s.isSplit ? _formatDateOnly(s.coPaymentOn) : null,
            'co_collection_on':
                s.isSplit ? _formatDateOnly(s.coCollectionOn) : null,
          },
        )
        .toList();

    await _client.rpc(
      'save_association_gom3eya',
      params: {
        'p_association_id': associationId,
        'p_payout_amount': payoutAmount ?? 0,
        'p_installment_amount': installmentAmount ?? 0,
        'p_collection_day': collectionDay,
        'p_slots': payload,
        'p_starts_on': _formatDateOnly(startsOn),
        'p_ends_on': _formatDateOnly(endsOn),
      },
    );
  }

  Future<String> addPayment({
    required String associationId,
    required String payerName,
    required double amount,
    required DateTime paidAt,
    String? turnSlotId,
    String? note,
  }) async {
    final id = await _client.rpc(
      'add_association_payment',
      params: {
        'p_association_id': associationId,
        'p_payer_name': payerName,
        'p_amount': amount,
        'p_paid_at': paidAt.toUtc().toIso8601String(),
        'p_turn_slot_id': turnSlotId,
        'p_note': note,
      },
    );
    return id.toString();
  }

  Future<void> deletePayment(String paymentId) async {
    await _client.rpc(
      'delete_association_payment',
      params: {'p_payment_id': paymentId},
    );
  }

  Future<DateTime> endGom3eya(String associationId) async {
    final raw = await _client.rpc(
      'end_association_gom3eya',
      params: {'p_association_id': associationId},
    );
    return DateTime.parse(raw.toString()).toLocal();
  }

  Future<int> advanceTurn(String associationId) async {
    final next = await _client.rpc(
      'advance_association_turn',
      params: {'p_association_id': associationId},
    );
    return (next as num).toInt();
  }

  AssociationHubData _parseHub(Map<String, dynamic> map) {
    final assoc = Map<String, dynamic>.from(
      map['association'] as Map? ?? {},
    );
    final slotsRaw = map['slots'] as List<dynamic>? ?? [];
    final membersRaw = map['members'] as List<dynamic>? ?? [];
    final paymentsRaw = map['payments'] as List<dynamic>? ?? [];

    final slots = slotsRaw.map((row) {
      final s = Map<String, dynamic>.from(row as Map);
      final received = s['received_at']?.toString();
      return AssociationTurnSlot(
        id: s['id']?.toString(),
        slotIndex: (s['slot_index'] as num?)?.toInt() ?? 0,
        holderName: s['holder_name']?.toString() ?? '',
        userId: s['user_id']?.toString(),
        receivedAt:
            received != null && received.isNotEmpty
                ? DateTime.tryParse(received)?.toLocal()
                : null,
        paymentOn: _parseDateOnly(s['payment_on']),
        collectionOn: _parseDateOnly(s['collection_on']),
        coHolderName: s['co_holder_name']?.toString(),
        coPaymentOn: _parseDateOnly(s['co_payment_on']),
        coCollectionOn: _parseDateOnly(s['co_collection_on']),
      );
    }).toList();

    final members = membersRaw.map((row) {
      final m = Map<String, dynamic>.from(row as Map);
      return AssociationHubMember(
        userId: m['user_id']?.toString() ?? '',
        role: m['role']?.toString() ?? 'member',
        username: m['username']?.toString() ?? '',
      );
    }).toList();

    final payments = paymentsRaw.map((row) {
      final p = Map<String, dynamic>.from(row as Map);
      final paidRaw = p['paid_at']?.toString();
      return AssociationInstallmentPayment(
        id: p['id']?.toString() ?? '',
        payerName: p['payer_name']?.toString() ?? '',
        turnSlotId: p['turn_slot_id']?.toString(),
        amount: _parseAmount(p['amount']) ?? 0,
        paidAt: paidRaw != null && paidRaw.isNotEmpty
            ? DateTime.parse(paidRaw).toLocal()
            : DateTime.now(),
        note: p['note']?.toString(),
      );
    }).toList();

    return AssociationHubData(
      id: assoc['id']?.toString() ?? '',
      name: assoc['name']?.toString() ?? '',
      isPersonal: assoc['is_personal'] == true,
      payoutAmount: _parseAmount(assoc['payout_amount']),
      installmentAmount: _parseAmount(assoc['installment_amount']),
      memberSlots: (assoc['member_slots'] as num?)?.toInt() ?? slots.length,
      currentTurnIndex: (assoc['current_turn_index'] as num?)?.toInt() ?? 0,
      collectionDay: (assoc['collection_day'] as num?)?.toInt(),
      startsOn: _parseDateOnly(assoc['starts_on']),
      endsOn: _parseDateOnly(assoc['ends_on']),
      slots: slots,
      members: members,
      payments: payments,
      isOwner: map['is_owner'] == true,
      gom3eyaEndedAt: _parseDateTime(assoc['gom3eya_ended_at']),
    );
  }

  String? _formatDateOnly(DateTime? date) {
    if (date == null) return null;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DateTime? _parseDateOnly(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    if (s.length < 10) return null;
    final y = int.tryParse(s.substring(0, 4));
    final m = int.tryParse(s.substring(5, 7));
    final d = int.tryParse(s.substring(8, 10));
    if (y == null || m == null || d == null) return null;
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    return DateTime(y, m, d);
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s)?.toLocal();
  }

  double? _parseAmount(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
