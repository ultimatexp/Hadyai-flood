'use client';

import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { TrendingUp, TrendingDown, Minus, Fuel, ChevronDown, ChevronUp, X } from 'lucide-react';

interface OilPrice {
  name: string;
  fuel_id: string | null;
  price_today: number;
  price_yesterday: number;
  price_tomorrow: number;
  diff_yesterday: number;
  diff_tomorrow: number;
  change: 'up' | 'down' | 'same';
}

interface PriceData {
  prices: OilPrice[];
  metadata: {
    source: string;
    price_date: string;
    price_time: string;
    remark: string;
  };
}

export default function OilPriceWidget() {
  const [data, setData] = useState<PriceData | null>(null);
  const [expanded, setExpanded] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/fuel/prices')
      .then((res) => res.json())
      .then((d) => {
        if (d.prices) setData(d);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  if (loading || !data) {
    return (
      <div style={styles.container}>
        <div style={styles.miniBar}>
          <Fuel size={14} style={{ color: '#f59e0b' }} />
          <span style={styles.loadingText}>กำลังโหลดราคาน้ำมัน...</span>
        </div>
      </div>
    );
  }

  // Show key fuels in mini bar
  const keyFuels = data.prices.filter((p) =>
    ['gasohol_91', 'gasohol_95', 'diesel_b7'].includes(p.fuel_id || '')
  );

  // Check if any fuel has a different tomorrow price
  const hasTomorrowChanges = data.prices.some(p => p.diff_tomorrow !== 0);

  return (
    <div style={styles.container}>
      {/* Mini ticker bar */}
      <motion.div
        style={styles.miniBar}
        onClick={() => setExpanded(!expanded)}
        whileTap={{ scale: 0.98 }}
      >
        <div style={styles.miniLeft}>
          <div style={styles.priceIcon}>
            <Fuel size={12} />
          </div>
          <div style={styles.tickerScroll}>
            {keyFuels.map((fuel, i) => (
              <span key={fuel.fuel_id} style={styles.tickerItem}>
                {i > 0 && <span style={styles.tickerDivider}>·</span>}
                <span style={styles.tickerName}>{shortName(fuel.name)}</span>
                <span style={styles.tickerPrice}>฿{fuel.price_today.toFixed(2)}</span>
                {fuel.diff_tomorrow !== 0 && (
                  <PriceChange diff={fuel.diff_tomorrow} label="พรุ่งนี้" />
                )}
              </span>
            ))}
          </div>
        </div>
        {expanded ? (
          <ChevronDown size={14} style={{ color: '#94a3b8', flexShrink: 0 }} />
        ) : (
          <ChevronUp size={14} style={{ color: '#94a3b8', flexShrink: 0 }} />
        )}
      </motion.div>

      {/* Expanded panel */}
      <AnimatePresence>
        {expanded && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.25 }}
            style={styles.expandedPanel}
          >
            <div style={styles.panelHeader}>
              <span style={styles.panelTitle}>💰 ราคาน้ำมัน</span>
              <span style={styles.panelMeta}>
                {data.metadata.remark}
              </span>
            </div>

            {/* Column headers */}
            <div style={{ ...styles.priceRow, padding: '4px 16px 2px', borderBottom: '2px solid rgba(0,0,0,0.06)' }}>
              <div style={{ flex: 1 }}>
                <span style={{ fontSize: 11, fontWeight: 700, color: '#94a3b8', textTransform: 'uppercase' as const, letterSpacing: 0.5 }}>ชนิด</span>
              </div>
              <div style={{ width: 90, textAlign: 'right' as const }}>
                <span style={{ fontSize: 11, fontWeight: 700, color: '#3b82f6' }}>วันนี้</span>
              </div>
              <div style={{ width: 110, textAlign: 'right' as const }}>
                <span style={{ fontSize: 11, fontWeight: 700, color: '#f59e0b' }}>พรุ่งนี้</span>
              </div>
            </div>

            <div style={styles.priceGrid}>
              {data.prices.map((fuel) => (
                <div key={fuel.name} style={styles.priceRow}>
                  <div style={styles.priceNameCol}>
                    <span style={styles.priceName}>{fuel.name}</span>
                  </div>
                  {/* Today */}
                  <div style={{ width: 90, textAlign: 'right' as const }}>
                    <span style={styles.priceValue}>฿{fuel.price_today.toFixed(2)}</span>
                  </div>
                  {/* Tomorrow */}
                  <div style={{ width: 110, display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: 4 }}>
                    <span style={{ 
                      fontSize: 14, 
                      fontWeight: 700, 
                      fontVariantNumeric: 'tabular-nums',
                      color: fuel.diff_tomorrow > 0 ? '#EF4444' : fuel.diff_tomorrow < 0 ? '#22C55E' : '#64748b',
                    }}>
                      ฿{fuel.price_tomorrow.toFixed(2)}
                    </span>
                    {fuel.diff_tomorrow !== 0 && (
                      <PriceChange diff={fuel.diff_tomorrow} showValue />
                    )}
                  </div>
                </div>
              ))}
            </div>

            {hasTomorrowChanges && (
              <div style={{ padding: '6px 16px 8px', background: 'rgba(245,158,11,0.06)', borderTop: '1px solid rgba(245,158,11,0.1)' }}>
                <span style={{ fontSize: 11, color: '#b45309', fontWeight: 600 }}>
                  ⚠️ ราคาน้ำมันพรุ่งนี้มีการเปลี่ยนแปลง
                </span>
              </div>
            )}

            <div style={styles.panelFooter}>
              <span style={styles.sourceText}>
                ข้อมูลจาก {data.metadata.source} · อัพเดท {data.metadata.price_date}
              </span>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

function shortName(name: string): string {
  return name
    .replace(/S EVO/g, '')
    .replace(/S$/g, '')
    .replace(/ไฮ/g, '')
    .replace(/พรีเมียม\s*\d*\s*/g, '')
    .trim();
}

function PriceChange({ diff, showValue, label }: { diff: number; showValue?: boolean; label?: string }) {
  if (diff === 0) {
    return (
      <span style={{ ...styles.changeTag, background: 'rgba(107,114,128,0.15)', color: '#9CA3AF' }}>
        <Minus size={10} />
        {showValue && ' -'}
      </span>
    );
  }

  const isUp = diff > 0;
  return (
    <span
      style={{
        ...styles.changeTag,
        background: isUp ? 'rgba(239,68,68,0.15)' : 'rgba(34,197,94,0.15)',
        color: isUp ? '#EF4444' : '#22C55E',
      }}
    >
      {label && <span style={{ fontSize: 9, marginRight: 2 }}>{label}</span>}
      {isUp ? <TrendingUp size={10} /> : <TrendingDown size={10} />}
      {showValue && ` ${isUp ? '+' : ''}${diff.toFixed(2)}`}
    </span>
  );
}

const styles: Record<string, React.CSSProperties> = {
  container: {
    position: 'fixed',
    bottom: 16,
    left: 16,
    right: 16,
    zIndex: 1500,
    display: 'flex',
    flexDirection: 'column',
    gap: 0,
    maxWidth: 480,
  },
  miniBar: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 8,
    padding: '8px 14px',
    background: 'rgba(255, 255, 255, 0.95)',
    backdropFilter: 'blur(20px)',
    WebkitBackdropFilter: 'blur(20px)',
    border: '1px solid rgba(0,0,0,0.08)',
    borderRadius: 16,
    cursor: 'pointer',
    boxShadow: '0 2px 16px rgba(0,0,0,0.1)',
  },
  miniLeft: {
    display: 'flex',
    alignItems: 'center',
    gap: 10,
    flex: 1,
    overflow: 'hidden',
  },
  priceIcon: {
    width: 24,
    height: 24,
    background: 'linear-gradient(135deg, #f59e0b, #ef4444)',
    borderRadius: 6,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    color: 'white',
    flexShrink: 0,
  },
  tickerScroll: {
    display: 'flex',
    alignItems: 'center',
    gap: 4,
    overflow: 'hidden',
  },
  tickerItem: {
    display: 'flex',
    alignItems: 'center',
    gap: 4,
    whiteSpace: 'nowrap',
  },
  tickerDivider: {
    color: 'rgba(0,0,0,0.15)',
    margin: '0 4px',
  },
  tickerName: {
    fontSize: 11,
    color: '#94a3b8',
    fontWeight: 500,
  },
  tickerPrice: {
    fontSize: 13,
    color: '#1e293b',
    fontWeight: 700,
    fontVariantNumeric: 'tabular-nums',
  },
  changeTag: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: 2,
    padding: '1px 5px',
    borderRadius: 4,
    fontSize: 10,
    fontWeight: 600,
  },
  loadingText: {
    fontSize: 12,
    color: '#94a3b8',
  },
  expandedPanel: {
    marginTop: 4,
    background: 'rgba(255, 255, 255, 0.98)',
    backdropFilter: 'blur(24px)',
    WebkitBackdropFilter: 'blur(24px)',
    border: '1px solid rgba(0,0,0,0.08)',
    borderRadius: 16,
    overflow: 'hidden',
    boxShadow: '0 4px 24px rgba(0,0,0,0.12)',
  },
  panelHeader: {
    padding: '14px 16px 8px',
    display: 'flex',
    flexDirection: 'column',
    gap: 2,
  },
  panelTitle: {
    fontSize: 15,
    fontWeight: 700,
    color: '#1e293b',
  },
  panelMeta: {
    fontSize: 11,
    color: '#94a3b8',
  },
  priceGrid: {
    padding: '4px 12px 8px',
  },
  priceRow: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: '8px 4px',
    borderBottom: '1px solid rgba(0,0,0,0.04)',
  },
  priceNameCol: {
    flex: 1,
    minWidth: 0,
  },
  priceName: {
    fontSize: 13,
    color: '#475569',
    fontWeight: 500,
    overflow: 'hidden',
    textOverflow: 'ellipsis',
    whiteSpace: 'nowrap',
  },
  priceValueCol: {
    display: 'flex',
    alignItems: 'center',
    gap: 8,
    flexShrink: 0,
  },
  priceValue: {
    fontSize: 15,
    color: '#1e293b',
    fontWeight: 700,
    fontVariantNumeric: 'tabular-nums',
  },
  panelFooter: {
    padding: '8px 16px 12px',
    borderTop: '1px solid rgba(0,0,0,0.04)',
  },
  sourceText: {
    fontSize: 10,
    color: '#94a3b8',
  },
};
