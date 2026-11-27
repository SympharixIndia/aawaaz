# Aawaaz — V3 Spec (Mobile app: backend integration)

*Every worker's voice, on record.*

This spec covers the **mobile app (Flutter) changes** to move off the in-memory store and
talk to the V2 backend, plus two product gaps found in testing: a **ticket-based status
check** for workers, and a **UI alignment** pass. The app is [`aawaaz-mobile/`](aawaaz-mobile);
the backend and its APIs are in [`SPEC_V2.md`](SPEC_V2.md).

> **Status:** drafting, spec-first. **No app code is being written yet.** Built incrementally,
> one tracker step per PR, same as V1/V2.

---

## 1. Scope & assumptions

- The backend base URL is built from an **`.env` file** holding the host + port (and scheme).
  **Placeholder port: `8080`** (the backend's current default — no backend port change needed).
- **In scope:** replace the in-memory `AppRepository` with calls to the backend; wire every
  screen to its endpoint; add a worker **status-by-ticket** section; fix UI alignment; one
  small backend addition (get-by-ticket, §1.2).
- **Out of scope (V3):** push notifications (status check is on-demand/pull), real
  manager→worker translation (kept as-is for now, matching the backend's translation stub),
  offline sync for integrated flows (the "Type instead" voice fallback stays).

### 1.1 Base URL via `.env` (host + port)
`localhost` means different things per target, so the host/port live in an **`.env` file**
loaded at startup (e.g. via `flutter_dotenv`); `ApiConfig.baseUrl` is composed as
`${API_SCHEME}://${API_HOST}:${API_PORT}`.

```
# .env  (dev; not committed — see .env.example)
API_SCHEME=http
API_HOST=10.0.2.2   # Android emulator → host machine
API_PORT=8080
```

Per target, only `.env` changes:
- **Android emulator** → `API_HOST=10.0.2.2` (the host from inside the emulator).
- **Physical device on same Wi-Fi** (e.g. the S23 FE) → `API_HOST=<host-LAN-IP>`
  (e.g. `192.168.1.50`), and the backend must bind to `0.0.0.0`.
- Commit a **`.env.example`** with placeholders; git-ignore the real `.env`.

### 1.2 Backend prerequisites
1. **Port:** resolved — use **`8080`** (backend default); no backend port change. ✅
2. **Get-by-ticket endpoint:** approved — add **`GET /api/requests/{id}`** returning one
   request (404 if absent), needed by the status-by-ticket feature (§3). This is the one
   backend change included in V3 (was "nice-to-have" in SPEC_V2 §5.6). ✅
3. **Binding:** run the backend bound to `0.0.0.0` for LAN access from a physical device.

### 1.3 Android networking
- Ensure `<uses-permission android:name="android.permission.INTERNET"/>` in the main manifest.
- Dev uses plain **HTTP**, which Android blocks by default (API 28+). Allow cleartext for
  dev via `android:usesCleartextTraffic="true"` (debug) or a network-security-config scoped
  to the dev host. Flag for production (should be HTTPS).

---

## 2. Architecture changes

- **HTTP layer:** add a client (`http` package is enough; `dio` if we want interceptors)
  plus `flutter_dotenv` for config. One `ApiClient` reads `ApiConfig.baseUrl` (from `.env`,
  §1.1) and does JSON GET/POST/PATCH/PUT with error mapping.
- **Keep `AppRepository` as the seam.** V1 deliberately put all data access behind it; V3
  swaps its body from in-memory lists to `ApiClient` calls. Screens change as little as
  possible — mostly becoming async (loading/error states).
- **Async UI:** calls are now network-bound → add loading indicators, error snackbars, and
  retry. Screens that were synchronous (dashboard list, my-status) use `FutureBuilder` or the
  existing `provider` with async methods.
- **Models align to backend DTOs** (§4). The app's `ticketNo` becomes the backend request
  **id**; `Query` fields map to `original/translated` text; `Worker` gains `profession`.
- **Remove startup demo seed** (`seedDemoData`) — data now lives in the backend. (Optionally
  keep a tiny "is the server reachable?" check on launch.)

---

## 3. New feature — worker status check by ticket

A dedicated, discoverable section so a worker who filed a request (and has the spoken ticket
number) can check it without hunting through screens.

- **Entry point:** a third button on the Home screen — **"Check request status"** — alongside
  "Register a request" and "Register".
- **Flow:**
  1. Prompt (TTS, chosen language): "Say or enter your ticket number."
  2. Worker enters (or speaks) the ticket number.
  3. App calls `GET /api/requests/{id}`.
  4. Show **and speak** the result: the current **status** (Open / In progress / Resolved)
     and the **manager's feedback** if any ("Still pending" otherwise).
  5. 404 → "No request found with that number."
- Language: status words spoken in the worker's chosen language (reuse `Prompts`); the
  manager comment is shown/spoken as stored (translation deferred, §1 out-of-scope).
- This complements the existing "My requests" list (reached after login); the ticket lookup
  needs **no login** — ticket number is the key.

---

## 4. API integration map

Base: `{baseUrl}` from `.env` (e.g. `http://10.0.2.2:8080`). All JSON.

| App action / screen | Method & path | Sends | Uses from response |
|---|---|---|---|
| Register (new worker) | `POST /api/workers` | username, name, password(PIN), profession, languageCode | created user (id) |
| Worker login | `POST /api/auth/login` | username, password | id, name, userType, languageCode |
| File a request | `POST /api/requests` | workerId, originalText, originalLanguage, categoryKey, urgency | id (= ticket no), status |
| My requests (after login) | `GET /api/requests?workerId={id}` | — | list (status, managerComment) |
| **Status by ticket (new)** | `GET /api/requests/{id}` | — | status, managerComment, category |
| Manager login | `POST /api/auth/login` | username, password | id, userType=MANAGER, languageCode |
| Manager dashboard | `GET /api/requests?date=YYYY-MM-DD` | — | list (translatedText, category, urgency, status) |
| Manager reply / status | `PATCH /api/requests/{id}` | status, managerComment, managerCommentLanguage | updated request |
| Categories (dashboard/priority) | `GET /api/categories` | — | list (priority, label) |
| Set category priority | `PUT /api/categories/{key}/priority` | priority | updated category |

Notes:
- **Categorization stays on-device** (the app's `Categorizer` already runs); the app sends
  `categoryKey` + `urgency` on create, per SPEC_V2.
- **Ticket number** = backend request `id`. The acknowledgement after filing ("Request filed
  #N") uses the id returned by `POST /api/requests`.
- Manager dashboard reads `translatedText` (already in the manager's language on the backend).

---

## 5. Data model alignment (app ↔ backend)

| App (current) | Backend DTO field | Note |
|---|---|---|
| `Worker.username/name/password/languageCode` | workers payload | add **`profession`** (optional) to the reg form |
| `Worker.id` (uuid String) | user `id` (Long) | switch app ids to int/Long from the server |
| `Query.ticketNo` (int 101+) | request `id` (Long) | drop local ticket counter; use server id |
| `Query.transcript` | `originalText` (+ `originalLanguage`) | |
| — | `translatedText` / `translatedLanguage` | manager-side display |
| `Query.category` (key) | `categoryKey` | same keys |
| `Query.urgency` / `status` | `urgency` / `status` enums | match names (HIGH/NORMAL/LOW, OPEN/IN_PROGRESS/RESOLVED) |
| `Query.managerComment` | `managerComment` (+ language) | |

---

## 6. UI alignment pass

Testing showed some sections are not properly aligned. Audit and fix across screens.

**Known issue (reported):** on the **Query Capture** screen (after a worker logs in, where
they file a request), the **mic / sound icon is not aligned properly** — fix this first.

Broader checks:
- Consistent screen padding and max-width; no clipped/overflowing rows.
- Home: evenly spaced, centered action buttons.
- Registration / login forms: aligned fields, consistent spacing, button full-width.
- Dashboard cards: aligned chips/row content; the urgency accent and category icon line up.
- My-status / ticket-result: label/value alignment; long text wraps.
- Verify on the physical device (S23 FE) and a smaller screen; check light + dark.
> Remaining fixes to be itemized during the pass (Step F7) with before/after.

---

## 7. Implementation tracker

Legend: `[ ]` not started · `[~]` in progress · `[x]` done.

### Step FB — Backend change (get-by-ticket)
- [ ] Add `GET /api/requests/{id}` to the backend (404 if absent) + a test. (§1.2)

### Step F0 — HTTP foundation
- [ ] Add `http` + `flutter_dotenv`; `.env` (git-ignored) + committed `.env.example`.
- [ ] `ApiConfig.baseUrl` composed from `API_SCHEME/API_HOST/API_PORT`.
- [ ] `ApiClient` (JSON GET/POST/PATCH/PUT + error mapping to a simple `ApiException`).
- [ ] Android: INTERNET permission + cleartext-for-dev.

### Step F1 — Models aligned to backend
- [ ] Update `Worker`/`Query`/`Category` (or add DTOs) to match backend fields + id types.

### Step F2 — Registration → `POST /api/workers`
- [ ] Add optional **profession** field; submit to backend; handle 409 duplicate / 400.

### Step F3 — Worker login → `POST /api/auth/login`
- [ ] Authenticate against backend; carry the returned worker (id, language).

### Step F4 — File request → `POST /api/requests`
- [ ] Send categoryKey + urgency from the on-device `Categorizer`; show server `id` as ticket.

### Step F5 — Manager login + dashboard
- [ ] Manager login; dashboard via `GET /api/requests?date=`; comment via `PATCH`;
      categories via `GET /api/categories` + `PUT .../priority`.

### Step F6 — Worker status-by-ticket (new, §3)
- [ ] Home "Check request status" entry; ticket entry; `GET /api/requests/{id}`; show + speak.
- [ ] (Backend endpoint delivered in Step FB.)

### Step F7 — UI alignment pass (§6)
- [ ] Fix the mic/sound icon alignment on Query Capture (known issue, first).
- [ ] Audit + fix alignment across the other screens; verify on device + dark mode.

### Step F8 — Cleanup & end-to-end
- [ ] Remove in-memory seed; loading/error states; run app against the live backend.

**Current status:** drafting. Nothing implemented yet.

---

## 8. Decisions & open questions

**Resolved**
- **Port:** `8080` (backend default); base URL from `.env`. ✅
- **Get-by-ticket:** add `GET /api/requests/{id}` to the backend in V3 (Step FB). ✅
- **Config:** host + port in an `.env` file (`flutter_dotenv`); `.env.example` committed. ✅
- **Status check identity:** ticket number only, no login (§3). ✅

- **Manager→worker translation:** keep showing the manager comment as-is for V3 (real
  translation deferred), consistent with the backend stub. ✅
- **Known misalignment:** the mic/sound icon on the Query Capture screen (post worker-login)
  — fix first in F7 (§6). ✅

*(No open questions — spec is final.)*
