import { NextRequest, NextResponse } from 'next/server';
import { GoogleGenerativeAI } from '@google/generative-ai';

// Initialize Gemini API
const apiKey = process.env.GOOGLE_GENERATIVE_AI_API_KEY || process.env.GEMINI_API_KEY;
if (!apiKey) {
    console.error("Missing Gemini API Key");
}
const genAI = new GoogleGenerativeAI(apiKey || 'DUMMY_KEY');

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
        Analyze this screenshot of a social media post about a lost pet.
        Extract all relevant information and return a JSON object.
        Do not include markdown formatting, just the raw JSON.
        
        Required fields:
        - species: "dog", "cat", or "other" (infer from image or text)
        - pet_name: Name of the pet if mentioned, otherwise null
        - breed: Breed if mentioned or visually obvious, otherwise null
        - color: Description of color/pattern
        - marks: Distinctive marks, injuries, or accessories mentioned or visible
        - sex: "male", "female", or "unknown"
        - description: A summary of the post content (e.g., "Lost at Central Festival, wearing a red collar"). If no text, describe the pet visually.
        - location_text: The location mentioned in the text (e.g., "Hat Yai Park", "Near 7-11")
        - last_seen_date: Date/Time mentioned if any (string format), otherwise null
        - contact_info: Phone numbers, Line IDs, or Facebook names mentioned for contact
        - reward: Reward amount if mentioned, otherwise null
        - owner_name: Name of the owner if mentioned, otherwise null
        
        If the image is not a lost pet post, still try to extract visual pet details (species, color, breed).
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
        console.error('Error analyzing social post:', error);
        return NextResponse.json(
            { success: false, error: error.message || 'Failed to analyze image' },
            { status: 500 }
        );
    }
}
