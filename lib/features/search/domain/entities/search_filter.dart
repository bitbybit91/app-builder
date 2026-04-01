import 'package:equatable/equatable.dart';

class SearchFilter extends Equatable {
  final String? coinType;
  final String? offerType;
  final String? paymentMethod;
  final String? currency;
  final String? country;
  final String? sortBy;
  final int page;

  const SearchFilter({
    this.coinType,
    this.offerType,
    this.paymentMethod,
    this.currency,
    this.country,
    this.sortBy,
    this.page = 1,
  });

  SearchFilter copyWith({String? coinType, String? offerType, String? paymentMethod, String? currency, String? country, String? sortBy, int? page}) {
    return SearchFilter(
      coinType: coinType ?? this.coinType,
      offerType: offerType ?? this.offerType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      currency: currency ?? this.currency,
      country: country ?? this.country,
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
    );
  }

  @override
  List<Object?> get props => [coinType, offerType, paymentMethod, currency, country, sortBy, page];
}
