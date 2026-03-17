'use client';

import { useState, useEffect, useCallback } from 'react';
import dynamic from 'next/dynamic';
import { motion, AnimatePresence } from 'framer-motion';
import { Fuel, MapPin, Search, X, ChevronDown, LocateFixed, Camera, Menu, Filter, MessageSquarePlus } from 'lucide-react';
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
  const [userLocation, setUserLocation] = useState<{ lat: number; lng: number } | null>(null);
  const [provinces, setProvinces] = useState<FilterOption[]>([]);
  const [brands, setBrands] = useState<FilterOption[]>([]);
  const [radius, setRadius] = useState(10); // km
  const [locationReady, setLocationReady] = useState(false);
  const [totalCount, setTotalCount] = useState(0);

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

      // Use radius search from user location
      if (userLocation && !selectedProvince) {
        params.set('lat', userLocation.lat.toString());
        params.set('lng', userLocation.lng.toString());
        params.set('radius', radius.toString());
      }
      params.set('limit', '750');

      const res = await fetch(`/api/fuel/stations?${params.toString()}`);
      const data = await res.json();
      setStations(data.stations || []);
      setTotalCount(data.total || 0);
      if (data.fuel_types) setFuelTypes(data.fuel_types);
    } catch (err) {
      console.error('Failed to fetch stations:', err);
    } finally {
      setLoading(false);
    }
  }, [selectedProvince, selectedBrand, searchQuery, userLocation, radius]);

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

        .fuel-filters {
          display: flex;
          gap: 8px;
          flex-wrap: wrap;
        }

        .filter-chip {
          display: flex;
          align-items: center;
          gap: 6px;
          padding: 6px 14px;
          background: rgba(255, 255, 255, 0.92);
          backdrop-filter: blur(16px);
          border: 1px solid rgba(0, 0, 0, 0.08);
          border-radius: 20px;
          color: #475569;
          font-size: 13px;
          cursor: pointer;
          transition: all 0.2s;
          white-space: nowrap;
          box-shadow: 0 1px 4px rgba(0, 0, 0, 0.04);
        }

        .filter-chip:hover {
          border-color: rgba(0, 0, 0, 0.15);
          color: #1e293b;
        }

        .filter-chip.active {
          background: rgba(245, 158, 11, 0.1);
          border-color: #f59e0b;
          color: #d97706;
        }

        .filter-select {
          padding: 6px 12px;
          background: rgba(255, 255, 255, 0.92);
          backdrop-filter: blur(16px);
          border: 1px solid rgba(0, 0, 0, 0.08);
          border-radius: 12px;
          color: #475569;
          font-size: 13px;
          cursor: pointer;
          outline: none;
          appearance: none;
          -webkit-appearance: none;
          padding-right: 28px;
          background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%2394a3b8' stroke-width='2'%3E%3Cpath d='M6 9l6 6 6-6'/%3E%3C/svg%3E");
          background-repeat: no-repeat;
          background-position: right 10px center;
          box-shadow: 0 1px 4px rgba(0, 0, 0, 0.04);
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
          position: absolute;
          right: 16px;
          bottom: 100px;
          z-index: 1000;
          display: flex;
          flex-direction: column;
          gap: 8px;
        }

        .floating-actions-center {
          position: absolute;
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
          stations={stations}
          fuelTypes={fuelTypes}
          selectedStation={selectedStation}
          onSelectStation={setSelectedStation}
          userLocation={userLocation}
          loading={loading}
          zoom={radiusToZoom(radius)}
        />
      </div>

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
            <button
              className={`header-btn ${showFilters ? 'active' : ''}`}
              onClick={() => setShowFilters(!showFilters)}
            >
              <Filter size={18} />
            </button>
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
        </div>

        {/* Filters */}
        <AnimatePresence>
          {showFilters && (
            <motion.div
              className="fuel-filters"
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              transition={{ duration: 0.2 }}
            >
              <select
                className="filter-select"
                value={radius.toString()}
                onChange={(e) => setRadius(parseInt(e.target.value))}
              >
                {RADIUS_OPTIONS.map((r) => (
                  <option key={r} value={r}>รัศมี {r} กม.</option>
                ))}
              </select>

              <select
                className="filter-select"
                value={selectedProvince}
                onChange={(e) => setSelectedProvince(e.target.value)}
              >
                <option value="">ทุกจังหวัด</option>
                {provinces.map((p) => (
                  <option key={p.name} value={p.name}>{p.name} ({p.count})</option>
                ))}
              </select>

              {brands.map((brand) => (
                <button
                  key={brand.name}
                  className={`filter-chip ${selectedBrand === brand.name ? 'active' : ''}`}
                  onClick={() => setSelectedBrand(selectedBrand === brand.name ? '' : brand.name)}
                >
                  {brand.name}
                </button>
              ))}

              {totalCount > 0 && (
                <span style={{ fontSize: 12, color: 'rgba(255,255,255,0.4)', alignSelf: 'center', whiteSpace: 'nowrap' }}>
                  พบ {totalCount} สถานี
                </span>
              )}
            </motion.div>
          )}
        </AnimatePresence>

        {/* Stats */}
        <StatsBar stations={stations} loading={loading} />
      </div>

      {/* Floating Actions */}
      <div className="floating-actions-right">
        <button className="fab locate" onClick={handleLocateMe}>
          <LocateFixed size={20} />
        </button>
      </div>

      <div className="floating-actions-center">
        <button className="fab report" onClick={() => setShowQuickUpdate(true)}>
          <MessageSquarePlus size={20} />
          อัปเดตสถานะน้ำมัน
        </button>
      </div>

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
            stations={stations}
            fuelTypes={fuelTypes}
            userLocation={userLocation}
            onClose={() => setShowQuickUpdate(false)}
            onVoteSuccess={handleVoteSuccess}
            getFingerprint={getFingerprint}
          />
        )}
      </AnimatePresence>
    </div>
  );
}
