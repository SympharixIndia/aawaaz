"""Pre-download the IndicTrans2 distilled models at image-build time.

Baking the weights into the image means the container starts fast and needs no
network at runtime (per SPEC_V4 §9). Run by the Dockerfile.

The AI4Bharat models are **gated** on Hugging Face: accept access on each model
page once, then supply a read token via the HF_TOKEN env var (the Dockerfile
passes it in as a build arg).
"""

import os

from transformers import AutoModelForSeq2SeqLM, AutoTokenizer

MODELS = [
    "ai4bharat/indictrans2-en-indic-dist-200M",
    "ai4bharat/indictrans2-indic-en-dist-200M",
]

if __name__ == "__main__":
    token = os.environ.get("HF_TOKEN")
    if not token:
        raise SystemExit(
            "HF_TOKEN is not set. The IndicTrans2 models are gated — create a "
            "Hugging Face token, accept access on each model page, and pass it "
            "with --build-arg HF_TOKEN=hf_xxx."
        )
    for name in MODELS:
        print(f"Downloading {name} ...")
        AutoTokenizer.from_pretrained(name, trust_remote_code=True, token=token)
        AutoModelForSeq2SeqLM.from_pretrained(name, trust_remote_code=True, token=token)
    print("Models cached.")
