# `assets/media/` — app-wide media

| File | What it is | In the repo? |
|---|---|---|
| `journey_theme.wav` | The app's one background track (§6.5) | yes — placeholder, see below |

## `journey_theme.wav` — placeholder, not final art

This file is a procedurally generated ambient pad loop (a few sine partials
in a sustained chord, 8-second period, mono, 16-bit PCM WAV), not composed
music — a stand-in so the toggle in Настройки has something real to play
end to end, the same "source not chosen yet, just follow the folder
structure" situation §9.1 already documents for quest art.

Replacing it with a real track:

- Keep the filename `journey_theme.wav` (or update the path constant in
  `lib/features/audio/data/background_music_player.dart` if renaming) — the
  directory is bundled whole (`pubspec.yaml`), so a same-name drop-in needs
  no other change.
- It loops (`ReleaseMode.loop` in `BackgroundMusicPlayer`) — a track that
  doesn't already start/end on the same phase/silence will click at the seam
  every loop. Master it as a seamless loop, or crossfade the ends yourself
  before exporting.
- A compressed format (mp3/ogg/aac) keeps the app bundle far smaller than
  WAV for anything longer than this short placeholder — `audioplayers`
  (§3) plays any of them the same way via `AssetSource`.
- Licensing applies here the same way §9 already requires it for the app's
  font and §1.1 for quest settings — check the track is actually cleared for
  use (commissioned, or a suitable open license) before committing it, "it's
  just a placeholder anyway" is not a reason to skip that check once it's
  the real one.
