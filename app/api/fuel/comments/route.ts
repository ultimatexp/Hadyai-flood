import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

// GET comments for a station
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const stationId = searchParams.get('station_id');

    if (!stationId) {
      return NextResponse.json({ error: 'station_id required' }, { status: 400 });
    }

    const { data, error } = await supabase
      .from('fuel_station_comments')
      .select('*')
      .eq('station_id', stationId)
      .order('created_at', { ascending: false })
      .limit(10);

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ comments: data || [] });
  } catch {
    return NextResponse.json({ error: 'เกิดข้อผิดพลาด' }, { status: 500 });
  }
}

// POST a new comment
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { station_id, message, fingerprint, image_url } = body;

    if (!station_id || !message?.trim()) {
      return NextResponse.json(
        { error: 'กรุณากรอกข้อความ' },
        { status: 400 }
      );
    }

    // Rate limit: max 1 comment per fingerprint per station per 5 min
    if (fingerprint) {
      const { data: recent } = await supabase
        .from('fuel_station_comments')
        .select('id')
        .eq('fingerprint', fingerprint)
        .eq('station_id', station_id)
        .gte('created_at', new Date(Date.now() - 5 * 60 * 1000).toISOString())
        .limit(1);

      if (recent && recent.length > 0) {
        return NextResponse.json(
          { error: 'กรุณารอ 5 นาทีก่อนแสดงความคิดเห็นอีกครั้ง' },
          { status: 429 }
        );
      }
    }

    const { data, error } = await supabase
      .from('fuel_station_comments')
      .insert({
        station_id,
        message: message.trim(),
        fingerprint: fingerprint || null,
        image_url: image_url || null,
      })
      .select()
      .single();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    // Cleanup: keep only latest 10 comments per station
    const { data: keepIds } = await supabase
      .from('fuel_station_comments')
      .select('id')
      .eq('station_id', station_id)
      .order('created_at', { ascending: false })
      .limit(10);

    if (keepIds && keepIds.length >= 10) {
      const idsToKeep = keepIds.map((r: { id: string }) => r.id);
      await supabase
        .from('fuel_station_comments')
        .delete()
        .eq('station_id', station_id)
        .not('id', 'in', `(${idsToKeep.join(',')})`);
    }

    return NextResponse.json({ success: true, comment: data });
  } catch {
    return NextResponse.json({ error: 'เกิดข้อผิดพลาด' }, { status: 500 });
  }
}
