import { NextRequest, NextResponse } from 'next/server';
import { GoogleGenerativeAI } from '@google/generative-ai';

// Initialize Gemini API
const apiKey = process.env.GOOGLE_GENERATIVE_AI_API_KEY || process.env.GEMINI_API_KEY;
if (!apiKey) {
    console.error("Missing Gemini API Key");
}
const genAI = new GoogleGenerativeAI(apiKey || 'DUMMY_KEY'); // Prevent crash on init, but will fail on call if invalid

function extractJsonObject(text: string): string | null {
    const cleaned = text
        .replace(/```json\s*/gi, '')
        .replace(/```/g, '')
        .trim();
    const first = cleaned.indexOf('{');
    const last = cleaned.lastIndexOf('}');
    if (first === -1 || last === -1 || last <= first) return null;
    return cleaned.slice(first, last + 1);
}

function normalizePetAnalysis(data: any) {
    if (!data || typeof data !== 'object') {
        return { ok: false as const, reason: 'not_object' as const };
    }

    const speciesRaw = typeof data.species === 'string' ? data.species.toLowerCase().trim() : null;
    if (data.not_dog_or_cat === true) {
        return { ok: false as const, reason: 'not_dog_or_cat' as const };
    }
    if (!speciesRaw || !['dog', 'cat'].includes(speciesRaw)) {
        return { ok: false as const, reason: 'not_dog_or_cat' as const };
    }

    return {
        ok: true as const,
        data: {
            ...data,
            species: speciesRaw === 'dog' ? 'dog' : 'cat',
        },
    };
}

async function callGeminiWithRetry(
    model: ReturnType<GoogleGenerativeAI['getGenerativeModel']>,
    parts: any[],
    retries = 1
) {
    let lastErr: any;
    for (let i = 0; i <= retries; i++) {
        try {
            return await model.generateContent(parts);
        } catch (e: any) {
            lastErr = e;
            const msg = String(e?.message || e || '').toLowerCase();
            const retryable =
                msg.includes('timeout') ||
                msg.includes('temporar') ||
                msg.includes('unavailable') ||
                msg.includes('overloaded') ||
                msg.includes('503') ||
                msg.includes('429');
            if (!retryable || i === retries) break;
            await new Promise((r) => setTimeout(r, 450));
        }
    }
    throw lastErr;
}

export async function POST(request: NextRequest) {
    try {
        const formData = await request.formData();
        const file = formData.get('image') as File;

        if (!file) {
            return NextResponse.json(
                { success: false, error: 'Missing image', code: 'MISSING_IMAGE' },
                { status: 400 }
            );
        }

        // Convert file to base64
        const arrayBuffer = await file.arrayBuffer();
        const buffer = Buffer.from(arrayBuffer);
        const base64Image = buffer.toString('base64');

        if (!apiKey) {
            return NextResponse.json(
                {
                    success: false,
                    error: 'Server configuration error: Missing AI API Key',
                    code: 'MISSING_SERVER_GEMINI_KEY',
                },
                { status: 500 }
            );
        }

        // Use Gemini 2.0 Flash
        const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash-001" });

        const prompt = `
        Analyze this pet image and return a JSON object with comprehensive characteristics.
        Do not include markdown formatting, just the raw JSON.
        
        Required fields:
        - species: exactly "dog" or "cat" (this app only supports lost/found dogs and cats). If the pet is not clearly a domestic dog or domestic cat, set species to null and set "not_dog_or_cat": true
        - color_main: Primary color ("black", "white", "orange", "gray", "brown", "mixed")
        - color_secondary: Secondary color if present, otherwise null
        - color_pattern: Pattern type ("solid", "tabby", "calico", "tuxedo", "bicolor", "tortie", "pointed", "spotted")
        - fur_length: "short", "medium", "long", or "hairless"
        - eye_color: Color of eyes ("yellow", "green", "blue", "copper", "odd-eye", or null if not visible)
        
        Body features (use null if not visible or applicable):
        - ear_shape: "pointy", "folded", or "cropped"
        - tail_type: "long", "short", "kinked", or "bobtail"
        
        Unique marks (use null if not present):
        - special_marks: Free text description of any distinctive features
        - white_patch_location: Array of locations like ["chest", "nose", "paws", "tail"], or null
        - injury_or_scar: Description of visible injuries/scars, or null  
        - heterochromia: true if eyes are different colors, false otherwise
        
        Accessories (use null if not present):
        - collar_color: Color of collar if visible, otherwise null
        - has_collar: true if wearing a collar, false otherwise
        - collar_type: "cloth", "leather", or "reflective" if visible, otherwise null
        - has_tag: true if tag/charm visible on collar, false otherwise
        - clothes: Description of any clothing/vest, or null
        
        Additional:
        - pose: Current pose ("standing", "sitting", "sleeping", "lying")
        - quality: Image quality ("good", "blur", "dark", "partial")
        - description: A concise 1-sentence description of the pet
        `;

        let result;
        try {
            result = await callGeminiWithRetry(model, [
                prompt,
                {
                    inlineData: {
                        data: base64Image,
                        mimeType: file.type || 'image/jpeg',
                    },
                },
            ], 1);
        } catch (e: any) {
            console.error('Gemini call failed:', e);
            return NextResponse.json(
                {
                    success: false,
                    error: 'Temporary AI service unavailable',
                    code: 'AI_TEMPORARY_UNAVAILABLE',
                    detail: e?.message ?? 'unknown',
                },
                { status: 503 }
            );
        }

        const response = await result.response;
        const text = response.text();
        const jsonString = extractJsonObject(text);
        if (!jsonString) {
            console.error('No JSON found in Gemini response:', text);
            return NextResponse.json(
                { success: false, error: 'Failed to parse AI response', code: 'AI_PARSE_FAILED' },
                { status: 502 }
            );
        }

        let parsed: any;
        try {
            parsed = JSON.parse(jsonString);
        } catch (e) {
            console.error('Failed to parse Gemini JSON:', jsonString);
            return NextResponse.json(
                { success: false, error: 'Failed to parse AI response', code: 'AI_PARSE_FAILED' },
                { status: 502 }
            );
        }

        if (parsed?.error) {
            const err = String(parsed.error);
            const lowered = err.toLowerCase();
            const code = lowered.includes('dog or cat')
                ? 'NOT_DOG_OR_CAT'
                : lowered.includes('not a pet')
                    ? 'NOT_A_PET'
                    : 'AI_REJECTED';
            return NextResponse.json(
                { success: false, error: err, code },
                { status: 400 }
            );
        }

        const normalized = normalizePetAnalysis(parsed);
        if (!normalized.ok) {
            if (normalized.reason === 'not_dog_or_cat') {
                return NextResponse.json(
                    {
                        success: false,
                        error: 'This service only supports dogs and cats. Please use a clear photo of a dog or cat.',
                        code: 'NOT_DOG_OR_CAT',
                    },
                    { status: 400 }
                );
            }
            return NextResponse.json(
                { success: false, error: 'Invalid AI response format', code: 'AI_INVALID_SCHEMA' },
                { status: 502 }
            );
        }

        return NextResponse.json({ success: true, data: normalized.data });

    } catch (error: any) {
        console.error('Error analyzing pet:', error);
        return NextResponse.json(
            {
                success: false,
                error: error.message || 'Failed to analyze image',
                code: 'ANALYZE_PET_UNEXPECTED',
            },
            { status: 500 }
        );
    }
}
