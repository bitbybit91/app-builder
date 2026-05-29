import '../../../trading/data/datasources/trading_data_source.dart';
import '../../../trading/domain/entities/offer.dart';
import '../../domain/repositories/search_repository.dart';

abstract class SearchDataSource {
  Future<List<Offer>> search(SearchQuery q);
}

class InMemorySearchDataSource implements SearchDataSource {
  InMemorySearchDataSource({required TradingDataSource trading})
      : _trading = trading;
  final TradingDataSource _trading;

  @override
  Future<List<Offer>> search(SearchQuery q) async {
    List<Offer> offers = await _trading.listOffers(
      coin: q.coin,
      fiatCurrency: q.fiatCurrency,
      paymentMethod: q.paymentMethod,
      country: q.country,
      type: q.type,
      page: q.page,
      pageSize: q.pageSize,
      sortBy: q.sortBy,
    );
    if (q.query != null && q.query!.trim().isNotEmpty) {
      final String needle = q.query!.trim().toLowerCase();
      offers = offers
          .where((Offer o) =>
              o.ownerUsername.toLowerCase().contains(needle) ||
              o.paymentMethod.toLowerCase().contains(needle) ||
              (o.country?.toLowerCase().contains(needle) ?? false) ||
              (o.city?.toLowerCase().contains(needle) ?? false))
          .toList();
    }
    return offers;
  }
}
