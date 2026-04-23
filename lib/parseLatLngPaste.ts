/**
 * Parses latitude/longitude pasted from Google Maps, e.g.
 * `(13.3226994, 101.1165946)` or `13.3226994, 101.1165946`.
 * Order is latitude, then longitude (WGS84).
 */
export function parseLatLngPaste(raw: string): { lat: number; lng: number } | null {
    const s = raw.trim();
    if (!s) return null;

    const inner =
        s.startsWith("(") && s.endsWith(")") ? s.slice(1, -1).trim() : s;

    const commaIdx = inner.indexOf(",");
    if (commaIdx === -1) return null;

    const lat = Number(inner.slice(0, commaIdx).trim());
    const lng = Number(inner.slice(commaIdx + 1).trim());

    if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
    if (Math.abs(lat) > 90 || Math.abs(lng) > 180) return null;

    return { lat, lng };
}
