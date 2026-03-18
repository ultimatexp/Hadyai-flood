'use client';

import { useEffect } from 'react';
import { MapContainer, TileLayer, Marker, useMap } from 'react-leaflet';
import MarkerClusterGroup from 'react-leaflet-cluster';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import 'leaflet-defaulticon-compatibility';
import 'leaflet-defaulticon-compatibility/dist/leaflet-defaulticon-compatibility.css';

interface FuelStatus {
  consensus_status: string;
  vote_count: number;
  last_voted_at: string;
  confidence: number;
}

interface GasStation {
  id: string;
  name: string;
  brand: string;
  lat: number;
  lng: number;
  address: string;
  province: string;
  district: string;
  fuel_types: string[];
  is_verified: boolean;
  fuel_status: Record<string, FuelStatus>;
}

interface FuelType {
  id: string;
  name_th: string;
  name_en: string;
  color: string;
  sort_order: number;
}

interface FuelMapProps {
  stations: GasStation[];
  fuelTypes: FuelType[];
  selectedStation: GasStation | null;
  onSelectStation: (station: GasStation) => void;
  userLocation: { lat: number; lng: number } | null;
  loading: boolean;
  zoom?: number;
}

const BRAND_ABBR: Record<string, string> = {
  'PTT': 'PTT',
  'Bangchak': 'BCP',
  'Shell': 'Shell',
  'Esso': 'Esso',
  'Caltex': 'CTX',
  'Susco': 'SSC',
  'PT': 'PT',
};

const BRAND_COLORS: Record<string, string> = {
  'PTT': '#2D5CA0',
  'Bangchak': '#00A651',
  'Shell': '#DD1D21',
  'Esso': '#D41E31',
  'Caltex': '#E2231A',
  'Susco': '#E4002B',
  'PT': '#0066B3',
};

function isAvailable(status: FuelStatus): boolean {
  const now = new Date();
  const lastVote = new Date(status.last_voted_at);
  const diffHours = (now.getTime() - lastVote.getTime()) / (1000 * 60 * 60);
  if (diffHours > 24) return false;
  return status.consensus_status === 'available' || status.consensus_status === 'refilled';
}

function isOutOfStock(status: FuelStatus): boolean {
  const now = new Date();
  const lastVote = new Date(status.last_voted_at);
  const diffHours = (now.getTime() - lastVote.getTime()) / (1000 * 60 * 60);
  if (diffHours > 24) return false;
  return status.consensus_status === 'out_of_stock';
}

function getOverallColor(station: GasStation): string {
  const statuses = Object.values(station.fuel_status);
  if (statuses.length === 0) return '#94a3b8';
  const hasOut = statuses.some(isOutOfStock);
  const allAvail = statuses.length > 0 && statuses.every(isAvailable);
  if (allAvail) return '#22C55E';
  if (hasOut) return '#EF4444';
  if (statuses.some(isAvailable)) return '#F59E0B';
  return '#94a3b8';
}

