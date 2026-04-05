part of 'offers_bloc.dart';

abstract class OffersState extends Equatable {
  const OffersState();
  @override
  List<Object?> get props => [];
}

class OffersInitial extends OffersState {
  const OffersInitial();
}

class OffersLoading extends OffersState {
  const OffersLoading();
}

class OffersLoaded extends OffersState {
  final List<Offer> offers;
  final bool hasReachedMax;

  const OffersLoaded({required this.offers, this.hasReachedMax = false});

  @override
  List<Object?> get props => [offers, hasReachedMax];
}

class OfferCreating extends OffersState {
  const OfferCreating();
}

class OfferCreated extends OffersState {
  final Offer offer;

  const OfferCreated({required this.offer});

  @override
  List<Object?> get props => [offer];
}

class OffersError extends OffersState {
  final String message;

  const OffersError({required this.message});

  @override
  List<Object?> get props => [message];
}
