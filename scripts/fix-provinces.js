/**
 * Fix province assignments for gas stations using Nominatim reverse geocoding.
 * Only processes stations with province = 'ไม่ทราบจังหวัด'.
 * 
 * Nominatim rate limit: 1 request/second, so this batches smartly.
 * We group nearby stations and use a grid-based approach.
 * 
 * Usage: source .env.local && node scripts/fix-provinces.js
 */

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

// Use grid cells (~0.25 degrees = ~25km) to reduce API calls
// Instead of geocoding each station, geocode the center of each grid cell
const GRID_SIZE = 0.25;

async function fetchUnknownStations() {
  console.log('📍 Fetching stations with unknown province...');
  
  let allStations = [];
  let offset = 0;
  const limit = 1000;

  while (true) {
    const url = `${SUPABASE_URL}/rest/v1/gas_stations?province=eq.ไม่ทราบจังหวัด&select=id,lat,lng&offset=${offset}&limit=${limit}`;
    const res = await fetch(url, {
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
      },
    });
    const data = await res.json();
    if (data.length === 0) break;
    allStations = allStations.concat(data);
    offset += limit;
    if (data.length < limit) break;
  }

  console.log(`   Found ${allStations.length} stations with unknown province\n`);
  return allStations;
}

function buildGrid(stations) {
  const grid = {};
  
  for (const station of stations) {
    const cellLat = Math.floor(station.lat / GRID_SIZE) * GRID_SIZE;
    const cellLng = Math.floor(station.lng / GRID_SIZE) * GRID_SIZE;
    const key = `${cellLat},${cellLng}`;

    if (!grid[key]) {
      grid[key] = {
        centerLat: cellLat + GRID_SIZE / 2,
        centerLng: cellLng + GRID_SIZE / 2,
        stationIds: [],
      };
    }
    grid[key].stationIds.push(station.id);
  }

  return grid;
}

async function reverseGeocode(lat, lng) {
  const url = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&zoom=6&accept-language=th&addressdetails=1`;
  
  const res = await fetch(url, {
    headers: {
      'User-Agent': 'HadyaiFloodApp/1.0 (fuel-tracker-province-fix)',
    },
  });

  if (!res.ok) return null;

  const data = await res.json();
  const address = data.address || {};
  
  // Try different fields for province
  let province = address.state || address.province || address.county || address.city || '';

  // Handle Bangkok special case
  if (province.includes('กรุงเทพ') || province === 'Bangkok') {
    province = 'กรุงเทพมหานคร';
  }

  // Remove country if no province found
  if (!province || province === address.country) {
    return null;
  }

  return province;
}

async function updateStations(stationIds, province) {
  // Update in batches
  const BATCH_SIZE = 200;
  for (let i = 0; i < stationIds.length; i += BATCH_SIZE) {
    const batch = stationIds.slice(i, i + BATCH_SIZE);
    const idFilter = batch.map(id => `"${id}"`).join(',');

    await fetch(`${SUPABASE_URL}/rest/v1/gas_stations?id=in.(${idFilter})`, {
      method: 'PATCH',
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
      body: JSON.stringify({ province }),
    });
  }
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {
  console.log('='.repeat(60));
  console.log('📍 Province Fixer — Nominatim Reverse Geocoding');
  console.log('='.repeat(60) + '\n');

  if (!SUPABASE_URL || !SUPABASE_KEY) {
    console.error('❌ Missing env vars. Run: source .env.local && node scripts/fix-provinces.js');
    process.exit(1);
  }

  // 1. Get stations with unknown province
  const stations = await fetchUnknownStations();
  if (stations.length === 0) {
    console.log('✅ No stations with unknown province. All good!');
    return;
  }

  // 2. Build grid
  const grid = buildGrid(stations);
  const gridCells = Object.entries(grid);
  console.log(`🗺️  Grouped into ${gridCells.length} grid cells (${GRID_SIZE}° ≈ 25km each)`);
  console.log(`📡 Will make ${gridCells.length} Nominatim API calls (~${Math.ceil(gridCells.length / 60)} minutes)\n`);

  // 3. Process each grid cell
  let processed = 0;
  let updated = 0;
  const provinceCount = {};

  for (const [key, cell] of gridCells) {
    processed++;
    const province = await reverseGeocode(cell.centerLat, cell.centerLng);

    if (province) {
      await updateStations(cell.stationIds, province);
      updated += cell.stationIds.length;
      provinceCount[province] = (provinceCount[province] || 0) + cell.stationIds.length;
      
      const pct = Math.round((processed / gridCells.length) * 100);
      if (processed % 10 === 0 || processed === gridCells.length) {
        console.log(`   [${pct}%] Cell ${processed}/${gridCells.length} → ${province} (${cell.stationIds.length} stations)`);
      }
    } else {
      console.log(`   ⚠️  Cell ${key} — no province found (${cell.stationIds.length} stations, likely outside Thailand)`);
    }

    // Respect Nominatim rate limit: 1 req/sec
    await sleep(1100);
  }

  // 4. Report
  console.log('\n' + '='.repeat(60));
  console.log(`✅ Updated ${updated} stations across ${Object.keys(provinceCount).length} provinces\n`);

  const sorted = Object.entries(provinceCount).sort((a, b) => b[1] - a[1]);
  for (const [prov, count] of sorted) {
    console.log(`   ${prov.padEnd(30)} ${count}`);
  }
  console.log('='.repeat(60));
}

main();
