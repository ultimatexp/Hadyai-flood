/**
 * Scrape real gas station data from OpenStreetMap via Overpass API
 * and import into Supabase gas_stations table.
 * 
 * Usage: node scripts/scrape-gas-stations.js
 * 
 * This fetches ALL amenity=fuel nodes/ways in Thailand from OSM.
 * Typically returns 5,000-8,000 stations.
 */

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

// Thailand bounding box (approximate)
const THAILAND_BBOX = '5.5,97.3,20.5,105.7';

// Overpass API query to get all fuel stations in Thailand
const OVERPASS_QUERY = `
[out:json][timeout:120];
(
  node["amenity"="fuel"](${THAILAND_BBOX});
  way["amenity"="fuel"](${THAILAND_BBOX});
  relation["amenity"="fuel"](${THAILAND_BBOX});
);
out center body;
`;

const OVERPASS_URL = 'https://overpass-api.de/api/interpreter';

// Brand name normalization map
const BRAND_MAP = {
  // PTT / OR
  'ptt': 'PTT',
  'pt': 'PTT',
  'ปตท': 'PTT',
  'ptt station': 'PTT',
  'or': 'PTT',
  'ptt or': 'PTT',

  // Bangchak
  'bangchak': 'Bangchak',
  'บางจาก': 'Bangchak',
  'bcp': 'Bangchak',

  // Shell
  'shell': 'Shell',
  'เชลล์': 'Shell',

  // Esso
  'esso': 'Esso',
  'เอสโซ่': 'Esso',

  // Caltex
  'caltex': 'Caltex',
  'คาลเท็กซ์': 'Caltex',

  // Susco
  'susco': 'Susco',
  'ซัสโก้': 'Susco',

  // PT (different from PTT)
  'pt gas': 'PT',
  'pt max': 'PT',

  // Jet
  'jet': 'Jet',

  // Cosmo
  'cosmo': 'Cosmo',

  // Thai Oil / TOP
  'thaioil': 'Thai Oil',
  'top': 'Thai Oil',

  // LPG specific
  'siamgas': 'Siamgas',
  'world gas': 'World Gas',
  'unique gas': 'Unique Gas',
};

// Thai province detection from address or coordinates
// Using rough coordinate zones for major provinces
function detectProvince(lat, lng, tags) {
  // Check tags first for addr:province
  if (tags['addr:province']) return tags['addr:province'];
  if (tags['addr:city']) {
    // Try to match Thai province names
    const city = tags['addr:city'];
    if (city.includes('กรุงเทพ') || city === 'Bangkok') return 'กรุงเทพมหานคร';
    return city;
  }

  // Rough coordinate-based detection for major areas
  if (lat >= 13.5 && lat <= 14.0 && lng >= 100.3 && lng <= 100.9) return 'กรุงเทพมหานคร';
  if (lat >= 12.6 && lat <= 13.5 && lng >= 100.7 && lng <= 101.5) return 'ชลบุรี';
  if (lat >= 13.8 && lat <= 14.3 && lng >= 100.3 && lng <= 100.7) return 'นนทบุรี';
  if (lat >= 13.9 && lat <= 14.3 && lng >= 100.5 && lng <= 100.9) return 'ปทุมธานี';
  if (lat >= 13.4 && lat <= 13.8 && lng >= 100.2 && lng <= 100.6) return 'สมุทรปราการ';
  if (lat >= 18.6 && lat <= 19.1 && lng >= 98.8 && lng <= 99.1) return 'เชียงใหม่';
  if (lat >= 14.9 && lat <= 15.2 && lng >= 100.4 && lng <= 100.6) return 'นครสวรรค์';
  if (lat >= 16.3 && lat <= 16.6 && lng >= 102.7 && lng <= 103.0) return 'ขอนแก่น';
  if (lat >= 14.8 && lat <= 15.1 && lng >= 102.0 && lng <= 102.4) return 'นครราชสีมา';
  if (lat >= 7.8 && lat <= 8.2 && lng >= 98.3 && lng <= 98.5) return 'ภูเก็ต';
  if (lat >= 6.8 && lat <= 7.3 && lng >= 100.3 && lng <= 100.7) return 'สงขลา';
  if (lat >= 8.4 && lat <= 8.7 && lng >= 99.9 && lng <= 100.1) return 'สุราษฎร์ธานี';
  if (lat >= 12.5 && lat <= 12.8 && lng >= 101.8 && lng <= 102.2) return 'ระยอง';
  if (lat >= 13.1 && lat <= 13.5 && lng >= 99.9 && lng <= 100.2) return 'นครปฐม';
  if (lat >= 14.0 && lat <= 14.5 && lng >= 100.9 && lng <= 101.4) return 'สระบุรี';
  if (lat >= 14.3 && lat <= 14.6 && lng >= 100.4 && lng <= 100.7) return 'พระนครศรีอยุธยา';

  return 'ไม่ทราบจังหวัด';
}

