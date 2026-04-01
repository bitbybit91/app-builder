import '../../../trading/domain/entities/offer.dart';
import '../entities/search_filter.dart';

abstract class SearchRepository {
  Future<List<Offer>> searchOffers(SearchFilter filter);
}
