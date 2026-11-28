# Standalone image for the face server (POC / local). In V5-4 this is folded into
# the single combined backend image.
FROM python:3.11-slim

WORKDIR /app

# OpenCV runtime libs.
RUN apt-get update \
    && apt-get install -y --no-install-recommends libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Bake the InsightFace model into the image.
COPY download_models.py .
RUN python download_models.py

COPY app.py .

EXPOSE 8000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
