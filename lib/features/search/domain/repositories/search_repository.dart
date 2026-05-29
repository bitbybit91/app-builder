import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../trading/domain/entities/offer.dart';

class SearchQuery {
  const SearchQuery({
    this.query,
    this.coin,
    this.fiatCurrency,
    this.paymentMethod,
    this.country,
    this.type,
    this.sortBy = 'price',
    this.page = 1,
    this.pageSize = 20,
  });
  final String? query;
  final String? coin;
  final String? fiatCurrency;
  final String? paymentMethod;
  final String? country;
  final OfferType? type;
  final String sortBy;
  final int page;
  final int pageSize;
}

abstract class SearchRepository {
  Future<Either<Failure, List<Offer>>> search(SearchQuery q);
}
