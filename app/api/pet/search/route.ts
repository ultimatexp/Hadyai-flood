import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

// Use service role key to bypass RLS
const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    {
        auth: {
            autoRefreshToken: false,
            persistSession: false
        }
    }
);

const PYTHON_SERVICE_URL = 'http://127.0.0.1:8000';

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

        // 1. Call Python service to get embedding
        // We need to construct a new FormData to send to the Python service
        const pythonFormData = new FormData();
        pythonFormData.append('file', file);

        const embedResponse = await fetch(`${PYTHON_SERVICE_URL}/embed`, {
            method: 'POST',
            body: pythonFormData,
        });

        if (!embedResponse.ok) {
            const errorText = await embedResponse.text();
            throw new Error(`Embedding service error: ${embedResponse.status} ${errorText}`);
        }

        const { embedding } = await embedResponse.json();

        // 2. Call match_pets RPC
        const { data: matches, error: matchError } = await supabase
            .rpc('match_pets', {
                query_embedding: `[${embedding.join(',')}]`,
                match_threshold: 0.7, // Adjust threshold as needed
                match_count: 5
            });

        if (matchError) {
            console.error('Match pets error:', matchError);
            return NextResponse.json(
                { success: false, error: matchError.message },
                { status: 500 }
            );
        }

        return NextResponse.json({ success: true, matches });

    } catch (error: any) {
        console.error('Unexpected error:', error);
        return NextResponse.json(
            { success: false, error: error.message },
            { status: 500 }
        );
    }
}
