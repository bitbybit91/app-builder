import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/trade.dart';
import '../repositories/trades_repository.dart';

class GetTradesUseCase extends UseCase<List<Trade>, GetTradesParams> {
  final TradesRepository repository;

  GetTradesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Trade>>> call(GetTradesParams params) {
    return repository.getTrades(
      status: params.status,
      page: params.page,
      limit: params.limit,
    );
  }
}

class GetTradesParams {
  final String? status;
  final int page;
  final int limit;

  const GetTradesParams({this.status, this.page = 1, this.limit = 20});
}
