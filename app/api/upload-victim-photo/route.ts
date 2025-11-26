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

export async function POST(request: NextRequest) {
    try {
        const formData = await request.formData();
        const file = formData.get('image') as File;
        const caseIdParam = formData.get('case_id') as string | null;
        const uploadedBy = (formData.get('uploaded_by') as string) || 'anonymous';
        const embedding = formData.get('embedding') as string;

        console.log('Received upload request:', {
            hasFile: !!file,
            uploadedBy,
            hasEmbedding: !!embedding
        });

        if (!file || !embedding) {
            return NextResponse.json(
                { success: false, error: 'Missing required fields' },
                { status: 400 }
            );
        }

        // Use provided case_id or null (standalone victim photo)
        const caseId = caseIdParam || null;
        console.log('Using case_id:', caseId);

        // Upload image to Supabase Storage
        const fileExt = file.name.split('.').pop();
        const fileName = `victim-photos/${caseId || 'standalone'}/${Date.now()}.${fileExt}`;

        console.log('Uploading to storage:', fileName);
        const { error: uploadError } = await supabase.storage
            .from('sos-photos')
            .upload(fileName, file);

        if (uploadError) {
            console.error('Storage upload error:', uploadError);
            return NextResponse.json(
                { success: false, error: uploadError.message },
                { status: 500 }
            );
        }

        // Get public URL
        const { data: { publicUrl } } = supabase.storage
            .from('sos-photos')
            .getPublicUrl(fileName);

        console.log('Public URL:', publicUrl);

        // Insert victim photo record
        console.log('Inserting victim photo record...');
        const { data: photoData, error: photoError } = await supabase
            .from('victim_photos')
            .insert({
                case_id: caseId,
                image_url: publicUrl,
                uploaded_by: uploadedBy,
            })
            .select()
            .single();

        if (photoError) {
            console.error('Photo insert error:', photoError);
            return NextResponse.json(
                { success: false, error: photoError.message },
                { status: 500 }
            );
        }

        console.log('Photo inserted:', photoData.id);

        // Parse embedding and insert
        const embeddingArray = JSON.parse(embedding);
        console.log('Inserting face embedding, length:', embeddingArray.length);

        const { error: faceError } = await supabase
            .from('victim_faces')
            .insert({
                photo_id: photoData.id,
                embedding: `[${embeddingArray.join(',')}]`,
            });

        if (faceError) {
            console.error('Face insert error:', faceError);
            return NextResponse.json(
                { success: false, error: faceError.message },
                { status: 500 }
            );
        }

        console.log('Success! Photo ID:', photoData.id);
        return NextResponse.json({ success: true, photo: photoData });
    } catch (error: any) {
        console.error('Unexpected error:', error);
        return NextResponse.json(
            { success: false, error: error.message },
            { status: 500 }
        );
    }
}
