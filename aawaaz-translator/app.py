"""Aawaaz translation service — self-hosted IndicTrans2 (CPU).

A tiny FastAPI wrapper the Java backend calls over HTTP:

    POST /translate  { "text": "...", "source": "hi-IN", "target": "en-IN" }
    ->               { "translation": "..." }

`source`/`target` are the app's locale codes (en-IN / hi-IN / bn-IN); they are
mapped internally to IndicTrans2 FLORES codes. Two distilled 200M models are
loaded (en->indic and indic->en); indic->indic pivots through English.

Models (AI4Bharat, MIT):
  - ai4bharat/indictrans2-en-indic-dist-200M
  - ai4bharat/indictrans2-indic-en-dist-200M
"""

from contextlib import asynccontextmanager

import torch
from fastapi import FastAPI
from pydantic import BaseModel
from transformers import AutoModelForSeq2SeqLM, AutoTokenizer

from IndicTransToolkit.processor import IndicProcessor

EN_INDIC_MODEL = "ai4bharat/indictrans2-en-indic-dist-200M"
INDIC_EN_MODEL = "ai4bharat/indictrans2-indic-en-dist-200M"

# App locale code -> IndicTrans2 FLORES code.
LOCALE_TO_FLORES = {
    "en-IN": "eng_Latn", "en": "eng_Latn",
    "hi-IN": "hin_Deva", "hi": "hin_Deva",
    "bn-IN": "ben_Beng", "bn": "ben_Beng",
}

_state: dict = {}


def _load(name: str):
    tokenizer = AutoTokenizer.from_pretrained(name, trust_remote_code=True)
    model = AutoModelForSeq2SeqLM.from_pretrained(name, trust_remote_code=True)
    model.eval()
    return tokenizer, model


@asynccontextmanager
async def lifespan(_app: FastAPI):
    # Load models + processor once at startup (CPU).
    _state["processor"] = IndicProcessor(inference=True)
    _state["en_indic"] = _load(EN_INDIC_MODEL)
    _state["indic_en"] = _load(INDIC_EN_MODEL)
    yield
    _state.clear()


app = FastAPI(title="Aawaaz Translator", lifespan=lifespan)


class TranslateRequest(BaseModel):
    text: str
    source: str
    target: str


class TranslateResponse(BaseModel):
    translation: str


def _run(text: str, src_flores: str, tgt_flores: str, model_key: str) -> str:
    tokenizer, model = _state[model_key]
    ip = _state["processor"]

    batch = ip.preprocess_batch([text], src_lang=src_flores, tgt_lang=tgt_flores)
    inputs = tokenizer(
        batch,
        truncation=True,
        padding="longest",
        return_tensors="pt",
        max_length=256,
    )
    with torch.no_grad():
        generated = model.generate(
            **inputs,
            num_beams=5,
            num_return_sequences=1,
            max_length=256,
        )
    decoded = tokenizer.batch_decode(generated, skip_special_tokens=True)
    return ip.postprocess_batch(decoded, lang=tgt_flores)[0]


def translate(text: str, source: str, target: str) -> str:
    src = LOCALE_TO_FLORES.get(source)
    tgt = LOCALE_TO_FLORES.get(target)

    # Nothing to do: empty, unknown language, or same language.
    if not text or not text.strip() or src is None or tgt is None or src == tgt:
        return text

    if src == "eng_Latn":
        return _run(text, src, tgt, "en_indic")
    if tgt == "eng_Latn":
        return _run(text, src, tgt, "indic_en")

    # indic -> indic: pivot through English with the two distilled models.
    via_english = _run(text, src, "eng_Latn", "indic_en")
    return _run(via_english, "eng_Latn", tgt, "en_indic")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/translate", response_model=TranslateResponse)
def do_translate(req: TranslateRequest):
    return TranslateResponse(translation=translate(req.text, req.source, req.target))
