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

export async function POST(request: NextRequest) {
    try {
        const formData = await request.formData();

        // Handle multiple images
        let files = formData.getAll('images') as File[];
        // Fallback for single image upload
        if (files.length === 0) {
            const singleFile = formData.get('image') as File;
            if (singleFile) {
                files = [singleFile];
            }
        }

        const contactInfo = formData.get('contact_info') as string;
        const description = formData.get('description') as string;
        const status = (formData.get('status') as string) || 'FOUND';

        if (files.length === 0) {
            return NextResponse.json(
                { success: false, error: 'Missing images' },
                { status: 400 }
            );
        }

        const uploadedUrls: string[] = [];

        // 1. Upload all images to Supabase Storage
        for (const file of files) {
            const fileExt = file.name.split('.').pop();
            const fileName = `pets/${Date.now()}_${Math.random().toString(36).substring(7)}.${fileExt}`;

            const { error: uploadError } = await supabase.storage
                .from('sos-photos')
                .upload(fileName, file);

            if (uploadError) {
                console.error('Storage upload error:', uploadError);
                // Continue with other files if one fails? Or fail all? 
                // Let's continue but log error.
                continue;
            }

            const { data: { publicUrl } } = supabase.storage
                .from('sos-photos')
                .getPublicUrl(fileName);

            uploadedUrls.push(publicUrl);
        }

        if (uploadedUrls.length === 0) {
            return NextResponse.json(
                { success: false, error: 'Failed to upload any images' },
                { status: 500 }
            );
        }

        // 2. Insert into pets table
        const { data: petData, error: petError } = await supabase
            .from('pets')
            .insert({
                image_url: uploadedUrls[0], // Main image (first one)
                images: uploadedUrls,       // All images
                status: status,
                contact_info: contactInfo,
                description: description,
                lat: formData.get('lat') ? parseFloat(formData.get('lat') as string) : null,
                lng: formData.get('lng') ? parseFloat(formData.get('lng') as string) : null,
                last_seen_at: formData.get('last_seen_at') || null,
                // Core characteristics from Gemini analysis
                species: formData.get('species') || null,
                color_main: formData.get('color_main') || null,
                color_secondary: formData.get('color_secondary') || null,
                color_pattern: formData.get('color_pattern') || null,
                fur_length: formData.get('fur_length') || null,
                eye_color: formData.get('eye_color') || null,
                body_size: formData.get('body_size') || null,
                sex: formData.get('sex') || null,
                // Accessories
                collar_color: formData.get('collar_color') || null,
                // Detailed characteristics (JSONB)
                characteristics: {
                    // Body features
                    ear_shape: formData.get('ear_shape') || null,
                    tail_type: formData.get('tail_type') || null,
                    // Unique marks
                    special_marks: formData.get('special_marks') || null,
                    white_patch_location: formData.get('white_patch_location') ? JSON.parse(formData.get('white_patch_location') as string) : null,
                    injury_or_scar: formData.get('injury_or_scar') || null,
                    heterochromia: formData.get('heterochromia') === 'true',
                    // Accessories
                    has_collar: formData.get('has_collar') === 'true',
                    collar_type: formData.get('collar_type') || null,
                    has_tag: formData.get('has_tag') === 'true',
                    clothes: formData.get('clothes') || null,
                    // Other
                    pose: formData.get('pose') || null,
                    quality: formData.get('quality') || null,
                },
                unique_marks: formData.get('unique_marks') || null,
                exif_time: formData.get('exif_time') || null,
                exif_location: formData.get('exif_location') ? JSON.parse(formData.get('exif_location') as string) : null
            })
            .select()
            .single();

        if (petError) {
            console.error('Pet insert error:', petError);
            return NextResponse.json(
                { success: false, error: petError.message },
                { status: 500 }
            );
        }

        // 3. Call Python service to get embedding for EACH image
        // We do this asynchronously/parallel to speed it up
        const embeddingPromises = uploadedUrls.map(async (url) => {
            try {
                const embedResponse = await fetch(`${PYTHON_SERVICE_URL}/embed-url`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ image_url: url }),
                });

                if (!embedResponse.ok) {
                    throw new Error(`Embedding service error: ${embedResponse.statusText}`);
                }

                const { embedding, colors, color_percentages } = await embedResponse.json();
                return { embedding, colors, color_percentages }; // Return embedding and color data
            } catch (err) {
                console.error(`Failed to generate embedding for ${url}:`, err);
                return null; // Return null for failed embeddings
            }
        });


        const embeddings = await Promise.all(embeddingPromises);

        // 4. Update pet with embeddings and color data
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
                console.error('Error updating pet with embedding:', updateError);
            }
        }

        // 5. Search for matching LOST pets and notify owners
        try {
            if (embeddingData && files[0]) {
                // Call search API with the first uploaded image
                const searchFormData = new FormData();
                searchFormData.append('image', files[0]);
                searchFormData.append('type', 'found'); // Search for LOST pets

                // Add analysis data if available from formData
                const species = formData.get('species');
                const colorMain = formData.get('color_main');
                const furLength = formData.get('fur_length');

                if (species) searchFormData.append('species', species as string);
                if (colorMain) searchFormData.append('color_main', colorMain as string);
                if (furLength) searchFormData.append('fur_length', furLength as string);

                // Internal API call
                const baseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL?.includes('localhost')
                    ? 'http://localhost:3000'
                    : `https://${process.env.VERCEL_URL || 'yourdomain.com'}`;

                const searchResponse = await fetch(`${baseUrl}/api/pet/search`, {
                    method: 'POST',
                    body: searchFormData,
                }).catch(() => null);

                if (searchResponse?.ok) {
                    const searchData = await searchResponse.json();
                    const highMatches = searchData.matches?.filter((match: any) =>
                        match.combined_score >= 0.80 && match.user_id
                    ) || [];

                    console.log(`Found ${highMatches.length} high-confidence matches (>80%)`);

                    if (highMatches.length > 0) {
                        const notifications = highMatches.map((match: any) => ({
                            user_id: match.user_id,
                            title: 'พบสัตว์เลี้ยงที่อาจเป็นของคุณ! 🐾',
                            message: `มีผู้พบสัตว์เลี้ยงที่คล้ายกับ "${match.pet_name || 'สัตว์เลี้ยงของคุณ'}" (${(match.combined_score * 100).toFixed(0)}% match)`,
                            type: 'pet_match',
                            data: {
                                found_pet_id: petData.id,
                                lost_pet_id: match.id,
                                combined_score: match.combined_score,
                                embedding_score: match.embedding_similarity,
                                color_score: match.color_similarity,
                                feature_score: match.feature_score,
                                found_image_url: uploadedUrls[0],
                                lost_image_url: match.image_url,
                            },
                        }));

                        const { error: notifyError } = await supabase
                            .from('notifications')
                            .insert(notifications);

                        if (notifyError) {
                            console.error('Notification error:', notifyError);
                        } else {
                            console.log(`✅ Sent ${notifications.length} notifications`);
                        }
                    }
                }
            }
        } catch (alertError) {
            console.error('Alert generation error:', alertError);
        }

        return NextResponse.json({ success: true, pet: petData });

    } catch (error: any) {
        console.error('Unexpected error:', error);
        return NextResponse.json(
            { success: false, error: error.message },
            { status: 500 }
        );
    }
}
