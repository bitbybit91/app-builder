import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../trading/domain/entities/offer.dart';
import '../../domain/repositories/search_repository.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();
  @override
  List<Object?> get props => const <Object?>[];
}

class SearchQueryChanged extends SearchEvent {
  const SearchQueryChanged(this.query);
  final SearchQuery query;
  @override
  List<Object?> get props => <Object?>[
        query.query, query.coin, query.fiatCurrency,
        query.paymentMethod, query.country, query.type, query.page,
      ];
}

abstract class SearchState extends Equatable {
  const SearchState();
  @override
  List<Object?> get props => const <Object?>[];
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchLoaded extends SearchState {
  const SearchLoaded(this.offers);
  final List<Offer> offers;
  @override
  List<Object?> get props => <Object?>[offers];
}

class SearchErrorState extends SearchState {
  const SearchErrorState(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => <Object?>[failure];
}

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({required SearchRepository repository})
      : _repository = repository,
        super(const SearchInitial()) {
    on<SearchQueryChanged>(_onQueryChanged);
  }

  final SearchRepository _repository;

  Future<void> _onQueryChanged(
      SearchQueryChanged event, Emitter<SearchState> emit) async {
    emit(const SearchLoading());
    final result = await _repository.search(event.query);
    result.fold(
      (failure) => emit(SearchErrorState(failure)),
      (offers) => emit(SearchLoaded(offers)),
    );
  }
}
