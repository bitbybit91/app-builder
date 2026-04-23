import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:capital_monero/core/errors/failures.dart';
import 'package:capital_monero/features/profile/domain/entities/profile_entity.dart';
import 'package:capital_monero/features/profile/domain/repositories/profile_repository.dart';

@injectable
class GetProfileUseCase {
  final ProfileRepository _repository;
  const GetProfileUseCase(this._repository);
  Future<Either<Failure, ProfileEntity>> call(String userId) => _repository.getProfile(userId);
}
