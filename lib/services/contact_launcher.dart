import 'package:agrilumina/utils/phone.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens phone dialer / WhatsApp after a contact is unlocked.
abstract class ContactLauncher {
  Future<bool> call(String phone);

  Future<bool> openWhatsApp(String phone);
}

/// Uses [url_launcher]; falls back from `whatsapp://` to `https://wa.me/`.
class UrlLauncherContactLauncher implements ContactLauncher {
  const UrlLauncherContactLauncher();

  @override
  Future<bool> call(String phone) async {
    final uri = telUri(phone);
    if (uri.path.isEmpty) return false;
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri);
  }

  @override
  Future<bool> openWhatsApp(String phone) async {
    if (digitsOnlyPhone(phone).isEmpty) return false;

    final appUri = whatsAppAppUri(phone);
    if (await canLaunchUrl(appUri)) {
      return launchUrl(appUri);
    }

    final webUri = whatsAppWebUri(phone);
    if (await canLaunchUrl(webUri)) {
      return launchUrl(webUri, mode: LaunchMode.externalApplication);
    }

    return false;
  }
}
