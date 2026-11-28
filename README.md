# Aawaaz

**Every worker's voice, on record.**

Aawaaz is a voice-first system that lets factory workers raise everyday requests — leave,
early exit, salary advance, health issues, safety concerns — simply by **speaking in their
own language**, and lets a manager see and act on every request in one prioritized place.

---

## The problem

In many factories, hundreds of workers depend on a single manager for everything, with no HR
team and no system. Requests get passed by word of mouth, forgotten, or lost in a crowded
shift. Workers who can't read or write forms, or who hesitate to ask, simply go without.

Aawaaz removes the barriers of forms, screens, and language. A worker walks up, is identified,
and says what they need. The app repeats it back to confirm, files it under the right
category, and gives a spoken acknowledgement with a ticket number. The manager opens a
dashboard, sees every request sorted by what matters most (safety and health first), and
replies. The worker can later ask for an update and hear the manager's answer read aloud.

---

## What's in the box

Aawaaz has two parts that work together:

| Part | Path | What it is |
|---|---|---|
| **Mobile app** | [`aawaaz-mobile/`](aawaaz-mobile) | A Flutter (Android) app — the on-floor voice interface for workers and the dashboard for managers. |
| **Backend** | [`aawaaz-backend/`](aawaaz-backend) | A Java / Spring Boot service exposing the REST API the app talks to. |

Supporting documents: [`DESIGN.md`](DESIGN.md) (product/architecture vision) and the
`SPEC_*.md` files (detailed specifications).

---

## Features

**For workers**
- **Register** with a username, name, a numeric PIN, and a preferred language (Hindi,
  Bengali, or English).
