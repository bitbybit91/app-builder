import 'package:capitalmonero/core/utils/input_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InputValidators.username', () {
    test('rejects short and invalid characters', () {
      expect(InputValidators.username(''), isNotNull);
      expect(InputValidators.username('ab'), isNotNull);
      expect(InputValidators.username('hello world'), isNotNull);
    });
    test('accepts valid usernames', () {
      expect(InputValidators.username('alice_99'), isNull);
    });
  });

  group('InputValidators.password', () {
    test('enforces complexity', () {
      expect(InputValidators.password('short'), isNotNull);
      expect(InputValidators.password('alllowercase!11'), isNotNull);
      expect(InputValidators.password('Valid_Passw0rd!'), isNull);
    });
  });

  group('InputValidators.cryptoAddress', () {
    test('rejects invalid Bitcoin and Monero addresses', () {
      expect(InputValidators.cryptoAddress('xyz', 'BTC'), isNotNull);
      expect(InputValidators.cryptoAddress('xyz', 'XMR'), isNotNull);
    });
    test('accepts well-formed Bitcoin bech32', () {
      expect(
        InputValidators.cryptoAddress(
          'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq',
          'BTC',
        ),
        isNull,
      );
    });
  });

  group('InputValidators.amount', () {
    test('rejects non-numeric and non-positive', () {
      expect(InputValidators.amount('abc'), isNotNull);
      expect(InputValidators.amount('0'), isNotNull);
    });
    test('accepts a positive amount', () {
      expect(InputValidators.amount('42.5'), isNull);
    });
  });

  group('InputValidators.totp', () {
    test('requires six digits', () {
      expect(InputValidators.totp('123'), isNotNull);
      expect(InputValidators.totp('1234567'), isNotNull);
      expect(InputValidators.totp('123456'), isNull);
    });
  });
}
