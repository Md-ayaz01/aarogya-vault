import 'package:encrypt/encrypt.dart' as enc;

class SecurityHelper {
  // Deriving a 32-byte key and 16-byte IV for AES-CBC
  static final _key = enc.Key.fromUtf8('aarogya_vault_super_secure_secur'); // 32 chars
  static final _iv = enc.IV.fromUtf8('aarogya_vault_iv'); // 16 chars

  static String encrypt(String plainText) {
    try {
      final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      return '';
    }
  }

  static String decrypt(String encryptedText) {
    try {
      final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
      final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
      return decrypted;
    } catch (e) {
      return '';
    }
  }
}
