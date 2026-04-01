import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../trading/domain/entities/offer.dart';
import '../../domain/entities/search_filter.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_datasource.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource _remoteDataSource;
  SearchRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Offer>> searchOffers(SearchFilter filter) async {
    try {
      return await _remoteDataSource.searchOffers(filter);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }
}
