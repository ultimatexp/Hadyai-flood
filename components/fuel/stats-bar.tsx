'use client';

import { motion } from 'framer-motion';
import { Fuel, CheckCircle, XCircle, HelpCircle } from 'lucide-react';

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

interface StatsBarProps {
  stations: GasStation[];
  loading: boolean;
}

export default function StatsBar({ stations, loading }: StatsBarProps) {
  const total = stations.length;

  const withReports = stations.filter(
    (s) => Object.keys(s.fuel_status).length > 0
  );

  const allAvailable = withReports.filter((s) => {
    const statuses = Object.values(s.fuel_status);
    return statuses.every(
      (st) => st.consensus_status === 'available' || st.consensus_status === 'refilled'
    );
  });

  const someOut = withReports.filter((s) => {
    const statuses = Object.values(s.fuel_status);
    return statuses.some((st) => st.consensus_status === 'out_of_stock');
  });

  const noReports = stations.filter(
    (s) => Object.keys(s.fuel_status).length === 0
  );

  if (loading) {
    return (
      <div style={{
        display: 'flex',
        gap: 8,
        padding: '8px 0',
        overflow: 'auto',
      }}>
        {[1, 2, 3, 4].map((i) => (
          <div key={i} style={{
            padding: '6px 14px',
            background: 'rgba(0, 0, 0, 0.04)',
            backdropFilter: 'blur(12px)',
            border: '1px solid rgba(0,0,0,0.06)',
            borderRadius: 12,
            width: 100,
            height: 32,
            animation: 'pulse 1.5s infinite',
          }} />
        ))}
      </div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: -8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: 0.3 }}
      style={{
        display: 'flex',
        gap: 8,
        overflow: 'auto',
        paddingBottom: 4,
        scrollbarWidth: 'none',
      }}
    >
      <StatChip
        icon={<Fuel size={13} />}
        label={`${total} สถานี`}
        color="#64748b"
        bg="rgba(255, 255, 255, 0.9)"
      />
      <StatChip
        icon={<CheckCircle size={13} />}
        label={`${allAvailable.length} มีน้ำมัน`}
        color="#22C55E"
        bg="rgba(34, 197, 94, 0.1)"
      />
      <StatChip
        icon={<XCircle size={13} />}
        label={`${someOut.length} บางชนิดหมด`}
        color="#EF4444"
        bg="rgba(239, 68, 68, 0.1)"
      />
      <StatChip
        icon={<HelpCircle size={13} />}
        label={`${noReports.length} ยังไม่มีรายงาน`}
        color="#9CA3AF"
        bg="rgba(107, 114, 128, 0.1)"
      />
    </motion.div>
  );
}

function StatChip({
  icon,
  label,
  color,
  bg,
}: {
  icon: React.ReactNode;
  label: string;
  color: string;
  bg: string;
}) {
  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 6,
        padding: '6px 14px',
        background: bg,
        backdropFilter: 'blur(12px)',
        WebkitBackdropFilter: 'blur(12px)',
        border: `1px solid ${color}25`,
        borderRadius: 12,
        color: color,
        fontSize: 12,
        fontWeight: 600,
        whiteSpace: 'nowrap',
        flexShrink: 0,
      }}
    >
      {icon}
      {label}
    </div>
  );
}
