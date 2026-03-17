import { NextResponse } from 'next/server';

interface BangchakOilItem {
  OilName: string;
  PriceYesterday: number;
  PriceToday: number;
  PriceTomorrow: number;
  PriceDifYesterday: number;
  PriceDifTomorrow: number;
}

interface BangchakResponse {
  OilPriceDate: string;
  OilPriceTime: string;
  OilRemark: string;
  OilRemark2: string;
  OilList: string;
}

// Map Bangchak names to our fuel type IDs for linking
const NAME_TO_FUEL_ID: Record<string, string> = {
  'แก๊สโซฮอล์ 91': 'gasohol_91',
  'แก๊สโซฮอล์ 95': 'gasohol_95',
  'แก๊สโซฮอล์ E20': 'gasohol_e20',
  'แก๊สโซฮอล์ E85': 'gasohol_e85',
  'ไฮดีเซล': 'diesel_b7',
  'ดีเซลพรีเมียม': 'diesel_premium',
};

function matchFuelId(oilName: string): string | null {
  const lower = oilName.toLowerCase();
  if (lower.includes('91')) return 'gasohol_91';
  if (lower.includes('e85')) return 'gasohol_e85';
  if (lower.includes('e20')) return 'gasohol_e20';
  if (lower.includes('95') && !lower.includes('97') && !lower.includes('พรีเมียม')) return 'gasohol_95';
  if (lower.includes('97') || (lower.includes('95') && lower.includes('พรีเมียม'))) return 'benzin_95';
  if (lower.includes('ดีเซล') && lower.includes('พรีเมียม')) return 'diesel_premium';
  if (lower.includes('ดีเซล')) return 'diesel_b7';
  return null;
}

// Cache prices in memory (refresh every 30 minutes)
let cachedData: { prices: unknown[]; metadata: unknown; cachedAt: number } | null = null;
const CACHE_TTL = 30 * 60 * 1000; // 30 minutes

export async function GET() {
  // Return cached data if fresh
  if (cachedData && Date.now() - cachedData.cachedAt < CACHE_TTL) {
    return NextResponse.json(cachedData);
  }

  try {
    const res = await fetch('https://oil-price.bangchak.co.th/ApiOilPrice2/th', {
      next: { revalidate: 1800 }, // Cache for 30 min
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'HadyaiFloodApp/1.0',
      },
    });

    if (!res.ok) {
      throw new Error(`Bangchak API error: ${res.status}`);
    }

    const rawData: BangchakResponse[] = await res.json();
    const data = rawData[0];

    if (!data?.OilList) {
      throw new Error('No oil price data');
    }

    const oilList: BangchakOilItem[] = JSON.parse(data.OilList);

    const prices = oilList.map((item) => ({
      name: item.OilName,
      fuel_id: matchFuelId(item.OilName),
      price_today: item.PriceToday,
      price_yesterday: item.PriceYesterday,
      price_tomorrow: item.PriceTomorrow,
      diff_yesterday: item.PriceDifYesterday,
      diff_tomorrow: item.PriceDifTomorrow,
      change: item.PriceToday > item.PriceYesterday
        ? 'up'
        : item.PriceToday < item.PriceYesterday
        ? 'down'
        : 'same',
    }));

    const result = {
      prices,
      metadata: {
        source: 'Bangchak',
        price_date: data.OilPriceDate,
        price_time: data.OilPriceTime,
        remark: data.OilRemark2 || data.OilRemark,
      },
      cachedAt: Date.now(),
    };

    cachedData = result;
    return NextResponse.json(result);
  } catch (error) {
    // Return cached data if available even if stale
    if (cachedData) {
      return NextResponse.json({ ...cachedData, stale: true });
    }
    return NextResponse.json(
      { error: 'ไม่สามารถดึงราคาน้ำมันได้', prices: [] },
      { status: 500 }
    );
  }
}
