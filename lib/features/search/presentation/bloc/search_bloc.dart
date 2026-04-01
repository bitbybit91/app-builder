import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../trading/domain/entities/offer.dart';
import '../../domain/entities/search_filter.dart';
import '../../domain/usecases/search_offers_usecase.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();
  @override
  List<Object?> get props => [];
}

class SearchOffers extends SearchEvent {
  final SearchFilter filter;
  const SearchOffers(this.filter);
  @override
  List<Object?> get props => [filter];
}

class LoadMoreResults extends SearchEvent {}

abstract class SearchState extends Equatable {
  const SearchState();
  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {}
class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<Offer> offers;
  final SearchFilter filter;
  final bool hasMore;
  const SearchLoaded({required this.offers, required this.filter, this.hasMore = true});
  @override
  List<Object?> get props => [offers, filter, hasMore];
}

class SearchError extends SearchState {
  final String message;
  const SearchError(this.message);
  @override
  List<Object?> get props => [message];
}

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchOffersUseCase searchOffersUseCase;

  SearchBloc({required this.searchOffersUseCase}) : super(SearchInitial()) {
    on<SearchOffers>(_onSearchOffers);
    on<LoadMoreResults>(_onLoadMoreResults);
  }

  Future<void> _onSearchOffers(SearchOffers event, Emitter<SearchState> emit) async {
    emit(SearchLoading());
    try {
      final offers = await searchOffersUseCase(event.filter);
      emit(SearchLoaded(offers: offers, filter: event.filter));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  Future<void> _onLoadMoreResults(LoadMoreResults event, Emitter<SearchState> emit) async {
    if (state is SearchLoaded) {
      final currentState = state as SearchLoaded;
      try {
        final nextFilter = currentState.filter.copyWith(page: currentState.filter.page + 1);
        final newOffers = await searchOffersUseCase(nextFilter);
        emit(SearchLoaded(
          offers: [...currentState.offers, ...newOffers],
          filter: nextFilter,
          hasMore: newOffers.isNotEmpty,
        ));
      } catch (e) {
        emit(SearchError(e.toString()));
      }
    }
  }
}
