# aawaaz-translator

Self-hosted **IndicTrans2** (AI4Bharat, MIT) translation service for Aawaaz. A small FastAPI
app the Java backend calls over HTTP. CPU-only, using the distilled **200M** models.

## API

```
GET  /health                → {"status":"ok"}
POST /translate             → {"translation": "..."}
     body: {"text": "...", "source": "hi-IN", "target": "en-IN"}
```

`source` / `target` are app locale codes: `en-IN`, `hi-IN`, `bn-IN` (mapped internally to
IndicTrans2 FLORES codes `eng_Latn` / `hin_Deva` / `ben_Beng`). `indic → indic` pivots through
English using the two distilled models.

## Hugging Face access (one-time)

The IndicTrans2 models are **gated** on Hugging Face, so the build needs an authenticated token:
1. Create a free account at huggingface.co and a **read** access token (Settings → Access Tokens).
2. Open each model page and click **Agree / access** (usually instant):
   - `ai4bharat/indictrans2-en-indic-dist-200M`
   - `ai4bharat/indictrans2-indic-en-dist-200M`

## Run with Docker (as deployed)

```bash
DOCKER_BUILDKIT=1 docker build --build-arg HF_TOKEN=hf_xxxxxxxx -t aawaaz-translator .
docker run --rm -p 8000:8000 aawaaz-translator
```

The build pre-downloads the two models (hundreds of MB) and bakes them in, so the first build
is slow but the container then starts offline. Test:

```bash
curl -s -X POST http://localhost:8000/translate \
  -H 'Content-Type: application/json' \
  -d '{"text":"मेरे को कल छुट्टी चाहिए","source":"hi-IN","target":"en-IN"}'
```

## Run locally (for the spike)

```bash
python -m venv .venv && source .venv/bin/activate
pip install torch --index-url https://download.pytorch.org/whl/cpu
pip install -r requirements.txt
export HF_TOKEN=hf_xxxxxxxx   # gated models (see above)
uvicorn app:app --host 0.0.0.0 --port 8000
```

## Notes
- **Models:** `ai4bharat/indictrans2-en-indic-dist-200M`, `ai4bharat/indictrans2-indic-en-dist-200M`.
- **`IndicTransToolkit`** provides the required pre/post-processing. If the PyPI build doesn't
  match, install from source: `pip install git+https://github.com/VarunGumma/IndicTransToolkit`.
- `trust_remote_code=True` is required — IndicTrans2 ships custom model/tokenizer code on the Hub.
- CPU latency with `num_beams=5` is a few seconds/translation; lower beams to trade quality for speed.
- **Spike checklist (V4-0):** install deps → models download → translate sample hi/bn↔en phrases →
  record quality + latency + image size. This validation runs on a CPU host (not in CI).
