/// Digits only (country code, no `+` or spaces) for WhatsApp / wa.me.
String digitsOnlyPhone(String phone) => phone.replaceAll(RegExp(r'\D'), '');

/// Dialable form: keeps a leading `+` when present, strips other non-digits.
String normalizePhoneForDial(String phone) {
  final trimmed = phone.trim();
  final hasPlus = trimmed.startsWith('+');
  final digits = digitsOnlyPhone(trimmed);
  if (digits.isEmpty) return '';
  return hasPlus ? '+$digits' : digits;
}

/// `tel:` URI for the phone dialer.
Uri telUri(String phone) {
  final normalized = normalizePhoneForDial(phone);
  return Uri(scheme: 'tel', path: normalized);
}

/// Prefer the WhatsApp app scheme; [whatsAppWebUri] is the fallback.
Uri whatsAppAppUri(String phone) {
  final digits = digitsOnlyPhone(phone);
  return Uri.parse('whatsapp://send?phone=$digits');
}

/// Universal WhatsApp link (works when the app scheme is unavailable).
Uri whatsAppWebUri(String phone) {
  final digits = digitsOnlyPhone(phone);
  return Uri.parse('https://wa.me/$digits');
}
