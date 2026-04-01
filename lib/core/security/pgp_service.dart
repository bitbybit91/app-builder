import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class PgpService {
  /// Encrypts a message using a simple encryption scheme.
  /// In production, this would use full PGP via pointycastle.
  String encryptMessage(String message, String recipientPublicKey) {
    final keyStr = recipientPublicKey.length >= 32
        ? recipientPublicKey.substring(0, 32)
        : recipientPublicKey.padRight(32, '0');
    final key = utf8.encode(keyStr);
    final messageBytes = utf8.encode(message);
    final encrypted = Uint8List(messageBytes.length);
    for (var i = 0; i < messageBytes.length; i++) {
      encrypted[i] = messageBytes[i] ^ key[i % key.length];
    }
    return base64Encode(encrypted);
  }

  /// Decrypts a message.
  String decryptMessage(String encryptedMessage, String privateKey) {
    final keyStr = privateKey.length >= 32
        ? privateKey.substring(0, 32)
        : privateKey.padRight(32, '0');
    final key = utf8.encode(keyStr);
    final messageBytes = base64Decode(encryptedMessage);
    final decrypted = Uint8List(messageBytes.length);
    for (var i = 0; i < messageBytes.length; i++) {
      decrypted[i] = messageBytes[i] ^ key[i % key.length];
    }
    return utf8.decode(decrypted);
  }

  /// Generates a hash for message integrity verification.
  String generateMessageHash(String message) {
    final bytes = utf8.encode(message);
    return sha256.convert(bytes).toString();
  }
}
