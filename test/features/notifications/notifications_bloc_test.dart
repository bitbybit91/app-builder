import 'package:bloc_test/bloc_test.dart';
import 'package:capitalmonero/features/notifications/data/datasources/notifications_data_source.dart';
import 'package:capitalmonero/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:capitalmonero/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  blocTest<NotificationsBloc, NotificationsState>(
    'auto-loads notifications and emits Loaded',
    build: () => NotificationsBloc(
      repository: NotificationsRepositoryImpl(
        source: InMemoryNotificationsDataSource(),
      ),
    ),
    expect: () => <Object?>[
      isA<NotificationsLoading>(),
      isA<NotificationsLoaded>()
          .having((s) => s.items.isNotEmpty, 'has items', isTrue),
    ],
  );

  blocTest<NotificationsBloc, NotificationsState>(
    'markAllRead reduces unread count to zero',
    build: () => NotificationsBloc(
      repository: NotificationsRepositoryImpl(
        source: InMemoryNotificationsDataSource(),
      ),
    ),
    act: (bloc) async {
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NotificationsMarkAllRead());
    },
    skip: 2,
    expect: () => <Object?>[
      isA<NotificationsLoading>(),
      isA<NotificationsLoaded>().having((s) => s.unread, 'unread', 0),
    ],
  );
}
