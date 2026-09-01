import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/drift/user_preference_repository.dart';
import 'database_provider.dart';

part 'user_preference_repository_provider.g.dart';

/// The drift-backed store for the Настройки toggles that persist across a
/// restart (§6.5, §14 — language, theme pin, background music, friends on
/// map): `app/` is the DI root (§4), and this repository is shared by four
/// different features' providers (`profile/`, `audio/`, `friends/`) rather
/// than owned by any one of them — same reasoning `database_provider.dart`
/// itself already documents for `appDatabaseProvider`. Overridden with an
/// in-memory `AppDatabase` in tests via `appDatabaseProvider` (`testing`
/// skill: never a real drift database in a test).
@riverpod
UserPreferenceRepository userPreferenceRepository(Ref ref) =>
    DriftUserPreferenceRepository(ref.watch(appDatabaseProvider));
