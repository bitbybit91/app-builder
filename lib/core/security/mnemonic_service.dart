import 'dart:convert';
import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart';

import '../errors/exceptions.dart';

/// BIP39 mnemonic helpers used for account recovery.
///
/// The mnemonic is generated locally at sign-up, displayed to the user, and
/// then stored encrypted on the device. The hashed form (sha256 of the
/// normalised seed phrase) is what gets persisted server-side so the server
/// can verify recovery without ever knowing the words.
class MnemonicService {
  const MnemonicService();

  /// Generate a fresh 12-word English mnemonic (128 bits of entropy).
  String generate({int strength = 128}) => bip39.generateMnemonic(strength: strength);

  /// Validates a mnemonic against the English BIP39 wordlist.
  bool validate(String mnemonic) => bip39.validateMnemonic(_normalize(mnemonic));

  /// Returns the BIP39 seed bytes for the supplied mnemonic.
  Uint8List seed(String mnemonic, {String passphrase = ''}) {
    if (!validate(mnemonic)) {
      throw CryptoException('Invalid mnemonic');
    }
    return bip39.mnemonicToSeed(_normalize(mnemonic), passphrase: passphrase);
  }

  /// SHA-256 fingerprint of the normalised mnemonic for transport.
  String fingerprint(String mnemonic) {
    final String normalized = _normalize(mnemonic);
    final List<int> bytes = utf8.encode(normalized);
    return sha256.convert(bytes).toString();
  }

  String _normalize(String mnemonic) =>
      mnemonic.trim().toLowerCase().split(RegExp(r'\s+')).join(' ');
}
