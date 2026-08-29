/// Deep-link used after Google / Facebook OAuth in the system browser.
///
/// Add this exact URL under Supabase → Authentication → URL Configuration →
/// Additional Redirect URLs.
class OAuthConfig {
  OAuthConfig._();

  static const redirectUrl = 'com.yasmen.pocketly://login-callback/';

  static bool isCallbackRoute(String? name) {
    if (name == null || name.isEmpty) return false;
    final lower = name.toLowerCase();
    if (lower.contains('login-callback')) return true;
    final uri = Uri.tryParse(name);
    if (uri == null) return false;
    return uri.queryParameters.containsKey('code') ||
        uri.queryParameters.containsKey('error');
  }

  static Uri? uriFromRouteName(String? name) {
    if (name == null || name.isEmpty) return null;
    final parsed = Uri.tryParse(name);
    if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) {
      return parsed;
    }
    final path = name.startsWith('/') ? name : '/$name';
    return Uri.tryParse('com.yasmen.pocketly:/$path');
  }
}
