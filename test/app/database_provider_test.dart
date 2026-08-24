import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/app/database_provider.dart';
import 'package:thereandback/data/drift/database.dart';

/// Every other test in this project overrides `appDatabaseProvider` with an
/// in-memory `AppDatabase.forTesting()` (`testing` skill: never a real
/// drift database in a test), which means the provider's own production
/// body — `AppDatabase()` plus its `ref.onDispose` wiring — is never
/// actually executed anywhere else. This covers just that wiring, without
/// touching the filesystem: `AppDatabase()`'s connection is a `LazyDatabase`
/// (`data/drift/database.dart`'s `_openConnection`), which only calls
/// `path_provider` on the *first query* — never opening it here means this
/// stays a pure-Dart, no-plugin-needed test.
void main() {
  test(
    'appDatabaseProvider builds a real AppDatabase and disposes it cleanly',
    () {
      final container = ProviderContainer();

      final db = container.read(appDatabaseProvider);
      expect(db, isA<AppDatabase>());

      // Disposing the container must trigger `ref.onDispose(db.close)`
      // without throwing — the underlying LazyDatabase was never opened
      // (no query ran), so closing it must be a safe no-op.
      expect(container.dispose, returnsNormally);
    },
  );
}
