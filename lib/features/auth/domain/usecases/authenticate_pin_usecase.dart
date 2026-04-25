import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:capital_monero/core/crypto/key_derivation.dart';
import 'package:capital_monero/core/errors/failures.dart';
import 'package:capital_monero/core/storage/secure_storage_service.dart';

@injectable
class AuthenticatePinUseCase {
  final SecureStorageService _secureStorage;
  final KeyDerivationService _keyDerivation;

  const AuthenticatePinUseCase(this._secureStorage, this._keyDerivation);

  Future<Either<Failure, bool>> call(String pin) async {
    try {
      final storedHash =
          await _secureStorage.read(SecureStorageService.kPinHashKey);

      if (storedHash == null) {
        return const Left(AuthFailure(message: 'No PIN configured'));
      }

      final isValid = _keyDerivation.verifyPin(pin, storedHash);
      return Right(isValid);
    } catch (e, st) {
      return Left(AuthFailure(message: e.toString(), stackTrace: st));
    }
  }
}
