import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:pointycastle/export.dart';

@singleton
class KeyDerivationService {
  static const int _iterations = 100000;
  static const int _keyLength = 32;
  static const int _saltBytes = 16;

  /// Derives a 32-byte key from [pin] and [salt] using PBKDF2-SHA-256.
  Uint8List deriveKeyFromPin(String pin, String salt) {
    final saltBytes = _hexToBytes(salt);
    final pinBytes = Uint8List.fromList(utf8.encode(pin));

    final params = Pbkdf2Parameters(saltBytes, _iterations, _keyLength);
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(params);

    return derivator.process(pinBytes);
  }

  /// Generates a cryptographically random 16-byte salt encoded as hex.
  String generateSalt() {
    final rng = Random.secure();
    final bytes = Uint8List(_saltBytes);
    for (var i = 0; i < _saltBytes; i++) {
      bytes[i] = rng.nextInt(256);
    }
    return _bytesToHex(bytes);
  }

  /// Derives a key from [pin] using a fresh salt and returns the
  /// base64-encoded key. The salt is embedded in the returned string
  /// as `<salt>:<base64Key>` so that [verifyPin] can reproduce it.
  String hashPin(String pin) {
    final salt = generateSalt();
    final key = deriveKeyFromPin(pin, salt);
    final encoded = base64Url.encode(key);
    return '$salt:$encoded';
  }

  /// Returns `true` when [pin] matches [storedHash] (produced by [hashPin]).
  ///
  /// [storedHash] must follow the `<salt>:<base64Key>` format written by
  /// [hashPin]. When [storedHash] contains an embedded salt that format takes
  /// precedence; [salt] is only used for legacy hashes that lack the prefix.
  bool verifyPin(String pin, String storedHash, [String? salt]) {
    final String effectiveSalt;
    final String expectedEncoded;

    if (storedHash.contains(':')) {
      final parts = storedHash.split(':');
      effectiveSalt = parts[0];
      expectedEncoded = parts[1];
    } else {
      // Legacy hash without embedded salt — caller must supply it.
      assert(salt != null, 'salt must be provided for legacy (no-prefix) hashes');
      effectiveSalt = salt ?? '';
      expectedEncoded = storedHash;
    }

    final derived = deriveKeyFromPin(pin, effectiveSalt);
    final derivedEncoded = base64Url.encode(derived);
    return derivedEncoded == expectedEncoded;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
