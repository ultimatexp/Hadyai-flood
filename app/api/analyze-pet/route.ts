import { NextRequest, NextResponse } from 'next/server';
import { GoogleGenerativeAI } from '@google/generative-ai';

// Initialize Gemini API
const genAI = new GoogleGenerativeAI(process.env.GOOGLE_GENERATIVE_AI_API_KEY || process.env.GEMINI_API_KEY || '');

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

        // Use Gemini 1.5 Flash for speed
        const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash-001" });

        const prompt = `
        Analyze this pet image and return a JSON object with the following fields. 
        Do not include markdown formatting, just the raw JSON.
        
        Fields:
        - species: "dog", "cat", or "other"
        - color_main: Main color of the pet (e.g., "orange", "black", "white", "calico")
        - color_pattern: Pattern (e.g., "solid", "tabby", "bicolor", "spotted")
        - fur_length: "short", "medium", "long"
        - eye_color: Color of the eyes
        - collar_color: Color of the collar if present, otherwise null
        - unique_marks: Any distinguishing marks (e.g., "scar on ear", "white socks"), otherwise null
        - pose: Current pose (e.g., "standing", "sitting", "sleeping")
        - quality: Image quality (e.g., "good", "blur", "dark")
        - description: A short 1-sentence description of the pet
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
