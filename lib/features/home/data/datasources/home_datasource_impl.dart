import 'package:imrpo/core/helpers/supabase_auth_helper.dart';
import 'package:imrpo/core/helpers/username_uniqueness.dart';
import 'package:imrpo/features/home/data/datasources/home_datasource.dart';
import 'package:imrpo/features/home/data/models/user_profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeDatasourceImpl implements HomeDatasource {
  final SupabaseClient supabaseClient;

  HomeDatasourceImpl({required this.supabaseClient});

  @override
  Future<UserProfileModel> getCurrentUserProfile() async {
    final userId = SupabaseAuthHelper.requireUserId();
    final user = supabaseClient.auth.currentUser!;

    final row = await supabaseClient
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (row != null) {
      return UserProfileModel.fromMap(row);
    }

    final metadataName = user.userMetadata?['username'];
    return UserProfileModel(
      id: userId,
      username: metadataName is String ? metadataName : '',
      email: user.email ?? '',
    );
  }

  @override
  Future<void> updateUsername(String username) async {
    final userId = SupabaseAuthHelper.requireUserId();
    final trimmed = username.trim();
    await assertUsernameAvailable(supabaseClient, trimmed);

    await supabaseClient
        .from('profiles')
        .update({'username': trimmed})
        .eq('id', userId);

    await supabaseClient.auth.updateUser(
      UserAttributes(data: {'username': trimmed}),
    );
  }
}