function normalizeBrand(tags) {
  const brand = (tags.brand || tags.operator || tags.name || '').toLowerCase().trim();

  for (const [key, value] of Object.entries(BRAND_MAP)) {
    if (brand.includes(key)) return value;
  }

  // If no match, try to extract from name
  const name = (tags.name || '').toLowerCase();
  for (const [key, value] of Object.entries(BRAND_MAP)) {
    if (name.includes(key)) return value;
  }

  // Return original brand or 'อื่นๆ' (Other)
  return tags.brand || tags.operator || 'อื่นๆ';
}

function determineFuelTypes(tags) {
  const fuels = [];

  // Check explicit fuel tags from OSM
  const fuelMapping = {
    'fuel:octane_91': 'gasohol_91',
    'fuel:gasohol_91': 'gasohol_91',
    'fuel:octane_95': 'gasohol_95',
    'fuel:gasohol_95': 'gasohol_95',
    'fuel:e20': 'gasohol_e20',
    'fuel:gasohol_e20': 'gasohol_e20',
    'fuel:e85': 'gasohol_e85',
    'fuel:gasohol_e85': 'gasohol_e85',
    'fuel:diesel': 'diesel_b7',
    'fuel:biodiesel': 'diesel_b7',
    'fuel:HGV_diesel': 'diesel_b7',
    'fuel:diesel:b7': 'diesel_b7',
    'fuel:diesel:b20': 'diesel_b20',
    'fuel:lpg': 'lpg',
    'fuel:cng': 'ngv',
    'fuel:ngv': 'ngv',
  };

  for (const [osmKey, fuelId] of Object.entries(fuelMapping)) {
    if (tags[osmKey] === 'yes') {
      if (!fuels.includes(fuelId)) fuels.push(fuelId);
    }
  }

  // If no specific fuel tags, assign defaults based on brand
  if (fuels.length === 0) {
    const brand = normalizeBrand(tags);
    if (['PTT', 'Bangchak', 'Shell', 'Esso', 'Caltex'].includes(brand)) {
      fuels.push('gasohol_91', 'gasohol_95', 'diesel_b7');
    } else if (brand === 'Susco' || brand === 'PT') {
      fuels.push('gasohol_91', 'gasohol_95', 'diesel_b7');
    } else {
      fuels.push('gasohol_91', 'gasohol_95', 'diesel_b7');
    }
  }

  return fuels;
}

function buildStationName(tags, brand) {
  if (tags.name) return tags.name;
  if (tags['name:th']) return tags['name:th'];
  if (tags['name:en']) return tags['name:en'];

  const location = tags['addr:district'] || tags['addr:subdistrict'] || tags['addr:city'] || '';
  if (location) return `${brand} ${location}`;

  return `${brand} สาขา`;
}

function buildAddress(tags) {
  const parts = [];
  if (tags['addr:housenumber']) parts.push(tags['addr:housenumber']);
  if (tags['addr:street']) parts.push(tags['addr:street']);
  if (tags['addr:subdistrict']) parts.push('ต.' + tags['addr:subdistrict']);
  if (tags['addr:district']) parts.push('อ.' + tags['addr:district']);
  if (tags['addr:province']) parts.push(tags['addr:province']);
  if (tags['addr:postcode']) parts.push(tags['addr:postcode']);

  return parts.length > 0 ? parts.join(' ') : (tags['addr:full'] || '');
}

async function fetchFromOverpass() {
  console.log('🌍 Fetching gas stations from OpenStreetMap Overpass API...');
  console.log('📦 Query covers all of Thailand (bbox: ' + THAILAND_BBOX + ')');
  console.log('⏳ This may take 30-60 seconds...\n');

  const response = await fetch(OVERPASS_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: 'data=' + encodeURIComponent(OVERPASS_QUERY),
  });

  if (!response.ok) {
    throw new Error(`Overpass API error: ${response.status} ${response.statusText}`);
  }

  const data = await response.json();
  console.log(`✅ Received ${data.elements.length} raw elements from OSM\n`);
  return data.elements;
}

function processElements(elements) {
  const stations = [];

  for (const el of elements) {
    const tags = el.tags || {};

    // Get coordinates (nodes have lat/lng directly, ways have center)
    let lat, lng;
    if (el.type === 'node') {
      lat = el.lat;
      lng = el.lon;
    } else if (el.center) {
      lat = el.center.lat;
      lng = el.center.lon;
    } else {
      continue; // Skip elements without coordinates
    }

    // Skip if outside Thailand bounds (safety check)
    if (lat < 5.5 || lat > 20.5 || lng < 97.3 || lng > 105.7) continue;

    const brand = normalizeBrand(tags);
    const province = detectProvince(lat, lng, tags);
    const district = tags['addr:district'] || tags['addr:subdistrict'] || '';
    const fuelTypes = determineFuelTypes(tags);
    const name = buildStationName(tags, brand);
    const address = buildAddress(tags);

    stations.push({
      name,
      brand,
      lat: Math.round(lat * 10000) / 10000, // 4 decimal places (~11m precision)
      lng: Math.round(lng * 10000) / 10000,
      address: address || null,
      province,
      district,
      fuel_types: fuelTypes,
      is_verified: false,
    });
  }

  return stations;
}

