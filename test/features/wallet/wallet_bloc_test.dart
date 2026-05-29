import 'package:bloc_test/bloc_test.dart';
import 'package:capitalmonero/features/wallet/data/datasources/wallet_data_source.dart';
import 'package:capitalmonero/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:capitalmonero/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:capitalmonero/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WalletRepository repo() =>
      WalletRepositoryImpl(source: InMemoryWalletDataSource());

  blocTest<WalletBloc, WalletState>(
    'load coin yields WalletLoaded with balance and address',
    build: () => WalletBloc(repository: repo()),
    act: (WalletBloc bloc) => bloc.add(const WalletLoadRequested('XMR')),
    expect: () => <Object?>[
      isA<WalletLoading>(),
      isA<WalletLoaded>()
          .having((s) => s.coin, 'coin', 'XMR')
          .having((s) => s.balance.available, 'balance', greaterThan(0.0)),
    ],
  );

  test('withdraw updates balance and pushes a new transaction', () async {
    final WalletBloc bloc = WalletBloc(repository: repo());
    bloc.add(const WalletLoadRequested('XMR'));
    await expectLater(
      bloc.stream,
      emitsThrough(isA<WalletLoaded>()),
    );
    final double before = (bloc.state as WalletLoaded).balance.available;
    bloc.add(const WalletWithdrawRequested(
      coin: 'XMR',
      destination:
          '47fEXMRkfp9pLcDTRvuczeRGn3hAQ2pYwxqcwGfeqqWdmnsZGqGsKqDfgQpcSPUbo3Sg5N1nFi72Xpa6kTu2gFCQpZWS9hY',
      amount: 0.1,
    ));
    await expectLater(
      bloc.stream,
      emitsThrough(isA<WalletLoaded>().having(
        (WalletLoaded s) => s.lastWithdrawal,
        'lastWithdrawal',
        isNotNull,
      )),
    );
    expect((bloc.state as WalletLoaded).balance.available, lessThan(before));
    await bloc.close();
  });
}
