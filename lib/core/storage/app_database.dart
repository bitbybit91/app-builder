import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'app_database.g.dart';

// ---------------------------------------------------------------------------
// Tables
// ---------------------------------------------------------------------------

class OffersTable extends Table {
  @override
  String get tableName => 'offers';

  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get type => text()(); // 'buy' | 'sell'
  TextColumn get cryptoCurrency => text()();
  TextColumn get fiatCurrency => text()();
  RealColumn get minAmount => real()();
  RealColumn get maxAmount => real()();
  RealColumn get price => real()();
  TextColumn get paymentMethod => text()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text()();
  TextColumn get userId => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class TradesTable extends Table {
  @override
  String get tableName => 'trades';

  TextColumn get id => text()();
  TextColumn get offerId => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get status => text()();
  RealColumn get amount => real()();
  RealColumn get price => real()();
  TextColumn get buyerId => text()();
  TextColumn get sellerId => text()();
  TextColumn get escrowTxId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class MessagesTable extends Table {
  @override
  String get tableName => 'messages';

  TextColumn get id => text()();
  TextColumn get tradeId => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get senderId => text()();
  TextColumn get content => text()();
  BoolColumn get isRead =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class UsersTable extends Table {
  @override
  String get tableName => 'users';

  TextColumn get id => text()();
  TextColumn get username => text()();
  RealColumn get reputationScore =>
      real().withDefault(const Constant(0.0))();
  IntColumn get tradesCount =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(tables: [OffersTable, TradesTable, MessagesTable, UsersTable])
class AppDatabase extends _$AppDatabase {
  /// Configures where the database file is stored.
  ///
  /// Call this before [AppDatabase] is first constructed, typically from
  /// `main()` after resolving the platform documents directory.
  static Future<File> Function()? dbFileResolver;

  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final File file;
      if (dbFileResolver != null) {
        file = await dbFileResolver!();
      } else {
        // Fallback for tests / desktop development.
        file = File('capital_monero.db');
      }
      return NativeDatabase.createInBackground(file);
    });
  }
}
