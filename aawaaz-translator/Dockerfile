# IndicTrans2 translation service (CPU). Internal to the compose network (port 8000).
FROM python:3.11-slim

WORKDIR /app

# git is needed if IndicTransToolkit must be installed from source.
RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
# CPU-only torch from the official CPU wheel index, then the rest.
RUN pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu \
    && pip install --no-cache-dir -r requirements.txt

# Bake the model weights into the image so startup needs no network.
# The IndicTrans2 models are gated on Hugging Face — pass a read token:
#   sudo DOCKER_BUILDKIT=1 docker build --build-arg HF_TOKEN=hf_xxx -t aawaaz-translator .
# HF_TOKEN is used only for this build step; it is not persisted as an image ENV.
ARG HF_TOKEN
COPY download_models.py .
RUN HF_TOKEN=${HF_TOKEN} python download_models.py

COPY app.py .

EXPOSE 8000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
