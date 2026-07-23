import 'package:flutter_test/flutter_test.dart';
import 'package:aarogya_vault_app/core/utils/security_helper.dart';

void main() {
  group('SecurityHelper Encryption/Decryption Tests', () {
    test('Encrypt and decrypt a standard string successfully', () {
      const originalText = "Patient: Majid Shaikh, Blood: O+, Chronic: None";
      
      final encryptedText = SecurityHelper.encrypt(originalText);
      expect(encryptedText, isNotEmpty);
      expect(encryptedText, isNot(equals(originalText)));

      final decryptedText = SecurityHelper.decrypt(encryptedText);
      expect(decryptedText, equals(originalText));
    });

    test('Decrypted value of invalid signature returns empty string', () {
      final decryptedText = SecurityHelper.decrypt("invalid_encrypted_data_12345");
      expect(decryptedText, isEmpty);
    });
  });
}
