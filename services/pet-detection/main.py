from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
import torch
import torchvision.models as models
import torchvision.transforms as transforms
from PIL import Image
import io
import requests
import numpy as np

app = FastAPI()

# Load pre-trained ResNet18 model
# We use ResNet18 for a good balance of speed and accuracy
model = models.resnet18(pretrained=True)
# Remove the last fully connected layer to get the embedding (512 dimensions)
model = torch.nn.Sequential(*(list(model.children())[:-1]))
model.eval()

# Define image transformations
preprocess = transforms.Compose([
    transforms.Resize(256),
    transforms.CenterCrop(224),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
])

class EmbeddingRequest(BaseModel):
    image_url: str

@app.get("/")
def read_root():
    return {"status": "ok", "service": "pet-detection"}

def get_embedding(image_bytes):
    try:
        img = Image.open(io.BytesIO(image_bytes)).convert('RGB')
        img_tensor = preprocess(img)
        img_tensor = img_tensor.unsqueeze(0)  # Add batch dimension

        with torch.no_grad():
            embedding = model(img_tensor)
        
        # Flatten the embedding
        embedding_np = embedding.squeeze().numpy()
        return embedding_np.tolist()
    except Exception as e:
        print(f"Error processing image: {e}")
        raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")

@app.post("/embed")
async def create_embedding_file(file: UploadFile = File(...)):
    contents = await file.read()
    embedding = get_embedding(contents)
    return {"embedding": embedding}

@app.post("/embed-url")
async def create_embedding_url(request: EmbeddingRequest):
    try:
        response = requests.get(request.image_url)
        response.raise_for_status()
        embedding = get_embedding(response.content)
        return {"embedding": embedding}
    except requests.exceptions.RequestException as e:
        raise HTTPException(status_code=400, detail=f"Error fetching image from URL: {str(e)}")
