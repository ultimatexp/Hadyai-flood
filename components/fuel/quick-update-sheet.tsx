'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { X, MapPin, CheckCircle, XCircle, RefreshCw, Navigation } from 'lucide-react';

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

interface QuickUpdateSheetProps {
  stations: GasStation[];
  fuelTypes: FuelType[];
  userLocation: { lat: number; lng: number } | null;
  onClose: () => void;
  onVoteSuccess: () => void;
  getFingerprint: () => string;
}

function haversineDistance(
  lat1: number, lng1: number,
  lat2: number, lng2: number
): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

const BRAND_COLORS: Record<string, string> = {
  PTT: '#2D5CA0',
  Bangchak: '#00A651',
  Shell: '#FFB81C',
  Esso: '#D41E31',
  Caltex: '#E2231A',
  Susco: '#E4002B',
};

export default function QuickUpdateSheet({
  stations,
  fuelTypes,
  userLocation,
  onClose,
  onVoteSuccess,
  getFingerprint,
}: QuickUpdateSheetProps) {
  const [submitting, setSubmitting] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  // Sort stations by distance from user
  const nearbyStations = userLocation
    ? stations
        .map((s) => ({
          ...s,
          distance: haversineDistance(userLocation.lat, userLocation.lng, s.lat, s.lng),
        }))
        .sort((a, b) => a.distance - b.distance)
        .slice(0, 8)
    : stations.slice(0, 8);

  const handleQuickVote = async (
    stationId: string,
    fuelTypeId: string,
    status: string
  ) => {
    const key = `${stationId}-${fuelTypeId}`;
    setSubmitting(key);
    setSuccess(null);

    try {
      const res = await fetch('/api/fuel/vote', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          station_id: stationId,
          fuel_type_id: fuelTypeId,
          status,
          fingerprint: getFingerprint(),
        }),
      });

      if (res.ok) {
        setSuccess(key);
        onVoteSuccess();
        setTimeout(() => setSuccess(null), 2000);
      }
    } catch {
      console.error('Vote failed');
    } finally {
      setSubmitting(null);
    }
  };

  return (
    <motion.div
      initial={{ y: '100%' }}
      animate={{ y: 0 }}
      exit={{ y: '100%' }}
      transition={{ type: 'spring', damping: 25, stiffness: 300 }}
      style={{
        position: 'fixed',
        bottom: 0,
        left: 0,
        right: 0,
        zIndex: 2000,
        maxHeight: '80vh',
        overflowY: 'auto',
        borderTopLeftRadius: 24,
        borderTopRightRadius: 24,
        background: 'rgba(255, 255, 255, 0.98)',
        backdropFilter: 'blur(24px)',
        WebkitBackdropFilter: 'blur(24px)',
        borderTop: '1px solid rgba(0,0,0,0.08)',
        boxShadow: '0 -8px 40px rgba(0,0,0,0.12)',
      }}
    >
      {/* Drag handle */}
      <div style={{
        width: 40, height: 4, background: 'rgba(0,0,0,0.15)',
        borderRadius: 2, margin: '12px auto',
      }} />

      <div style={{ padding: '0 20px 24px' }}>
        {/* Header */}
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          marginBottom: 16,
        }}>
          <div>
            <div style={{ fontSize: 18, fontWeight: 700, color: '#1e293b' }}>
              📢 รายงานสถานะน้ำมัน
            </div>
            <div style={{ fontSize: 13, color: '#94a3b8', marginTop: 2 }}>
              {userLocation ? 'ปั๊มใกล้คุณ — แตะเพื่อรายงานเลย' : 'เลือกปั๊มที่คุณต้องการรายงาน'}
            </div>
          </div>
          <button
            onClick={onClose}
            style={{
              width: 36, height: 36, background: 'rgba(0,0,0,0.05)',
              border: 'none', borderRadius: '50%',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              color: '#94a3b8', cursor: 'pointer',
            }}
          >
            <X size={18} />
          </button>
        </div>

        {/* Station List */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {nearbyStations.map((station) => {
            const dist = 'distance' in station ? (station as { distance: number }).distance : null;
            const brandColor = BRAND_COLORS[station.brand] || '#64748b';
            const stationFuelTypes = fuelTypes.filter((ft) =>
              station.fuel_types.includes(ft.id)
            );

            return (
              <div
                key={station.id}
                style={{
                  background: 'rgba(0,0,0,0.02)',
                  border: '1px solid rgba(0,0,0,0.06)',
                  borderRadius: 16,
                  padding: 14,
                }}
              >
                {/* Station header */}
                <div style={{
                  display: 'flex', alignItems: 'center', gap: 10,
                  marginBottom: 10,
                }}>
                  <div style={{
                    width: 36, height: 36, borderRadius: 10,
                    background: `${brandColor}15`,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    color: brandColor, fontWeight: 800, fontSize: 11,
                    flexShrink: 0,
                  }}>
                    {station.brand.slice(0, 3)}
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{
                      fontSize: 14, fontWeight: 600, color: '#1e293b',
                      overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                    }}>
                      {station.name}
                    </div>
                    <div style={{
                      fontSize: 11, color: '#94a3b8',
                      display: 'flex', alignItems: 'center', gap: 4,
                    }}>
                      <MapPin size={10} />
                      {station.district}, {station.province}
                      {dist !== null && (
                        <span style={{
                          marginLeft: 6, color: '#3b82f6', fontWeight: 600,
                          display: 'inline-flex', alignItems: 'center', gap: 2,
                        }}>
                          <Navigation size={9} />
                          {dist < 1 ? `${Math.round(dist * 1000)}m` : `${dist.toFixed(1)}km`}
                        </span>
                      )}
                    </div>
                  </div>
                </div>

                {/* Quick vote buttons per fuel type */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                  {stationFuelTypes.slice(0, 4).map((ft) => {
                    const key = `${station.id}-${ft.id}`;
                    const isSubmitting = submitting === key;
                    const isSuccess = success === key;

                    return (
                      <div key={ft.id} style={{
                        display: 'flex', alignItems: 'center', gap: 8,
                      }}>
                        {/* Fuel name */}
                        <div style={{
                          display: 'flex', alignItems: 'center', gap: 6,
                          flex: 1, minWidth: 0,
                        }}>
                          <div style={{
                            width: 8, height: 8, borderRadius: '50%',
                            background: ft.color, flexShrink: 0,
                          }} />
                          <span style={{
                            fontSize: 12, color: '#475569', fontWeight: 500,
                            overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                          }}>
                            {ft.name_th}
                          </span>
                        </div>

                        {/* Vote buttons */}
                        {isSuccess ? (
                          <div style={{
                            fontSize: 11, color: '#22C55E', fontWeight: 600,
                            display: 'flex', alignItems: 'center', gap: 4,
                          }}>
                            <CheckCircle size={12} /> สำเร็จ!
                          </div>
                        ) : (
                          <div style={{ display: 'flex', gap: 4 }}>
                            <button
                              disabled={isSubmitting}
                              onClick={() => handleQuickVote(station.id, ft.id, 'available')}
                              style={{
                                padding: '4px 10px', fontSize: 11, fontWeight: 600,
                                background: '#22C55E12', color: '#22C55E',
                                border: '1px solid #22C55E30', borderRadius: 8,
                                cursor: isSubmitting ? 'not-allowed' : 'pointer',
                                opacity: isSubmitting ? 0.5 : 1,
                                display: 'flex', alignItems: 'center', gap: 3,
                              }}
                            >
                              <CheckCircle size={11} /> มี
                            </button>
                            <button
                              disabled={isSubmitting}
                              onClick={() => handleQuickVote(station.id, ft.id, 'out_of_stock')}
                              style={{
                                padding: '4px 10px', fontSize: 11, fontWeight: 600,
                                background: '#EF444412', color: '#EF4444',
                                border: '1px solid #EF444430', borderRadius: 8,
                                cursor: isSubmitting ? 'not-allowed' : 'pointer',
                                opacity: isSubmitting ? 0.5 : 1,
                                display: 'flex', alignItems: 'center', gap: 3,
                              }}
                            >
                              <XCircle size={11} /> หมด
                            </button>
                            <button
                              disabled={isSubmitting}
                              onClick={() => handleQuickVote(station.id, ft.id, 'refilled')}
                              style={{
                                padding: '4px 10px', fontSize: 11, fontWeight: 600,
                                background: '#3B82F612', color: '#3B82F6',
                                border: '1px solid #3B82F630', borderRadius: 8,
                                cursor: isSubmitting ? 'not-allowed' : 'pointer',
                                opacity: isSubmitting ? 0.5 : 1,
                                display: 'flex', alignItems: 'center', gap: 3,
                              }}
                            >
                              <RefreshCw size={11} /> เติมใหม่
                            </button>
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>
            );
          })}
        </div>

        {nearbyStations.length === 0 && (
          <div style={{
            textAlign: 'center', padding: 32, color: '#94a3b8', fontSize: 14,
          }}>
            ไม่พบปั๊มใกล้เคียง — ลองเปิด GPS หรือขยายรัศมีค้นหา
          </div>
        )}
      </div>
    </motion.div>
  );
}
