# aawaaz-face

Self-hosted face-embedding service for Aawaaz (InsightFace / ArcFace `buffalo_l` via ONNX
Runtime, CPU). The Java backend calls it to turn a captured photo into a face embedding; the
backend stores embeddings and does the 1:N match. **Stateless — no storage.**

In production this runs **inside the backend's single container** (V5-4); this folder also
builds standalone for the POC.

## API

```
GET  /health                → {"status":"ok"}
POST /embed                 → {"embedding": [512 floats]}   (L2-normalized ArcFace vector)
     body: {"imageBase64": "<raw base64 or data URL>"}
```

Errors: `400` invalid image; `422` no face / multiple faces detected.

## Run (POC)

```bash
docker build -t aawaaz-face .
docker run --rm -p 8000:8000 aawaaz-face
# then:
curl -s -X POST http://localhost:8000/embed -H 'Content-Type: application/json' \
  -d "{\"imageBase64\":\"$(base64 -w0 some_face.jpg)\"}" | head -c 200
```

The build pre-downloads the `buffalo_l` model (~hundreds of MB), so the first build is slow but
the container then starts offline.

## Matching (done in the backend)

Embeddings are L2-normalized, so **cosine similarity = dot product**. The backend compares a
login embedding against every stored worker embedding and takes the best match if it clears a
threshold (tuned in the POC — ArcFace is typically ~0.35–0.5 cosine).
