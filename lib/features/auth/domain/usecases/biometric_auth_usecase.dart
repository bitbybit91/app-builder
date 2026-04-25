import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

import 'package:capital_monero/core/errors/failures.dart';

@injectable
class BiometricAuthUseCase {
  final LocalAuthentication _localAuth;

  BiometricAuthUseCase() : _localAuth = LocalAuthentication();

  Future<Either<Failure, bool>> call() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!isAvailable || !isDeviceSupported) {
        return const Left(AuthFailure(message: 'Biometrics not available on this device'));
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access CapitalMonero',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      return Right(authenticated);
    } catch (e, st) {
      return Left(AuthFailure(message: e.toString(), stackTrace: st));
    }
  }
}
