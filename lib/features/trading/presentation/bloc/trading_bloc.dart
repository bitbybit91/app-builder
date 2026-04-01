import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/offer.dart';
import '../../domain/entities/trade.dart';
import '../../domain/usecases/get_offers_usecase.dart';

// Events
abstract class TradingEvent extends Equatable {
  const TradingEvent();
  @override
  List<Object?> get props => [];
}

class LoadOffers extends TradingEvent {
  final String? coinType;
  final OfferType? offerType;
  final String? currency;
  final int page;
  const LoadOffers({this.coinType, this.offerType, this.currency, this.page = 1});
  @override
  List<Object?> get props => [coinType, offerType, currency, page];
}

class LoadMoreOffers extends TradingEvent {}

// States
abstract class TradingState extends Equatable {
  const TradingState();
  @override
  List<Object?> get props => [];
}

class TradingInitial extends TradingState {}
class TradingLoading extends TradingState {}

class TradingLoaded extends TradingState {
  final List<Offer> offers;
  final bool hasMore;
  final int currentPage;
  const TradingLoaded({required this.offers, this.hasMore = true, this.currentPage = 1});
  @override
  List<Object?> get props => [offers, hasMore, currentPage];
}

class TradingError extends TradingState {
  final String message;
  const TradingError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class TradingBloc extends Bloc<TradingEvent, TradingState> {
  final GetOffersUseCase getOffersUseCase;

  TradingBloc({required this.getOffersUseCase}) : super(TradingInitial()) {
    on<LoadOffers>(_onLoadOffers);
    on<LoadMoreOffers>(_onLoadMoreOffers);
  }

  Future<void> _onLoadOffers(LoadOffers event, Emitter<TradingState> emit) async {
    emit(TradingLoading());
    try {
      final offers = await getOffersUseCase(
        coinType: event.coinType,
        offerType: event.offerType,
        currency: event.currency,
        page: event.page,
      );
      emit(TradingLoaded(offers: offers, currentPage: event.page));
    } catch (e) {
      emit(TradingError(e.toString()));
    }
  }

  Future<void> _onLoadMoreOffers(LoadMoreOffers event, Emitter<TradingState> emit) async {
    if (state is TradingLoaded) {
      final currentState = state as TradingLoaded;
      try {
        final nextPage = currentState.currentPage + 1;
        final newOffers = await getOffersUseCase(page: nextPage);
        emit(TradingLoaded(
          offers: [...currentState.offers, ...newOffers],
          hasMore: newOffers.isNotEmpty,
          currentPage: nextPage,
        ));
      } catch (e) {
        emit(TradingError(e.toString()));
      }
    }
  }
}
