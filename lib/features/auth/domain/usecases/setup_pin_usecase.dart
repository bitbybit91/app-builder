import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:capital_monero/core/crypto/key_derivation.dart';
import 'package:capital_monero/core/errors/failures.dart';
import 'package:capital_monero/core/storage/secure_storage_service.dart';

@injectable
class SetupPinUseCase {
  final SecureStorageService _secureStorage;
  final KeyDerivationService _keyDerivation;

  const SetupPinUseCase(this._secureStorage, this._keyDerivation);

  Future<Either<Failure, void>> call(String pin) async {
    try {
      if (pin.length < 4) {
        return const Left(ValidationFailure(message: 'PIN must be at least 4 digits'));
      }

      final hash = _keyDerivation.hashPin(pin);
      await _secureStorage.write(SecureStorageService.kPinHashKey, hash);
      return const Right(null);
    } catch (e, st) {
      return Left(AuthFailure(message: e.toString(), stackTrace: st));
    }
  }
}
