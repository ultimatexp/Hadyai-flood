# Pet Detection Service

This service generates image embeddings using **CLIP ViT-B/32** (OpenCLIP, pretrained on LAION-2B) and extracts dominant colors in **CIELAB** color space for perceptually-accurate pet matching.

## Model Details

| Property | Value |
|----------|-------|
| Model | CLIP ViT-B/32 |
| Pretrained | laion2b_s34b_b79k |
| Embedding dim | 512 (L2-normalized) |
| Color space | CIELAB (CIEDE2000 Delta-E) |
| Color clusters | 3 (K-Means, center-cropped) |

## Requirements

- Python 3.10, 3.11, or 3.12 (Python 3.13 is currently not supported by PyTorch)
- CUDA (optional, for GPU support)

## Setup

1.  Navigate to the service directory:
    ```bash
    cd services/pet-detection
    ```

2.  Create a virtual environment (recommended):
    ```bash
    python3.11 -m venv venv
    source venv/bin/activate
    ```

3.  Install dependencies:
    ```bash
    pip install -r requirements.txt
    ```

## Running the Service

Start the FastAPI server:

```bash
uvicorn main:app --reload --port 8000
```

The service will be available at `http://127.0.0.1:8000`.

## API Endpoints

-   `GET /`: Health check (returns model name).
-   `POST /embed`: Upload an image file to get its 512-dim CLIP embedding + LAB colors.
-   `POST /embed-url`: Provide an image URL to get its embedding + LAB colors.
-   `POST /color-similarity`: Upload two images to get CIEDE2000 color similarity.

## Response Format

```json
{
  "embedding": [0.012, -0.034, ...],        // 512-dim L2-normalized
  "colors": [[200, 150, 80], ...],           // RGB (for display)
  "lab_colors": [[65.2, 12.1, 40.3], ...],  // CIELAB (for matching)
  "color_percentages": [0.55, 0.30, 0.15]   // Ratio per cluster
}
```
