import '../../../trading/domain/entities/offer.dart';
import '../entities/search_filter.dart';
import '../repositories/search_repository.dart';

class SearchOffersUseCase {
  final SearchRepository _repository;
  SearchOffersUseCase(this._repository);

  Future<List<Offer>> call(SearchFilter filter) {
    return _repository.searchOffers(filter);
  }
}
