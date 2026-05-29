import 'package:bloc_test/bloc_test.dart';
import 'package:capitalmonero/core/errors/failures.dart';
import 'package:capitalmonero/features/trading/domain/entities/offer.dart';
import 'package:capitalmonero/features/trading/domain/repositories/offer_repository.dart';
import 'package:capitalmonero/features/trading/presentation/bloc/offers_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOfferRepo extends Mock implements OfferRepository {}

class _FakeQuery extends Fake implements OfferQuery {}

class _FakeOffer extends Fake implements Offer {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeQuery());
    registerFallbackValue(_FakeOffer());
  });

  late _MockOfferRepo repo;

  final List<Offer> sample = <Offer>[
    Offer(
      id: 'o1',
      ownerUsername: 'satoshi',
      coin: 'XMR',
      fiatCurrency: 'USD',
      paymentMethod: 'Bank',
      kind: OfferKind.onlineSell,
      priceEquation: 'market',
      minAmount: 10,
      maxAmount: 100,
      createdAt: DateTime(2024),
    ),
  ];

  setUp(() {
    repo = _MockOfferRepo();
  });

  blocTest<OffersBloc, OffersState>(
    'loads offers successfully',
    build: () {
      when(() => repo.listOffers(any())).thenAnswer(
        (_) async => Right<Failure, List<Offer>>(sample),
      );
      return OffersBloc(repository: repo);
    },
    act: (bloc) => bloc.add(const OffersLoadRequested()),
    expect: () => <Object?>[
      isA<OffersLoading>(),
      isA<OffersLoaded>().having((s) => s.offers, 'offers', sample),
    ],
  );

  blocTest<OffersBloc, OffersState>(
    'emits OffersError when repository fails',
    build: () {
      when(() => repo.listOffers(any())).thenAnswer(
        (_) async => const Left<Failure, List<Offer>>(
          ServerFailure('boom'),
        ),
      );
      return OffersBloc(repository: repo);
    },
    act: (bloc) => bloc.add(const OffersLoadRequested()),
    expect: () => <Object?>[
      isA<OffersLoading>(),
      isA<OffersError>(),
    ],
  );

  blocTest<OffersBloc, OffersState>(
    'create offer reloads list',
    build: () {
      when(() => repo.listOffers(any())).thenAnswer(
        (_) async => Right<Failure, List<Offer>>(sample),
      );
      when(() => repo.createOffer(any())).thenAnswer(
        (_) async => Right<Failure, Offer>(sample.first),
      );
      return OffersBloc(repository: repo);
    },
    act: (bloc) => bloc.add(OfferCreated(sample.first)),
    expect: () => <Object?>[isA<OffersLoaded>()],
  );
}
