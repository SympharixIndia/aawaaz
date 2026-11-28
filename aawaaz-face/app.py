"""Aawaaz face server — self-hosted face embedding (InsightFace / ONNX, CPU).

A tiny FastAPI service the Java backend calls (in the same container):

    POST /embed  { "imageBase64": "..." }  ->  { "embedding": [512 floats] }

Detects exactly one face and returns its L2-normalized ArcFace embedding, so the
backend can compare embeddings with a plain dot product (= cosine similarity).
Stateless — no storage; the backend owns enrolment and matching.
"""

import base64
import io
from contextlib import asynccontextmanager

import numpy as np
from fastapi import FastAPI, HTTPException
from PIL import Image
from pydantic import BaseModel

from insightface.app import FaceAnalysis

_state: dict = {}


@asynccontextmanager
async def lifespan(_app: FastAPI):
    fa = FaceAnalysis(name="buffalo_l", providers=["CPUExecutionProvider"])
    fa.prepare(ctx_id=-1, det_size=(640, 640))  # ctx_id=-1 → CPU
    _state["fa"] = fa
    yield
    _state.clear()


app = FastAPI(title="Aawaaz Face", lifespan=lifespan)


class EmbedRequest(BaseModel):
    imageBase64: str


class EmbedResponse(BaseModel):
    embedding: list[float]


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/embed", response_model=EmbedResponse)
def embed(req: EmbedRequest):
    try:
        raw = base64.b64decode(_strip_data_url(req.imageBase64))
        image = Image.open(io.BytesIO(raw)).convert("RGB")
    except Exception as e:  # noqa: BLE001
        raise HTTPException(status_code=400, detail="Invalid image") from e

    # InsightFace expects BGR.
    bgr = np.array(image)[:, :, ::-1]
    faces = _state["fa"].get(bgr)
    if len(faces) == 0:
        raise HTTPException(status_code=422, detail="No face detected")
    if len(faces) > 1:
        raise HTTPException(status_code=422, detail="Multiple faces detected")

    embedding = faces[0].normed_embedding  # 512-d, L2-normalized
    return EmbedResponse(embedding=[float(x) for x in embedding])


def _strip_data_url(s: str) -> str:
    # Accept raw base64 or a data URL ("data:image/jpeg;base64,....").
    return s.split(",", 1)[1] if s.startswith("data:") else s