- **File a request by voice** — the app prompts in the worker's language, the worker speaks,
  and the app reads the request back to confirm before filing it. Each request gets a spoken
  **ticket number**. (A "type instead" option is available where speech isn't usable.)
- **Automatic categorization** — requests are sorted into Safety, Health, Early exit, Leave,
  Salary advance, or Other, with an urgency level.
- **Check status** — a worker can look up a request by its ticket number and hear the current
  status and the manager's reply read aloud in their own language.

**For managers**
- **One prioritized dashboard** of all requests, grouped by day and sorted by category
  priority (safety and health on top), with an urgency accent for quick scanning.
- **Reply and resolve** — add a comment and move a request through Open → In progress →
  Resolved. The worker can then hear that reply.
- **Tune priorities** — adjust each category's priority; the dashboard re-sorts accordingly.

**Multilingual** — Hindi (`hi-IN`), Bengali (`bn-IN`), and English (`en-IN`), for both speech
input and spoken output.

---

## How it works

```
Worker speaks ─▶ App (speech-to-text) ─▶ categorized ─▶ Backend stores the request
                                                             │
Manager dashboard ◀── reads requests (prioritized) ──────────┘
       │
       └─▶ Manager replies / resolves ─▶ Backend ─▶ Worker hears the reply (text-to-speech)
```

- The **app** handles the voice interaction (speech-to-text for capture, text-to-speech for
  prompts and playback) and on-device categorization, and calls the backend over HTTP.
- The **backend** stores workers, requests, and categories, authenticates logins, and serves
  the prioritized request lists and updates.

---

## Getting started

You need two things running: the **backend** (the API) and the **app** (on an emulator or an
Android phone). Start the backend first.

### Prerequisites
- **Java 17+** (for the backend; the Maven wrapper is bundled, so Maven itself isn't needed).
- **Flutter SDK** 3.35.x ([install guide](https://docs.flutter.dev/get-started/install)).
- An **Android device or emulator**. For a physical phone, keep it on the same Wi-Fi as the
  computer running the backend.

### 1. Run the backend

```bash
cd aawaaz-backend
./mvnw spring-boot:run
```

The API starts on **`http://localhost:8080`**. It uses an in-memory database that is created
fresh on each start and seeded with the default manager and the category list. Check it's up:

```bash
curl http://localhost:8080/actuator/health
```

**Translation** (worker speech → English for the manager; manager reply → the worker's
language) uses the [Sarvam](https://sarvam.ai) API. Provide a key via the environment to enable
it; without it, text is stored/shown untranslated:

```bash
SARVAM_API_KEY=your_key_here ./mvnw spring-boot:run
```

Run the backend tests with:

```bash
cd aawaaz-backend
./mvnw test
```

### 2. Point the app at the backend

The app reads the backend address from [`aawaaz-mobile/.env`](aawaaz-mobile/.env):

```
API_SCHEME=http
API_HOST=10.0.2.2
API_PORT=8080
```

Set `API_HOST` for your target:
- **Android emulator** → `10.0.2.2` (this is the host machine as seen from the emulator).
- **Physical phone (same Wi-Fi)** → your computer's LAN IP, e.g. `192.168.1.50`
  (find it with `hostname -I`).

`.env` is read when the app launches, so after changing it do a full restart of the app.

### 3. Run the app

```bash
cd aawaaz-mobile
flutter pub get
flutter run
```

If more than one device is connected, target one explicitly, e.g.
`flutter run -d <device-id>` (list them with `flutter devices`).

**In a browser (web):** the app also builds for the web.

```bash
cd aawaaz-mobile
flutter run -d chrome          # or: flutter build web  → serve build/web/
```

For the web build set `API_HOST=localhost` (a browser can't use the emulator's `10.0.2.2`). The
backend enables CORS for this. Microphone/speech works on `http://localhost` or HTTPS (Chrome
recommended); the "type instead" options cover anything speech can't.

Analyze and test the app:

```bash
cd aawaaz-mobile
flutter analyze
flutter test
```

### Default manager login
- **Username:** `admin`
- **Password:** `admin123`

---

## Using the app

**As a worker**
1. On the home screen, tap **Register (new worker)** and create an account (username, name,
   numeric PIN, language).
2. Tap **Register a request**, log in with your username + PIN, then speak your request when
   prompted. Confirm it when the app reads it back — you'll get a ticket number.
3. Tap **Check request status**, enter your ticket number, and hear the current status and any
   manager reply.

**As a manager**
1. Tap **Manager** and log in with `admin` / `admin123`.
2. Review the day's requests (safety/health first). Tap one to add a comment and set its
   status. Use the date picker to view other days and pull down to refresh.
3. Use the priorities screen to adjust how categories are ranked.

---

## API reference

Base URL: `http://<host>:8080`. All JSON.

| Method & path | Purpose |
|---|---|
| `POST /api/auth/login` | Log in (manager or worker); returns the user. |
| `POST /api/workers` | Register a worker. |
| `POST /api/requests` | File a request. |
| `GET /api/requests?date=YYYY-MM-DD` | Manager listing for a day (priority-sorted). |
| `GET /api/requests?workerId={id}` | A worker's own requests. |
| `GET /api/requests/{id}` | Look up a single request by ticket number. |
| `PATCH /api/requests/{id}` | Manager update: status and/or comment. |
| `GET /api/categories` | List categories with priorities. |
| `PUT /api/categories/{key}/priority` | Set a category's priority. |
| `GET /actuator/health` | Service health check. |

---

## Running with Docker

From the repository root, one command builds and starts the backend:

```bash
docker compose up --build
```

The API comes up on **`http://localhost:8080`** (in-memory DB, seeded with `admin`/`admin123`
and the categories). The mobile/web app then points its `API_HOST` at this host.

**Translation** is optional: provide a Sarvam key and `docker compose` picks it up automatically
— either export it, or copy `.env.example` to `.env` and fill it in:

```bash
export SARVAM_API_KEY=your_key_here    # (or: cp .env.example .env && edit)
docker compose up --build
```

Without a key the app still runs; text is just stored/shown untranslated. The backend needs
outbound HTTPS to `api.sarvam.ai` for live translation.

---

## Tech stack

- **App:** Flutter (Android + web), `provider` for state, `speech_to_text` + `flutter_tts` for
  voice, `http` + `flutter_dotenv` for backend calls.
- **Backend:** Java 17, Spring Boot 4 (Spring Web MVC, Spring Data JPA), H2 in-memory
  database, BCrypt password hashing. Translation via the Sarvam API.

---

## Notes

- The backend database is **in-memory**: all data (except the seeded manager and categories)
  resets each time the backend restarts.
- Speech uses the Android on-device engines, so the `hi-IN` / `bn-IN` / `en-IN` voices should
  be installed on the device (Settings → Languages & input → voice). Where a voice isn't
  available, use the app's "type instead" option.
- For local development the app talks to the backend over plain HTTP; cleartext traffic is
  enabled for that purpose.
