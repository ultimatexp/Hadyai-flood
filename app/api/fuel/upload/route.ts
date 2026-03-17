import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData();
    const file = formData.get('file') as File;

    if (!file) {
      return NextResponse.json({ error: 'ไม่พบไฟล์' }, { status: 400 });
    }

    const fileExt = file.name.split('.').pop();
    const fileName = `fuel-votes/${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`;

    const buffer = await file.arrayBuffer();
    const { data, error } = await supabase.storage
      .from('fuel-images')
      .upload(fileName, buffer, {
        contentType: file.type,
        upsert: false,
      });

    if (error) {
      // If bucket doesn't exist, create it
      if (error.message.includes('not found')) {
        await supabase.storage.createBucket('fuel-images', {
          public: true,
          fileSizeLimit: 5 * 1024 * 1024, // 5MB
        });
        
        const { data: retryData, error: retryError } = await supabase.storage
          .from('fuel-images')
          .upload(fileName, buffer, {
            contentType: file.type,
            upsert: false,
          });

        if (retryError) {
          return NextResponse.json({ error: retryError.message }, { status: 500 });
        }

        const { data: urlData } = supabase.storage
          .from('fuel-images')
          .getPublicUrl(retryData.path);

        return NextResponse.json({ url: urlData.publicUrl });
      }

      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    const { data: urlData } = supabase.storage
      .from('fuel-images')
      .getPublicUrl(data.path);

    return NextResponse.json({ url: urlData.publicUrl });
  } catch {
    return NextResponse.json({ error: 'อัพโหลดรูปล้มเหลว' }, { status: 500 });
  }
}