function createStationCardIcon(
  station: GasStation,
  fuelTypes: FuelType[],
  isSelected: boolean
): L.DivIcon {
  const brandColor = BRAND_COLORS[station.brand] || '#64748b';
  const abbr = BRAND_ABBR[station.brand] || station.brand.substring(0, 3);
  const overallColor = getOverallColor(station);

  // Build fuel dots — only show fuels this station carries
  const stationFuelTypes = fuelTypes.filter(ft => station.fuel_types.includes(ft.id));
  const dotsHtml = stationFuelTypes.slice(0, 4).map(ft => {
    const status = station.fuel_status[ft.id];
    let dotColor = '#d1d5db'; // gray - unknown
    if (status) {
      if (isAvailable(status)) dotColor = '#22C55E';
      else if (isOutOfStock(status)) dotColor = '#EF4444';
      else dotColor = '#F59E0B';
    }
    return `<div style="width:6px;height:6px;border-radius:50%;background:${dotColor};"></div>`;
  }).join('');

  const scale = isSelected ? 1.1 : 1;
  const shadow = isSelected
    ? `0 3px 12px rgba(0,0,0,0.35), 0 0 0 3px ${overallColor}40`
    : '0 2px 8px rgba(0,0,0,0.25)';

  return L.divIcon({
    className: 'station-card-marker',
    html: `
      <div style="
        transform: scale(${scale});
        transition: transform 0.2s;
        cursor: pointer;
        display: flex;
        flex-direction: column;
        align-items: center;
      ">
        <div style="
          background: white;
          border-radius: 8px;
          padding: 3px 6px;
          box-shadow: ${shadow};
          border-left: 3px solid ${brandColor};
          min-width: 38px;
          text-align: center;
        ">
          <div style="
            font-size: 9px;
            font-weight: 800;
            color: ${brandColor};
            line-height: 1.2;
            letter-spacing: -0.3px;
            white-space: nowrap;
          ">${abbr}</div>
          <div style="
            display: flex;
            gap: 2px;
            justify-content: center;
            margin-top: 2px;
          ">${dotsHtml}</div>
        </div>
        <div style="
          width: 0; height: 0;
          border-left: 5px solid transparent;
          border-right: 5px solid transparent;
          border-top: 5px solid white;
          filter: drop-shadow(0 1px 1px rgba(0,0,0,0.15));
        "></div>
      </div>
    `,
    iconSize: [50, 36],
    iconAnchor: [25, 36],
  });
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function createClusterIcon(cluster: any): L.DivIcon {
  const count = cluster.getChildCount();
  const size = count > 50 ? 56 : count > 20 ? 48 : 40;

  return L.divIcon({
    className: 'custom-cluster-icon',
    html: `
      <div style="
        width: ${size}px;
        height: ${size}px;
        background: rgba(255, 255, 255, 0.95);
        border: 2px solid rgba(0, 0, 0, 0.12);
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        color: #1e293b;
        font-size: ${count > 50 ? 14 : 13}px;
        font-weight: 700;
        box-shadow: 0 2px 12px rgba(0,0,0,0.12);
        backdrop-filter: blur(8px);
        letter-spacing: -0.5px;
      ">${count}</div>
    `,
    iconSize: [size, size],
    iconAnchor: [size / 2, size / 2],
  });
}

function LocationUpdater({ location, zoom }: { location: { lat: number; lng: number } | null; zoom: number }) {
  const map = useMap();
  useEffect(() => {
    if (location) {
      map.setView([location.lat, location.lng], zoom, { animate: true });
    }
  }, [location, zoom, map]);
  return null;
}

export default function FuelMap({
  stations,
  fuelTypes,
  selectedStation,
  onSelectStation,
  userLocation,
  loading,
  zoom = 13,
}: FuelMapProps) {
  const center: [number, number] = userLocation
    ? [userLocation.lat, userLocation.lng]
    : [13.7563, 100.5018];

  return (
    <MapContainer
      center={center}
      zoom={zoom}
      style={{ height: '100%', width: '100%' }}
      zoomControl={false}
    >
      <TileLayer
        attribution='&copy; MapTiler'
        url={`https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=${process.env.NEXT_PUBLIC_MAPTILER_KEY}`}
      />

      <LocationUpdater location={userLocation} zoom={zoom} />

      <MarkerClusterGroup
        chunkedLoading
        maxClusterRadius={60}
        spiderfyOnMaxZoom
        showCoverageOnHover={false}
        iconCreateFunction={createClusterIcon}
      >
        {stations.map((station) => (
          <Marker
            key={station.id}
            position={[station.lat, station.lng]}
            icon={createStationCardIcon(station, fuelTypes, selectedStation?.id === station.id)}
            eventHandlers={{
              click: () => onSelectStation(station),
            }}
          />
        ))}
      </MarkerClusterGroup>

      {/* User location marker */}
      {userLocation && (
        <Marker
          position={[userLocation.lat, userLocation.lng]}
          icon={L.divIcon({
            className: 'user-location-marker',
            html: `
              <div style="
                width: 20px;
                height: 20px;
                background: #3B82F6;
                border: 3px solid white;
                border-radius: 50%;
                box-shadow: 0 0 0 8px rgba(59,130,246,0.2), 0 2px 8px rgba(0,0,0,0.3);
              "></div>
            `,
            iconSize: [20, 20],
            iconAnchor: [10, 10],
          })}
        />
      )}
    </MapContainer>
  );
}
