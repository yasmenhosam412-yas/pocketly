import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:imrpo/core/utils/network_errors.dart';
import 'package:imrpo/core/helpers/supabase_auth_helper.dart';
import 'package:imrpo/core/helpers/supabase_delete_helper.dart';
import 'package:imrpo/features/associations/domain/entities/association_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Loads associations for the signed-in user and tracks the active ledger.
class AssociationContext extends ChangeNotifier {
  static const _prefsKeyPrefix = 'active_association_';
  static const _offlineFlagPrefix = 'association_offline_';
  static const _networkTimeout = Duration(seconds: 8);

  final SupabaseClient _client;

  List<AssociationItem> _items = [];
  String? _activeId;
  bool _loaded = false;
  bool _available = true;
  String? _loadError;

  AssociationContext({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  List<AssociationItem> get items => List.unmodifiable(_items);

  String? get activeAssociationId => _activeId;

  AssociationItem? get activeItem {
    if (_activeId == null) return null;
    for (final item in _items) {
      if (item.id == _activeId) return item;
    }
    return null;
  }

  bool get isLoaded => _loaded;

  bool get isAvailable => _available;

  /// True when financial queries may include [association_id] scoping.
  bool get isReadyForData =>
      isLoaded && (!_available || (_activeId != null && _activeId!.isNotEmpty));

  String? get loadError => _loadError;

  bool get isOffline => _loadError == 'network';

  String requireActiveId() {
    final id = _activeId;
    if (id == null || id.isEmpty) {
      throw StateError('No active association selected');
    }
    return id;
  }

  String displayName(AssociationItem item, {String personalFallback = 'Personal'}) {
    if (item.isPersonal) return personalFallback;
    return item.name;
  }

  /// True when the active ledger allows adding/editing financial entries.
  bool get canEditActiveLedger {
    final item = activeItem;
    if (item == null) return true;
    return item.canEditLedger;
  }

  bool get isActiveAssociationReadOnly {
    final item = activeItem;
    return item != null && item.isMemberViewOnly;
  }

  /// Loads ledgers from Supabase. When [forceNetwork] is false and the last
  /// session ended offline, skips RPC so startup does not hit the network.
  Future<void> load({bool forceNetwork = false}) async {
    if (!SupabaseAuthHelper.isSignedIn) {
      clear(notify: false);
      return;
    }

    if (!forceNetwork && await _readPersistedOfflineFlag()) {
      await _setOfflineLedgerMode();
      return;
    }

    _loadError = null;
    try {
      await _loadFromNetwork();
    } on PostgrestException catch (e) {
      if (_isSchemaMissing(e)) {
        _setUnavailableLedgerMode();
        return;
      }
      if (SupabaseAuthHelper.isJwtClockSkew(e)) {
        await _retryAfterJwtClockSkew();
        return;
      }
      _loadError = e.message;
      await _setOfflineLedgerMode();
    } catch (e) {
      if (SupabaseAuthHelper.isJwtClockSkew(e)) {
        await _retryAfterJwtClockSkew();
        return;
      }
      if (isNetworkError(e)) {
        await _persistOfflineFlag();
        await _setOfflineLedgerMode();
        return;
      }
      _loadError = e.toString();
      await _setOfflineLedgerMode();
    }
  }

  Future<void> _loadFromNetwork() async {
    await _ensurePersonalAndFetch();
    if (_items.isEmpty) {
      await _ensurePersonalAndFetch();
    }
    await _restoreActiveSelection();
    _available = _activeId != null && _activeId!.isNotEmpty;
    _loaded = true;
    await _clearPersistedOfflineFlag();
    notifyListeners();
  }

  Future<void> _retryAfterJwtClockSkew() async {
    final recovered = await SupabaseAuthHelper.recoverFromJwtClockSkew();
    if (recovered) {
      try {
        await _loadFromNetwork();
        return;
      } catch (e) {
        if (isNetworkError(e)) {
          await _persistOfflineFlag();
          await _setOfflineLedgerMode();
          return;
        }
      }
    }
    await _setOfflineLedgerMode();
  }

  Future<void> _ensurePersonalAndFetch() async {
    await _client
        .rpc('ensure_personal_association')
        .timeout(_networkTimeout);
    await _fetchMemberships().timeout(_networkTimeout);
  }

  void _setUnavailableLedgerMode() {
    _available = false;
    _items = [];
    _activeId = null;
    _loaded = true;
    notifyListeners();
  }

  Future<void> _setOfflineLedgerMode() async {
    _loadError = 'network';
    _items = [];
    _available = true;
    await _restoreActiveIdFromPrefsOnly();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _restoreActiveIdFromPrefsOnly() async {
    if (!SupabaseAuthHelper.isSignedIn) {
      _activeId = null;
      return;
    }
    final userId = SupabaseAuthHelper.requireUserId();
    final prefs = await SharedPreferences.getInstance();
    _activeId = prefs.getString('$_prefsKeyPrefix$userId');
  }

  Future<String?> peekSavedActiveAssociationId() async {
    if (_activeId != null && _activeId!.isNotEmpty) return _activeId;
    await _restoreActiveIdFromPrefsOnly();
    return _activeId;
  }

  Future<void> _fetchMemberships() async {
    final userId = SupabaseAuthHelper.requireUserId();
    final rows = await _client
        .from('association_members')
        .select('role, associations(id, name, is_personal)')
        .eq('user_id', userId);

    final parsed = <AssociationItem>[];
    for (final row in rows) {
      final assoc = row['associations'];
      if (assoc is! Map) continue;
      final id = assoc['id']?.toString();
      final name = assoc['name']?.toString();
      if (id == null || name == null) continue;
      parsed.add(
        AssociationItem(
          id: id,
          name: name,
          isPersonal: assoc['is_personal'] == true,
          role: row['role']?.toString() ?? 'member',
        ),
      );
    }

    parsed.sort((a, b) {
      if (a.isPersonal != b.isPersonal) return a.isPersonal ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    _items = parsed;
  }

  Future<void> _restoreActiveSelection() async {
    if (_items.isEmpty) {
      _activeId = null;
      return;
    }

    final userId = SupabaseAuthHelper.requireUserId();
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('$_prefsKeyPrefix$userId');

    if (saved != null && _items.any((i) => i.id == saved)) {
      _activeId = saved;
      return;
    }

    AssociationItem? personal;
    for (final item in _items) {
      if (item.isPersonal) {
        personal = item;
        break;
      }
    }
    _activeId = personal?.id ?? _items.first.id;
    await prefs.setString('$_prefsKeyPrefix$userId', _activeId!);
  }

  Future<void> selectAssociation(String associationId) async {
    if (!_items.any((i) => i.id == associationId)) return;
    _activeId = associationId;
    final userId = SupabaseAuthHelper.requireUserId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefsKeyPrefix$userId', associationId);
    notifyListeners();
  }

  Future<String> createAssociation(String name) async {
    final raw = await _client.rpc(
      'create_association',
      params: {'p_name': name.trim()},
    );
    final id = raw.toString();
    await _fetchMemberships();
    await selectAssociation(id);
    return id;
  }

  /// Deletes a non-personal ledger and all of its financial data (DB cascade).
  Future<void> deleteAssociation(String associationId) async {
    AssociationItem? item;
    for (final candidate in _items) {
      if (candidate.id == associationId) {
        item = candidate;
        break;
      }
    }
    if (item == null) {
      throw StateError('Association not found');
    }
    if (item.isPersonal) {
      throw StateError('Cannot delete personal ledger');
    }

    await _deleteAssociationOnServer(associationId);

    final wasActive = _activeId == associationId;
    await _fetchMemberships();
    if (wasActive || !_items.any((i) => i.id == _activeId)) {
      await _restoreActiveSelection();
    }
    notifyListeners();
  }

  void clear({bool notify = true}) {
    _items = [];
    _activeId = null;
    _loaded = false;
    _available = true;
    _loadError = null;
    _clearPersistedOfflineFlag();
    if (notify) notifyListeners();
  }

  Future<bool> _readPersistedOfflineFlag() async {
    final userId = SupabaseAuthHelper.userId;
    if (userId == null) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_offlineFlagPrefix$userId') ?? false;
  }

  Future<void> _persistOfflineFlag() async {
    final userId = SupabaseAuthHelper.userId;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_offlineFlagPrefix$userId', true);
  }

  Future<void> _clearPersistedOfflineFlag() async {
    final userId = SupabaseAuthHelper.userId;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_offlineFlagPrefix$userId');
  }

  Future<void> _deleteAssociationOnServer(String associationId) async {
    try {
      await _client.rpc(
        'delete_association',
        params: {'p_association_id': associationId},
      );
      return;
    } on PostgrestException catch (e) {
      if (!_isMissingDeleteRpc(e)) {
        rethrow;
      }
    }

    final deleted = await _client
        .from('associations')
        .delete()
        .eq('id', associationId)
        .select('id');
    ensureDeleteSucceeded(deleted);
  }

  bool _isMissingDeleteRpc(PostgrestException e) {
    final msg = e.message.toLowerCase();
    return e.code == 'PGRST202' ||
        msg.contains('delete_association') ||
        msg.contains('could not find the function');
  }

  bool _isSchemaMissing(PostgrestException e) {
    final msg = e.message.toLowerCase();
    return e.code == 'PGRST205' ||
        msg.contains('association_members') ||
        msg.contains('ensure_personal_association') ||
        msg.contains('does not exist');
  }
}
