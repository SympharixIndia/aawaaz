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

Features 1 & 2 both need a **translation engine**; feature 3 needs reliable **spoken-number
recognition**. Both are unproven on our stack, so V4 starts with POCs (§4, §7).

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

## 4. Translation engine — IndicTrans2, self-hosted (decided)

**Engine: [AI4Bharat IndicTrans2](https://github.com/ai4bharat/IndicTrans2)**, **self-hosted**.
MIT-licensed, Indic-first, supports hi/bn ↔ en in both directions. Self-hosting means **no
per-call cost, no API key, and all data stays in-country** (worker voice/text is sensitive) —
which is why we chose it over hosted options (Bhashini/Google/Azure).

### 4.1 Architecture
IndicTrans2 is Python; our backend is Java. So we run a **small Python inference service** and
the Java backend calls it over HTTP:

```
Flutter app ──▶ Java backend (Spring Boot)
                    │  TranslationService (HTTP impl)
                    ▼
            IndicTrans2 service (Python / FastAPI)  ──  loads the models, returns translations
```

- **Models:** the **distilled ~200M** checkpoints via **CTranslate2** for CPU inference
  (`indic-en` for worker→English, `en-indic` for English→worker-language), with
  IndicTransToolkit for pre/post-processing. Distilled + CT2 keeps it CPU-viable for the demo;
  a GPU host is an optional speed-up.
- **Service API:** a tiny `POST /translate { text, source, target } → { translation }`.
- **Manager→worker when the manager isn't English:** pivot through English
  (`indic → en → indic`) so only the two distilled models are needed (no separate
  indic↔indic model).
- **Java side:** replace the `PassThroughTranslationService` stub with an HTTP client impl of
  the existing `TranslationService` interface (SPEC_V2 B6); the service URL is configurable.
  Controllers/entities don't change.

### 4.2 Spike (validate, not choose)
A short spike to de-risk, since the engine is already chosen: stand up the Python service with
the distilled CT2 models, translate 8–10 sample Hindi/Bengali worker phrases → English and a
few English manager replies → hi/bn, and check **quality, CPU latency, and the model
download/footprint**. Output: a working `/translate` endpoint the Java backend can call.

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

### Step V4-0 — IndicTrans2 service (gates V4-1/2)
- [x] `aawaaz-translator/` service scaffolded — FastAPI `GET /health` + `POST /translate`
      (distilled 200M models, IndicTransToolkit, en↔indic + indic↔indic via English pivot),
      with `Dockerfile` (CPU torch, models baked in) and README.
- [ ] Spike on a CPU host: `pip install` + model download, translate sample hi/bn↔en phrases,
      record quality, CPU latency, and image size. (Can't run in CI — needs the model weights.)

### Step V4-1 — Worker → English (backend)
- [ ] Replace the `TranslationService` stub with an HTTP client to the IndicTrans2 service.
- [ ] On create, translate `original_language → en`, store in `translated_text` (`en-IN`).
- [ ] Dashboard shows English (already reads `translated_text`).

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
- [ ] `aawaaz-backend/Dockerfile` (JRE, runs the Spring Boot jar).
- [ ] `aawaaz-translator/` Python service (FastAPI + CT2 + IndicTrans2) + its `Dockerfile`.
- [ ] Root `docker-compose.yml` wiring both; backend → translator via env URL.
- [ ] Deploy to the EC2 (`docker compose up -d`); open 8080, keep translator internal.

### Step V4-5 — Polish & verify
- [ ] End-to-end on device: worker speaks (lang) → English on dashboard → manager replies →
      worker hears it in their language → voice ticket lookup works.

**Current status:** V4 plan finalized; **V4-0 translator service scaffolded**
(`aawaaz-translator/`). Next: run the CPU spike (model download + latency) on a host, then
V4-1 (wire the Java backend's `TranslationService` to it).

---

## 8. Decisions & open questions

**Resolved**
- **Engine:** AI4Bharat **IndicTrans2, self-hosted** (MIT, Indic-first, data stays in-country);
  Python/FastAPI inference service called by the Java backend (§4). ✅
- **Compute:** **CPU-only** (no GPU) — distilled CT2 models; a few seconds/translation is acceptable. ✅
- **Voice status language:** **login first (Option B)** — language comes from the worker's profile (§5). ✅
- **Manager→worker reply:** **store the translated copy** in the worker's language when the comment is saved. ✅
- **Voice numbers:** start with **digits + Indic-numeral normalization**; add spoken number *words* only if the device needs it. ✅

**Open**
- *(none — ready to build; remaining choices have working defaults above.)*

---

## 9. Deployment (single EC2, Docker)

Both server-side services run on **one EC2**, but as **two containers** orchestrated by a
single `docker-compose.yml` — **not** one container running both. Different runtimes (JRE vs.
Python+ML), independent build/restart, and clean logs make two images the right call; compose
keeps it a one-command deploy.

### 9.1 Topology
```
                 EC2 host
          ┌───────────────────────────────────────────┐
  :8080   │  aawaaz-backend  (Spring Boot, JRE)         │
 ◀────────┤       │  http://translator:8000 (internal)  │
 (public) │       ▼                                     │
          │  aawaaz-translator (FastAPI + CT2 +         │
          │       IndicTrans2 distilled models)  :8000  │  ← not exposed publicly
          └───────────────────────────────────────────┘
          docker compose up -d   (private bridge network)
```

### 9.2 Repo additions (built in Step V4-D)
- `aawaaz-backend/Dockerfile` — multi-stage: build the jar with the Maven wrapper, run it on a
  slim JRE base; `EXPOSE 8080`.
- `aawaaz-translator/` — the Python service: `app.py` (FastAPI, `POST /translate`),
  `requirements.txt` (ctranslate2, transformers/sentencepiece, IndicTransToolkit, fastapi,
  uvicorn), and a `Dockerfile` on a `python:3.x-slim` base.
- `docker-compose.yml` (repo root) — defines both services on one network.

### 9.3 Compose wiring
- **backend**: `build: ./aawaaz-backend`, `ports: ["8080:8080"]`, env
  `TRANSLATION_SERVICE_URL=http://translator:8000`, `depends_on: [translator]`.
- **translator**: `build: ./aawaaz-translator`, **no public port** (only reachable in-network
  as `translator:8000`); model weights baked into the image **or** mounted as a volume to keep
  the image smaller and startup flexible.
- Both on a private bridge network so the backend reaches the translator by service name.

### 9.4 Config & security
- Backend reads `TRANSLATION_SERVICE_URL` (new property/env) — the HTTP `TranslationService`
  impl targets it; defaults to `http://localhost:8000` for local dev.
- EC2 **security group**: open `8080` (API) to where the app/demo runs; keep `8000` closed
  (translator is internal only).
- The mobile/web app points `API_HOST` at the EC2's public IP/DNS (port `8080`).
- DB stays **in-memory** — data resets if the backend container restarts (fine for the demo).

### 9.5 Sizing
- Distilled CT2 models run on **CPU**; budget a few GB RAM for the translator. Start around a
  **`t3.large` (2 vCPU / 8 GB)**; revisit after the latency spike (§4.2). GPU only if we later
  want the full 1B models.
