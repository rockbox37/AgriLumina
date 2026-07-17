import 'package:agrilumina/services/contact_launcher.dart';

/// Records launch attempts without opening platform apps.
class FakeContactLauncher implements ContactLauncher {
  String? lastCallPhone;
  String? lastWhatsAppPhone;
  bool callSucceeds = true;
  bool whatsAppSucceeds = true;

  @override
  Future<bool> call(String phone) async {
    lastCallPhone = phone;
    return callSucceeds;
  }

  @override
  Future<bool> openWhatsApp(String phone) async {
    lastWhatsAppPhone = phone;
    return whatsAppSucceeds;
  }
}
