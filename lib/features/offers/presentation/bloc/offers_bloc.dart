import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/offer.dart';
import '../../domain/usecases/get_offers_usecase.dart';
import '../../domain/usecases/create_offer_usecase.dart';

part 'offers_event.dart';
part 'offers_state.dart';

class OffersBloc extends Bloc<OffersEvent, OffersState> {
  final GetOffersUseCase getOffersUseCase;
  final CreateOfferUseCase createOfferUseCase;

  OffersBloc({
    required this.getOffersUseCase,
    required this.createOfferUseCase,
  }) : super(const OffersInitial()) {
    on<OffersLoadRequested>(_onLoadRequested);
    on<OffersRefreshRequested>(_onRefreshRequested);
    on<OffersLoadMoreRequested>(_onLoadMoreRequested);
    on<OfferCreateRequested>(_onCreateRequested);
    on<OffersFilterChanged>(_onFilterChanged);
  }

  int _currentPage = 1;
  String? _currentTradeType;
  String? _currentCrypto;

  Future<void> _onLoadRequested(
    OffersLoadRequested event,
    Emitter<OffersState> emit,
  ) async {
    emit(const OffersLoading());
    _currentPage = 1;
    _currentTradeType = event.tradeType;
    _currentCrypto = event.cryptoCurrency;
    final result = await getOffersUseCase(GetOffersParams(
      tradeType: event.tradeType,
      cryptoCurrency: event.cryptoCurrency,
      fiatCurrency: event.fiatCurrency,
      paymentMethod: event.paymentMethod,
      countryCode: event.countryCode,
      page: 1,
    ));
    result.fold(
      (failure) => emit(OffersError(message: failure.message)),
      (offers) => emit(OffersLoaded(
        offers: offers,
        hasReachedMax: offers.length < 20,
      )),
    );
  }

  Future<void> _onRefreshRequested(
    OffersRefreshRequested event,
    Emitter<OffersState> emit,
  ) async {
    _currentPage = 1;
    final result = await getOffersUseCase(GetOffersParams(
      tradeType: _currentTradeType,
      cryptoCurrency: _currentCrypto,
      page: 1,
    ));
    result.fold(
      (failure) => emit(OffersError(message: failure.message)),
      (offers) => emit(OffersLoaded(
        offers: offers,
        hasReachedMax: offers.length < 20,
      )),
    );
  }

  Future<void> _onLoadMoreRequested(
    OffersLoadMoreRequested event,
    Emitter<OffersState> emit,
  ) async {
    if (state is OffersLoaded) {
      final currentState = state as OffersLoaded;
      if (currentState.hasReachedMax) return;
      _currentPage++;
      final result = await getOffersUseCase(GetOffersParams(
        tradeType: _currentTradeType,
        cryptoCurrency: _currentCrypto,
        page: _currentPage,
      ));
      result.fold(
        (failure) => emit(OffersError(message: failure.message)),
        (offers) => emit(OffersLoaded(
          offers: [...currentState.offers, ...offers],
          hasReachedMax: offers.length < 20,
        )),
      );
    }
  }

  Future<void> _onCreateRequested(
    OfferCreateRequested event,
    Emitter<OffersState> emit,
  ) async {
    emit(const OfferCreating());
    final result = await createOfferUseCase(CreateOfferParams(
      tradeType: event.tradeType,
      offerType: event.offerType,
      cryptoCurrency: event.cryptoCurrency,
      fiatCurrency: event.fiatCurrency,
      paymentMethod: event.paymentMethod,
      fixedPrice: event.fixedPrice,
      marketPriceMargin: event.marketPriceMargin,
      minAmount: event.minAmount,
      maxAmount: event.maxAmount,
      terms: event.terms,
      countryCode: event.countryCode,
    ));
    result.fold(
      (failure) => emit(OffersError(message: failure.message)),
      (offer) => emit(OfferCreated(offer: offer)),
    );
  }

  Future<void> _onFilterChanged(
    OffersFilterChanged event,
    Emitter<OffersState> emit,
  ) async {
    add(OffersLoadRequested(
      tradeType: event.tradeType,
      cryptoCurrency: event.cryptoCurrency,
      fiatCurrency: event.fiatCurrency,
      paymentMethod: event.paymentMethod,
      countryCode: event.countryCode,
    ));
  }
}