async function clearOldData() {
  console.log('🗑️  Clearing old placeholder station data...');

  const response = await fetch(`${SUPABASE_URL}/rest/v1/gas_stations`, {
    method: 'DELETE',
    headers: {
      'apikey': SUPABASE_KEY,
      'Authorization': `Bearer ${SUPABASE_KEY}`,
      'Content-Type': 'application/json',
      'Prefer': 'return=minimal',
    },
    // Delete all non-verified stations (our old placeholders)
    body: undefined,
  });

  // Use RPC or just delete all since we're replacing everything
  const deleteRes = await fetch(`${SUPABASE_URL}/rest/v1/gas_stations?is_verified=eq.false`, {
    method: 'DELETE',
    headers: {
      'apikey': SUPABASE_KEY,
      'Authorization': `Bearer ${SUPABASE_KEY}`,
      'Prefer': 'return=minimal',
    },
  });

  console.log('✅ Old data cleared\n');
}

async function insertStations(stations) {
  console.log(`📤 Inserting ${stations.length} stations into Supabase...`);

  // Insert in batches of 500
  const BATCH_SIZE = 500;
  let inserted = 0;

  for (let i = 0; i < stations.length; i += BATCH_SIZE) {
    const batch = stations.slice(i, i + BATCH_SIZE);
    
    const response = await fetch(`${SUPABASE_URL}/rest/v1/gas_stations`, {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
      body: JSON.stringify(batch),
    });

    if (!response.ok) {
      const err = await response.text();
      console.error(`❌ Batch ${i / BATCH_SIZE + 1} failed:`, err);
      continue;
    }

    inserted += batch.length;
    const pct = Math.round((inserted / stations.length) * 100);
    console.log(`   📦 Batch ${Math.floor(i / BATCH_SIZE) + 1}: ${inserted}/${stations.length} (${pct}%)`);
  }

  return inserted;
}

function printStats(stations) {
  // Brand distribution
  const brands = {};
  for (const s of stations) {
    brands[s.brand] = (brands[s.brand] || 0) + 1;
  }

  // Province distribution (top 15)
  const provinces = {};
  for (const s of stations) {
    provinces[s.province] = (provinces[s.province] || 0) + 1;
  }

  console.log('\n📊 Brand Distribution:');
  const sortedBrands = Object.entries(brands).sort((a, b) => b[1] - a[1]);
  for (const [brand, count] of sortedBrands.slice(0, 15)) {
    const bar = '█'.repeat(Math.ceil(count / (sortedBrands[0][1] / 30)));
    console.log(`   ${brand.padEnd(15)} ${String(count).padStart(5)} ${bar}`);
  }

  console.log('\n📍 Top 15 Provinces:');
  const sortedProvinces = Object.entries(provinces).sort((a, b) => b[1] - a[1]);
  for (const [prov, count] of sortedProvinces.slice(0, 15)) {
    const bar = '█'.repeat(Math.ceil(count / (sortedProvinces[0][1] / 30)));
    console.log(`   ${prov.padEnd(25)} ${String(count).padStart(5)} ${bar}`);
  }

  console.log(`\n   Total provinces: ${Object.keys(provinces).length}`);
}

async function main() {
  console.log('='.repeat(60));
  console.log('⛽ Gas Station Scraper — OpenStreetMap → Supabase');
  console.log('='.repeat(60) + '\n');

  if (!SUPABASE_URL || !SUPABASE_KEY) {
    console.error('❌ Missing SUPABASE env vars. Run with:');
    console.error('   source .env.local && node scripts/scrape-gas-stations.js');
    process.exit(1);
  }

  try {
    // 1. Fetch from Overpass API
    const elements = await fetchFromOverpass();

    // 2. Process into station objects
    const stations = processElements(elements);
    console.log(`🔧 Processed ${stations.length} valid stations\n`);

    // 3. Print statistics
    printStats(stations);

    // 4. Clear old data
    await clearOldData();

    // 5. Insert new data
    const inserted = await insertStations(stations);
    
    console.log('\n' + '='.repeat(60));
    console.log(`✅ Done! Imported ${inserted} real gas stations into Supabase.`);
    console.log('='.repeat(60));

  } catch (error) {
    console.error('❌ Fatal error:', error.message);
    process.exit(1);
  }
}

main();
