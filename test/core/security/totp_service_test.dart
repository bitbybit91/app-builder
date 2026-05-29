import 'package:capitalmonero/core/security/totp_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TotpService', () {
    final TotpService service = TotpService();

    test('generates a Base32 secret of expected length', () {
      final String secret = service.generateSecret();
      expect(secret.length, greaterThanOrEqualTo(32));
      expect(RegExp(r'^[A-Z2-7]+$').hasMatch(secret), isTrue);
    });

    test('current code matches RFC 6238 reference vector', () {
      // RFC 6238 Appendix B vector for time 59 sec with SHA1 secret.
      const String secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';
      final String code = service.currentCode(
        secret,
        now: DateTime.fromMillisecondsSinceEpoch(59 * 1000, isUtc: true),
      );
      expect(code, '287082');
    });

    test('verify accepts current code', () {
      final String secret = service.generateSecret();
      final DateTime now = DateTime.now().toUtc();
      final String code = service.currentCode(secret, now: now);
      expect(service.verify(code, secret, now: now), isTrue);
    });

    test('verify rejects unrelated code', () {
      final String secret = service.generateSecret();
      expect(service.verify('000000', secret), isFalse);
    });

    test('buildUri encodes account and issuer', () {
      final Uri uri = service.buildUri(
        secret: 'JBSWY3DPEHPK3PXP',
        account: 'alice@example.com',
        issuer: 'CapitalMonero',
      );
      expect(uri.scheme, 'otpauth');
      expect(uri.host, 'totp');
      expect(uri.queryParameters['secret'], 'JBSWY3DPEHPK3PXP');
      expect(uri.queryParameters['issuer'], 'CapitalMonero');
    });

    test('backup codes are unique and uppercase', () {
      final List<String> codes = service.generateBackupCodes();
      expect(codes.toSet().length, codes.length);
      for (final String c in codes) {
        expect(c, equals(c.toUpperCase()));
      }
    });
  });
}
