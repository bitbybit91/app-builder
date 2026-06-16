import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/offer.dart';
import '../repositories/offers_repository.dart';

class GetOffersUseCase extends UseCase<List<Offer>, GetOffersParams> {
  final OffersRepository repository;

  GetOffersUseCase(this.repository);

  @override
  Future<Either<Failure, List<Offer>>> call(GetOffersParams params) {
    return repository.getOffers(
      tradeType: params.tradeType,
      cryptoCurrency: params.cryptoCurrency,
      fiatCurrency: params.fiatCurrency,
      paymentMethod: params.paymentMethod,
      countryCode: params.countryCode,
      page: params.page,
      limit: params.limit,
    );
  }
}

class GetOffersParams {
  final String? tradeType;
  final String? cryptoCurrency;
  final String? fiatCurrency;
  final String? paymentMethod;
  final String? countryCode;
  final int page;
  final int limit;

  const GetOffersParams({
    this.tradeType,
    this.cryptoCurrency,
    this.fiatCurrency,
    this.paymentMethod,
    this.countryCode,
    this.page = 1,
    this.limit = 20,
  });
}
