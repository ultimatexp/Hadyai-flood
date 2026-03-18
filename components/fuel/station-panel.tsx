'use client';

import { useState, useRef, useEffect } from 'react';
import { motion } from 'framer-motion';
import { X, MapPin, Navigation, Clock, MessageCircle, AlertTriangle, Upload, Image as ImageIcon, CheckCircle, XCircle, RefreshCw, Send, Edit2, Camera } from 'lucide-react';

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

interface StationPanelProps {
  station: GasStation;
  fuelTypes: FuelType[];
  onClose: () => void;
  onVoteSuccess: () => void;
  getFingerprint: () => string;
}

const BRAND_COLORS: Record<string, string> = {
  PTT: '#2D5CA0',
  Bangchak: '#00A651',
  Shell: '#FFB81C',
  Esso: '#D41E31',
  Caltex: '#E2231A',
  Susco: '#E4002B',
};

function getDecisiveStatus(status: FuelStatus | undefined): { label: string; color: string; bars: number; needsVerify: boolean } {
  if (!status) return { label: 'ยังไม่มีรายงาน', color: '#94a3b8', bars: 0, needsVerify: true };
  
  const now = new Date();
  const lastVote = new Date(status.last_voted_at);
  const diffHours = (now.getTime() - lastVote.getTime()) / (1000 * 60 * 60);

  const isAvailable = status.consensus_status === 'available' || status.consensus_status === 'refilled';
  const isOut = status.consensus_status === 'out_of_stock';

  if (diffHours > 24) return { label: 'ข้อมูลเก่า · รอยืนยัน', color: '#94a3b8', bars: 0, needsVerify: true };

  if (isAvailable) {
    if (diffHours < 6 && (status.confidence > 80 || status.vote_count >= 5)) {
      return { label: 'มีน้ำมันแน่นอน', color: '#22C55E', bars: 3, needsVerify: false };
    }
    return { label: 'แจ้งว่ามี · รอยืนยัน', color: '#F59E0B', bars: 2, needsVerify: true };
  }

  if (isOut) {
    if (diffHours < 12 && status.confidence > 80) {
      return { label: 'หมดแล้วแน่นอน', color: '#EF4444', bars: 3, needsVerify: false };
    }
    return { label: 'แจ้งว่าหมด · รอยืนยัน', color: '#EF4444', bars: 2, needsVerify: true };
  }

  return { label: 'รอยืนยัน', color: '#F59E0B', bars: 1, needsVerify: true };
}

function SignalBars({ count }: { count: number }) {
  return (
    <div style={{ display: 'flex', gap: 2, alignItems: 'flex-end', height: 10 }}>
      {[1, 2, 3].map((i) => (
        <div key={i} style={{
          width: 3,
          height: i * 3,
          background: i <= count ? 'currentColor' : 'rgba(0,0,0,0.1)',
          borderRadius: 1,
        }} />
      ))}
    </div>
  );
}

function timeAgo(date: string): string {
  const now = new Date();
  const then = new Date(date);
  const diffMs = now.getTime() - then.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMins / 60);

  if (diffMins < 1) return 'เมื่อสักครู่';
  if (diffMins < 60) return `${diffMins} นาทีที่แล้ว`;
  if (diffHours < 24) return `${diffHours} ชั่วโมงที่แล้ว`;
  return `${Math.floor(diffHours / 24)} วันที่แล้ว`;
}

