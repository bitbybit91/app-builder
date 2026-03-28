import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService._internal() {
    _auth = LocalAuthentication();
  }
  static final BiometricService instance = BiometricService._internal();

  late LocalAuthentication _auth;

  Future<bool> isAvailable() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return isSupported && canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({
    String reason = 'Authenticate to access CapitalMonero',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: false),
      );
    } catch (_) {
      return false;
    }
  }
}
