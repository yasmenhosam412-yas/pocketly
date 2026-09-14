import 'package:url_launcher/url_launcher.dart';

/// Android applicationId / Play Store package for Pocketly.
const String kPocketlyPlayStoreId = 'com.yasmen.pocketly';

/// Opens the Pocketly listing in the Play Store app, or the web listing.
Future<bool> openPocketlyPlayStoreListing() async {
  final marketUri = Uri.parse('market://details?id=$kPocketlyPlayStoreId');
  final httpsUri = Uri.parse(
    'https://play.google.com/store/apps/details?id=$kPocketlyPlayStoreId',
  );

  try {
    final openedMarket = await launchUrl(
      marketUri,
      mode: LaunchMode.externalApplication,
    );
    if (openedMarket) return true;
  } catch (_) {
    // Fall through to https (emulator / no Play Store / non-Android).
  }

  try {
    return await launchUrl(httpsUri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
