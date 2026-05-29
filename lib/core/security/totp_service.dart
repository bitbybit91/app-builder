import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// RFC 6238 TOTP implementation, kept dependency-free so the app does not
/// rely on `package:otp` (which historically had transitive issues on iOS).
class TotpService {
  TotpService({this.digits = 6, this.period = 30, this.algorithm = 'SHA1'});

  final int digits;
  final int period;
  final String algorithm;

  /// Generate a new random Base32 secret (default 20 bytes / 160 bits).
  String generateSecret({int length = 20}) {
    final Random rng = Random.secure();
    final List<int> bytes = List<int>.generate(length, (_) => rng.nextInt(256));
    return _base32Encode(bytes);
  }

  /// Generates the current TOTP code for [secret].
  String currentCode(String secret, {DateTime? now}) {
    final int counter = ((now ?? DateTime.now().toUtc()).millisecondsSinceEpoch ~/ 1000) ~/ period;
    return _hotp(secret, counter);
  }

  /// Verifies [code] against [secret], allowing a +/- [window] step drift.
  bool verify(String code, String secret, {int window = 1, DateTime? now}) {
    final int currentCounter =
        ((now ?? DateTime.now().toUtc()).millisecondsSinceEpoch ~/ 1000) ~/ period;
    for (int offset = -window; offset <= window; offset++) {
      if (_hotp(secret, currentCounter + offset) == code) return true;
    }
    return false;
  }

  /// Builds an `otpauth://` URI suitable for Google Authenticator import.
  Uri buildUri({
    required String secret,
    required String account,
    required String issuer,
  }) {
    return Uri(
      scheme: 'otpauth',
      host: 'totp',
      path: '/${Uri.encodeComponent(issuer)}:${Uri.encodeComponent(account)}',
      queryParameters: <String, String>{
        'secret': secret,
        'issuer': issuer,
        'algorithm': algorithm,
        'digits': digits.toString(),
        'period': period.toString(),
      },
    );
  }

  String _hotp(String secret, int counter) {
    final Uint8List key = Uint8List.fromList(_base32Decode(secret));
    final ByteData counterBytes = ByteData(8)..setUint64(0, counter);
    final Hmac hmac = Hmac(sha1, key);
    final List<int> digest = hmac.convert(counterBytes.buffer.asUint8List()).bytes;
    final int offset = digest[digest.length - 1] & 0x0f;
    final int binary = ((digest[offset] & 0x7f) << 24) |
        ((digest[offset + 1] & 0xff) << 16) |
        ((digest[offset + 2] & 0xff) << 8) |
        (digest[offset + 3] & 0xff);
    final int otp = binary % pow(10, digits).toInt();
    return otp.toString().padLeft(digits, '0');
  }

  static const String _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  String _base32Encode(List<int> bytes) {
    final StringBuffer out = StringBuffer();
    int buffer = 0;
    int bitsLeft = 0;
    for (final int b in bytes) {
      buffer = (buffer << 8) | (b & 0xff);
      bitsLeft += 8;
      while (bitsLeft >= 5) {
        bitsLeft -= 5;
        out.writeCharCode(_alphabet.codeUnitAt((buffer >> bitsLeft) & 0x1f));
      }
    }
    if (bitsLeft > 0) {
      out.writeCharCode(_alphabet.codeUnitAt((buffer << (5 - bitsLeft)) & 0x1f));
    }
    return out.toString();
  }

  List<int> _base32Decode(String input) {
    final String normalized = input.toUpperCase().replaceAll('=', '').replaceAll(' ', '');
    final List<int> bytes = <int>[];
    int buffer = 0;
    int bitsLeft = 0;
    for (final int rune in normalized.runes) {
      final int v = _alphabet.indexOf(String.fromCharCode(rune));
      if (v < 0) {
        throw FormatException('Invalid base32 character', String.fromCharCode(rune));
      }
      buffer = (buffer << 5) | v;
      bitsLeft += 5;
      if (bitsLeft >= 8) {
        bitsLeft -= 8;
        bytes.add((buffer >> bitsLeft) & 0xff);
      }
    }
    return bytes;
  }

  /// Returns a stable backup-code list. Useful for the 2FA setup flow.
  List<String> generateBackupCodes({int count = 8, int length = 10}) {
    final Random rng = Random.secure();
    final List<String> codes = <String>[];
    for (int i = 0; i < count; i++) {
      final List<int> raw = List<int>.generate(length, (_) => rng.nextInt(256));
      codes.add(base64UrlEncode(raw).substring(0, length).toUpperCase());
    }
    return codes;
  }
}
