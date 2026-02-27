import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { autoRefreshToken: false, persistSession: false } }
);

const PYTHON_SERVICE_URL = process.env.PYTHON_SERVICE_URL || 'https://hadyai-flood-production.up.railway.app';

export async function POST() {
    try {
        // 1. Get all pets that have an image_url
        const { data: pets, error } = await supabase
            .from('pets')
            .select('id, image_url, images')
            .not('image_url', 'is', null);

        if (error) throw error;
        if (!pets || pets.length === 0) {
            return NextResponse.json({ message: 'No pets to backfill' });
        }

        console.log(`🔄 Starting CLIP backfill for ${pets.length} pets...`);

        const results: { id: string; status: string; error?: string }[] = [];

        for (const pet of pets) {
            try {
                const imageUrl = pet.image_url;

                console.log(`  Processing pet ${pet.id}: ${imageUrl}`);

                // Call Python service to generate new CLIP embedding + LAB colors
                const embedResponse = await fetch(`${PYTHON_SERVICE_URL}/embed-url`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ image_url: imageUrl }),
                });

                if (!embedResponse.ok) {
                    const errText = await embedResponse.text();
                    throw new Error(`Embed service: ${embedResponse.status} ${errText}`);
                }

                const { embedding, colors, lab_colors, color_percentages } = await embedResponse.json();

                // Update the pet record
                const { error: updateError } = await supabase
                    .from('pets')
                    .update({
                        embedding: `[${embedding.join(',')}]`,
                        dominant_colors: JSON.stringify(colors),
                        color_percentages: JSON.stringify(color_percentages),
                        lab_colors: lab_colors ? JSON.stringify(lab_colors) : null,
                    })
                    .eq('id', pet.id);

                if (updateError) throw updateError;

                results.push({ id: pet.id, status: 'ok' });
                console.log(`  ✅ Pet ${pet.id} updated`);
            } catch (e: any) {
                results.push({ id: pet.id, status: 'error', error: e.message });
                console.error(`  ❌ Pet ${pet.id} failed: ${e.message}`);
            }
        }

        const succeeded = results.filter(r => r.status === 'ok').length;
        const failed = results.filter(r => r.status === 'error').length;

        console.log(`🏁 Backfill complete: ${succeeded} ok, ${failed} failed`);

        return NextResponse.json({
            success: true,
            total: pets.length,
            succeeded,
            failed,
            results,
        });
    } catch (error: any) {
        console.error('Backfill error:', error);
        return NextResponse.json(
            { success: false, error: error.message },
            { status: 500 }
        );
    }
}
