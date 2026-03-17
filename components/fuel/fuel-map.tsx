'use client';

import { useEffect, useMemo } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
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

type DecisiveStatus = 'confirmed_available' | 'confirmed_out' | 'mixed' | 'unknown';

function getDecisiveStatus(status: FuelStatus): DecisiveStatus {
  const now = new Date();
  const lastVote = new Date(status.last_voted_at);
  const diffHours = (now.getTime() - lastVote.getTime()) / (1000 * 60 * 60);

  const isAvailable = status.consensus_status === 'available' || status.consensus_status === 'refilled';
  const isOut = status.consensus_status === 'out_of_stock';

  // 1. Stale or no data
  if (diffHours > 24) return 'unknown';

  // 2. Confirmed cases
  if (isAvailable && diffHours < 6 && (status.confidence > 75 || status.vote_count >= 5)) {
    return 'confirmed_available';
  }
  if (isOut && diffHours < 12 && status.confidence > 75) {
    return 'confirmed_out';
  }

  // 3. Mixed or borderline
  return 'mixed';
}

function getStationColor(station: GasStation): string {
  const fuelStatuses = Object.values(station.fuel_status);
  if (fuelStatuses.length === 0) return '#94a3b8'; // gray - no reports

  const decisiveStatuses = fuelStatuses.map(getDecisiveStatus);

  // If any fuel is confirmed out, prioritize making the marker red
  if (decisiveStatuses.includes('confirmed_out')) return '#EF4444'; 
  
  // If all reported fuels are confirmed available
  if (decisiveStatuses.every(s => s === 'confirmed_available')) return '#22C55E';

  // If we have some availability but also mixed/unknown
  if (decisiveStatuses.includes('confirmed_available')) return '#F59E0B'; // yellow/orange

  return '#94a3b8'; // gray default
}

function createStationIcon(station: GasStation, isSelected: boolean): L.DivIcon {
  const color = getStationColor(station);
  const size = isSelected ? 44 : 34;
  const borderWidth = isSelected ? 3 : 2;

  const fuelStatuses = Object.values(station.fuel_status);
  const voteCount = fuelStatuses.reduce((sum, s) => sum + s.vote_count, 0);

  return L.divIcon({
    className: 'custom-station-marker',
    html: `
      <div style="
        width: ${size}px;
        height: ${size}px;
        background: ${color};
        border: ${borderWidth}px solid white;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        box-shadow: 0 2px 12px rgba(0,0,0,0.4), 0 0 0 ${isSelected ? '4' : '0'}px ${color}40;
        transition: all 0.2s;
        cursor: pointer;
        position: relative;
      ">
        <svg width="${size * 0.45}" height="${size * 0.45}" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <path d="M3 22V6c0-1.1.9-2 2-2h6c1.1 0 2 .9 2 2v16"/>
          <path d="M14 10h2a2 2 0 0 1 2 2v2a2 2 0 0 0 2 2 2 2 0 0 0 2-2V9.83a2 2 0 0 0-.59-1.42L18 5"/>
          <path d="M3 22h10"/>
          <path d="M7 10h4"/>
          <path d="M7 14h4"/>
        </svg>
        ${voteCount > 0 ? `<div style="
          position: absolute;
          top: -4px;
          right: -4px;
          min-width: 18px;
          height: 18px;
          background: white;
          color: ${color};
          border-radius: 9px;
          font-size: 10px;
          font-weight: 700;
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 0 4px;
          box-shadow: 0 1px 4px rgba(0,0,0,0.3);
        ">${voteCount}</div>` : ''}
      </div>
    `,
    iconSize: [size, size],
    iconAnchor: [size / 2, size / 2],
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
  // Use user location or fallback to Thailand center
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
            icon={createStationIcon(station, selectedStation?.id === station.id)}
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
