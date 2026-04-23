import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:capital_monero/core/logging/app_logger.dart';
import 'package:capital_monero/features/trading/domain/entities/create_offer_params.dart';
import 'package:capital_monero/features/trading/domain/entities/offer_entity.dart';
import 'package:capital_monero/features/trading/domain/usecases/create_offer_usecase.dart';
import 'package:capital_monero/features/trading/domain/usecases/get_offers_params.dart';
import 'package:capital_monero/features/trading/domain/usecases/get_offers_usecase.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

sealed class TradingEvent extends Equatable {
  const TradingEvent();

  @override
  List<Object?> get props => [];
}

final class LoadOffers extends TradingEvent {
  final GetOffersParams? filters;

  const LoadOffers({this.filters});

  @override
  List<Object?> get props => [filters];
}

final class RefreshOffers extends TradingEvent {
  const RefreshOffers();
}

final class CreateOffer extends TradingEvent {
  final CreateOfferParams params;

  const CreateOffer(this.params);

  @override
  List<Object?> get props => [params];
}

final class FilterOffers extends TradingEvent {
  final OfferType? type;
  final String? currency;

  const FilterOffers({this.type, this.currency});

  @override
  List<Object?> get props => [type, currency];
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

sealed class TradingState extends Equatable {
  const TradingState();

  @override
  List<Object?> get props => [];
}

final class TradingInitial extends TradingState {
  const TradingInitial();
}

final class TradingLoading extends TradingState {
  const TradingLoading();
}

final class TradingLoaded extends TradingState {
  final List<OfferEntity> offers;
  final GetOffersParams? filters;

  const TradingLoaded({required this.offers, this.filters});

  @override
  List<Object?> get props => [offers, filters];
}

final class TradingError extends TradingState {
  final String message;

  const TradingError(this.message);

  @override
  List<Object?> get props => [message];
}

final class OfferCreated extends TradingState {
  final OfferEntity offer;

  const OfferCreated(this.offer);

  @override
  List<Object?> get props => [offer];
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

@injectable
class TradingBloc extends Bloc<TradingEvent, TradingState> {
  static const _tag = 'TradingBloc';

  final GetOffersUseCase _getOffers;
  final CreateOfferUseCase _createOffer;

  GetOffersParams? _currentFilters;

  TradingBloc(this._getOffers, this._createOffer) : super(const TradingInitial()) {
    on<LoadOffers>(_onLoad);
    on<RefreshOffers>(_onRefresh);
    on<CreateOffer>(_onCreate);
    on<FilterOffers>(_onFilter);
  }

  Future<void> _onLoad(LoadOffers event, Emitter<TradingState> emit) async {
    _currentFilters = event.filters;
    AppLogger.d(_tag, 'Loading offers');
    emit(const TradingLoading());
    await _fetchOffers(emit);
  }

  Future<void> _onRefresh(
    RefreshOffers event,
    Emitter<TradingState> emit,
  ) async {
    AppLogger.d(_tag, 'Refreshing offers');
    await _fetchOffers(emit);
  }

  Future<void> _onCreate(CreateOffer event, Emitter<TradingState> emit) async {
    AppLogger.d(_tag, 'Creating offer');
    emit(const TradingLoading());

    final result = await _createOffer(event.params);
    result.fold(
      (failure) {
        AppLogger.e(_tag, 'Create offer failed', failure.message);
        emit(TradingError(failure.message));
      },
      (offer) => emit(OfferCreated(offer)),
    );
  }

  void _onFilter(FilterOffers event, Emitter<TradingState> emit) {
    _currentFilters = GetOffersParams(
      type: event.type,
      currency: event.currency,
    );
    add(const RefreshOffers());
  }

  Future<void> _fetchOffers(Emitter<TradingState> emit) async {
    final result = await _getOffers(_currentFilters ?? const GetOffersParams());
    result.fold(
      (failure) {
        AppLogger.e(_tag, 'Load offers failed', failure.message);
        emit(TradingError(failure.message));
      },
      (offers) => emit(TradingLoaded(offers: offers, filters: _currentFilters)),
    );
  }
}
