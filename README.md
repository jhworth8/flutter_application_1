# 🥒 Pickleball Round Robin

A mobile-first (iOS / Android / mobile web) Flutter mini-app for running casual
doubles pickleball round-robins on the fly. The whole point is **speed-to-play**:
get from an empty roster to players on courts in under thirty seconds, while the
engine quietly handles fair pairings, rest equity, late arrivals and early
departures.

## Features

- **Launchpad roster check-in** — quick-add bar, tap-to-toggle player pills,
  long-press to delete, and a court stepper. One tap starts the tournament.
- **Constraint-based scheduling engine** — generates each round by minimizing a
  penalty function that enforces bye equity, rotates partners, and spreads out
  opponents:

  ```
  E = 1000 · Variance(byes)
    +  100 · Σ max(0, partnerships − 1)²
    +   10 · Σ max(0, oppositions  − 2)²
  ```

- **Active Board** — bench-legible top-down court cards, a starred first server,
  tap-a-side scoring with optional exact point entry, an on-the-bench shelf, and
  an optional per-round timer.
- **Live standings** — wins / losses / point differential, ranked in real time.
- **"Life happens" mid-session controls** — inject late arrivals (back-filled
  with synthetic byes so they're prioritized to play), toggle early departures
  (records freeze, not erased), and change court counts on the fly.
- **Crash recovery** — the full session is serialized to local storage on every
  mutation and restored on launch, so a backgrounded/killed app resumes mid-round.
- **Session archive** — completed tournaments are stored with podium + full
  round history for read-only review.
- **Native share** — flatten the current matchups or standings into a PNG and
  push it straight to the platform share sheet.

## Architecture

| Layer | Location |
| --- | --- |
| Data models (JSON-serializable) | `lib/models/models.dart` |
| Scheduling engine | `lib/logic/scheduler.dart` |
| Standings calculator | `lib/logic/standings.dart` |
| Single-source-of-truth state (Cubit) | `lib/state/app_cubit.dart` |
| Persistence (`shared_preferences`) | `lib/services/storage_service.dart` |
| Image share | `lib/services/share_service.dart` |
| Screens | `lib/screens/` |
| Widgets | `lib/widgets/` |

State is managed with a single `AppCubit` (flutter_bloc). Every user-initiated
mutation re-serializes the relevant slices to local non-volatile storage.

## Running

```bash
flutter pub get
flutter run            # mobile (iOS / Android)
flutter run -d chrome  # mobile web
flutter test           # unit + widget tests
```

## Tests

- `test/scheduler_test.dart` — structural guarantees, bye equity, partner rotation.
- `test/standings_test.dart` — win/loss/differential tallying.
- `test/widget_test.dart` — boot smoke test into the Launchpad.
