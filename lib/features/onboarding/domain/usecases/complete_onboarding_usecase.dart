import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:capital_monero/core/errors/failures.dart';
import 'package:capital_monero/core/storage/preferences_service.dart';

@injectable
class CompleteOnboardingUseCase {
  final PreferencesService _preferencesService;

  const CompleteOnboardingUseCase(this._preferencesService);

  Future<Either<Failure, void>> call() async {
    try {
      await _preferencesService.setBool(
        PreferencesService.kOnboardingCompleteKey,
        value: true,
      );
      return const Right(null);
    } catch (e, st) {
      return Left(CacheFailure(message: e.toString(), stackTrace: st));
    }
  }
}
