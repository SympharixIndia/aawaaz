# Aawaaz — V5 Spec (face recognition for worker auth)

*Every worker's voice, on record.*

V5 adds **server-side face recognition** so a worker can register with a live photo and later
log in by simply showing their face — with username + PIN kept as a backup. Builds on V2–V4.
Face matching happens on the **backend** (not the device).

> **Status:** drafting, spec-first. **No code yet.** A face-engine **POC** gates the build (§7).

---

## 1. The idea

- **Register with a face:** the worker enters username, PIN, name, profession, language **and**
  a **live front-camera photo**. The backend computes a **face embedding** and stores it on the
  worker. The **photo itself is not stored** — only the embedding is needed to recognise them.
- **Log in by face:** on "Register a request" and "Check request status," the front camera opens;
  the worker captures a photo; the backend **identifies** the matching worker (1:N) and logs
  them in. **Username + PIN remains a backup** on both screens.
- **Matching is backend-side**, so it's device-independent and centrally tunable.

This is the server-side version of the face recognition deferred in V1.

---

## 2. Decisions (confirmed)

- **Engine:** **self-hosted** — a small **Python** face server (no cloud face API). Proposed
  model: **InsightFace (ArcFace / `buffalo_l`) via ONNX Runtime** (accurate, CPU-capable,
  prebuilt — no dlib build); final pick confirmed in the POC (§7).
- **Packaging:** **one Docker image runs both** the Java backend and the Python face server. The
  Java backend (port 8080) is the single external entry point; it calls the Python server on
  `localhost` **inside the same container**. (Trade-off noted in §9.)
- **Store the embedding only** — no face photo persisted.
- **Login mode:** **1:N identification** (show face → backend finds the worker); no username on
  the face path. **Username + PIN** stays as the backup.
- **Platform:** face login is **Android-only** — not built for web.
- **No anti-spoofing / liveness**, and **no consent/retention** handling — out of scope (hackathon).

*(No open questions — ready to build once the POC confirms the model + threshold.)*

---

## 3. Architecture — one container, two processes

```
                         ┌─ aawaaz backend container ───────────────────────────┐
Flutter app ──▶ :8080 ──▶│  Java backend (Spring Boot)                           │
 (photo, base64)         │     │  http://localhost:8000/embed (in-container)     │
                         │     ▼                                                 │
                         │  Python face server (FastAPI, InsightFace/ONNX)       │
                         │     └─ returns a face embedding (vector)              │
                         └───────────────────────────────────────────────────────┘
```

- The **Python face server** exposes `POST /embed { imageBase64 } → { embedding: [...] }`.
  Detects exactly one face (errors on 0 or >1). Stateless — no DB, no storage.
- The **Java backend** stores embeddings and does the 1:N cosine-similarity match (a few hundred
  workers → trivial in memory).
- Both run in **one image**; a small entrypoint starts the Python server (background) then the
  JVM (foreground). Only `8080` is exposed; the face server stays internal on `localhost:8000`.

---

## 4. Data model change

`users` gains one nullable column:
- `face_embedding` — the stored vector (JSON `float[]`, CLOB).

No photo column. Managers and password-only workers are unaffected (embedding stays null).

---

## 5. API changes

- **Registration — `POST /api/workers`** (extended): also accepts `photoBase64`. The backend
  sends it to the face server, stores the returned **embedding** on the worker (photo discarded).
  No face / multiple faces detected → `400` (retake). Registering without a photo is allowed —
  that worker just won't have face login (PIN only).
- **Face login — `POST /api/auth/face`** (new): body `{ photoBase64 }`. Backend embeds the
  capture, finds the closest stored worker embedding; similarity ≥ threshold → returns that
  `UserDto` (same shape as password login); else `401` "face not recognised."
- **Password login — `POST /api/auth/login`** (unchanged): the backup path.

Images travel as base64 in JSON (fits our existing APIs; note payload size).

