import 'package:imrpo/core/helpers/error_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Throws [UsernameTakenException] if another profile already uses [username].
Future<void> assertUsernameAvailable(
  SupabaseClient client,
  String username,
) async {
  final trimmed = username.trim();
  if (trimmed.isEmpty) return;
  try {
    final taken = await client.rpc(
      'is_username_taken',
      params: {'p_username': trimmed},
    );
    if (taken == true) {
      throw const UsernameTakenException();
    }
  } on UsernameTakenException {
    rethrow;
  } on PostgrestException catch (e) {
    if (e.code == 'PGRST202' ||
        e.message.toLowerCase().contains('is_username_taken')) {
      return;
    }
    rethrow;
  }
}
