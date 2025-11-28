# Pet Detection Service

This service generates image embeddings using a pre-trained ResNet18 model. It is used by the "Find Pet" feature to search for lost pets.

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

-   `GET /`: Health check.
-   `POST /embed`: Upload an image file to get its embedding.
-   `POST /embed-url`: Provide an image URL to get its embedding.
