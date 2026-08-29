import 'package:imrpo/features/association_invites/domain/entities/association_invite_item.dart';
import 'package:imrpo/features/association_invites/domain/entities/profile_search_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssociationInviteDatasource {
  final SupabaseClient _client;

  AssociationInviteDatasource(this._client);

  Future<List<ProfileSearchResult>> searchProfiles(String query) async {
    final rows = await _client.rpc(
      'search_profiles_for_invite',
      params: {'p_query': query.trim()},
    );
    final list = rows as List<dynamic>? ?? [];
    return list.map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      return ProfileSearchResult(
        userId: map['user_id']?.toString() ?? '',
        username: map['username']?.toString() ?? '',
      );
    }).where((r) => r.userId.isNotEmpty).toList();
  }

  Future<String> sendInvite({
    required String associationId,
    required String inviteeUserId,
  }) async {
    final id = await _client.rpc(
      'send_association_invite',
      params: {
        'p_association_id': associationId,
        'p_invitee_user_id': inviteeUserId,
      },
    );
    return id.toString();
  }

  Future<void> respondInvite({
    required String inviteId,
    required bool accept,
  }) async {
    await _client.rpc(
      'respond_association_invite',
      params: {
        'p_invite_id': inviteId,
        'p_accept': accept,
      },
    );
  }

  Future<List<AssociationInviteItem>> listMyPendingInvites() async {
    try {
      final rows = await _client.rpc('list_my_pending_association_invites');
      final list = rows as List<dynamic>? ?? [];
      return list.map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        return AssociationInviteItem(
          inviteId: map['invite_id']?.toString() ?? '',
          associationId: map['association_id']?.toString() ?? '',
          associationName: map['association_name']?.toString() ?? '',
          inviterUsername: map['inviter_username']?.toString() ?? '',
          createdAt: DateTime.parse(
            map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
          ),
          expiresAt: DateTime.parse(
            map['expires_at']?.toString() ?? DateTime.now().toIso8601String(),
          ),
        );
      }).where((i) => i.inviteId.isNotEmpty).toList();
    } on PostgrestException catch (e) {
      final msg = e.message.toLowerCase();
      if (e.code == 'PGRST202' ||
          msg.contains('list_my_pending_association_invites') ||
          msg.contains('could not find the function')) {
        return [];
      }
      rethrow;
    }
  }
}
