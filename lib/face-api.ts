import * as faceapi from 'face-api.js';

let modelsLoaded = false;

export async function loadModels() {
    if (modelsLoaded) return;

    const MODEL_URL = '/models'; // Store models in public/models directory

    await Promise.all([
        faceapi.nets.ssdMobilenetv1.loadFromUri(MODEL_URL),
        faceapi.nets.faceLandmark68Net.loadFromUri(MODEL_URL),
        faceapi.nets.faceRecognitionNet.loadFromUri(MODEL_URL),
    ]);

    modelsLoaded = true;
}

export async function detectFaceAndGetDescriptor(imageElement: HTMLImageElement): Promise<Float32Array | null> {
    await loadModels();

    const detection = await faceapi
        .detectSingleFace(imageElement)
        .withFaceLandmarks()
        .withFaceDescriptor();

    if (!detection) {
        return null;
    }

    return detection.descriptor;
}

export async function detectAllFacesAndGetDescriptors(imageElement: HTMLImageElement): Promise<Float32Array[]> {
    await loadModels();

    const detections = await faceapi
        .detectAllFaces(imageElement)
        .withFaceLandmarks()
        .withFaceDescriptors();

    return detections.map(d => d.descriptor);
}

export function cosineSimilarity(a: Float32Array, b: Float32Array): number {
    let dotProduct = 0;
    let normA = 0;
    let normB = 0;

    for (let i = 0; i < a.length; i++) {
        dotProduct += a[i] * b[i];
        normA += a[i] * a[i];
        normB += b[i] * b[i];
    }

    return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
}
