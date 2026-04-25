import 'package:bip39/bip39.dart' as bip39;
import 'package:injectable/injectable.dart';

@singleton
class MnemonicService {
  /// Generates a new 12-word BIP-39 mnemonic phrase.
  String generateMnemonic() => bip39.generateMnemonic(strength: 128);

  /// Returns `true` if [mnemonic] is a valid BIP-39 word sequence.
  bool validateMnemonic(String mnemonic) =>
      bip39.validateMnemonic(mnemonic.trim().toLowerCase());

  /// Converts [mnemonic] to the corresponding seed as a lowercase hex string.
  ///
  /// An optional [passphrase] may be supplied for BIP-39 passphrase support.
  String mnemonicToSeedHex(String mnemonic, [String passphrase = '']) =>
      bip39.mnemonicToSeedHex(mnemonic, passphrase: passphrase);

  /// Splits a space-delimited [mnemonic] into individual words.
  List<String> splitMnemonic(String mnemonic) =>
      mnemonic.trim().split(RegExp(r'\s+'));
}
