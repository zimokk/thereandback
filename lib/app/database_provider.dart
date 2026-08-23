import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/drift/database.dart';

part 'database_provider.g.dart';

/// The app-wide drift database (CLAUDE.md §4: `app/` is the DI root; §8:
/// drift is the offline-first source of truth). Every feature repository
/// depends on this instead of constructing its own [AppDatabase], so a
/// single override replaces the whole local storage layer with an
/// in-memory instance in tests (`testing` skill: never a real drift
/// database in a test).
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
