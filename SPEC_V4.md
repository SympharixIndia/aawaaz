# Aawaaz — V4 Spec (real translation + voice ticket entry)

*Every worker's voice, on record.*

V4 adds the three features that make the multilingual promise real, plus hands-free status
lookup. It builds on the V2 backend ([`SPEC_V2.md`](SPEC_V2.md)) and the V3 app integration
([`SPEC_V3.md`](SPEC_V3.md)), and **supersedes** their translation decisions (which were a
pass-through stub showing text "as-is").

> **Status:** drafting, spec-first. **No code yet.** A translation-engine **POC** gates the
> build — see §4.

---

## 1. The three features

1. **Worker speech → English (stored).** Whatever language a worker speaks, the backend
   auto-translates it to **English** and stores that. The manager dashboard shows **English
   only**. (Change from V2/V3, which stored a manager-language copy via a stub.)
2. **Manager reply → worker's language (shown).** Whatever the manager types in their own
   language is translated into **that worker's local language** and shown/played to the
   worker. (V3 showed it untranslated.)
3. **Voice ticket-ID entry.** On "Check request status," instead of typing, the worker taps
   a mic; the app asks in the local language *"please tell me your ticket number,"* the worker
   **says** the number in their language (e.g. Bengali "এক", English "one"), and the app
   resolves it — no typing.
4. **Web build for the demo.** Produce a web build of the app so it can be shown in a browser
   (not only on an Android device) — see §6.

Features 1 & 2 use the **Sarvam translation API** (§4). Feature 3 needs reliable
**spoken-number recognition**, which is the one piece to validate on-device (§5.1).

---

## 2. Translation model (revised)

