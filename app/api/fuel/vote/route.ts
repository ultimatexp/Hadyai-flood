import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { station_id, fuel_type_id, status, fingerprint, note, image_url } = body;

    if (!station_id || !fuel_type_id || !status) {
      return NextResponse.json(
        { error: 'กรุณากรอกข้อมูลให้ครบ' },
        { status: 400 }
      );
    }

    if (!['available', 'out_of_stock', 'refilled'].includes(status)) {
      return NextResponse.json(
        { error: 'สถานะไม่ถูกต้อง' },
        { status: 400 }
      );
    }

    // Check cooldown: 1 vote per fingerprint per station+fuel per hour
    if (fingerprint) {
      const { data: recentVote } = await supabase
        .from('fuel_votes')
        .select('id')
        .eq('fingerprint', fingerprint)
        .eq('station_id', station_id)
        .eq('fuel_type_id', fuel_type_id)
        .gte('created_at', new Date(Date.now() - 60 * 60 * 1000).toISOString())
        .limit(1);

      if (recentVote && recentVote.length > 0) {
        return NextResponse.json(
          { error: 'กรุณารอ 1 ชั่วโมงก่อนโหวตอีกครั้ง', cooldown: true },
          { status: 429 }
        );
      }
    }

    const { data, error } = await supabase
      .from('fuel_votes')
      .insert({
        station_id,
        fuel_type_id,
        status,
        fingerprint: fingerprint || null,
        note: note || null,
        image_url: image_url || null,
      })
      .select()
      .single();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ success: true, vote: data });
  } catch {
    return NextResponse.json(
      { error: 'เกิดข้อผิดพลาด กรุณาลองใหม่' },
      { status: 500 }
    );
  }
}
