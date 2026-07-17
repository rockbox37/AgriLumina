import 'package:flutter_test/flutter_test.dart';
import 'package:agrilumina/utils/phone.dart';

void main() {
  test('digitsOnlyPhone strips spaces and plus', () {
    expect(digitsOnlyPhone('+243 970 111 201'), '243970111201');
  });

  test('normalizePhoneForDial keeps leading plus', () {
    expect(normalizePhoneForDial('+243 970 111 201'), '+243970111201');
    expect(normalizePhoneForDial('0970 111 201'), '0970111201');
  });

  test('tel and WhatsApp URIs use normalized phone', () {
    const phone = '+243 970 111 201';
    expect(telUri(phone).toString(), 'tel:+243970111201');
    expect(whatsAppAppUri(phone).toString(), 'whatsapp://send?phone=243970111201');
    expect(whatsAppWebUri(phone).toString(), 'https://wa.me/243970111201');
  });
}
