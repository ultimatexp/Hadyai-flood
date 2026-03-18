'use client';

import { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import dynamic from 'next/dynamic';
import { motion, AnimatePresence } from 'framer-motion';
import { Fuel, MapPin, Search, X, ChevronDown, LocateFixed, Camera, Menu, Filter, MessageSquarePlus, Plus } from 'lucide-react';
import Lottie from 'lottie-react';
import donateAnimation from '@/assets/json/Donaciones.json';
import StationPanel from '@/components/fuel/station-panel';
import StatsBar from '@/components/fuel/stats-bar';
import OilPriceWidget from '@/components/fuel/oil-price-widget';
import QuickUpdateSheet from '@/components/fuel/quick-update-sheet';
import { supabase } from '@/lib/supabase';

const FuelMap = dynamic(() => import('@/components/fuel/fuel-map'), { ssr: false });

interface FuelType {
  id: string;
  name_th: string;
  name_en: string;
  color: string;
  sort_order: number;
}

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

interface FilterOption {
  name: string;
  count: number;
}

export default function FuelPage() {
  const [stations, setStations] = useState<GasStation[]>([]);
  const [fuelTypes, setFuelTypes] = useState<FuelType[]>([]);
  const [selectedStation, setSelectedStation] = useState<GasStation | null>(null);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedProvince, setSelectedProvince] = useState<string>('');
  const [selectedBrand, setSelectedBrand] = useState<string>('');
  const [showFilters, setShowFilters] = useState(false);
  const [showQuickUpdate, setShowQuickUpdate] = useState(false);
  const [selectedFuelType, setSelectedFuelType] = useState<string>('');
  const [userLocation, setUserLocation] = useState<{ lat: number; lng: number } | null>(null);
  const [provinces, setProvinces] = useState<FilterOption[]>([]);
  const [brands, setBrands] = useState<FilterOption[]>([]);
  const [radius, setRadius] = useState(10); // km
  const [locationReady, setLocationReady] = useState(false);
  const [totalCount, setTotalCount] = useState(0);
  const [showInstructions, setShowInstructions] = useState(false);
  const [mapCenter, setMapCenter] = useState<{ lat: number; lng: number } | null>(null);
  const [showAddStation, setShowAddStation] = useState(false);
  const [isPickingLocation, setIsPickingLocation] = useState(false);
  const [addStationName, setAddStationName] = useState('');
  const [addStationBrand, setAddStationBrand] = useState('PTT');
  const [addingStation, setAddingStation] = useState(false);
  const moveDebounceRef = useRef<NodeJS.Timeout | null>(null);

  // Show instructions on first visit
  useEffect(() => {
    const seen = localStorage.getItem('fuel_instructions_seen');
    if (!seen) setShowInstructions(true);
  }, []);

  const dismissInstructions = () => {
    setShowInstructions(false);
    localStorage.setItem('fuel_instructions_seen', '1');
  };

  const RADIUS_OPTIONS = [5, 10, 25, 50, 100];

  // Auto-detect user location on mount
  useEffect(() => {
    if (!navigator.geolocation) {
      setLocationReady(true);
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setUserLocation({ lat: pos.coords.latitude, lng: pos.coords.longitude });
        setLocationReady(true);
      },
      () => {
        // Geolocation denied — will use viewport-based loading
        setLocationReady(true);
      },
      { timeout: 8000, enableHighAccuracy: false }
    );
  }, []);

  const fetchStations = useCallback(async () => {
    try {
      const params = new URLSearchParams();
      if (selectedProvince) params.set('province', selectedProvince);
      if (selectedBrand) params.set('brand', selectedBrand);
      if (searchQuery) params.set('search', searchQuery);

      // Use radius search from map center (follows pan) or user location
      const center = mapCenter || userLocation;
      if (center && !selectedProvince) {
        params.set('lat', center.lat.toString());
        params.set('lng', center.lng.toString());
        params.set('radius', radius.toString());
      }
      params.set('limit', '750');

      const res = await fetch(`/api/fuel/stations?${params.toString()}`);
      const data = await res.json();

      // Fallback: if radius returned 0 stations, retry without location filter
      if ((data.stations || []).length === 0 && userLocation && !selectedProvince) {
        const fallbackParams = new URLSearchParams();
        if (selectedBrand) fallbackParams.set('brand', selectedBrand);
        if (searchQuery) fallbackParams.set('search', searchQuery);
        fallbackParams.set('limit', '750');
        const fbRes = await fetch(`/api/fuel/stations?${fallbackParams.toString()}`);
        const fbData = await fbRes.json();
        setStations(fbData.stations || []);
        setTotalCount(fbData.total || 0);
        if (fbData.fuel_types) setFuelTypes(fbData.fuel_types);
      } else {
        setStations(data.stations || []);
        setTotalCount(data.total || 0);
        if (data.fuel_types) setFuelTypes(data.fuel_types);
      }
    } catch (err) {
      console.error('Failed to fetch stations:', err);
    } finally {
      setLoading(false);
    }
  }, [selectedProvince, selectedBrand, searchQuery, userLocation, mapCenter, radius]);

  // Fetch when filters, location, or radius change
  useEffect(() => {
    if (locationReady) fetchStations();
  }, [fetchStations, locationReady]);

  // Fetch dynamic filter options
  useEffect(() => {
    fetch('/api/fuel/filters')
      .then(res => res.json())
      .then(data => {
        if (data.provinces) setProvinces(data.provinces);
        if (data.brands) setBrands(data.brands);
      })
      .catch(console.error);
  }, []);

  // Supabase Realtime subscription for live vote updates
  useEffect(() => {
    const channel = supabase
      .channel('fuel-votes-realtime')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'fuel_votes' },
        () => fetchStations()
      )
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchStations]);

  // Map zoom level based on radius
  const radiusToZoom = (r: number): number => {
    if (r <= 5) return 14;
    if (r <= 10) return 13;
    if (r <= 25) return 11;
    if (r <= 50) return 10;
    return 9;
  };

  const handleLocateMe = () => {
    if (!navigator.geolocation) return;
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setUserLocation({ lat: pos.coords.latitude, lng: pos.coords.longitude });
      },
      (err) => console.error('Geolocation error:', err),
      { enableHighAccuracy: true }
    );
  };

  // When user pans/zooms the map, refetch based on new center
  const handleMapMoveEnd = useCallback((center: { lat: number; lng: number }) => {
    if (moveDebounceRef.current) clearTimeout(moveDebounceRef.current);
    moveDebounceRef.current = setTimeout(() => {
      setMapCenter(center);
    }, 400);
  }, []);

  const handleVoteSuccess = () => {
    fetchStations();
    // Don't close panel, let user continue voting on other fuels
  };

  const getFingerprint = (): string => {
    const stored = localStorage.getItem('fuel_fingerprint');
    if (stored) return stored;
    const fp = Math.random().toString(36).substring(2) + Date.now().toString(36);
    localStorage.setItem('fuel_fingerprint', fp);
    return fp;
  };

  // Client-side filtering by fuel type and brand
  const filteredStations = useMemo(() => {
    let result = stations;
    if (selectedFuelType) {
      result = result.filter(s => s.fuel_types.includes(selectedFuelType));
    }
    if (selectedBrand) {
      result = result.filter(s => s.brand === selectedBrand);
    }
    return result;
  }, [stations, selectedFuelType, selectedBrand]);

  return (
    <div className="fuel-page">
      <style jsx global>{`
        .fuel-page {
          position: fixed;
          inset: 0;
          overflow: hidden;
          font-family: 'Prompt', 'Sarabun', sans-serif;
          background: #f8fafc;
        }

        .fuel-header {
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          z-index: 1000;
          padding: 12px 16px;
          display: flex;
          flex-direction: column;
          gap: 8px;
          pointer-events: none;
        }

        .fuel-header > * {
          pointer-events: auto;
        }

        .fuel-logo-bar {
          display: flex;
          align-items: center;
          justify-content: space-between;
        }

        .fuel-logo {
          display: flex;
          align-items: center;
          gap: 8px;
          background: rgba(255, 255, 255, 0.92);
          backdrop-filter: blur(16px);
          -webkit-backdrop-filter: blur(16px);
          padding: 8px 16px;
          border-radius: 20px;
          border: 1px solid rgba(0, 0, 0, 0.08);
          box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
        }

        .fuel-logo-icon {
          width: 28px;
          height: 28px;
          background: linear-gradient(135deg, #f59e0b, #ef4444);
          border-radius: 8px;
          display: flex;
          align-items: center;
          justify-content: center;
          color: white;
        }

        .fuel-logo-text {
          font-size: 16px;
          font-weight: 700;
          color: #1e293b;
          letter-spacing: -0.3px;
        }

        .fuel-logo-sub {
          font-size: 11px;
          color: #94a3b8;
          font-weight: 400;
        }

        .header-actions {
          display: flex;
          gap: 8px;
        }

        .header-btn {
          width: 40px;
          height: 40px;
          background: rgba(255, 255, 255, 0.92);
          backdrop-filter: blur(16px);
          -webkit-backdrop-filter: blur(16px);
          border: 1px solid rgba(0, 0, 0, 0.08);
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          color: #475569;
          cursor: pointer;
          transition: all 0.2s;
          box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
        }

        .header-btn:hover {
          background: rgba(255, 255, 255, 0.98);
          border-color: rgba(0, 0, 0, 0.12);
        }

        .header-btn.active {
          background: rgba(245, 158, 11, 0.1);
          border-color: #f59e0b;
          color: #d97706;
        }

        .fuel-search-bar {
          display: flex;
          align-items: center;
          gap: 8px;
          background: rgba(255, 255, 255, 0.95);
          backdrop-filter: blur(16px);
          -webkit-backdrop-filter: blur(16px);
          padding: 8px 16px;
          border-radius: 16px;
          border: 1px solid rgba(0, 0, 0, 0.08);
          box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
        }

        .fuel-search-input {
          flex: 1;
          background: transparent;
          border: none;
          color: #1e293b;
          font-size: 15px;
          outline: none;
        }

        .fuel-search-input::placeholder {
          color: #94a3b8;
        }

        .filter-section {
          display: flex;
          flex-direction: column;
          gap: 4px;
        }

        .filter-label {
          font-size: 11px;
          font-weight: 600;
          color: #64748b;
          text-transform: uppercase;
          letter-spacing: 0.5px;
          padding-left: 2px;
        }

        .quick-filter-row {
          display: flex;
          gap: 6px;
          overflow-x: auto;
          padding: 2px 0;
          -webkit-overflow-scrolling: touch;
          scrollbar-width: none;
          -ms-overflow-style: none;
        }
        .quick-filter-row::-webkit-scrollbar { display: none; }

        .qf-pill {
          display: flex;
          align-items: center;
          gap: 4px;
          padding: 7px 14px;
          background: rgba(255, 255, 255, 0.95);
          backdrop-filter: blur(20px);
          border: 1.5px solid rgba(0, 0, 0, 0.08);
          border-radius: 20px;
          color: #64748b;
          font-size: 13px;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.2s;
          white-space: nowrap;
          flex-shrink: 0;
          box-shadow: 0 1px 3px rgba(0,0,0,0.06);
          font-family: inherit;
        }
        .qf-pill:hover { border-color: rgba(0,0,0,0.2); color: #334155; }
        .qf-pill.active {
          background: linear-gradient(135deg, #f59e0b, #ef4444);
          border-color: transparent;
          color: white;
          box-shadow: 0 2px 8px rgba(245,158,11,0.3);
        }
        .fuel-pill.active { background: linear-gradient(135deg, #f59e0b, #ea580c); }

        /* Brand-specific pill colors (inactive) */
        .brand-pill { border-width: 2px; }
        .brand-pill[data-brand='PTT']   { background: rgba(45,92,160,0.08); border-color: rgba(45,92,160,0.25); color: #2D5CA0; }
        .brand-pill[data-brand='Bangchak'] { background: rgba(0,166,81,0.08); border-color: rgba(0,166,81,0.25); color: #00A651; }
        .brand-pill[data-brand='Shell']  { background: rgba(255,185,0,0.10); border-color: rgba(255,185,0,0.35); color: #B38200; }
        .brand-pill[data-brand='Caltex'] { background: rgba(226,35,26,0.08); border-color: rgba(226,35,26,0.25); color: #C41E1A; }
        .brand-pill[data-brand='Esso']   { background: rgba(212,30,49,0.08); border-color: rgba(212,30,49,0.25); color: #D41E31; }
        .brand-pill[data-brand='Susco']  { background: rgba(255,107,0,0.10); border-color: rgba(255,107,0,0.35); color: #E06000; }
        .brand-pill[data-brand='PT']     { background: rgba(0,102,179,0.08); border-color: rgba(0,102,179,0.25); color: #0066B3; }
        .brand-pill[data-brand='Sinopec']{ background: rgba(200,16,46,0.08); border-color: rgba(200,16,46,0.25); color: #C8102E; }

        /* Brand-specific active states */
        .brand-pill[data-brand='PTT'].active    { background: #2D5CA0; color: white; border-color: transparent; box-shadow: 0 2px 8px rgba(45,92,160,0.4); }
        .brand-pill[data-brand='Bangchak'].active { background: #00A651; color: white; border-color: transparent; box-shadow: 0 2px 8px rgba(0,166,81,0.4); }
        .brand-pill[data-brand='Shell'].active   { background: #FFB900; color: #333; border-color: transparent; box-shadow: 0 2px 8px rgba(255,185,0,0.4); }
        .brand-pill[data-brand='Caltex'].active  { background: #E2231A; color: white; border-color: transparent; box-shadow: 0 2px 8px rgba(226,35,26,0.4); }
        .brand-pill[data-brand='Esso'].active    { background: #D41E31; color: white; border-color: transparent; box-shadow: 0 2px 8px rgba(212,30,49,0.4); }
        .brand-pill[data-brand='Susco'].active   { background: #FF6B00; color: white; border-color: transparent; box-shadow: 0 2px 8px rgba(255,107,0,0.4); }
        .brand-pill[data-brand='PT'].active      { background: #0066B3; color: white; border-color: transparent; box-shadow: 0 2px 8px rgba(0,102,179,0.4); }
        .brand-pill[data-brand='Sinopec'].active { background: #C8102E; color: white; border-color: transparent; box-shadow: 0 2px 8px rgba(200,16,46,0.4); }
        .clear-pill {
          background: rgba(239,68,68,0.08) !important;
          border-color: rgba(239,68,68,0.2) !important;
          color: #ef4444 !important;
          font-weight: 700;
        }
        .clear-pill:hover { background: rgba(239,68,68,0.15) !important; }

        .qf-divider {
          width: 1px;
          background: rgba(0,0,0,0.1);
          flex-shrink: 0;
          margin: 4px 2px;
        }

        .filter-select option {
          background: white;
          color: #1e293b;
        }

        .map-container {
          position: absolute;
          inset: 0;
        }

        .floating-actions-right {
          position: fixed;
          right: 16px;
          bottom: 100px;
          z-index: 1000;
          display: flex;
          flex-direction: column;
          gap: 8px;
        }

        .floating-actions-left {
          position: fixed;
          left: 16px;
          bottom: 100px;
          z-index: 1000;
        }

        .donate-fab {
          width: 56px;
          height: 56px;
          border-radius: 50%;
          background: rgba(255, 255, 255, 0.95);
          backdrop-filter: blur(16px);
          border: 2px solid rgba(251, 191, 36, 0.4);
          box-shadow: 0 4px 16px rgba(251, 191, 36, 0.3);
          cursor: pointer;
          display: flex;
          align-items: center;
          justify-content: center;
          overflow: hidden;
          transition: transform 0.2s, box-shadow 0.2s;
        }
        .donate-fab:hover {
          transform: scale(1.1);
          box-shadow: 0 6px 24px rgba(251, 191, 36, 0.5);
        }

        .radius-select {
          padding: 6px 8px;
          border: none;
          border-left: 1px solid rgba(0,0,0,0.08);
          background: transparent;
          font-size: 13px;
          font-weight: 600;
          color: #3b82f6;
          cursor: pointer;
          outline: none;
          appearance: auto;
          min-width: 90px;
        }

        .floating-actions-center {
          position: fixed;
          left: 50%;
          transform: translateX(-50%);
          bottom: 110px;
          z-index: 1000;
          display: flex;
          justify-content: center;
        }

        .fab {
          width: 48px;
          height: 48px;
          background: rgba(255, 255, 255, 0.95);
          backdrop-filter: blur(16px);
          border: 1px solid rgba(0, 0, 0, 0.08);
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          color: #475569;
          cursor: pointer;
          transition: all 0.2s;
          box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
        }

        .fab:hover {
          transform: scale(1.05);
          border-color: rgba(0, 0, 0, 0.15);
        }

        .fab.locate {
          color: #3b82f6;
          border-color: rgba(59, 130, 246, 0.2);
        }

        .fab.report {
          width: auto;
          height: 48px;
          padding: 0 24px;
          border-radius: 24px;
          background: linear-gradient(135deg, #f59e0b, #ef4444);
          color: white;
          border: none;
          box-shadow: 0 4px 20px rgba(245, 158, 11, 0.35);
          font-weight: 600;
          font-size: 14px;
          gap: 8px;
          white-space: nowrap;
        }

        .fab.report:hover {
          box-shadow: 0 6px 28px rgba(245, 158, 11, 0.5);
          transform: scale(1.02);
        }

        @media (max-width: 640px) {
          .fuel-header {
            padding: 8px 12px;
          }
          .fuel-logo-text { font-size: 14px; }
          .fuel-search-bar { padding: 6px 12px; }
        }
      `}</style>

      {/* Map */}
      <div className="map-container">
        <FuelMap
          stations={filteredStations}
          fuelTypes={fuelTypes}
          selectedStation={selectedStation}
          onSelectStation={setSelectedStation}
          userLocation={userLocation}
          loading={loading}
          zoom={radiusToZoom(radius)}
          onMoveEnd={handleMapMoveEnd}
        />
      </div>

      {/* Instruction Popup */}
      <AnimatePresence>
        {showInstructions && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={dismissInstructions}
            style={{
              position: 'fixed', inset: 0, zIndex: 9999,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              background: 'rgba(0,0,0,0.6)', backdropFilter: 'blur(8px)',
              WebkitBackdropFilter: 'blur(8px)', padding: 20,
            }}
          >
            <motion.div
              initial={{ opacity: 0, scale: 0.9, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.9, y: 20 }}
              transition={{ type: 'spring', damping: 25 }}
              onClick={(e) => e.stopPropagation()}
              style={{
                background: 'white', borderRadius: 24, padding: '32px 24px',
                maxWidth: 400, width: '100%', textAlign: 'center' as const,
                boxShadow: '0 20px 60px rgba(0,0,0,0.3)',
              }}
            >
              <div style={{
                width: 64, height: 64, margin: '0 auto 16px',
                background: 'linear-gradient(135deg, #f59e0b, #ef4444)',
                borderRadius: 20, display: 'flex', alignItems: 'center',
                justifyContent: 'center', fontSize: 32,
              }}>⛽</div>
              <div style={{ fontSize: 22, fontWeight: 800, color: '#0f172a', marginBottom: 8 }}>
                เช็คน้ำมัน ใกล้ฉัน
              </div>
              <div style={{ fontSize: 14, color: '#64748b', marginBottom: 24, lineHeight: 1.6 }}>
                ช่วยกันรายงานสถานะน้ำมันแต่ละปั๊ม<br />
                เพื่อให้ทุกคนรู้ว่าปั๊มไหนมี ปั๊มไหนหมด
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: 12, textAlign: 'left' as const, marginBottom: 28 }}>
                {[
                  { icon: '📍', text: <>กดที่ <b>หมุดปั๊ม</b> บนแผนที่ เพื่อดูสถานะน้ำมัน</> },
                  { icon: '🗳️', text: <>กด <b>โหวต</b> ว่าน้ำมันแต่ละชนิด มี/หมด/เติมใหม่</> },
                  { icon: '🟢', text: <>สีเขียว = มีน้ำมัน &nbsp; 🔴 สีแดง = หมดแล้ว</> },
                  { icon: '📢', text: <>กดปุ่ม <b>&quot;แจ้งน้ำมันหมด&quot;</b> ด้านล่าง เพื่ออัปเดตหลายปั๊มพร้อมกัน</> },
                ].map((step, i) => (
                  <div key={i} style={{
                    display: 'flex', alignItems: 'flex-start', gap: 12,
                    padding: 12, background: '#f8fafc', borderRadius: 14,
                    border: '1px solid #e2e8f0',
                  }}>
                    <div style={{
                      width: 28, height: 28, borderRadius: '50%',
                      background: 'linear-gradient(135deg, #f59e0b, #ef4444)',
                      color: 'white', display: 'flex', alignItems: 'center',
                      justifyContent: 'center', fontSize: 13, fontWeight: 700, flexShrink: 0,
                    }}>{i + 1}</div>
                    <div style={{ fontSize: 14, color: '#334155', fontWeight: 500, lineHeight: 1.5 }}>
                      {step.icon} {step.text}
                    </div>
                  </div>
                ))}
              </div>

              <button
                onClick={dismissInstructions}
                style={{
                  width: '100%', padding: 14,
                  background: 'linear-gradient(135deg, #f59e0b, #ef4444)',
                  color: 'white', border: 'none', borderRadius: 14,
                  fontSize: 16, fontWeight: 700, fontFamily: 'inherit',
                  cursor: 'pointer', boxShadow: '0 4px 16px rgba(245,158,11,0.3)',
                }}
              >
                เข้าใจแล้ว เริ่มใช้งาน! 🚀
              </button>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Header */}
      <div className="fuel-header">
        <div className="fuel-logo-bar">
          <div className="fuel-logo">
            <div className="fuel-logo-icon">
              <Fuel size={16} />
            </div>
            <div>
              <div className="fuel-logo-text">เช็คน้ำมัน</div>
              <div className="fuel-logo-sub">สถานีไหนมี สถานีไหนหมด</div>
            </div>
          </div>
          <div className="header-actions">
            <button className="header-btn locate" onClick={handleLocateMe}>
              <LocateFixed size={18} />
            </button>
          </div>
        </div>

        {/* Search */}
        <div className="fuel-search-bar">
          <Search size={18} color="#94a3b8" />
          <input
            className="fuel-search-input"
            placeholder="ค้นหาสถานี หรือ ที่อยู่..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
          {searchQuery && (
            <button onClick={() => setSearchQuery('')} style={{ background: 'none', border: 'none', cursor: 'pointer' }}>
              <X size={16} color="#94a3b8" />
            </button>
          )}
          <select
            className="radius-select"
            value={radius}
            onChange={(e) => setRadius(Number(e.target.value))}
          >
            {[5, 10, 25, 50, 100].map((r) => (
              <option key={r} value={r}>{r} กม.</option>
            ))}
          </select>
        </div>

        {/* Fuel type row */}
        <div className="filter-section">
          <span className="filter-label">ประเภทน้ำมัน</span>
          <div className="quick-filter-row">
            <button
              className={`qf-pill fuel-pill ${selectedFuelType === '' ? 'active' : ''}`}
              onClick={() => setSelectedFuelType('')}
            >
              ⛽ ทั้งหมด
            </button>
            <button
              className={`qf-pill fuel-pill ${selectedFuelType === 'diesel_b7' ? 'active' : ''}`}
              onClick={() => setSelectedFuelType(selectedFuelType === 'diesel_b7' ? '' : 'diesel_b7')}
            >
              🟡 ดีเซล
            </button>
            <button
              className={`qf-pill fuel-pill ${selectedFuelType === 'gasohol_91' ? 'active' : ''}`}
              onClick={() => setSelectedFuelType(selectedFuelType === 'gasohol_91' ? '' : 'gasohol_91')}
            >
              🟢 91
            </button>
            <button
              className={`qf-pill fuel-pill ${selectedFuelType === 'gasohol_95' ? 'active' : ''}`}
              onClick={() => setSelectedFuelType(selectedFuelType === 'gasohol_95' ? '' : 'gasohol_95')}
            >
              🔵 95
            </button>
            {selectedFuelType && (
              <button className="qf-pill clear-pill" onClick={() => setSelectedFuelType('')}>✕</button>
            )}
          </div>
        </div>

        {/* Brand row */}
        <div className="filter-section">
          <span className="filter-label">แบรนด์</span>
          <div className="quick-filter-row">
            {['PTT', 'Bangchak', 'Shell', 'Caltex', 'Esso', 'Susco', 'PT', 'Sinopec'].map((brand) => (
              <button
                key={brand}
                data-brand={brand}
                className={`qf-pill brand-pill ${selectedBrand === brand ? 'active' : ''}`}
                onClick={() => setSelectedBrand(selectedBrand === brand ? '' : brand)}
              >
                {brand}
              </button>
            ))}
            {selectedBrand && (
              <button className="qf-pill clear-pill" onClick={() => setSelectedBrand('')}>✕</button>
            )}
          </div>
        </div>


      </div>

      {/* Floating Actions */}
      {!isPickingLocation && (
        <div className="floating-actions-right">
          <button className="fab locate" onClick={handleLocateMe}>
            <LocateFixed size={20} />
          </button>
          <button className="fab" onClick={() => setIsPickingLocation(true)} title="เพิ่มสถานีใหม่" style={{ background: 'linear-gradient(135deg, #22c55e, #16a34a)', color: 'white', border: 'none' }}>
            <Plus size={22} />
          </button>
        </div>
      )}

      {/* Donate FAB — bottom left */}
      {!isPickingLocation && (
        <a href="/donate" className="floating-actions-left">
          <div className="donate-fab">
            <Lottie animationData={donateAnimation} loop autoplay style={{ width: 44, height: 44 }} />
          </div>
        </a>
      )}

      {!isPickingLocation && (
        <div className="floating-actions-center">
          <button className="fab report" onClick={() => setShowQuickUpdate(true)}>
            <MessageSquarePlus size={20} />
            แจ้งน้ำมันหมด
          </button>
        </div>
      )}

      {/* Oil Price Widget — hide when station panel is open */}
      {!selectedStation && <OilPriceWidget />}

      {/* Station Detail Panel */}
      <AnimatePresence>
        {selectedStation && (
          <StationPanel
            station={selectedStation}
            fuelTypes={fuelTypes}
            onClose={() => setSelectedStation(null)}
            onVoteSuccess={handleVoteSuccess}
            getFingerprint={getFingerprint}
          />
        )}
      </AnimatePresence>

      {/* Quick Update Sheet */}
      <AnimatePresence>
        {showQuickUpdate && (
          <QuickUpdateSheet
            stations={filteredStations}
            fuelTypes={fuelTypes}
            userLocation={userLocation}
            onClose={() => setShowQuickUpdate(false)}
            onVoteSuccess={handleVoteSuccess}
            getFingerprint={getFingerprint}
          />
        )}
      </AnimatePresence>

      {/* Add Station Modal */}
      <AnimatePresence>
        {showAddStation && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setShowAddStation(false)}
            style={{
              position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)',
              zIndex: 2000, display: 'flex', alignItems: 'center', justifyContent: 'center',
              padding: 16,
            }}
          >
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              onClick={(e) => e.stopPropagation()}
              style={{
                background: 'white', borderRadius: 16, padding: 24,
                width: '100%', maxWidth: 400, boxShadow: '0 25px 60px rgba(0,0,0,0.3)',
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
                <h3 style={{ margin: 0, fontSize: 18, fontWeight: 700, color: '#1e293b' }}>
                  📍 เพิ่มสถานีใหม่
                </h3>
                <button onClick={() => setShowAddStation(false)} style={{ background: 'none', border: 'none', cursor: 'pointer' }}>
                  <X size={20} color="#94a3b8" />
                </button>
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                <div>
                  <label style={{ fontSize: 13, fontWeight: 600, color: '#475569', marginBottom: 4, display: 'block' }}>
                    ชื่อสถานี
                  </label>
                  <input
                    value={addStationName}
                    onChange={(e) => setAddStationName(e.target.value)}
                    placeholder="เช่น ปั๊ม PTT สาขาหาดใหญ่ใน"
                    style={{
                      width: '100%', padding: '10px 14px', borderRadius: 10,
                      border: '1px solid #e2e8f0', fontSize: 14, outline: 'none',
                      boxSizing: 'border-box',
                    }}
                  />
                </div>

                <div>
                  <label style={{ fontSize: 13, fontWeight: 600, color: '#475569', marginBottom: 4, display: 'block' }}>
                    แบรนด์
                  </label>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
                    {['PTT', 'Bangchak', 'Shell', 'Caltex', 'Esso', 'Susco', 'PT', 'Sinopec', 'อื่นๆ'].map((b) => (
                      <button
                        key={b}
                        onClick={() => setAddStationBrand(b)}
                        style={{
                          padding: '6px 14px', borderRadius: 20, fontSize: 12, fontWeight: 600,
                          border: addStationBrand === b ? '2px solid #3b82f6' : '1px solid #e2e8f0',
                          background: addStationBrand === b ? '#eff6ff' : 'white',
                          color: addStationBrand === b ? '#2563eb' : '#64748b',
                          cursor: 'pointer', transition: 'all 0.15s',
                        }}
                      >
                        {b}
                      </button>
                    ))}
                  </div>
                </div>

                <button
                  disabled={!addStationName.trim() || addingStation}
                  onClick={async () => {
                    const center = mapCenter || userLocation;
                    if (!center) {
                      alert('ไม่สามารถระบุตำแหน่งได้ กรุณาเลื่อนแผนที่');
                      return;
                    }
                    setAddingStation(true);
                    try {
                      const res = await fetch('/api/fuel/stations', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                          name: addStationName.trim(),
                          brand: addStationBrand === 'อื่นๆ' ? 'Other' : addStationBrand,
                          lat: center.lat,
                          lng: center.lng,
                        }),
                      });
                      const data = await res.json();
                      if (data.success) {
                        setShowAddStation(false);
                        setAddStationName('');
                        setAddStationBrand('PTT');
                        // Refresh stations
                        fetchStations();
                        alert('✅ เพิ่มสถานีสำเร็จ! สถานีจะแสดงบนแผนที่');
                      } else {
                        alert('เกิดข้อผิดพลาด: ' + (data.error || 'ลองใหม่อีกครั้ง'));
                      }
                    } catch {
                      alert('เกิดข้อผิดพลาด กรุณาลองใหม่');
                    } finally {
                      setAddingStation(false);
                    }
                  }}
                  style={{
                    marginTop: 8, padding: '12px', borderRadius: 12, border: 'none',
                    background: addStationName.trim() ? 'linear-gradient(135deg, #22c55e, #16a34a)' : '#e2e8f0',
                    color: addStationName.trim() ? 'white' : '#94a3b8',
                    fontSize: 15, fontWeight: 700, cursor: addStationName.trim() ? 'pointer' : 'default',
                    transition: 'all 0.2s',
                  }}
                >
                  {addingStation ? '⏳ กำลังเพิ่ม...' : '✅ เพิ่มสถานี'}
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Location Picker Overlay */}
      {isPickingLocation && (
        <>
          <div style={{
            position: 'fixed', top: '50%', left: '50%', transform: 'translate(-50%, -100%)',
            zIndex: 1500, pointerEvents: 'none',
          }}>
            <MapPin size={48} color="#dc2626" fill="#fecaca" strokeWidth={1.5} style={{ filter: 'drop-shadow(0 4px 6px rgba(0,0,0,0.3))' }} />
          </div>
          
          <div style={{
            position: 'fixed', bottom: 40, left: '50%', transform: 'translateX(-50%)',
            zIndex: 1500, display: 'flex', flexDirection: 'column', alignItems: 'center',
            gap: 12, background: 'rgba(255,255,255,0.95)', backdropFilter: 'blur(8px)',
            padding: '16px 24px', borderRadius: 20, boxShadow: '0 10px 40px rgba(0,0,0,0.2)',
            border: '1px solid rgba(0,0,0,0.1)', width: 'max-content',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, color: '#1e293b', fontWeight: 600 }}>
              <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#22c55e', animation: 'pulse 2s infinite' }} />
              เลื่อนแผนที่เพื่อระบุตำแหน่งสถานี
            </div>
            <div style={{ display: 'flex', gap: 12, width: '100%' }}>
              <button
                onClick={() => setIsPickingLocation(false)}
                style={{
                  flex: 1, padding: '10px 16px', borderRadius: 12, border: '1px solid #e2e8f0',
                  background: 'white', color: '#64748b', fontWeight: 600, cursor: 'pointer',
                }}
              >
                ยกเลิก
              </button>
              <button
                onClick={() => {
                  setIsPickingLocation(false);
                  setShowAddStation(true);
                }}
                style={{
                  flex: 1, padding: '10px 16px', borderRadius: 12, border: 'none',
                  background: 'linear-gradient(135deg, #22c55e, #16a34a)', color: 'white',
                  fontWeight: 600, cursor: 'pointer', boxShadow: '0 4px 12px rgba(34,197,94,0.3)',
                }}
              >
                ยืนยันตำแหน่ง
              </button>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
