'use client';

import { useEffect, useRef, useMemo } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap, useMapEvents } from 'react-leaflet';
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
  onMoveEnd?: (center: { lat: number; lng: number }) => void;
  isPickingLocation?: boolean;
  pickerLocation?: { lat: number; lng: number } | null;
  onPickerLocationChange?: (loc: { lat: number; lng: number }) => void;
  searchedLocation?: { lat: number; lng: number } | null;
}

const BRAND_ABBR: Record<string, string> = {
  'PTT': 'PTT',
  'Bangchak': 'BCP',
  'Shell': 'Shell',
  'Esso': 'Esso',
  'Caltex': 'CTX',
  'Susco': 'SSC',
  'PT': 'PT',
  'Other': 'อื่นๆ',
};

const BRAND_COLORS: Record<string, string> = {
  'PTT': '#2D5CA0',
  'Bangchak': '#00A651',
  'Shell': '#FFB900',
  'Esso': '#D41E31',
  'Caltex': '#E2231A',
  'Susco': '#FF6B00',
  'PT': '#1B5E20',
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

  // Focus on main fuel types
  const MAIN_FUELS = ['diesel', 'diesel_b7', 'gasohol_91', 'gasohol_95'];
  const FUEL_LABELS: Record<string, string> = {
    'diesel': 'D',
    'diesel_b7': 'D',
    'gasohol_91': '91',
    'gasohol_95': '95',
  };

  // Build fuel badge pills — large colored badges
  const badgesHtml = MAIN_FUELS.map(fuelId => {
    const hasType = station.fuel_types.includes(fuelId);
    if (!hasType) return ''; // skip fuels this station doesn't carry

    const status = station.fuel_status[fuelId];
    let bg = '#e2e8f0'; let textColor = '#94a3b8'; // gray = no data
    if (status) {
      if (isAvailable(status)) { bg = '#22C55E'; textColor = '#fff'; }
      else if (isOutOfStock(status)) { bg = '#EF4444'; textColor = '#fff'; }
      else { bg = '#F59E0B'; textColor = '#fff'; }
    }
    const label = FUEL_LABELS[fuelId] || fuelId;
    return `<div style="
      background:${bg};
      color:${textColor};
      font-size:12px;
      font-weight:800;
      padding:2px 7px;
      border-radius:6px;
      line-height:1.3;
      min-width:20px;
      text-align:center;
    ">${label}</div>`;
  }).filter(Boolean).join('');

  const scale = isSelected ? 1.15 : 1;
  const shadow = isSelected
    ? '0 4px 16px rgba(0,0,0,0.3), 0 0 0 2px ' + brandColor + '60'
    : '0 2px 8px rgba(0,0,0,0.2)';

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
          background: linear-gradient(135deg, ${brandColor}12, white 60%);
          border-radius: 10px;
          padding: 5px 6px 4px;
          box-shadow: ${shadow};
          text-align: center;
          border-left: 3px solid ${brandColor};
        ">
          <div style="
            font-size:9px;
            font-weight:700;
            color:${brandColor};
            line-height:1;
            letter-spacing:-0.2px;
            white-space:nowrap;
            margin-bottom:3px;
          ">${abbr}</div>
          <div style="
            display:flex;
            gap:3px;
            justify-content:center;
          ">${badgesHtml}</div>
        </div>
        <div style="
          width:0; height:0;
          border-left:6px solid transparent;
          border-right:6px solid transparent;
          border-top:6px solid white;
          filter:drop-shadow(0 1px 1px rgba(0,0,0,0.12));
        "></div>
      </div>
    `,
    iconSize: [70, 48],
    iconAnchor: [35, 48],
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

function MoveEndHandler({ onMoveEnd }: { onMoveEnd?: (center: { lat: number; lng: number }) => void }) {
  useMapEvents({
    moveend: (e) => {
      if (onMoveEnd) {
        const center = e.target.getCenter();
        onMoveEnd({ lat: center.lat, lng: center.lng });
      }
    },
  });
  return null;
}

function SearchPanUpdater({ location }: { location: { lat: number; lng: number } | null }) {
  const map = useMap();
  useEffect(() => {
    if (location) {
      map.flyTo([location.lat, location.lng], 16, { animate: true });
    }
  }, [location, map]);
  return null;
}

const pickerIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-red.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41]
});

function DraggableMarker({
  position,
  setPosition,
}: {
  position: { lat: number; lng: number };
  setPosition: (pos: { lat: number; lng: number }) => void;
}) {
  const markerRef = useRef<L.Marker>(null);
  const eventHandlers = useMemo(
    () => ({
      dragend() {
        const marker = markerRef.current;
        if (marker != null) {
          setPosition(marker.getLatLng());
        }
      },
    }),
    [setPosition]
  );

  return (
    <Marker
      draggable={true}
      eventHandlers={eventHandlers}
      position={[position.lat, position.lng]}
      ref={markerRef}
      icon={pickerIcon}
      zIndexOffset={2000}
    >
      <Popup minWidth={90}>📍 เลื่อนหมุดเพื่อระบุตำแหน่ง</Popup>
    </Marker>
  );
}

export default function FuelMap({
  stations,
  fuelTypes,
  selectedStation,
  onSelectStation,
  userLocation,
  loading,
  zoom = 13,
  onMoveEnd,
  isPickingLocation,
  pickerLocation,
  onPickerLocationChange,
  searchedLocation,
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
      <SearchPanUpdater location={searchedLocation || null} />
      <MoveEndHandler onMoveEnd={onMoveEnd} />

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

      {isPickingLocation && pickerLocation && onPickerLocationChange && (
        <DraggableMarker position={pickerLocation} setPosition={onPickerLocationChange} />
      )}

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
