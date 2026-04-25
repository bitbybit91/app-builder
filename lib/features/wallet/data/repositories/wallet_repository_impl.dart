import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:capital_monero/core/errors/failures.dart';
import 'package:capital_monero/core/logging/app_logger.dart';
import 'package:capital_monero/core/storage/secure_storage_service.dart';
import 'package:capital_monero/features/wallet/domain/entities/wallet_entity.dart';
import 'package:capital_monero/features/wallet/domain/repositories/wallet_repository.dart';

@Injectable(as: WalletRepository)
class WalletRepositoryImpl implements WalletRepository {
  static const _tag = 'WalletRepositoryImpl';
  static const _xmrAddressKey = 'xmr_address';
  static const _btcAddressKey = 'btc_address';

  // Placeholder addresses used when no real wallet is connected.
  static const _xmrPlaceholder =
      '44AFFq5kSiGBoZ4NMDwYtN18obc8AemS33DBLWs3H7otXft3XjrpDtQGv7SqSsaBYBb98uNbr2VBBEt7f2wfn3RVGQBEP3A';
  static const _btcPlaceholder =
      'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh';

  final SecureStorageService _secureStorage;

  const WalletRepositoryImpl(this._secureStorage);

  @override
  Future<Either<Failure, String>> getWalletAddress(
    CryptoCurrency currency,
  ) async {
    try {
      final key = _storageKey(currency);
      final stored = await _secureStorage.read(key);

      if (stored != null && stored.isNotEmpty) {
        return Right(stored);
      }

      final placeholder = _placeholder(currency);
      await _secureStorage.write(key, placeholder);
      AppLogger.d(_tag, 'Generated placeholder address for $currency');
      return Right(placeholder);
    } catch (e, st) {
      AppLogger.e(_tag, 'getWalletAddress failed', e, st);
      return Left(WalletFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Either<Failure, BalanceEntity>> getBalance(
    CryptoCurrency currency,
  ) async {
    // Stub: returns zeroed balance until real wallet integration is added.
    AppLogger.d(_tag, 'Returning stub balance for $currency');
    return const Right(
      BalanceEntity(available: '0.0000', locked: '0.0000'),
    );
  }

  @override
  Future<Either<Failure, String>> sendTransaction(
    CryptoCurrency currency,
    String toAddress,
    String amount, [
    String? fee,
  ]) async {
    // Stub: real implementation requires wallet SDK integration.
    AppLogger.w(_tag, 'sendTransaction stub called — not yet implemented');
    return const Left(
      WalletFailure(message: 'Send transaction not yet implemented'),
    );
  }

  String _storageKey(CryptoCurrency currency) => switch (currency) {
        CryptoCurrency.xmr => _xmrAddressKey,
        CryptoCurrency.btc => _btcAddressKey,
      };

  String _placeholder(CryptoCurrency currency) => switch (currency) {
        CryptoCurrency.xmr => _xmrPlaceholder,
        CryptoCurrency.btc => _btcPlaceholder,
      };
}
