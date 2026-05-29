import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../trading/domain/entities/offer.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_data_source.dart';

class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl({required SearchDataSource source}) : _source = source;
  final SearchDataSource _source;

  @override
  Future<Either<Failure, List<Offer>>> search(SearchQuery q) async {
    try {
      return Right<Failure, List<Offer>>(await _source.search(q));
    } catch (e) {
      return Left<Failure, List<Offer>>(UnexpectedFailure(e.toString()));
    }
  }
}
