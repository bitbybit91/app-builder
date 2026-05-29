import 'package:capitalmonero/core/errors/exceptions.dart';
import 'package:capitalmonero/core/security/mnemonic_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MnemonicService', () {
    const MnemonicService service = MnemonicService();

    test('generates valid 12-word mnemonics', () {
      for (int i = 0; i < 10; i++) {
        final String phrase = service.generate();
        expect(phrase.split(' '), hasLength(12));
        expect(service.validate(phrase), isTrue);
      }
    });

    test('rejects invalid mnemonics', () {
      expect(service.validate('not a real mnemonic'), isFalse);
    });

    test('fingerprint is deterministic across whitespace and case', () {
      const String a = 'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon about';
      final String b = '  ABANDON abandon\tabandon ABANDON abandon abandon '
          'abandon abandon abandon abandon abandon about ';
      expect(service.fingerprint(a), service.fingerprint(b));
    });

    test('seed throws CryptoException for invalid mnemonic', () {
      expect(
        () => service.seed('totally bogus'),
        throwsA(isA<CryptoException>()),
      );
    });
  });
}