| Direction | Source | Stored / shown | Who translates |
|---|---|---|---|
| Worker → manager | worker's spoken text (hi/bn/…) | **English** in `translated_text`; dashboard shows it | backend, on create |
| Manager → worker | manager's typed comment (their language) | **worker's language**, shown/played in My Status & status-by-ticket | backend, when the worker reads it (worker's `language_code` is known) |

- The **verbatim original** is always kept (`original_text` / `original_language`) — unchanged.
- "English only on the dashboard" means the dashboard renders `translated_text` (now English)
  and no longer tries to match a manager language.

### Data-model impact (small)
- `requests.translated_text` now holds **English** (and `translated_language = 'en-IN'`).
- Manager→worker: add a stored translation of the reply in the worker's language, e.g.
  `manager_comment_translated` (+ its language), filled when the comment is saved/served.
  *(Alternative: translate on read. Decide during build; storing is simpler to cache.)*

---

## 3. Feature 1 & 2 — behavior

### 3.1 Worker → English (Feature 1)
On `POST /api/requests`: store `original_text`/`original_language` verbatim, call the
translation engine (`original_language → en`), store the result in `translated_text`. The
manager dashboard already reads `translated_text` — it will now be English. The on-device
`Categorizer` continues to send `categoryKey`/`urgency` as today.

### 3.2 Manager → worker (Feature 2)
When the manager saves a comment (their language), translate it into the **worker's language**
(looked up via the request's worker) and expose that to the worker in **My Requests** and
**status-by-ticket** (shown as text + spoken via TTS). The manager keeps seeing their own
text. This replaces V3's "show the comment as-is / translate on the app."

---

## 4. Translation engine — Sarvam hosted API (decided)

**Engine: [Sarvam Translate API](https://docs.sarvam.ai/api-reference-docs/text/translate)**
(`POST https://api.sarvam.ai/translate`). A hosted Indic translation service — no model hosting,
no GPU/CPU inference infra, just an HTTP call with an API key. Chosen over self-hosted
IndicTrans2 to remove all deployment friction for the demo (gated model downloads, a second
container, CPU latency). Sarvam is an Indian provider (data stays in-region).

### 4.1 How it's wired
- **Auth:** `api-subscription-key` header. Key comes from config (`SARVAM_API_KEY` env →
  `sarvam.api-key`); never hard-coded.
- **Language codes match ours exactly** — `en-IN` / `hi-IN` / `bn-IN` pass straight through as
  `source_language_code` / `target_language_code`; no FLORES mapping needed.
- **Request/response:** body `{ input, source_language_code, target_language_code, model }`
  (model `sarvam-translate:v1`); response field `translated_text`.
- **Java side:** `SarvamTranslationService` implements the existing `TranslationService`
  interface (SPEC_V2 B6) using Spring `RestClient`. Controllers/entities don't change.
- **Graceful fallback:** if the key is blank or a call fails, it returns the original text
  unchanged — so filing a request never breaks on a translation hiccup, and tests need no network.

> No self-hosted translator service, no model files, no second container. Because everything
> stays behind `TranslationService`, we can swap back to self-hosted IndicTrans2 later with no
> app/controller changes.

---

## 5. Feature 3 — voice ticket-ID entry

**Status check is now login-gated** (decided): the worker logs in first, then speaks the
ticket number. Logging in means the app knows the worker's language (from their profile), so
no on-screen language picker is needed, and the voice prompt/recognition use that language.

Flow on **Check request status**:
1. Worker logs in (username + PIN) — same login as filing a request.
2. App speaks, **in the worker's language**: *"Please tell me your ticket number."* (TTS)
3. Worker says the number in their language (Bengali "এক", Hindi "एक", English "one", or multi-digit).
4. App captures via STT (locale = worker's language), **normalizes the spoken number to an
   integer**, and calls `GET /api/requests/{id}` — same result UI as today (shows + speaks status).
5. On no match / unparseable → spoken + on-screen "I couldn't catch the number, please try again,"
   with a **manual text field as a fallback**.

### 5.1 Spoken-number normalization (the tricky bit — POC)
STT output for numbers varies by device/locale: it may return **ASCII digits** ("247"),
**Indic numerals** ("२४७" / "২৪৭"), or **number words** ("two forty seven" / Hindi/Bengali
words). We need a normalizer that handles:
- Indic (Devanagari/Bengali) numerals → ASCII digits.
- Number words → integer, per language (en, hi, bn).
**POC:** on the S23 FE, log what `speech_to_text` returns for spoken ticket numbers in hi-IN /
bn-IN / en-IN, then build the smallest normalizer that covers it.

### 5.2 Language — resolved
**Decided: login first (Option B).** The worker signs in on the status path, so the app uses
their profile language for the TTS prompt and STT locale. This supersedes V3's no-login
ticket lookup — the "Check request status" entry now goes through worker login before the
ticket prompt.

---

## 6. Web build for the demo (Feature 4)

Build and run the Flutter app in a browser so the demo isn't tied to an Android device. The
app's packages (`speech_to_text`, `flutter_tts`, `http`, `flutter_dotenv`) all support web.

What this needs:
- **Add web support** to the project (it was created Android-only — no `web/` folder yet):
  `flutter create --platforms=web .`, then `flutter run -d chrome` (dev) or `flutter build web`
  (produces `build/web/` to serve statically).
- **Backend CORS.** A browser enforces CORS, and the web app's origin differs from the
  backend's (`localhost:<port>` → `localhost:8080`). The backend must allow the web origin
  (add a CORS config for `/api/**` and `/actuator/**`). Without this, every API call fails.
- **Base URL / `.env` for web.** In a browser, `10.0.2.2` is meaningless — set `API_HOST` to
  `localhost` (same machine) or the server's LAN IP/hostname. Avoid HTTPS-page → HTTP-API
  mixed content (serve both over the same scheme for the demo).

Caveats to verify on web:
- **Microphone/speech** needs a secure context — works on `http://localhost` and HTTPS, and
  depends on the browser (Chrome best). The "type instead" / manual fallbacks keep the demo
  working if browser speech is flaky.
- Android-specific bits (manifest permissions, `usesCleartextTraffic`) don't apply to web.

## 7. Implementation tracker

Legend: `[ ]` not started · `[~]` in progress · `[x]` done.

### Step V4-0 — Sarvam translation engine (gates V4-1/2) ✅
- [x] `SarvamTranslationService` (Spring `RestClient`) implements `TranslationService`, calling
      `POST api.sarvam.ai/translate` with `api-subscription-key`; app locale codes pass through.
- [x] Config `sarvam.*` (key via `SARVAM_API_KEY`); blank-key / error → pass-through fallback.
- [x] Removed the self-hosted `aawaaz-translator/` service and the pass-through stub.
- [ ] Validate live with the real key (sample hi/bn↔en) once the backend runs with `SARVAM_API_KEY`.

### Step V4-1 — Worker → English (backend)
- [ ] On create, translate `original_language → en` and store in `translated_text` (`en-IN`),
      regardless of manager language. (Dashboard already reads `translated_text`.)

### Step V4-2 — Manager → worker language (backend)
- [ ] On manager comment, translate → worker's language; store/serve it to the worker.
- [ ] App: My Requests + status-by-ticket show/play the worker-language reply.

### Step V4-3 — Voice number POC
- [ ] Log `speech_to_text` output for spoken ticket numbers (hi/bn/en) on device.
- [ ] Build the spoken-number → integer normalizer (Indic numerals + number words).

### Step V4-4 — Voice ticket entry (app)
- [ ] Gate "Check request status" behind worker login; use the worker's profile language.
- [ ] Mic + TTS prompt ("tell me your ticket number") in that language.
- [ ] Capture → normalize → `GET /api/requests/{id}`; manual typing stays as fallback.

### Step V4-W — Web build (Feature 4, §6)
- [ ] Add web support (`flutter create --platforms=web .`); run via `flutter run -d chrome`.
- [ ] Add backend CORS for `/api/**` + `/actuator/**`.
- [ ] Web `.env` host (`localhost` / server IP); verify mic/speech in the browser.
- [ ] Produce `build/web/` and confirm the full flow works in a browser.

### Step V4-D — Dockerize & deploy (single EC2, §9)
- [ ] `aawaaz-backend/Dockerfile` (JRE, runs the Spring Boot jar); `EXPOSE 8080`.
- [ ] Deploy to the EC2 with `SARVAM_API_KEY` injected at runtime; open 8080; allow outbound
      HTTPS to `api.sarvam.ai`. (`docker run` or an optional single-service compose.)

### Step V4-5 — Polish & verify
- [ ] End-to-end on device: worker speaks (lang) → English on dashboard → manager replies →
      worker hears it in their language → voice ticket lookup works.

**Current status:** Translation engine switched to **Sarvam** and wired into the backend
(`SarvamTranslationService`, V4-0 done); self-hosted translator removed. Next: V4-1 (store
worker requests as English) and V4-2 (translate manager replies to the worker's language).

---

## 8. Decisions & open questions

**Resolved**
- **Engine:** AI4Bharat **IndicTrans2, self-hosted** (MIT, Indic-first, data stays in-country);
  the Java backend calls it over HTTP (§4). (Reversed the earlier self-hosted IndicTrans2 plan
  to remove demo deployment friction; swappable later via the same `TranslationService` seam.) ✅
- **Compute:** no inference infra needed (hosted API) — no GPU/CPU model hosting. ✅
- **Voice status language:** **login first (Option B)** — language comes from the worker's profile (§5). ✅
- **Manager→worker reply:** **store the translated copy** in the worker's language when the comment is saved. ✅
- **Voice numbers:** start with **digits + Indic-numeral normalization**; add spoken number *words* only if the device needs it. ✅

**Open**
- *(none — ready to build; remaining choices have working defaults above.)*

---

## 9. Deployment (single EC2, Docker)

With translation now a hosted API, the server side is **just the backend** — a **single
container** on one EC2. No translator service to run.

### 9.1 Topology
```
                 EC2 host                         Sarvam API (hosted)
          ┌─────────────────────────────┐        api.sarvam.ai/translate
  :8080   │  aawaaz-backend              │ ───────────▶ (HTTPS, api-subscription-key)
 ◀────────┤  (Spring Boot, JRE)         │
 (public) └─────────────────────────────┘
          docker run / docker compose up -d
```

### 9.2 Repo additions (built in Step V4-D)
- `aawaaz-backend/Dockerfile` — multi-stage: build the jar with the Maven wrapper, run it on a
  slim JRE base; `EXPOSE 8080`.
- *(Optional)* a root `docker-compose.yml` with just the backend service, for a one-command
  deploy and easy env injection — or plain `docker run` is enough for one container.

### 9.3 Config & security
- Backend env: **`SARVAM_API_KEY`** (required for live translation) and standard Spring config.
  The key is injected at runtime (env/compose), never baked into the image.
- EC2 **security group**: open `8080` (API) to where the app/demo runs. Outbound HTTPS to
  `api.sarvam.ai` must be allowed.
- The mobile/web app points `API_HOST` at the EC2's public IP/DNS (port `8080`).
- DB stays **in-memory** — data resets if the backend container restarts (fine for the demo).

### 9.4 Sizing
- No local inference, so modest: a small instance (e.g. **`t3.small` / `t3.medium`**) is plenty
  for the JVM; translation latency is Sarvam's network round-trip.
