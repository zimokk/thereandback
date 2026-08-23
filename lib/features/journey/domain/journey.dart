import 'package:freezed_annotation/freezed_annotation.dart';

part 'journey.freezed.dart';

/// A quest a user can walk: a path from [pointA] to [pointB] with a fixed
/// length in meters (CLAUDE.md §5).
///
/// Quests come from a read-only catalog (§8) — a user never builds their own
/// route. Today the catalog is a small static list (`journey_catalog.dart`);
/// Phase 8 replaces the source with Firestore without changing this type.
@freezed
abstract class Journey with _$Journey {
  const factory Journey({
    required String id,
    required String name,
    required String pointA,
    required String pointB,

    /// Total route length in meters. Always a whole, non-negative number —
    /// the domain never deals in fractional meters (§11).
    required int totalMeters,
  }) = _Journey;
}
