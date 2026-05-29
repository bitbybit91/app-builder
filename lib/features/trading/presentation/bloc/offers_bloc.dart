import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/offer.dart';
import '../../domain/repositories/offer_repository.dart';

abstract class OffersEvent extends Equatable {
  const OffersEvent();
  @override
  List<Object?> get props => const <Object?>[];
}

class OffersLoadRequested extends OffersEvent {
  const OffersLoadRequested({this.query = const OfferQuery()});
  final OfferQuery query;
  @override
  List<Object?> get props => <Object?>[query.coin, query.type, query.fiatCurrency, query.page];
}

class OffersRefreshRequested extends OffersEvent {
  const OffersRefreshRequested();
}

class OfferCreated extends OffersEvent {
  const OfferCreated(this.offer);
  final Offer offer;
  @override
  List<Object?> get props => <Object?>[offer];
}

abstract class OffersState extends Equatable {
  const OffersState();
  @override
  List<Object?> get props => const <Object?>[];
}

class OffersInitial extends OffersState {
  const OffersInitial();
}

class OffersLoading extends OffersState {
  const OffersLoading();
}

class OffersLoaded extends OffersState {
  const OffersLoaded(this.offers, {this.query = const OfferQuery()});
  final List<Offer> offers;
  final OfferQuery query;
  @override
  List<Object?> get props => <Object?>[offers, query.page];
}

class OffersError extends OffersState {
  const OffersError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => <Object?>[failure];
}

class OffersBloc extends Bloc<OffersEvent, OffersState> {
  OffersBloc({required OfferRepository repository})
      : _repository = repository,
        super(const OffersInitial()) {
    on<OffersLoadRequested>(_onLoad);
    on<OffersRefreshRequested>(_onRefresh);
    on<OfferCreated>(_onCreated);
  }

  final OfferRepository _repository;
  OfferQuery _lastQuery = const OfferQuery();

  Future<void> _onLoad(OffersLoadRequested event, Emitter<OffersState> emit) async {
    emit(const OffersLoading());
    _lastQuery = event.query;
    final result = await _repository.listOffers(event.query);
    result.fold(
      (failure) => emit(OffersError(failure)),
      (List<Offer> offers) => emit(OffersLoaded(offers, query: event.query)),
    );
  }

  Future<void> _onRefresh(
      OffersRefreshRequested event, Emitter<OffersState> emit) async {
    final result = await _repository.listOffers(_lastQuery);
    result.fold(
      (failure) => emit(OffersError(failure)),
      (List<Offer> offers) => emit(OffersLoaded(offers, query: _lastQuery)),
    );
  }

  Future<void> _onCreated(OfferCreated event, Emitter<OffersState> emit) async {
    final result = await _repository.createOffer(event.offer);
    if (result.isLeft()) {
      emit(OffersError(result.fold((f) => f, (_) => const UnexpectedFailure())));
      return;
    }
    final reloaded = await _repository.listOffers(_lastQuery);
    reloaded.fold(
      (failure) => emit(OffersError(failure)),
      (List<Offer> offers) => emit(OffersLoaded(offers, query: _lastQuery)),
    );
  }
}
