import 'package:flutter/foundation.dart';
import 'package:imrpo/core/helpers/supabase_auth_helper.dart';
import 'package:imrpo/core/services/association_context.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps family-ledger member ids to usernames for "added by" labels.
class AssociationMemberNames extends ChangeNotifier {
  AssociationMemberNames(this._client, this._associationContext);

  final SupabaseClient _client;
  final AssociationContext _associationContext;
  Map<String, String> _byUserId = {};
  String? _associationId;
  bool _loading = false;

  Future<void> ensureLoaded() async {
    final item = _associationContext.activeItem;
    if (item == null || !item.isFamily) {
      _clearIfNeeded();
      return;
    }
    if (_associationId == item.id) return;
    await refresh();
  }

  Future<void> refresh() async {
    final item = _associationContext.activeItem;
    if (item == null || !item.isFamily) {
      _clearIfNeeded();
      return;
    }
    if (_loading && _associationId == item.id) return;
    _loading = true;
    _associationId = item.id;
    try {
      final rows = await _client.rpc(
        'list_association_member_names',
        params: {'p_association_id': item.id},
      );
      final map = <String, String>{};
      for (final row in (rows as List<dynamic>? ?? [])) {
        final m = Map<String, dynamic>.from(row as Map);
        final id = m['user_id']?.toString() ?? '';
        if (id.isEmpty) continue;
        map[id] = m['username']?.toString().trim() ?? '';
      }
      _byUserId = map;
    } catch (_) {
      _byUserId = {};
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _byUserId = {};
    _associationId = null;
    notifyListeners();
  }

  void _clearIfNeeded() {
    if (_byUserId.isEmpty && _associationId == null) return;
    clear();
  }

  String label(String? userId, AppLocalizations l10n) {
    if (userId != null && userId == SupabaseAuthHelper.userId) {
      return l10n.familyAuthorYou;
    }
    final name = userId == null ? '' : (_byUserId[userId] ?? '').trim();
    if (name.isNotEmpty) return name;
    return l10n.familyAuthorUnknown;
  }
}
