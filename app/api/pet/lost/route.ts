import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';

// Initialize Supabase client
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

const PYTHON_SERVICE_URL = process.env.PYTHON_SERVICE_URL || 'https://hadyai-flood-production.up.railway.app';

export async function POST(request: Request) {
    try {
        const formData = await request.formData();
        const images = formData.getAll('images') as File[];
        const contactInfo = formData.get('contact_info') as string;
        const description = formData.get('description') as string;
        const lat = formData.get('lat') ? parseFloat(formData.get('lat') as string) : null;
        const lng = formData.get('lng') ? parseFloat(formData.get('lng') as string) : null;

        // New fields
        const petName = formData.get('pet_name') as string;
        const ownerName = formData.get('owner_name') as string;
        const petType = formData.get('pet_type') as string;
        const breed = formData.get('breed') as string;
        const color = formData.get('color') as string;
        const marks = formData.get('marks') as string;
        const reward = formData.get('reward') as string;
        const userId = formData.get('user_id') as string;

        if (!images || images.length === 0) {
            return NextResponse.json({ error: 'No images uploaded' }, { status: 400 });
        }

        const uploadedUrls: string[] = [];
        const embeddingPromises: Promise<any>[] = [];

        // 1. Upload images to Supabase Storage and Generate Embeddings
        for (const file of images) {
            const fileName = `lost-pets/${Date.now()}-${file.name}`;

            // Upload to Supabase
            const { error: uploadError } = await supabase.storage
                .from('sos-photos')
                .upload(fileName, file);

            if (uploadError) {
                console.error('Upload error:', uploadError);
                continue; // Skip failed uploads
            }

            // Get Public URL
            const { data: { publicUrl } } = supabase.storage
                .from('sos-photos')
                .getPublicUrl(fileName);

            uploadedUrls.push(publicUrl);

            // Generate Embedding
            embeddingPromises.push((async () => {
                try {
                    const embedResponse = await fetch(`${PYTHON_SERVICE_URL}/embed-url`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                        },
                        body: JSON.stringify({ image_url: publicUrl }),
                    });

                    if (embedResponse.ok) {
                        const { embedding, colors, color_percentages } = await embedResponse.json();
                        return { embedding, colors, color_percentages };
                    } else {
                        console.error('Embedding service error:', await embedResponse.text());
                        return null;
                    }
                } catch (embedErr) {
                    console.error('Embedding service connection error:', embedErr);
                    return null;
                }
            })());
        }

        if (uploadedUrls.length === 0) {
            return NextResponse.json({ error: 'Failed to upload any images' }, { status: 500 });
        }

        // 2. Insert into 'pets' table
        const { data: petData, error: petError } = await supabase
            .from('pets')
            .insert({
                image_url: uploadedUrls[0], // Primary image
                images: uploadedUrls,       // All images
                status: 'LOST',
                contact_info: contactInfo,
                description: description,
                lat: lat,
                lng: lng,
                pet_name: petName,
                owner_name: ownerName,
                pet_type: petType,
                breed: breed,
                color: color,
                marks: marks,
                reward: reward,
                user_id: userId,
                last_seen_at: formData.get('last_seen_at') || null,
                // New fields from Gemini analysis
                species: formData.get('species') || null,
                color_main: formData.get('color_main') || null,
                color_pattern: formData.get('color_pattern') || null,
                fur_length: formData.get('fur_length') || null,
                eye_color: formData.get('eye_color') || null,
                collar_color: formData.get('collar_color') || null,
                unique_marks: formData.get('unique_marks') || null,
                pose: formData.get('pose') || null,
                quality: formData.get('quality') || null,
                exif_time: formData.get('exif_time') || null,
                exif_location: formData.get('exif_location') ? JSON.parse(formData.get('exif_location') as string) : null
            })
            .select()
            .single();

        if (petError) {
            console.error('Database error:', petError);
            return NextResponse.json({ error: 'Failed to save pet data' }, { status: 500 });
        }

        // 3. Process embeddings and update 'pets' table
        const embeddings = await Promise.all(embeddingPromises);

        // Update pet with embeddings and color data
        const embeddingData = embeddings.find(e => e !== null);
        if (embeddingData) {
            const { error: updateError } = await supabase
                .from('pets')
                .update({
                    embedding: `[${embeddingData.embedding.join(',')}]`,
                    dominant_colors: JSON.stringify(embeddingData.colors),
                    color_percentages: JSON.stringify(embeddingData.color_percentages)
                })
                .eq('id', petData.id);

            if (updateError) {
                console.error('Error updating pet with embedding and color data:', updateError);
                // Non-critical, we still return success for the pet creation
            }
        }

        return NextResponse.json({ success: true, pet: petData });

    } catch (error: any) {
        console.error('Server error:', error);
        return NextResponse.json({ error: error.message }, { status: 500 });
    }
}
