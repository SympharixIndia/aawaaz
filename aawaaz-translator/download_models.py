"""Pre-download the IndicTrans2 distilled models at image-build time.

Baking the weights into the image means the container starts fast and needs no
network at runtime (per SPEC_V4 §9). Run by the Dockerfile.
"""

from transformers import AutoModelForSeq2SeqLM, AutoTokenizer

MODELS = [
    "ai4bharat/indictrans2-en-indic-dist-200M",
    "ai4bharat/indictrans2-indic-en-dist-200M",
]

if __name__ == "__main__":
    for name in MODELS:
        print(f"Downloading {name} ...")
        AutoTokenizer.from_pretrained(name, trust_remote_code=True)
        AutoModelForSeq2SeqLM.from_pretrained(name, trust_remote_code=True)
    print("Models cached.")
