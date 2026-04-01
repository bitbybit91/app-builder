import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class TotpService {
  static const int _digits = 6;
  static const int _period = 30;

  /// Generates a random secret key for TOTP.
  String generateSecret() {
    final random = Random.secure();
    final bytes = List<int>.generate(20, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// Generates a TOTP code for the current time period.
  String generateCode(String secret) {
    final time = DateTime.now().millisecondsSinceEpoch ~/ 1000 ~/ _period;
    return _generateTotpCode(secret, time);
  }

  /// Verifies a TOTP code, allowing for time drift of +/- 1 period.
  bool verifyCode(String secret, String code) {
    final time = DateTime.now().millisecondsSinceEpoch ~/ 1000 ~/ _period;
    for (var i = -1; i <= 1; i++) {
      if (_generateTotpCode(secret, time + i) == code) {
        return true;
      }
    }
    return false;
  }

  /// Gets the provisioning URI for QR code generation.
  String getProvisioningUri(String secret, String accountName) {
    final encodedAccount = Uri.encodeComponent(accountName);
    return 'otpauth://totp/CapitalMonero:$encodedAccount?secret=$secret&issuer=CapitalMonero&digits=$_digits&period=$_period';
  }

  String _generateTotpCode(String secret, int time) {
    final timeBytes = _intToBytes(time);
    final key = utf8.encode(secret);
    final hmacSha1 = Hmac(sha1, key);
    final hash = hmacSha1.convert(timeBytes).bytes;
    final offset = hash[hash.length - 1] & 0xf;
    final binary = ((hash[offset] & 0x7f) << 24) |
        ((hash[offset + 1] & 0xff) << 16) |
        ((hash[offset + 2] & 0xff) << 8) |
        (hash[offset + 3] & 0xff);
    final otp = binary % _pow(10, _digits);
    return otp.toString().padLeft(_digits, '0');
  }

  List<int> _intToBytes(int value) {
    final result = List<int>.filled(8, 0);
    for (var i = 7; i >= 0; i--) {
      result[i] = value & 0xff;
      value >>= 8;
    }
    return result;
  }

  int _pow(int base, int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}
