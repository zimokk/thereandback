import 'package:freezed_annotation/freezed_annotation.dart';

part 'narrative_beat.freezed.dart';

/// One line of narrative, tied to a position along the route (CLAUDE.md §5:
/// `NarrativeBeat`, "строка нарратива, привязанная к позиции в метрах") —
/// today, one per landmark in `assets/journeys/{id}/locations.json`. Pure
/// Dart, no Flutter import (§4) — the scene only turns [meters] into a
/// screen position and prints [text].
@freezed
abstract class NarrativeBeat with _$NarrativeBeat {
  const factory NarrativeBeat({required int meters, required String text}) =
      _NarrativeBeat;
}

/// The narrative line to show for the route position currently centered on
/// screen (§6.1: "строка нарратива курсивом" updates in step with the
/// scroll) — the most recent [beats] entry at or before [meters], i.e. the
/// last landmark the traveler has actually reached at that point in the
/// route, same "rewind re-derives everything from the scrolled-to position"
/// idiom `fictional_time.dart`'s `fictionalHourFor` already uses for the sky.
///
/// Returns `null` when [beats] is empty, or when [meters] sits before the
/// very first beat (nothing has been reached yet to narrate) — the caller
/// falls back to its own placeholder either way, the same as it already
/// does when a quest ships no narrative content at all.
///
/// [beats] is assumed sorted ascending by [NarrativeBeat.meters] (the
/// loader sorts on read) — not re-validated here, since this runs on every
/// scroll frame just like `fictionalHourFor`.
NarrativeBeat? narrativeBeatFor(List<NarrativeBeat> beats, int meters) {
  NarrativeBeat? current;
  for (final beat in beats) {
    if (beat.meters > meters) break;
    current = beat;
  }
  return current;
}
