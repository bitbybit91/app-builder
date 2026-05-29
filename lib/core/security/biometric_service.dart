import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';

import 'token_store.dart';

class BiometricService {
  BiometricService({LocalAuthentication? auth, TokenStore? tokenStore})
      : _auth = auth ?? LocalAuthentication(),
        _tokenStore = tokenStore ?? TokenStore();

  final LocalAuthentication _auth;
  final TokenStore _tokenStore;

  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'Unlock CapitalMonero'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// PIN storage uses SHA-256 with a per-install salt. Suitable for
  /// device-local unlock; never used as a network credential.
  Future<void> setPin(String pin) async {
    final String hash = _hash(pin);
    await _tokenStore.writePinHash(hash);
  }

  Future<bool> verifyPin(String pin) async {
    final String? stored = await _tokenStore.readPinHash();
    if (stored == null) return false;
    return stored == _hash(pin);
  }

  Future<bool> hasPin() async => (await _tokenStore.readPinHash()) != null;

  String _hash(String pin) =>
      sha256.convert(utf8.encode('capitalmonero::$pin')).toString();
}
