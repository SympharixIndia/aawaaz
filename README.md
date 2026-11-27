# Aawaaz

**Every worker's voice, on record.**

In many factories, hundreds of workers depend on one manager for everything — leave, early
exits, salary advances, health issues, safety concerns — with no HR team and no system.
Requests are passed by word of mouth, forgotten, or lost in a crowded shift. Workers who
can't read or write forms, or are afraid to ask, simply go without.

Aawaaz removes the barrier of forms, screens, and language: a worker walks up, is identified,
and **speaks their request in their own language**. The app confirms it back, categorizes it,
and files it on a permanent record. The manager sees every request in one prioritized place —
safety and health first — and replies. Later, the worker can ask for an update and **hear the
manager's answer read aloud**.

---

## Repository layout

| Path | What it is |
|---|---|
| [`aawaaz-mobile/`](aawaaz-mobile) | The **V1 Flutter app** (Android) — the current build. |
| [`aawaaz-backend/`](aawaaz-backend) | The **backend** (Java / Spring Boot) — early scaffold, in progress. |
| [`SPEC_V1.md`](SPEC_V1.md) | V1 specification and the step-by-step implementation tracker. |
| [`DESIGN.md`](DESIGN.md) | The longer-term product/architecture vision (web + backend). Not the V1 target. |

---

## V1 — the Flutter app

A single self-contained Android app. **No backend, no database, all data in memory** (it
resets when the app closes; demo data is seeded at startup). Deliberately simple, built for a
hackathon and structured so each piece can be upgraded later.

### What it does

**Worker**
1. **Register** — username, name, a numeric PIN, and a language (Hindi / Bengali / English).
2. **Log in** and **file a request** — the app prompts in the worker's language; the worker
   speaks (or types), the app reads the request back to confirm, categorizes it, and files it
   with a ticket number, spoken aloud.
3. **My requests** — hear the current status / manager's reply read aloud.

**Manager** (hardcoded login — default `admin` / `admin123`)
- One dashboard of all requests, grouped by date and **sorted by priority** (safety & health
  on top), with an urgency accent for quick scanning.
- Add a comment and change status (open → in progress → resolved) per request.
- Tune category priorities with sliders — the dashboard re-sorts live.

### Tech

- **Flutter** (Android), `provider` for state, a single in-memory `AppRepository`.
- **Voice:** `speech_to_text` (capture) + `flutter_tts` (prompts & playback), wrapped in a
  swappable `VoiceService`. A **"Type instead"** fallback keeps the flow usable where device
  speech isn't available.
- **Categorization:** on-device, rule-based keyword matching (`Categorizer`) across the three
  languages plus romanized forms — isolated behind one call so it can later be swapped for an
  LLM.

### Project structure (`aawaaz-mobile/lib`)

```
constants.dart            App config, manager credentials, supported languages
data/app_repository.dart  Single in-memory store (workers, queries, categories)
models/                   Worker, Query, Category (+ Urgency, QueryStatus)
services/
  voice_service.dart      TTS + STT wrapper
  categorizer.dart        Rule-based intent → category + urgency
l10n/prompts.dart         Localized spoken/on-screen strings (hi/bn/en)
screens/                  Home, registration, worker login, query capture,
                          my status, manager login, dashboard, priorities
ui/                       Theme and formatting/icon helpers
```

---

## Running it

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (developed on 3.35.x).

```bash
cd aawaaz-mobile
flutter pub get
flutter run
```

Analyze and test:

```bash
cd aawaaz-mobile
flutter analyze
flutter test
```

> **Voice on a device:** speech recognition and text-to-speech use the Android on-device
> engines, so the `hi-IN` / `bn-IN` / `en-IN` voices must be installed on the device/emulator
> (Settings → Languages & input → voice). Without them, use **"Type instead"** in the query flow.

---

## Backend (`aawaaz-backend/`)

Early scaffold — a **Spring Boot 4** (Java 17) service with the bundled Maven wrapper, so
nothing extra to install. Run it:

```bash
cd aawaaz-backend
./mvnw spring-boot:run
```

Then it's up on `http://localhost:8080` — try `GET /` (landing/health JSON), `GET /api/ping`,
or `GET /actuator/health`. Build / test:

```bash
cd aawaaz-backend
./mvnw test
```

The real APIs (workers, requests, categories, the tamper-evident record) and persistence come
in later increments — see [`DESIGN.md`](DESIGN.md).

## Status

V1 is **feature-complete**: register → log in → speak/type a request → confirm → filed with a
ticket → manager prioritizes & replies → worker hears the reply. See [`SPEC_V1.md`](SPEC_V1.md)
for the full tracker. Live voice I/O still needs verification on real hardware.

### What's next (V2)

Per [`DESIGN.md`](DESIGN.md): a backend with real persistence, LLM-based categorization, and a
tamper-evident (hash-chained, append-only) request record.
