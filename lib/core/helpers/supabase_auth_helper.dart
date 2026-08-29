import 'package:supabase_flutter/supabase_flutter.dart';

/// Guards Supabase calls that require a signed-in user id (UUID).
class SupabaseAuthHelper {
  SupabaseAuthHelper._();

  static String? get userId =>
      Supabase.instance.client.auth.currentUser?.id;

  static bool get isSignedIn {
    final id = userId;
    return id != null && id.isNotEmpty;
  }

  static String requireUserId() {
    final id = userId;
    if (id == null || id.isEmpty) {
      throw const AuthException('Not signed in');
    }
    return id;
  }

  /// PostgREST PGRST303: token `iat` is later than the API clock.
  static bool isJwtClockSkew(Object error) {
    if (error is PostgrestException) {
      final msg = error.message.toLowerCase();
      return error.code == 'PGRST303' ||
          msg.contains('issued at future') ||
          msg.contains('jwt issued at');
    }
    final msg = error.toString().toLowerCase();
    return msg.contains('issued at future') || msg.contains('pgrst303');
  }

  /// Wait and refresh so a token issued on a skewed device clock is accepted.
  static Future<bool> recoverFromJwtClockSkew() async {
    try {
      await Future<void>.delayed(const Duration(seconds: 1));
      final response = await Supabase.instance.client.auth.refreshSession();
      return response.session != null;
    } catch (_) {
      return false;
    }
  }
}
