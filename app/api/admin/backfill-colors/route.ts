import { NextResponse } from 'next/server';
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

export async function GET() {
    try {
        // 1. Fetch pets without color data
        const { data: pets, error: fetchError } = await supabase
            .from('pets')
            .select('id, image_url')
            .is('embedding', null)
            .not('image_url', 'is', null)
            .limit(50); // Process in batches

        if (fetchError) {
            throw new Error(`Error fetching pets: ${fetchError.message}`);
        }

        if (!pets || pets.length === 0) {
            return NextResponse.json({ message: 'No pets to backfill' });
        }

        const results = [];

        // 2. Process each pet
        for (const pet of pets) {
            try {
                // Call Python service to get colors
                const response = await fetch(`${PYTHON_SERVICE_URL}/embed-url`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ image_url: pet.image_url }),
                });

                if (!response.ok) {
                    console.error(`Failed to get colors for pet ${pet.id}: ${response.statusText}`);
                    results.push({ id: pet.id, status: 'failed', error: response.statusText });
                    continue;
                }

                const { embedding, colors, color_percentages } = await response.json();

                // Update pet
                const { error: updateError } = await supabase
                    .from('pets')
                    .update({
                        embedding: `[${embedding.join(',')}]`,
                        dominant_colors: JSON.stringify(colors),
                        color_percentages: JSON.stringify(color_percentages)
                    })
                    .eq('id', pet.id);

                if (updateError) {
                    console.error(`Failed to update pet ${pet.id}: ${updateError.message}`);
                    results.push({ id: pet.id, status: 'failed', error: updateError.message });
                } else {
                    results.push({ id: pet.id, status: 'success' });
                }

            } catch (err: any) {
                console.error(`Error processing pet ${pet.id}:`, err);
                results.push({ id: pet.id, status: 'error', error: err.message });
            }
        }

        return NextResponse.json({
            success: true,
            processed: results.length,
            results
        });

    } catch (error: any) {
        console.error('Backfill error:', error);
        return NextResponse.json(
            { success: false, error: error.message },
            { status: 500 }
        );
    }
}
