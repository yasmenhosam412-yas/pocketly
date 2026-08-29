import 'dart:async';

import 'package:imrpo/core/config/oauth_config.dart';
import 'package:imrpo/core/helpers/error_helper.dart';
import 'package:imrpo/core/helpers/supabase_auth_helper.dart';
import 'package:imrpo/core/helpers/username_uniqueness.dart';
import 'package:imrpo/features/auth/data/datasources/auth_datasource.dart';
import 'package:imrpo/features/auth/domain/entities/social_auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthDatasourceImpl extends AuthDatasource {
  final SupabaseClient supabaseClient;
  Completer<void>? _oauthSessionReady;

  AuthDatasourceImpl({required this.supabaseClient});
  @override
  Future<void> forgetPassword(String email) async {
    await supabaseClient.auth.signInWithOtp(
      email: email,
      shouldCreateUser: false,
    );
  }

  @override
  Future<void> login(String email, String password) async {
    await supabaseClient.auth.signInWithPassword(
      password: password,
      email: email,
    );
  }

  @override
  Future<void> loginWithSocial(SocialAuthProvider provider) async {
    if (supabaseClient.auth.currentSession != null) {
      await _ensureProfileForCurrentUser();
      return;
    }

    final oauthProvider = switch (provider) {
      SocialAuthProvider.google => OAuthProvider.google,
      SocialAuthProvider.facebook => OAuthProvider.facebook,
    };

    final sessionReady = Completer<void>();
    final previous = _oauthSessionReady;
    if (previous != null && !previous.isCompleted) {
      previous.completeError(const SocialAuthCancelledException());
    }
    _oauthSessionReady = sessionReady;
    final authSub = supabaseClient.auth.onAuthStateChange.listen((data) {
      if (data.session != null && !sessionReady.isCompleted) {
        sessionReady.complete();
      }
    });

    try {
      final launched = await supabaseClient.auth.signInWithOAuth(
        oauthProvider,
        redirectTo: OAuthConfig.redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
        queryParams: provider == SocialAuthProvider.google
            ? const {'prompt': 'select_account'}
            : null,
      );
      if (!launched) {
        throw const AuthException('Could not start social login.');
      }

      try {
        await sessionReady.future.timeout(const Duration(minutes: 3));
      } on TimeoutException {
        throw const SocialAuthCancelledException();
      } on SocialAuthCancelledException {
        rethrow;
      } finally {
        if (identical(_oauthSessionReady, sessionReady)) {
          _oauthSessionReady = null;
        }
      }

      await _ensureProfileForCurrentUser();
    } finally {
      await authSub.cancel();
    }
  }

  Future<void> _ensureProfileForCurrentUser() async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) return;

    final existing = await supabaseClient
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();
    if (existing != null) return;

    var username = _usernameFrom(user);
    try {
      await assertUsernameAvailable(supabaseClient, username);
    } on UsernameTakenException {
      username = '${username}_${user.id.substring(0, 6)}';
    }

    try {
      await supabaseClient.from('profiles').insert({
        'id': user.id,
        'username': username,
        'email': user.email ?? '',
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') return;
      rethrow;
    }

    try {
      await supabaseClient.auth.updateUser(
        UserAttributes(data: {'username': username}),
      );
    } catch (_) {}
  }

  String _usernameFrom(User user) {
    final meta = user.userMetadata ?? {};
    for (final key in ['full_name', 'name', 'username']) {
      final value = meta[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    final email = user.email;
    if (email != null && email.contains('@')) {
      final local = email.split('@').first.trim();
      if (local.isNotEmpty) return local;
    }
    return 'user_${user.id.substring(0, 8)}';
  }

  @override
  Future<void> signup(String username, String email, String password) async {
    final trimmedName = username.trim();
    await assertUsernameAvailable(supabaseClient, trimmedName);
    final response = await supabaseClient.auth.signUp(
      password: password,
      email: email,
      data: {"username": trimmedName},
    );
    final user = response.user;
    if (user != null) {
      try {
        await supabaseClient.from("profiles").insert({
          "id": user.id,
          "username": trimmedName,
          "email": email,
        });
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          throw const UsernameTakenException();
        }
        rethrow;
      }
    }
  }

  @override
  Future<void> verifyOTP(String newPassword, String otp, String email) async {
    await supabaseClient.auth.verifyOTP(
      email: email,
      token: otp,
      type: OtpType.email,
    );
    await supabaseClient.auth.updateUser(UserAttributes(password: newPassword));
    await supabaseClient.auth.signOut();
  }

  @override
  Future<void> logout() async {
    await supabaseClient.auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final userId = SupabaseAuthHelper.requireUserId();

    try {
      await supabaseClient.rpc('delete_account');
    } on PostgrestException catch (e) {
      if (_isMissingRpc(e)) {
        await _deleteUserData(userId);
      } else {
        try {
          await _deleteUserData(userId);
        } catch (_) {
          rethrow;
        }
      }
    }

    try {
      await supabaseClient.auth.signOut();
    } catch (_) {}
  }

  Future<void> _deleteUserData(String userId) async {
    await supabaseClient.from('incomes').delete().eq('user_id', userId);
    await supabaseClient.from('expenses').delete().eq('user_id', userId);
    await supabaseClient.from('plans').delete().eq('user_id', userId);
    await supabaseClient.from('profiles').delete().eq('id', userId);
  }

  bool _isMissingRpc(PostgrestException e) {
    final message = e.message.toLowerCase();
    return e.code == 'PGRST202' ||
        message.contains('could not find the function') ||
        message.contains('delete_account');
  }
}
