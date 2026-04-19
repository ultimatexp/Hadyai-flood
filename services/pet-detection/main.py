from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
import torch
import open_clip
from PIL import Image
import io
import requests
import numpy as np
from sklearn.cluster import KMeans
from skimage.color import rgb2lab, deltaE_ciede2000

app = FastAPI()

# ──────────────────────────────────────────────
# 1. Load CLIP ViT-L/14  (768-dim, upgraded from ViT-B/32 512-dim)
# ──────────────────────────────────────────────
model, _, preprocess = open_clip.create_model_and_transforms(
    'ViT-L-14', pretrained='laion2b_s32b_b82k'
)
model.eval()


# ──────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────

class EmbeddingRequest(BaseModel):
    image_url: str


@app.get("/")
def read_root():
    return {"status": "ok", "service": "pet-detection", "model": "CLIP-ViT-L-14"}


def _center_crop_pil(img: Image.Image, margin_ratio: float = 0.2) -> Image.Image:
    """Crop away outer margins so embeddings focus on the subject (same idea as color extraction)."""
    w, h = img.size
    margin_w, margin_h = int(w * margin_ratio), int(h * margin_ratio)
    return img.crop((margin_w, margin_h, w - margin_w, h - margin_h))


def get_embedding(image_bytes: bytes) -> list[float]:
    """Generate a 768-dim L2-normalised CLIP embedding from raw image bytes."""
    try:
        img = Image.open(io.BytesIO(image_bytes)).convert('RGB')
        img = _center_crop_pil(img, margin_ratio=0.2)
        img_tensor = preprocess(img).unsqueeze(0)          # [1, 3, 224, 224]

        with torch.no_grad():
            features = model.encode_image(img_tensor)       # [1, 512]
            features /= features.norm(dim=-1, keepdim=True) # L2-normalise

        return features.squeeze().tolist()
    except Exception as e:
        print(f"Error processing image: {e}")
        raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")


# ──────────────────────────────────────────────
# 2. LAB Color Extraction  (perceptually-uniform)
# ──────────────────────────────────────────────

def extract_dominant_colors(image_bytes: bytes, n_colors: int = 3):
    """
    Extract dominant colors using K-Means in CIELAB space.
    Returns both LAB centroids and their RGB equivalents for display.
    """
    try:
        img = Image.open(io.BytesIO(image_bytes)).convert('RGB')
        img = img.resize((150, 150))

        img_array = np.array(img, dtype=np.float64)

        # Center-crop the inner 60% to reduce background influence
        h, w = img_array.shape[:2]
        margin_h, margin_w = int(h * 0.2), int(w * 0.2)
        cropped = img_array[margin_h:h - margin_h, margin_w:w - margin_w]

        # Convert to CIELAB (expects float64 in [0, 1])
        lab_image = rgb2lab(cropped / 255.0)
        lab_pixels = lab_image.reshape(-1, 3)

        # K-Means in LAB space
        kmeans = KMeans(n_clusters=n_colors, random_state=42, n_init=10)
        kmeans.fit(lab_pixels)

        lab_centers = kmeans.cluster_centers_   # shape (n, 3)
        labels = kmeans.labels_
        counts = np.bincount(labels)
        percentages = counts / len(labels)

        # Sort by percentage (dominant first)
        sorted_idx = np.argsort(-percentages)
        lab_centers = lab_centers[sorted_idx]
        percentages = percentages[sorted_idx]

        # Also return RGB equivalents for display / backward compat
        rgb_pixels = cropped.reshape(-1, 3)
        rgb_centers = []
        for cluster_id in sorted_idx:
            mask = labels == cluster_id
            cluster_rgb = rgb_pixels[mask].mean(axis=0).astype(int)
            rgb_centers.append(cluster_rgb.tolist())

        return {
            "colors": rgb_centers,                    # RGB for display
            "lab_colors": lab_centers.tolist(),        # LAB for matching
            "percentages": percentages.tolist(),
        }
    except Exception as e:
        print(f"Error extracting colors: {e}")
        raise HTTPException(status_code=500, detail=f"Error extracting colors: {str(e)}")


def calculate_color_similarity_lab(
    lab1: list[list[float]], pct1: list[float],
    lab2: list[list[float]], pct2: list[float],
) -> float:
    """
    Perceptually-accurate color similarity using CIEDE2000 in LAB space.
    Returns a float in [0, 1] where 1 = identical.
    """
    try:
        total_sim = 0.0
        lab1_arr = np.array(lab1)
        lab2_arr = np.array(lab2)

        for i in range(len(lab1_arr)):
            best = 0.0
            for j in range(len(lab2_arr)):
                # deltaE_ciede2000 expects (L, a, b) shaped arrays
                de = deltaE_ciede2000(
                    lab1_arr[i].reshape(1, 3),
                    lab2_arr[j].reshape(1, 3),
                )[0]
                # Convert Delta-E to similarity: DE=0 → 1.0, DE=100 → 0.0
                sim = max(0.0, 1.0 - de / 100.0)
                best = max(best, sim)
            total_sim += best * pct1[i]

        return float(total_sim)
    except Exception as e:
        print(f"Error calculating LAB color similarity: {e}")
        return 0.0


# ──────────────────────────────────────────────
# 3. API Endpoints
# ──────────────────────────────────────────────

@app.post("/embed")
async def create_embedding_file(file: UploadFile = File(...)):
    contents = await file.read()
    embedding = get_embedding(contents)
    colors_data = extract_dominant_colors(contents)
    return {
        "embedding": embedding,
        "colors": colors_data["colors"],               # RGB (backward compat)
        "lab_colors": colors_data["lab_colors"],        # LAB (new)
        "color_percentages": colors_data["percentages"],
    }


@app.post("/embed-url")
async def create_embedding_url(request: EmbeddingRequest):
    try:
        response = requests.get(request.image_url, timeout=30)
        response.raise_for_status()
        embedding = get_embedding(response.content)
        colors_data = extract_dominant_colors(response.content)
        return {
            "embedding": embedding,
            "colors": colors_data["colors"],
            "lab_colors": colors_data["lab_colors"],
            "color_percentages": colors_data["percentages"],
        }
    except requests.exceptions.RequestException as e:
        raise HTTPException(status_code=400, detail=f"Error fetching image from URL: {str(e)}")


@app.post("/color-similarity")
async def calculate_color_similarity_endpoint(
    file1: UploadFile = File(...),
    file2: UploadFile = File(...),
):
    """Calculate perceptual color similarity (CIEDE2000) between two images."""
    try:
        contents1 = await file1.read()
        contents2 = await file2.read()

        c1 = extract_dominant_colors(contents1)
        c2 = extract_dominant_colors(contents2)

        similarity = calculate_color_similarity_lab(
            c1["lab_colors"], c1["percentages"],
            c2["lab_colors"], c2["percentages"],
        )

        return {
            "color_similarity": similarity,
            "image1_colors": c1,
            "image2_colors": c2,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error calculating similarity: {str(e)}")
