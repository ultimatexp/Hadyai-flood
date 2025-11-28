from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
import torch
import torchvision.models as models
import torchvision.transforms as transforms
from PIL import Image
import io
import requests
import numpy as np
from sklearn.cluster import KMeans

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

def extract_dominant_colors(image_bytes, n_colors=3):
    """Extract dominant colors from an image using K-means clustering."""
    try:
        img = Image.open(io.BytesIO(image_bytes)).convert('RGB')
        # Resize for faster processing
        img = img.resize((150, 150))
        
        # Convert to numpy array and reshape
        img_array = np.array(img)
        pixels = img_array.reshape(-1, 3)
        
        # Use K-means to find dominant colors
        kmeans = KMeans(n_clusters=n_colors, random_state=42, n_init=10)
        kmeans.fit(pixels)
        
        # Get colors and their proportions
        colors = kmeans.cluster_centers_.astype(int)
        labels = kmeans.labels_
        counts = np.bincount(labels)
        percentages = counts / len(labels)
        
        # Sort by percentage
        sorted_indices = np.argsort(-percentages)
        dominant_colors = colors[sorted_indices].tolist()
        color_percentages = percentages[sorted_indices].tolist()
        
        return {
            "colors": dominant_colors,
            "percentages": color_percentages
        }
    except Exception as e:
        print(f"Error extracting colors: {e}")
        raise HTTPException(status_code=500, detail=f"Error extracting colors: {str(e)}")

def calculate_color_similarity(colors1, percentages1, colors2, percentages2):
    """Calculate similarity between two sets of dominant colors."""
    try:
        total_similarity = 0.0
        
        # Compare each dominant color from image 1 with colors from image 2
        for i, (color1, pct1) in enumerate(zip(colors1, percentages1)):
            color1 = np.array(color1)
            max_color_similarity = 0.0
            
            # Find the most similar color in image 2
            for color2 in colors2:
                color2 = np.array(color2)
                # Calculate Euclidean distance in RGB space
                distance = np.linalg.norm(color1 - color2)
                # Convert distance to similarity (0-1 scale, where 1 is identical)
                # Max distance in RGB space is sqrt(3 * 255^2) ≈ 441
                similarity = max(0, 1 - (distance / 441))
                max_color_similarity = max(max_color_similarity, similarity)
            
            # Weight by the percentage of this color in image 1
            total_similarity += max_color_similarity * pct1
        
        return total_similarity
    except Exception as e:
        print(f"Error calculating color similarity: {e}")
        return 0.0

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
    colors_data = extract_dominant_colors(contents)
    return {
        "embedding": embedding,
        "colors": colors_data["colors"],
        "color_percentages": colors_data["percentages"]
    }

@app.post("/embed-url")
async def create_embedding_url(request: EmbeddingRequest):
    try:
        response = requests.get(request.image_url)
        response.raise_for_status()
        embedding = get_embedding(response.content)
        colors_data = extract_dominant_colors(response.content)
        return {
            "embedding": embedding,
            "colors": colors_data["colors"],
            "color_percentages": colors_data["percentages"]
        }
    except requests.exceptions.RequestException as e:
        raise HTTPException(status_code=400, detail=f"Error fetching image from URL: {str(e)}")

@app.post("/color-similarity")
async def calculate_color_similarity_endpoint(
    file1: UploadFile = File(...),
    file2: UploadFile = File(...)
):
    """Calculate color similarity between two images."""
    try:
        contents1 = await file1.read()
        contents2 = await file2.read()
        
        colors1_data = extract_dominant_colors(contents1)
        colors2_data = extract_dominant_colors(contents2)
        
        similarity = calculate_color_similarity(
            colors1_data["colors"],
            colors1_data["percentages"],
            colors2_data["colors"],
            colors2_data["percentages"]
        )
        
        return {
            "color_similarity": similarity,
            "image1_colors": colors1_data,
            "image2_colors": colors2_data
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error calculating similarity: {str(e)}")
