import { NextRequest, NextResponse } from 'next/server';
import { GoogleGenerativeAI } from '@google/generative-ai';

// Initialize Gemini API
const apiKey = process.env.GOOGLE_GENERATIVE_AI_API_KEY || process.env.GEMINI_API_KEY;
if (!apiKey) {
    console.error("Missing Gemini API Key");
}
const genAI = new GoogleGenerativeAI(apiKey || 'DUMMY_KEY'); // Prevent crash on init, but will fail on call if invalid

export async function POST(request: NextRequest) {
    try {
        const formData = await request.formData();
        const file = formData.get('image') as File;

        if (!file) {
            return NextResponse.json(
                { success: false, error: 'Missing image' },
                { status: 400 }
            );
        }

        // Convert file to base64
        const arrayBuffer = await file.arrayBuffer();
        const buffer = Buffer.from(arrayBuffer);
        const base64Image = buffer.toString('base64');

        if (!apiKey) {
            return NextResponse.json(
                { success: false, error: 'Server configuration error: Missing AI API Key' },
                { status: 500 }
            );
        }

        // Use Gemini 2.0 Flash
        const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash-001" });

        const prompt = `
        Analyze this pet image and return a JSON object with comprehensive characteristics.
        Do not include markdown formatting, just the raw JSON.
        
        Required fields:
        - species: "dog", "cat", or "other"
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

        const result = await model.generateContent([
            prompt,
            {
                inlineData: {
                    data: base64Image,
                    mimeType: file.type || 'image/jpeg',
                },
            },
        ]);

        const response = await result.response;
        const text = response.text();

        // Clean up markdown code blocks if present
        const jsonString = text.replace(/```json\n|\n```/g, '').trim();

        let data;
        try {
            data = JSON.parse(jsonString);
        } catch (e) {
            console.error('Failed to parse Gemini response:', text);
            return NextResponse.json({ success: false, error: 'Failed to parse AI response' }, { status: 500 });
        }

        return NextResponse.json({ success: true, data });

    } catch (error: any) {
        console.error('Error analyzing pet:', error);
        return NextResponse.json(
            { success: false, error: error.message || 'Failed to analyze image' },
            { status: 500 }
        );
    }
}