---

## 6. App changes (Android)

- **Registration screen:** add a live **front-camera capture** (preview + retake); send
  `photoBase64` with the existing fields. PIN is still required (needed for the backup login).
- **Worker entry (both "Register a request" and "Check request status"):** a **"Scan face"**
  option opens the front camera → capture → `POST /api/auth/face` → on match, continue to the
  destination. A **"Use username & PIN"** link keeps the current login as backup.
- **Camera:** `camera` plugin; add the Android **CAMERA** permission; on permission-denied fall
  back to PIN login.

---

## 7. Face-engine POC (gates the build)

- Stand up the Python face server with the chosen model; `POST /embed` returns an embedding.
- Enrol 2–3 faces, then test login photos: measure **match accuracy**, a sensible **similarity
  threshold**, false accept/reject behaviour, and **CPU latency**.
- Confirm single-face detection and reasonable behaviour on poor lighting / angles.
- Output: a working `/embed` endpoint + the threshold the backend will use.

---

## 8. Deployment (one container)

- **One Dockerfile** builds a combined image: build the Java jar (`mvnw`), then a final stage
  with **both a JRE and Python**, the jar, the face-server code, and the baked-in face model. An
  entrypoint runs the Python server (background) + the JVM (foreground).
- `docker-compose.yml` stays a **single service** built from this image; `docker compose up`
  still starts everything in one command. Only `8080` is published.
- **Trade-off (noted):** two runtimes in one container is less "clean" than two containers, but
  it's the single-point-of-deploy you want and is fine for the demo. If the Python server dies,
  the container should be restarted (compose `restart`).
- The InsightFace model (~hundreds of MB) is baked in → larger image, slower first build; CPU
  face embedding is heavier than translation, so revisit EC2 sizing after the latency spike.

---

## 9. Implementation tracker

Legend: `[ ]` not started · `[~]` in progress · `[x]` done.

### Step V5-0 — Face server POC (gates V5-1+)
- [x] `aawaaz-face/` Python/FastAPI with `POST /embed` + `/health` (InsightFace `buffalo_l`,
      ONNX/CPU); returns an L2-normalized 512-d embedding; 422 on no/multiple faces. Dockerfile
      (model baked in) + README.
- [ ] Spike on a host: build, embed a few faces, pick a cosine threshold, record CPU latency.
      (Can't run in CI — needs the model + real photos.)

### Step V5-1 — Data model ✅
- [x] `users.face_embedding` (CLOB, CSV of floats); `User` entity + schema updated.

### Step V5-2 — Registration with photo
- [x] Backend: `POST /api/workers` accepts optional `photoBase64` → `FaceService.embed` →
      store embedding. Bad photo → 400 (retake); face server down → registers PIN-only.
- [x] App: `camera` plugin + `FaceCaptureScreen` (front-camera preview + capture → base64);
      registration has a "Capture face" step; photo sent with `registerWorker`.

### Step V5-3 — Face login
- [x] Backend: `POST /api/auth/face` → embed → 1:N cosine match ≥ `face.match-threshold`
      (0.40) → `UserResponse` / 401; `FaceService` wraps the face server (`/embed`).
- [x] App: "Scan face" on the worker login (serves both "Register a request" and "Check
      status" via the `destination` builder); username/PIN kept as backup; Android CAMERA permission.

### Step V5-4 — Single-container packaging
- [ ] One combined Dockerfile (JRE + Python + model + entrypoint running both); update compose.
- [ ] Android CAMERA permission; graceful permission-denied fallback.

### Step V5-5 — Verify
- [ ] End-to-end on device: register with face → face login on both worker entries → PIN backup works.

**Current status:** V5-0..V5-3 done — face server, data model, backend enrolment + 1:N face
login, and the app camera flows (registration capture + "Scan face"). Last step: V5-4 (fold the
face server into the single combined container + compose).
