import 'package:imrpo/core/helpers/error_helper.dart';
import 'package:imrpo/core/helpers/supabase_auth_helper.dart';
import 'package:imrpo/core/helpers/username_uniqueness.dart';
import 'package:imrpo/features/auth/data/datasources/auth_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthDatasourceImpl extends AuthDatasource {
  final SupabaseClient supabaseClient;

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