export default function StationPanel({
  station,
  fuelTypes,
  onClose,
  onVoteSuccess,
  getFingerprint,
}: StationPanelProps) {
  const [votingFuel, setVotingFuel] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [note, setNote] = useState('');
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [uploadingImage, setUploadingImage] = useState(false);
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [isEditingName, setIsEditingName] = useState(false);
  const [editNameValue, setEditNameValue] = useState(station.name);
  const [savingName, setSavingName] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const stationFuelTypes = fuelTypes.filter((ft) =>
    station.fuel_types.includes(ft.id)
  );

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Preview
    const reader = new FileReader();
    reader.onload = (ev) => setImagePreview(ev.target?.result as string);
    reader.readAsDataURL(file);

    // Upload
    setUploadingImage(true);
    try {
      const formData = new FormData();
      formData.append('file', file);
      const res = await fetch('/api/fuel/upload', { method: 'POST', body: formData });
      const data = await res.json();
      if (data.url) {
        setImageUrl(data.url);
      }
    } catch {
      console.error('Upload failed');
    } finally {
      setUploadingImage(false);
    }
  };

  const handleSaveName = async () => {
    if (!editNameValue.trim() || editNameValue.trim() === station.name) {
      setIsEditingName(false);
      return;
    }
    
    setSavingName(true);
    try {
      const res = await fetch('/api/fuel/stations/update', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: station.id, name: editNameValue.trim() }),
      });
      
      if (res.ok) {
        setIsEditingName(false);
        onVoteSuccess(); // Trigger parent refresh
      } else {
        alert('บันทึกชื่อล้มเหลว กรุณาลองใหม่');
      }
    } catch {
      alert('เกิดข้อผิดพลาดในการเชื่อมต่อ');
    } finally {
      setSavingName(false);
    }
  };

  const handleVote = async (fuelTypeId: string, status: string) => {
    setSubmitting(true);
    setError(null);
    setSuccess(null);

    try {
      const res = await fetch('/api/fuel/vote', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          station_id: station.id,
          fuel_type_id: fuelTypeId,
          status,
          fingerprint: getFingerprint(),
          note: note || undefined,
          image_url: imageUrl || undefined,
        }),
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.error);
        return;
      }

      setSuccess(`โหวตสำเร็จ!`);
      setNote('');
      setImagePreview(null);
      setImageUrl(null);
      setVotingFuel(null);
      onVoteSuccess();
    } catch {
      setError('เกิดข้อผิดพลาด');
    } finally {
      setSubmitting(false);
    }
  };

  const brandColor = BRAND_COLORS[station.brand] || '#6B7280';

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
        maxHeight: '75vh',
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
      <style jsx>{`
        .panel-content {
          padding: 0 20px 24px;
        }

        .drag-handle {
          width: 40px;
          height: 4px;
          background: rgba(0,0,0,0.15);
          border-radius: 2px;
          margin: 12px auto;
        }

        .panel-header {
          display: flex;
          align-items: flex-start;
          justify-content: space-between;
          gap: 12px;
          margin-bottom: 16px;
        }

        .station-info {
          flex: 1;
        }

        .brand-badge {
          display: inline-flex;
          align-items: center;
          padding: 3px 10px;
          border-radius: 8px;
          font-size: 11px;
          font-weight: 700;
          letter-spacing: 0.5px;
          margin-bottom: 6px;
        }

        .station-name {
          font-size: 20px;
          font-weight: 700;
          color: #1e293b;
          margin-bottom: 4px;
          line-height: 1.3;
        }

        .station-address {
          font-size: 13px;
          color: #94a3b8;
          display: flex;
          align-items: flex-start;
          gap: 4px;
        }

        .close-btn {
          width: 36px;
          height: 36px;
          background: rgba(0,0,0,0.05);
          border: none;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          color: #94a3b8;
          cursor: pointer;
          transition: all 0.2s;
          flex-shrink: 0;
        }

        .close-btn:hover {
          background: rgba(0,0,0,0.1);
          color: #475569;
        }

        .fuel-grid {
          display: flex;
          flex-direction: column;
          gap: 8px;
        }

        .fuel-card {
          background: rgba(0,0,0,0.02);
          border: 1px solid rgba(0,0,0,0.06);
          border-radius: 14px;
          padding: 12px 14px;
          transition: all 0.2s;
        }

        .fuel-card:hover {
          background: rgba(0,0,0,0.04);
        }

        .fuel-card-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          margin-bottom: 8px;
        }

        .fuel-label {
          display: flex;
          align-items: center;
          gap: 8px;
        }

        .fuel-dot {
          width: 10px;
          height: 10px;
          border-radius: 50%;
          flex-shrink: 0;
        }

        .fuel-name {
          font-size: 14px;
          font-weight: 600;
          color: #1e293b;
        }

        .fuel-status-badge {
          display: inline-flex;
          align-items: center;
          gap: 4px;
          padding: 3px 10px;
          border-radius: 8px;
          font-size: 11px;
          font-weight: 600;
        }

        .status-available {
          background: rgba(34, 197, 94, 0.15);
          color: #22C55E;
        }

        .status-out {
          background: rgba(239, 68, 68, 0.15);
          color: #EF4444;
        }

        .status-refilled {
          background: rgba(59, 130, 246, 0.15);
          color: #3B82F6;
        }

        .status-unknown {
          background: rgba(107, 114, 128, 0.15);
          color: #9CA3AF;
        }

        .fuel-meta {
          display: flex;
          align-items: center;
          gap: 12px;
          font-size: 11px;
          color: #94a3b8;
          margin-bottom: 8px;
        }

        .vote-actions {
          display: flex;
          gap: 8px;
        }

        .vote-btn {
          flex: 1;
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 6px;
          padding: 8px 12px;
          border-radius: 10px;
          border: 1px solid;
          font-size: 12px;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.2s;
        }

        .vote-btn:disabled {
          opacity: 0.5;
          cursor: not-allowed;
        }

        .vote-available {
          background: rgba(34, 197, 94, 0.08);
          border-color: rgba(34, 197, 94, 0.25);
          color: #22C55E;
        }

        .vote-available:hover:not(:disabled) {
          background: rgba(34, 197, 94, 0.2);
          border-color: #22C55E;
        }

        .vote-out {
          background: rgba(239, 68, 68, 0.08);
          border-color: rgba(239, 68, 68, 0.25);
          color: #EF4444;
        }

        .vote-out:hover:not(:disabled) {
          background: rgba(239, 68, 68, 0.2);
          border-color: #EF4444;
        }

        .vote-refilled {
          background: rgba(59, 130, 246, 0.08);
          border-color: rgba(59, 130, 246, 0.25);
          color: #3B82F6;
        }

        .vote-refilled:hover:not(:disabled) {
          background: rgba(59, 130, 246, 0.2);
          border-color: #3B82F6;
        }

        .note-section {
          margin-top: 12px;
          display: flex;
          flex-direction: column;
          gap: 8px;
        }

        .note-input {
          background: rgba(0,0,0,0.03);
          border: 1px solid rgba(0,0,0,0.08);
          border-radius: 10px;
          padding: 10px 14px;
          color: #1e293b;
          font-size: 13px;
          outline: none;
          resize: none;
        }

        .note-input::placeholder {
          color: #94a3b8;
        }

        .note-input:focus {
          border-color: rgba(245, 158, 11, 0.4);
        }

        .image-actions {
          display: flex;
          gap: 8px;
          align-items: center;
        }

        .upload-btn {
          display: flex;
          align-items: center;
          gap: 6px;
          padding: 8px 14px;
          background: rgba(0,0,0,0.03);
          border: 1px solid rgba(0,0,0,0.08);
          border-radius: 10px;
          color: #64748b;
          font-size: 12px;
          cursor: pointer;
          transition: all 0.2s;
        }

        .upload-btn:hover {
          background: rgba(0,0,0,0.06);
          color: #1e293b;
        }

        .image-preview {
          width: 48px;
          height: 48px;
          border-radius: 8px;
          object-fit: cover;
          border: 1px solid rgba(0,0,0,0.08);
        }

        .alert {
          padding: 10px 14px;
          border-radius: 10px;
          font-size: 13px;
          display: flex;
          align-items: center;
          gap: 8px;
          margin-top: 8px;
        }

        .alert-error {
          background: rgba(239, 68, 68, 0.15);
          color: #EF4444;
          border: 1px solid rgba(239, 68, 68, 0.2);
        }

        .alert-success {
          background: rgba(34, 197, 94, 0.15);
          color: #22C55E;
          border: 1px solid rgba(34, 197, 94, 0.2);
        }

        .section-title {
          font-size: 13px;
          font-weight: 600;
          color: #94a3b8;
          margin-bottom: 8px;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }

        .station-header-main {
          display: flex;
          align-items: center;
          gap: 12px;
          flex: 1;
        }

        .station-logo {
          width: 40px;
          height: 40px;
          border-radius: 10px;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 14px;
          font-weight: 700;
          flex-shrink: 0;
        }

        .station-title-area {
          flex: 1;
        }

        .station-meta {
          display: flex;
          align-items: center;
          gap: 8px;
          font-size: 13px;
          color: #64748b;
          margin-top: 4px;
        }

        .station-district {
          display: flex;
          align-items: center;
          gap: 4px;
        }
      `}</style>

      <div className="drag-handle" />

      <div className="panel-content">
        {/* Header */}
        <div className="panel-header">
            <div className="station-header-main">
              <div 
                className="station-logo"
                style={{
                  background: `${BRAND_COLORS[station.brand] || '#64748b'}15`,
                  color: BRAND_COLORS[station.brand] || '#64748b'
                }}
              >
                {station.brand.slice(0, 3)}
              </div>
              <div className="station-title-area">
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  {isEditingName ? (
                    <div style={{ display: 'flex', gap: 6, alignItems: 'center', flex: 1 }}>
                      <input 
                        type="text"
                        value={editNameValue}
                        onChange={(e) => setEditNameValue(e.target.value)}
                        placeholder="ชื่อปั๊มใหม่..."
                        disabled={savingName}
                        autoFocus
                        style={{
                          flex: 1,
                          padding: '6px 12px',
                          border: '1px solid #cbd5e1',
                          borderRadius: 8,
                          fontSize: 16,
                          fontWeight: 700,
                          color: '#0f172a',
                          background: 'white',
                          outline: 'none',
                        }}
                        onKeyDown={(e) => {
                          if (e.key === 'Enter') handleSaveName();
                          if (e.key === 'Escape') setIsEditingName(false);
                        }}
                      />
                      <button 
                        onClick={handleSaveName}
                        disabled={savingName}
                        style={{
                          padding: '6px 12px',
                          background: '#3b82f6',
                          color: 'white',
                          border: 'none',
                          borderRadius: 8,
                          fontSize: 13,
                          fontWeight: 600,
                          cursor: savingName ? 'not-allowed' : 'pointer',
                          opacity: savingName ? 0.7 : 1,
                        }}
                      >
                        {savingName ? 'กำลังบันทึก...' : 'บันทึก'}
                      </button>
                      <button 
                        onClick={() => { setIsEditingName(false); setEditNameValue(station.name); }}
                        disabled={savingName}
                        style={{
                          padding: '6px 12px',
                          background: '#f1f5f9',
                          color: '#64748b',
                          border: 'none',
                          borderRadius: 8,
                          fontSize: 13,
                          fontWeight: 600,
                          cursor: savingName ? 'not-allowed' : 'pointer',
                        }}
                      >
                        ยกเลิก
                      </button>
                    </div>
                  ) : (
                    <>
                      <h2 className="station-name">{station.name}</h2>
                      <button 
                        onClick={() => setIsEditingName(true)}
                        style={{ 
                          background: 'none', border: 'none', color: '#94a3b8', 
                          cursor: 'pointer', padding: 4, display: 'flex', 
                          alignItems: 'center', justifyContent: 'center',
                          borderRadius: '50%', transition: 'all 0.2s',
                        }}
                        title="แก้ไขชื่อปั๊ม"
                        onMouseEnter={(e) => e.currentTarget.style.color = '#3b82f6'}
                        onMouseLeave={(e) => e.currentTarget.style.color = '#94a3b8'}
                      >
                        <Edit2 size={16} />
                      </button>
                    </>
                  )}
                </div>
                <div className="station-meta">
                  <span className="station-district">
                    <MapPin size={12} />
                    {station.district}, {station.province}
                  </span>
                </div>
              </div>
            </div>
            <button className="close-btn" onClick={onClose}>
            <X size={18} />
          </button>
        </div>

        {/* Alerts */}
        {error && (
          <motion.div
            className="alert alert-error"
            initial={{ opacity: 0, y: -8 }}
            animate={{ opacity: 1, y: 0 }}
          >
            <XCircle size={16} /> {error}
          </motion.div>
        )}
        {success && (
          <motion.div
            className="alert alert-success"
            initial={{ opacity: 0, y: -8 }}
            animate={{ opacity: 1, y: 0 }}
          >
            <CheckCircle size={16} /> {success}
          </motion.div>
        )}

        {/* Image Upload + Note */}

        {/* Fuel Grid */}
        <div style={{ marginTop: 16 }}>
          <div className="section-title">⛽ สถานะน้ำมันแต่ละชนิด</div>
          <div className="fuel-grid">
            {stationFuelTypes.map((ft) => {
              const status = station.fuel_status[ft.id];
              const decisive = getDecisiveStatus(status);

              return (
                <div key={ft.id} className="fuel-card" style={{
                  background: decisive.color === '#EF4444' ? '#FEF2F2' : decisive.color === '#22C55E' ? '#F0FDF4' : undefined,
                  borderColor: decisive.color === '#EF4444' ? '#FECACA' : decisive.color === '#22C55E' ? '#BBF7D0' : undefined,
                }}>
                  <div className="fuel-card-header">
                    <div className="fuel-label">
                      <div className="fuel-dot" style={{ background: ft.color }} />
                      <span className="fuel-name">{ft.name_th}</span>
                    </div>
                    <div
                      className="fuel-status-badge"
                      style={{
                        background: `${decisive.color}15`,
                        color: decisive.color,
                        display: 'flex',
                        alignItems: 'center',
                        gap: 6,
                      }}
                    >
                      <SignalBars count={decisive.bars} />
                      {decisive.label}
                    </div>
                  </div>

                  {status && (
                    <div className="fuel-meta">
                      <span>👥 {status.vote_count} โหวต</span>
                      <span>🎯 {status.confidence}% เห็นด้วย</span>
                      <span>🕐 {timeAgo(status.last_voted_at)}</span>
                    </div>
                  )}

                  {decisive.needsVerify && (
                    <div style={{
                      padding: '8px 12px',
                      background: 'linear-gradient(135deg, #f59e0b10, #f59e0b08)',
                      border: '1px dashed #f59e0b40',
                      borderRadius: 10,
                      textAlign: 'center',
                      fontSize: 12,
                      color: '#b45309',
                      fontWeight: 600,
                      marginBottom: 8,
                    }}>
                      📢 ข้อมูลนี้ยังไม่ชัวร์ — ช่วยยืนยันสถานะด้านล่าง!
                    </div>
                  )}

                  <div className="vote-actions">
                    <button
                      className="vote-btn vote-available"
                      disabled={submitting}
                      onClick={() => handleVote(ft.id, 'available')}
                    >
                      <CheckCircle size={14} />
                      มีน้ำมัน
                    </button>
                    <button
                      className="vote-btn vote-out"
                      disabled={submitting}
                      onClick={() => handleVote(ft.id, 'out_of_stock')}
                    >
                      <XCircle size={14} />
                      หมดแล้ว
                    </button>
                    <button
                      className="vote-btn vote-refilled"
                      disabled={submitting}
                      onClick={() => handleVote(ft.id, 'refilled')}
                    >
                      <RefreshCw size={14} />
                      เติมใหม่
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Photo / Note — moved to bottom */}
        <div className="note-section" style={{ marginTop: 20 }}>
          <div className="section-title">📷 แนบรูป / หมายเหตุ (ไม่จำเป็น)</div>
          <div className="image-actions">
            <button className="upload-btn" onClick={() => fileInputRef.current?.click()}>
              <Camera size={14} />
              {uploadingImage ? 'กำลังอัพโหลด...' : 'ถ่ายรูป / เลือกรูป'}
            </button>
            {imagePreview && (
              <img src={imagePreview} alt="preview" className="image-preview" />
            )}
          </div>
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            capture="environment"
            onChange={handleImageUpload}
            style={{ display: 'none' }}
          />
          <textarea
            className="note-input"
            placeholder="เพิ่มหมายเหตุ เช่น คิวยาว, ปั๊มปิดแล้ว..."
            value={note}
            onChange={(e) => setNote(e.target.value)}
            rows={2}
          />
        </div>

        {/* Comments Section */}
        <CommentsSection stationId={station.id} getFingerprint={getFingerprint} />
      </div>
    </motion.div>
  );
}

// ——— Comments Section ———
interface Comment {
  id: string;
  message: string;
  image_url: string | null;
  created_at: string;
}

function CommentsSection({ stationId, getFingerprint }: { stationId: string; getFingerprint: () => string }) {
  const [comments, setComments] = useState<Comment[]>([]);
  const [newComment, setNewComment] = useState('');
  const [posting, setPosting] = useState(false);
  const [loadingComments, setLoadingComments] = useState(true);

  useEffect(() => {
    fetch(`/api/fuel/comments?station_id=${stationId}`)
      .then(r => r.json())
      .then(d => setComments(d.comments || []))
      .catch(() => {})
      .finally(() => setLoadingComments(false));
  }, [stationId]);

  const postComment = async () => {
    if (!newComment.trim() || posting) return;
    setPosting(true);
    try {
      const res = await fetch('/api/fuel/comments', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          station_id: stationId,
          message: newComment.trim(),
          fingerprint: getFingerprint(),
        }),
      });
      const data = await res.json();
      if (data.success && data.comment) {
        setComments(prev => [data.comment, ...prev]);
        setNewComment('');
      }
    } catch { /* ignore */ }
    setPosting(false);
  };

  const commentTimeAgo = (dateStr: string) => {
    const diff = Date.now() - new Date(dateStr).getTime();
    const mins = Math.floor(diff / 60000);
    if (mins < 1) return 'เมื่อสักครู่';
    if (mins < 60) return `${mins} นาทีที่แล้ว`;
    const hrs = Math.floor(mins / 60);
    if (hrs < 24) return `${hrs} ชม. ที่แล้ว`;
    return `${Math.floor(hrs / 24)} วันที่แล้ว`;
  };

  return (
    <div style={{ marginTop: 20 }}>
      <div style={{ fontSize: 14, fontWeight: 700, color: '#1e293b', marginBottom: 10 }}>
        💬 ความคิดเห็น ({comments.length})
      </div>

      {/* Post form */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 14 }}>
        <input
          type="text"
          value={newComment}
          onChange={(e) => setNewComment(e.target.value)}
          placeholder="แสดงความคิดเห็น เช่น คิวยาว, ปิดก่อนเวลา..."
          onKeyDown={(e) => e.key === 'Enter' && postComment()}
          style={{
            flex: 1, padding: '10px 14px', borderRadius: 12,
            border: '1px solid #e2e8f0', fontSize: 13,
            fontFamily: 'inherit', outline: 'none',
            background: '#f8fafc',
          }}
        />
        <button
          onClick={postComment}
          disabled={posting || !newComment.trim()}
          style={{
            padding: '10px 16px', borderRadius: 12, border: 'none',
            background: posting || !newComment.trim() ? '#e2e8f0' : 'linear-gradient(135deg, #f59e0b, #ef4444)',
            color: posting || !newComment.trim() ? '#94a3b8' : 'white',
            fontWeight: 700, fontSize: 13, cursor: 'pointer',
            fontFamily: 'inherit', whiteSpace: 'nowrap',
          }}
        >
          <Send size={14} style={{ verticalAlign: 'middle', marginRight: 4 }} />
          ส่ง
        </button>
      </div>

      {/* Comments list */}
      {loadingComments ? (
        <div style={{ textAlign: 'center', fontSize: 12, color: '#94a3b8', padding: 16 }}>กำลังโหลด...</div>
      ) : comments.length === 0 ? (
        <div style={{
          textAlign: 'center', fontSize: 13, color: '#94a3b8', padding: 20,
          background: '#f8fafc', borderRadius: 12, border: '1px dashed #e2e8f0',
        }}>ยังไม่มีความคิดเห็น — เป็นคนแรกที่แสดงความคิดเห็น!</div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {comments.map((c) => (
            <div key={c.id} style={{
              padding: '10px 14px', borderRadius: 12,
              background: '#f8fafc', border: '1px solid #f1f5f9',
            }}>
              <div style={{ fontSize: 13, color: '#334155', lineHeight: 1.5 }}>
                {c.message}
              </div>
              {c.image_url && (
                <img src={c.image_url} alt="" style={{
                  marginTop: 8, maxWidth: '100%', borderRadius: 8,
                  maxHeight: 150, objectFit: 'cover',
                }} />
              )}
              <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 6 }}>
                🕐 {commentTimeAgo(c.created_at)}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
