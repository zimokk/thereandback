import 'package:test/test.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/features/journey/data/lock_screen_preference_repository.dart';

void main() {
  late AppDatabase db;
  late LockScreenPreferenceRepository repository;

  setUp(() {
    db = AppDatabase.forTesting();
    repository = DriftLockScreenPreferenceRepository(db);
  });
  tearDown(() => db.close());

  test('loadEnabled() is false for an owner nothing was ever saved for — '
      'same default as a fresh LockScreenState', () async {
    expect(await repository.loadEnabled('owner-1'), isFalse);
  });

  test('saveEnabled() then loadEnabled() round-trips true', () async {
    await repository.saveEnabled('owner-1', true);
    expect(await repository.loadEnabled('owner-1'), isTrue);
  });

  test('a later saveEnabled() for the same owner overwrites, not adds — '
      'loadEnabled() sees the latest value', () async {
    await repository.saveEnabled('owner-1', true);
    await repository.saveEnabled('owner-1', false);

    expect(await repository.loadEnabled('owner-1'), isFalse);
  });

  test('a different owner never sees another owner\'s saved value (§8, '
      '§13)', () async {
    await repository.saveEnabled('owner-1', true);

    expect(await repository.loadEnabled('owner-2'), isFalse);
  });
}
