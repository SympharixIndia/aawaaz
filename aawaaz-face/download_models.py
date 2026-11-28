"""Pre-download the InsightFace model at image-build time so startup is offline.

buffalo_l is ~hundreds of MB; baking it in avoids a first-request download.
"""

from insightface.app import FaceAnalysis

if __name__ == "__main__":
    fa = FaceAnalysis(name="buffalo_l", providers=["CPUExecutionProvider"])
    fa.prepare(ctx_id=-1, det_size=(640, 640))
    print("buffalo_l ready")
