import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const province = searchParams.get('province');
  const brand = searchParams.get('brand');
  const search = searchParams.get('search');
  const north = searchParams.get('north');
  const south = searchParams.get('south');
  const east = searchParams.get('east');
  const west = searchParams.get('west');
  const lat = searchParams.get('lat');
  const lng = searchParams.get('lng');
  const radius = searchParams.get('radius'); // km

  let query = supabase.from('gas_stations').select('*');

  if (province) {
    query = query.eq('province', province);
  }

  if (brand) {
    query = query.eq('brand', brand);
  }

  if (search) {
    query = query.or(`name.ilike.%${search}%,address.ilike.%${search}%`);
  }

  // Priority: radius search > bounding box > no spatial filter
  if (lat && lng && radius) {
    // Use bounding box approximation for radius search
    // 1 degree lat ≈ 111km, 1 degree lng ≈ 111km * cos(lat)
    const latNum = parseFloat(lat);
    const lngNum = parseFloat(lng);
    const radiusKm = parseFloat(radius);
    const latDelta = radiusKm / 111;
    const lngDelta = radiusKm / (111 * Math.cos((latNum * Math.PI) / 180));

    query = query
      .gte('lat', latNum - latDelta)
      .lte('lat', latNum + latDelta)
      .gte('lng', lngNum - lngDelta)
      .lte('lng', lngNum + lngDelta);
  } else if (north && south && east && west) {
    query = query
      .gte('lat', parseFloat(south))
      .lte('lat', parseFloat(north))
      .gte('lng', parseFloat(west))
      .lte('lng', parseFloat(east));
  }
  // No default location — let the client decide

  // Limit results
  const limit = parseInt(searchParams.get('limit') || '750');
  query = query.limit(Math.min(limit, 2000));

  const { data: stations, error } = await query;

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  // If radius search, compute actual distance and filter/sort by distance
  let resultStations = stations || [];
  if (lat && lng && radius) {
    const latNum = parseFloat(lat);
    const lngNum = parseFloat(lng);
    const radiusKm = parseFloat(radius);

    resultStations = resultStations
      .map((s) => ({
        ...s,
        distance_km: haversine(latNum, lngNum, s.lat, s.lng),
      }))
      .filter((s) => s.distance_km <= radiusKm)
      .sort((a, b) => a.distance_km - b.distance_km);
  }

  // Get fuel status for all returned stations
  const stationIds = resultStations.map((s) => s.id);

  let fuelStatus: Record<
    string,
    Record<string, { consensus_status: string; vote_count: number; last_voted_at: string; confidence: number }>
  > = {};

  if (stationIds.length > 0) {
    const { data: statusData } = await supabase
      .from('station_fuel_status')
      .select('*')
      .in('station_id', stationIds.slice(0, 750));

    if (statusData) {
      for (const s of statusData) {
        if (!fuelStatus[s.station_id]) fuelStatus[s.station_id] = {};
        fuelStatus[s.station_id][s.fuel_type_id] = {
          consensus_status: s.consensus_status,
          vote_count: s.vote_count,
          last_voted_at: s.last_voted_at,
          confidence: s.confidence,
        };
      }
    }
  }

  // Get fuel types
  const { data: fuelTypes } = await supabase
    .from('fuel_types')
    .select('*')
    .order('sort_order');

  const result = resultStations.map((station) => ({
    ...station,
    fuel_status: fuelStatus[station.id] || {},
  }));

  return NextResponse.json({
    stations: result,
    fuel_types: fuelTypes,
    total: result.length,
  });
}

function haversine(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371; // Earth radius in km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// POST: Add a new gas station (community-submitted)
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { name, brand, lat, lng, address, province, district, fuel_types, submitted_by } = body;

    if (!name || !brand || !lat || !lng) {
      return NextResponse.json({ error: 'name, brand, lat, lng are required' }, { status: 400 });
    }

    const { data, error } = await supabase
      .from('gas_stations')
      .insert({
        name,
        brand,
        lat: parseFloat(lat),
        lng: parseFloat(lng),
        address: address || '',
        province: province || '',
        district: district || '',
        fuel_types: fuel_types || ['diesel', 'gasohol_95', 'gasohol_91'],
        is_verified: false,
        submitted_by: submitted_by || null,
      })
      .select()
      .single();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ success: true, station: data });
  } catch (e: unknown) {
    const message = e instanceof Error ? e.message : 'Unknown error';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
