import { NextRequest, NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

export async function POST(request: NextRequest) {
    try {
        const { embedding, threshold = 0.7 } = await request.json();

        if (!embedding || !Array.isArray(embedding)) {
            return NextResponse.json(
                { success: false, error: 'Invalid embedding' },
                { status: 400 }
            );
        }

        // Search for similar faces using pgvector
        // Using cosine similarity (1 - cosine_distance)
        const { data, error } = await supabase.rpc('search_similar_faces', {
            query_embedding: `[${embedding.join(',')}]`,
            similarity_threshold: threshold,
            match_count: 10
        });

        if (error) {
            return NextResponse.json(
                { success: false, error: error.message },
                { status: 500 }
            );
        }

        return NextResponse.json({ success: true, results: data });
    } catch (error: any) {
        return NextResponse.json(
            { success: false, error: error.message },
            { status: 500 }
        );
    }
}
