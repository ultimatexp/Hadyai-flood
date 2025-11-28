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

const PYTHON_SERVICE_URL = process.env.PYTHON_SERVICE_URL || 'https://hadyai-flood-production.up.railway.app';

function calculateColorSimilarity(colors1: number[][], percentages1: number[], colors2: number[][], percentages2: number[]): number {
    let totalSimilarity = 0.0;

    // Compare each dominant color from colors1 with colors2
    for (let i = 0; i < colors1.length; i++) {
        const color1 = colors1[i];
        const pct1 = percentages1[i];
        let maxColorSimilarity = 0.0;

        // Find the most similar color in colors2
        for (const color2 of colors2) {
            // Calculate Euclidean distance in RGB space
            const distance = Math.sqrt(
                Math.pow(color1[0] - color2[0], 2) +
                Math.pow(color1[1] - color2[1], 2) +
                Math.pow(color1[2] - color2[2], 2)
            );
            // Convert distance to similarity (0-1 scale, where 1 is identical)
            // Max distance in RGB space is sqrt(3 * 255^2) ≈ 441
            const similarity = Math.max(0, 1 - (distance / 441));
            maxColorSimilarity = Math.max(maxColorSimilarity, similarity);
        }

        // Weight by the percentage of this color in the query image
        totalSimilarity += maxColorSimilarity * pct1;
    }

    return totalSimilarity;
}

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

        // 1. Call Python service to get embedding and colors
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

        const { embedding, colors: queryColors, color_percentages: queryPercentages } = await embedResponse.json();

        // 2. Call match_pets RPC to get candidates based on embedding
        const { data: matches, error: matchError } = await supabase
            .rpc('match_pets', {
                query_embedding: `[${embedding.join(',')}]`,
                match_threshold: 0.5, // Lower threshold to get more candidates
                match_count: 20 // Get more candidates for color filtering
            });

        if (matchError) {
            console.error('Match pets error:', matchError);
            return NextResponse.json(
                { success: false, error: matchError.message },
                { status: 500 }
            );
        }

        // 3. Calculate color similarity for each match and compute combined score
        const matchesWithColorScore = matches.map((match: any) => {
            // Parse stored color data if available
            let colorSimilarity = 0.5; // Default neutral score if no color data

            if (match.dominant_colors && match.color_percentages) {
                try {
                    const petColors = typeof match.dominant_colors === 'string'
                        ? JSON.parse(match.dominant_colors)
                        : match.dominant_colors;
                    const petPercentages = typeof match.color_percentages === 'string'
                        ? JSON.parse(match.color_percentages)
                        : match.color_percentages;

                    colorSimilarity = calculateColorSimilarity(
                        queryColors,
                        queryPercentages,
                        petColors,
                        petPercentages
                    );
                } catch (e) {
                    console.error('Error parsing color data:', e);
                }
            }

            // Combined score: 70% embedding + 30% color
            const embeddingSimilarity = match.similarity || 0;
            const combinedScore = (embeddingSimilarity * 0.7) + (colorSimilarity * 0.3);

            return {
                ...match,
                color_similarity: colorSimilarity,
                embedding_similarity: embeddingSimilarity,
                combined_score: combinedScore
            };
        });

        // 4. Sort by combined score and filter
        const filteredMatches = matchesWithColorScore
            .filter((match: any) => match.combined_score >= 0.6) // Stricter threshold
            .sort((a: any, b: any) => b.combined_score - a.combined_score)
            .slice(0, 5); // Return top 5

        return NextResponse.json({ success: true, matches: filteredMatches });

    } catch (error: any) {
        console.error('Unexpected error:', error);
        return NextResponse.json(
            { success: false, error: error.message },
            { status: 500 }
        );
    }
}
