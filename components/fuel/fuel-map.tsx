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

  // Short labels for fuel types
  const FUEL_LABELS: Record<string, string> = {
    'gasohol_91': '91',
    'gasohol_95': '95',
    'gasohol_e20': 'E20',
    'gasohol_e85': 'E85',
    'diesel_b7': 'D',
    'diesel_b20': 'D20',
    'diesel_premium': 'DP',
    'benzin_95': 'B95',
    'lpg': 'LP',
    'ngv': 'NG',
  };

  // Build fuel labels — only show fuels this station carries
  const stationFuelTypes = fuelTypes.filter(ft => station.fuel_types.includes(ft.id));
  const labelsHtml = stationFuelTypes.slice(0, 4).map(ft => {
    const status = station.fuel_status[ft.id];
    let color = '#d1d5db'; // gray - unknown
    if (status) {
      if (isAvailable(status)) color = '#22C55E';
      else if (isOutOfStock(status)) color = '#EF4444';
      else color = '#F59E0B';
    }
    const label = FUEL_LABELS[ft.id] || ft.name_en.substring(0, 2);
    return `<div style="font-size:11px;font-weight:700;color:${color};line-height:1;">${label}</div>`;
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
          border-radius: 10px;
          padding: 6px 10px;
          box-shadow: ${shadow};
          border-left: 4px solid ${brandColor};
          min-width: 60px;
          text-align: center;
        ">
          <div style="
            font-size: 14px;
            font-weight: 800;
            color: ${brandColor};
            line-height: 1.2;
            letter-spacing: -0.3px;
            white-space: nowrap;
          ">${abbr}</div>
          <div style="
            display: flex;
            gap: 4px;
            justify-content: center;
            margin-top: 3px;
          ">${labelsHtml}</div>
        </div>
        <div style="
          width: 0; height: 0;
          border-left: 7px solid transparent;
          border-right: 7px solid transparent;
          border-top: 7px solid white;
          filter: drop-shadow(0 1px 1px rgba(0,0,0,0.15));
        "></div>
      </div>
    `,
    iconSize: [80, 50],
    iconAnchor: [40, 50],
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
