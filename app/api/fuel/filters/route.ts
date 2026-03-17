import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

export async function GET() {
  const { data, error } = await supabase
    .from('gas_stations')
    .select('province')
    .neq('province', 'ไม่ทราบจังหวัด')
    .order('province');

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  // Deduplicate and count
  const provinceCounts: Record<string, number> = {};
  for (const row of data || []) {
    provinceCounts[row.province] = (provinceCounts[row.province] || 0) + 1;
  }

  const provinces = Object.entries(provinceCounts)
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => b.count - a.count);

  // Also get unique brands
  const { data: brandData } = await supabase
    .from('gas_stations')
    .select('brand');

  const brandCounts: Record<string, number> = {};
  for (const row of brandData || []) {
    brandCounts[row.brand] = (brandCounts[row.brand] || 0) + 1;
  }

  const brands = Object.entries(brandCounts)
    .map(([name, count]) => ({ name, count }))
    .filter(b => b.count >= 10) // Only show brands with 10+ stations
    .sort((a, b) => b.count - a.count);

  return NextResponse.json({ provinces, brands });
}
