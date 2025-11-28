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

// Calculate color similarity using RGB distance
// For bicolor patterns, checks if colors overlap (e.g., orange/white should match white/orange)
function calculateColorSimilarity(
    colors1: number[][],
    percentages1: number[],
    colors2: number[][],
    percentages2: number[]
): number {
    let totalSimilarity = 0.0;

    // For each color in query image
    for (let i = 0; i < colors1.length; i++) {
        const color1 = colors1[i];
        const pct1 = percentages1[i];

        let bestMatch = 0.0;

        // Find best matching color in database pet
        for (let j = 0; j < colors2.length; j++) {
            const color2 = colors2[j];

            // Euclidean distance in RGB space
            const distance = Math.sqrt(
                Math.pow(color1[0] - color2[0], 2) +
                Math.pow(color1[1] - color2[1], 2) +
                Math.pow(color1[2] - color2[2], 2)
            );

            // Convert to similarity (max distance is ~441 for RGB)
            const similarity = 1 - (distance / 441);

            if (similarity > bestMatch) {
                bestMatch = similarity;
            }
        }

        // Weight by percentage this color occupies
        totalSimilarity += bestMatch * pct1;
    }

    // For bicolor patterns: require at least ONE color to match well
    // If top 2 colors, check if ANY pair has good similarity
    if (colors1.length >= 2 && colors2.length >= 2) {
        // Find best cross-match between any two colors
        let hasBicolorOverlap = false;

        for (let i = 0; i < Math.min(2, colors1.length); i++) {
            for (let j = 0; j < Math.min(2, colors2.length); j++) {
                const distance = Math.sqrt(
                    Math.pow(colors1[i][0] - colors2[j][0], 2) +
                    Math.pow(colors1[i][1] - colors2[j][1], 2) +
                    Math.pow(colors1[i][2] - colors2[j][2], 2)
                );
                const similarity = 1 - (distance / 441);

                // Require at least 70% RGB similarity for one color pair
                if (similarity > 0.7) {
                    hasBicolorOverlap = true;
                    break;
                }
            }
            if (hasBicolorOverlap) break;
        }

        // Penalize if bicolor patterns don't share ANY common color
        if (!hasBicolorOverlap) {
            totalSimilarity *= 0.7; // 30% penalty
        }
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

        const type = formData.get('type') as string || 'found';
        const filterStatus = type === 'found' ? 'LOST' : 'FOUND';

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
                match_threshold: 0.4, // Production threshold
                match_count: 50,
                filter_status: filterStatus,
            });

        if (matchError) {
            console.error('Match pets error:', matchError);
            return NextResponse.json(
                { success: false, error: matchError.message },
                { status: 500 }
            );
        }

        // 3. Calculate color and feature similarity for each match
        const matchesWithScores = matches.map((match: any) => {
            // --- Color Similarity (RGB) ---
            let colorSimilarity = 0.5; // Default neutral
            if (match.dominant_colors && match.color_percentages) {
                try {
                    // Use the queryColors and queryPercentages from the embedding response
                    // The instruction snippet incorrectly referenced `queryEmbedding.colors`
                    // which is not defined here.
                    const matchColors = typeof match.dominant_colors === 'string'
                        ? JSON.parse(match.dominant_colors)
                        : match.dominant_colors;
                    const matchPercentages = typeof match.color_percentages === 'string'
                        ? JSON.parse(match.color_percentages)
                        : match.color_percentages;

                    colorSimilarity = calculateColorSimilarity(queryColors, queryPercentages, matchColors, matchPercentages);

                    // Log color details for debugging (show top 2 colors for bicolor)
                    const queryColorStr = queryColors.slice(0, 2).map((c: number[], i: number) =>
                        `[${c}] ${(queryPercentages[i] * 100).toFixed(0)}%`
                    ).join(', ');
                    const matchColorStr = matchColors.slice(0, 2).map((c: number[], i: number) =>
                        `[${c}] ${(matchPercentages[i] * 100).toFixed(0)}%`
                    ).join(', ');

                    console.log(`  Color comparison (RGB):`);
                    console.log(`    Query: ${queryColorStr}`);
                    console.log(`    Match: ${matchColorStr}`);
                } catch (e) {
                    console.error('Color parsing error:', e);
                }
            }

            // --- Location Proximity (Bonus only, no penalty for distance) ---
            let locationBonus = 0;
            const queryLat = formData.get('lat') ? parseFloat(formData.get('lat') as string) : null;
            const queryLng = formData.get('lng') ? parseFloat(formData.get('lng') as string) : null;

            if (queryLat && queryLng && match.lat && match.lng) {
                // Calculate distance using Haversine formula (in km)
                const R = 6371; // Earth's radius in km
                const dLat = (match.lat - queryLat) * Math.PI / 180;
                const dLon = (match.lng - queryLng) * Math.PI / 180;
                const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                    Math.cos(queryLat * Math.PI / 180) * Math.cos(match.lat * Math.PI / 180) *
                    Math.sin(dLon / 2) * Math.sin(dLon / 2);
                const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
                const distance = R * c;

                // Proximity bonus (decreasing with distance, but no penalty)
                if (distance < 1) {
                    locationBonus = 0.20; // Within 1km = 20% bonus
                } else if (distance < 3) {
                    locationBonus = 0.15; // 1-3km = 15% bonus
                } else if (distance < 5) {
                    locationBonus = 0.10; // 3-5km = 10% bonus
                } else if (distance < 10) {
                    locationBonus = 0.05; // 5-10km = 5% bonus
                }
                // Beyond 10km = 0 bonus (but no penalty - pets can travel far)

                console.log(`  Location: ${distance.toFixed(1)}km away → ${(locationBonus * 100).toFixed(0)}% proximity bonus`);
            }

            // --- Feature Similarity (Gemini) ---
            let featureScore = 0.5; // Default neutral
            let featureCount = 0;

            // Helper to compare strings loosely
            const compare = (a: string | null, b: string | null) => {
                if (!a || !b) return 0;
                return a.toLowerCase().includes(b.toLowerCase()) || b.toLowerCase().includes(a.toLowerCase()) ? 1 : 0;
            };

            const querySpecies = formData.get('species') as string;
            const queryColor = formData.get('color_main') as string;
            const queryColorSecondary = formData.get('color_secondary') as string;
            const queryFur = formData.get('fur_length') as string;
            const queryPattern = formData.get('color_pattern') as string;
            const querySex = formData.get('sex') as string;

            console.log(`Query features - Species: ${querySpecies}, Color: ${queryColor}, Pattern: ${queryPattern}, Fur: ${queryFur}, Sex: ${querySex}`);

            // CRITICAL: Species (wrong species = 0)
            if (querySpecies) {
                if (match.species && match.species.toLowerCase() !== querySpecies.toLowerCase()) {
                    featureScore = 0;
                } else {
                    featureScore += 1;
                }
                featureCount++;
            }

            // CRITICAL: Sex (wrong sex = heavy penalty)
            if (querySex) {
                if (match.sex && match.sex !== 'unknown' && match.sex !== querySex) {
                    featureScore *= 0.3; // 70% reduction
                } else {
                    featureScore += 1;
                }
                featureCount++;
            }

            // HIGH: Color Main
            if (queryColor) {
                featureScore += compare(match.color_main, queryColor);
                featureCount++;
            }

            // MEDIUM: Color Pattern
            if (queryPattern) {
                featureScore += compare(match.color_pattern, queryPattern);
                featureCount++;
            }

            // MEDIUM: Color Secondary
            if (queryColorSecondary) {
                featureScore += compare(match.color_secondary, queryColorSecondary);
                featureCount++;
            }

            // MEDIUM: Fur Length
            if (queryFur) {
                featureScore += compare(match.fur_length, queryFur);
                featureCount++;
            }

            // BONUS ONLY: Accessories (collar/clothes can be changed, so only bonus if match, no penalty if not)
            const queryChars = formData.get('has_collar') === 'true';
            const queryCollarColor = formData.get('collar_color') as string;
            const queryClothes = formData.get('clothes') as string;
            const matchChars = match.characteristics ? (typeof match.characteristics === 'string' ? JSON.parse(match.characteristics) : match.characteristics) : null;

            if (queryChars && matchChars?.has_collar && queryCollarColor && match.collar_color) {
                // Both have collars AND colors are specified - check if they match
                if (queryCollarColor.toLowerCase() === match.collar_color.toLowerCase()) {
                    featureScore += 1; // Strong evidence!
                    featureCount++;
                }
                // If collar colors don't match = no penalty (collar could be changed)
            }

            if (queryClothes && matchChars?.clothes) {
                // Both wearing clothes - bonus if similar
                if (compare(matchChars.clothes, queryClothes) > 0) {
                    featureScore += 0.5;
                    featureCount++;
                }
                // If clothes don't match = no penalty (clothes can be changed)
            }

            // BONUS: Unique marks (white patches)
            const queryWhitePatches = formData.get('white_patch_location') as string;
            if (queryWhitePatches && matchChars?.white_patch_location) {
                const queryPatchArray = JSON.parse(queryWhitePatches);
                const matchPatchArray = matchChars.white_patch_location;

                if (Array.isArray(queryPatchArray) && Array.isArray(matchPatchArray)) {
                    const overlap = queryPatchArray.filter(p => matchPatchArray.includes(p));
                    if (overlap.length > 0) {
                        featureScore += overlap.length * 0.3; // Bonus for each matching location
                        featureCount++;
                    }
                }
            }

            // BONUS: Heterochromia (rare, strong indicator)
            const queryHeterochromia = formData.get('heterochromia') === 'true';
            if (queryHeterochromia && matchChars?.heterochromia) {
                featureScore += 1; // Strong bonus for this rare trait
                featureCount++;
            }

            // Normalize feature score (core features only)
            if (featureCount > 0) {
                featureScore = featureScore / featureCount;
            }

            // Cap feature score at 1.0 (100%) to prevent bonuses from inflating beyond 100%
            featureScore = Math.min(1.0, featureScore);

            // --- Combined Score ---
            // Base weights: Embedding 40%, Color 30%, Features 30%
            const embeddingSimilarity = match.similarity || 0;
            let combinedScore = (embeddingSimilarity * 0.4) + (colorSimilarity * 0.3) + (featureScore * 0.3);

            // Apply location proximity bonus (up to 20% boost)
            combinedScore = Math.min(1.0, combinedScore + locationBonus);

            console.log(`Match: ${match.pet_name} (${match.id})`);
            console.log(`  - Embedding: ${(embeddingSimilarity * 100).toFixed(1)}%`);
            console.log(`  - Color: ${(colorSimilarity * 100).toFixed(1)}%`);
            console.log(`  - Features: ${(featureScore * 100).toFixed(1)}%`);
            console.log(`  = Combined: ${(combinedScore * 100).toFixed(1)}%`);

            return {
                ...match,
                color_similarity: colorSimilarity,
                embedding_similarity: embeddingSimilarity,
                feature_score: featureScore,
                combined_score: combinedScore
            };
        });

        // 4. Filter for high-confidence matches only (>= 80%)
        const filteredMatches = matchesWithScores
            .filter((match: any) => match.combined_score >= 0.80)
            .sort((a: any, b: any) => b.combined_score - a.combined_score)
            .slice(0, 20);

        console.log(`✅ Returning ${filteredMatches.length} high-confidence matches (>= 80%)`);

        return NextResponse.json({ success: true, matches: filteredMatches });

    } catch (error: any) {
        console.error('Unexpected error:', error);
        return NextResponse.json(
            { success: false, error: error.message },
            { status: 500 }
        );
    }
}
