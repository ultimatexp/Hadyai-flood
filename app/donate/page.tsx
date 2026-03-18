'use client';

import { useState, useRef } from 'react';
import { Heart, ArrowLeft, Download, MessageCircle, Send } from 'lucide-react';
import Link from 'next/link';

export default function DonatePage() {
  const [saved, setSaved] = useState(false);
  const [feedback, setFeedback] = useState('');
  const [feedbackSent, setFeedbackSent] = useState(false);
  const [sending, setSending] = useState(false);
  const PROMPTPAY_NUMBER = '0877484066';

  const handleSendFeedback = async () => {
    if (!feedback.trim()) return;
    setSending(true);
    try {
      await fetch('/api/feedback', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: feedback.trim(), source: 'donate_page' }),
      });
    } catch { /* silent fail */ }
    setFeedbackSent(true);
    setSending(false);
    setFeedback('');
    setTimeout(() => setFeedbackSent(false), 5000);
  };

  const handleSaveQR = async () => {
    try {
      const res = await fetch(`https://promptpay.io/${PROMPTPAY_NUMBER}.png`);
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'promptpay-donate.png';
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      setSaved(true);
      setTimeout(() => setSaved(false), 3000);
    } catch {
      // Fallback: open in new tab
      window.open(`https://promptpay.io/${PROMPTPAY_NUMBER}.png`, '_blank');
    }
  };

  return (
    <div className="donate-page">
      <style jsx global>{`
        .donate-page {
          min-height: 100dvh;
          background: linear-gradient(160deg, #0f172a 0%, #1e1b4b 40%, #312e81 70%, #1e1b4b 100%);
          font-family: 'Prompt', 'Sarabun', sans-serif;
          color: white;
          overflow-x: hidden;
        }

        .donate-container {
          max-width: 480px;
          margin: 0 auto;
          padding: 20px 20px 40px;
        }

        .donate-back {
          display: inline-flex;
          align-items: center;
          gap: 6px;
          color: rgba(255,255,255,0.6);
          text-decoration: none;
          font-size: 14px;
          margin-bottom: 24px;
          transition: color 0.2s;
        }
        .donate-back:hover { color: white; }

        .donate-hero {
          text-align: center;
          margin-bottom: 32px;
        }

        .donate-emoji {
          font-size: 64px;
          margin-bottom: 16px;
          display: block;
          animation: float 3s ease-in-out infinite;
        }

        @keyframes float {
          0%, 100% { transform: translateY(0px); }
          50% { transform: translateY(-10px); }
        }

        .donate-title {
          font-size: 28px;
          font-weight: 800;
          background: linear-gradient(135deg, #fbbf24, #f472b6, #a78bfa);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
          background-clip: text;
          margin-bottom: 12px;
          line-height: 1.3;
        }

        .donate-subtitle {
          font-size: 15px;
          color: rgba(255,255,255,0.7);
          line-height: 1.7;
          max-width: 380px;
          margin: 0 auto;
        }

        .qr-card {
          background: rgba(255,255,255,0.95);
          border-radius: 24px;
          padding: 28px 24px;
          text-align: center;
          margin-bottom: 24px;
          box-shadow: 0 20px 60px rgba(0,0,0,0.3), 0 0 0 1px rgba(255,255,255,0.1);
          position: relative;
          overflow: hidden;
        }

        .qr-card::before {
          content: '';
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          height: 4px;
          background: linear-gradient(90deg, #fbbf24, #f472b6, #a78bfa);
        }

        .qr-label {
          font-size: 13px;
          color: #6b7280;
          font-weight: 600;
          margin-bottom: 4px;
          letter-spacing: 0.3px;
        }

        .qr-brand {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 8px;
          margin-bottom: 16px;
        }

        .qr-brand-text {
          font-size: 20px;
          font-weight: 700;
          background: linear-gradient(135deg, #1e40af, #7c3aed);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
          background-clip: text;
        }

        .qr-image-wrap {
          background: white;
          border-radius: 16px;
          padding: 16px;
          display: inline-block;
          margin-bottom: 16px;
          border: 2px solid #e5e7eb;
        }

        .qr-image-wrap img {
          width: 220px;
          height: 220px;
          display: block;
        }

        .qr-number {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 10px;
          margin-top: 8px;
        }

        .qr-number-text {
          font-size: 22px;
          font-weight: 700;
          color: #1e293b;
          letter-spacing: 1.5px;
          font-variant-numeric: tabular-nums;
        }

        .save-btn {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 8px;
          width: 100%;
          padding: 12px 20px;
          background: linear-gradient(135deg, #6366f1, #8b5cf6);
          border: none;
          border-radius: 12px;
          color: white;
          font-size: 14px;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.2s;
          font-family: inherit;
          margin-top: 12px;
        }
        .save-btn:hover { transform: translateY(-1px); box-shadow: 0 4px 16px rgba(99,102,241,0.4); }
        .save-btn.saved { background: linear-gradient(135deg, #22c55e, #16a34a); }

        .qr-instruction {
          font-size: 12px;
          color: #9ca3af;
          margin-top: 12px;
          line-height: 1.6;
          text-align: center;
        }

        .message-card {
          background: rgba(255,255,255,0.08);
          backdrop-filter: blur(20px);
          border: 1px solid rgba(255,255,255,0.12);
          border-radius: 20px;
          padding: 24px;
          margin-bottom: 20px;
        }

        .message-title {
          display: flex;
          align-items: center;
          gap: 8px;
          font-size: 16px;
          font-weight: 700;
          margin-bottom: 12px;
          color: #fbbf24;
        }

        .message-text {
          font-size: 14px;
          color: rgba(255,255,255,0.8);
          line-height: 1.8;
        }

        .message-text p {
          margin-bottom: 10px;
        }

        .amount-grid {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 10px;
          margin-bottom: 24px;
        }

        .amount-card {
          background: rgba(255,255,255,0.06);
          border: 1px solid rgba(255,255,255,0.1);
          border-radius: 14px;
          padding: 14px 8px;
          text-align: center;
          transition: all 0.2s;
          cursor: default;
        }
        .amount-card:hover {
          background: rgba(255,255,255,0.12);
          border-color: rgba(255,255,255,0.2);
          transform: translateY(-2px);
        }

        .amount-emoji {
          font-size: 24px;
          margin-bottom: 6px;
          display: block;
        }

        .amount-value {
          font-size: 18px;
          font-weight: 700;
          color: white;
          margin-bottom: 2px;
        }

        .amount-desc {
          font-size: 11px;
          color: rgba(255,255,255,0.5);
        }

        .donate-footer {
          text-align: center;
          color: rgba(255,255,255,0.4);
          font-size: 12px;
          line-height: 1.6;
          margin-top: 32px;
        }

        .donate-heart {
          display: inline-block;
          animation: heartbeat 1.5s ease-in-out infinite;
        }

        @keyframes heartbeat {
          0%, 100% { transform: scale(1); }
          50% { transform: scale(1.2); }
        }
      `}</style>

      <div className="donate-container">
        <Link href="/fuel" className="donate-back">
          <ArrowLeft size={16} /> กลับหน้าหลัก
        </Link>

        {/* Hero */}
        <div className="donate-hero">
          <span className="donate-emoji">☕</span>
          <h1 className="donate-title">ซื้อกาแฟให้ทีมงาน</h1>
          <p className="donate-subtitle">
            เราสร้างแอปนี้เพื่อคนไทยทุกคน 💛<br />
            น้ำใจของคุณช่วยให้เราพัฒนาต่อไปได้ครับ
          </p>
        </div>

        {/* QR Card */}
        <div className="qr-card">
          <div className="qr-label">สแกนเพื่อบริจาค</div>
          <div className="qr-brand">
            <span className="qr-brand-text">PromptPay</span>
          </div>
          <div className="qr-image-wrap">
            <img
              src={`https://promptpay.io/${PROMPTPAY_NUMBER}.png`}
              alt="PromptPay QR Code"
              width={220}
              height={220}
            />
          </div>
          <button
            className={`save-btn ${saved ? 'saved' : ''}`}
            onClick={handleSaveQR}
          >
            <Download size={16} />
            {saved ? 'บันทึกแล้ว ✓' : 'บันทึก QR เพื่อโอนผ่าน Mobile Banking'}
          </button>
          <div className="qr-instruction">
            📱 บันทึกรูป QR → เปิดแอปธนาคาร → สแกน QR จากรูปภาพ
          </div>
        </div>

        {/* Suggested amounts */}
        <div className="amount-grid">
          <div className="amount-card">
            <span className="amount-emoji">☕</span>
            <div className="amount-value">฿20</div>
            <div className="amount-desc">กาแฟ 1 แก้ว</div>
          </div>
          <div className="amount-card">
            <span className="amount-emoji">🍜</span>
            <div className="amount-value">฿50</div>
            <div className="amount-desc">ข้าวกลางวัน</div>
          </div>
          <div className="amount-card">
            <span className="amount-emoji">💪</span>
            <div className="amount-value">฿100</div>
            <div className="amount-desc">ค่าเซิร์ฟเวอร์</div>
          </div>
        </div>

        {/* Feedback section */}
        <div className="message-card">
          <div className="message-title">
            <MessageCircle size={18} /> ฝากข้อความถึงทีมงาน
          </div>
          {feedbackSent ? (
            <div style={{ textAlign: 'center', padding: '16px 0' }}>
              <div style={{ fontSize: 40, marginBottom: 8 }}>💛</div>
              <div style={{ color: 'rgba(255,255,255,0.8)', fontSize: 15, fontWeight: 600 }}>ขอบคุณสำหรับข้อความครับ!</div>
              <div style={{ color: 'rgba(255,255,255,0.5)', fontSize: 12, marginTop: 4 }}>ทีมงานจะอ่านทุกข้อความ 🙏</div>
            </div>
          ) : (
            <div className="message-text">
              <p style={{ marginBottom: 12, color: 'rgba(255,255,255,0.6)' }}>
                อยากให้เพิ่มฟีเจอร์อะไร? มีข้อเสนอแนะ? หรือแค่อยากส่งกำลังใจ — เขียนถึงเราได้เลยครับ 😊
              </p>
              <textarea
                value={feedback}
                onChange={(e) => setFeedback(e.target.value)}
                placeholder="เขียนข้อความถึงทีมงาน..."
                rows={3}
                style={{
                  width: '100%',
                  padding: '12px 14px',
                  background: 'rgba(255,255,255,0.08)',
                  border: '1px solid rgba(255,255,255,0.15)',
                  borderRadius: 12,
                  color: 'white',
                  fontSize: 14,
                  fontFamily: 'inherit',
                  resize: 'vertical' as const,
                  outline: 'none',
                  lineHeight: 1.6,
                }}
              />
              <button
                onClick={handleSendFeedback}
                disabled={!feedback.trim() || sending}
                style={{
                  width: '100%',
                  marginTop: 10,
                  padding: '10px 20px',
                  background: feedback.trim()
                    ? 'linear-gradient(135deg, #fbbf24, #f59e0b)'
                    : 'rgba(255,255,255,0.1)',
                  border: 'none',
                  borderRadius: 10,
                  color: feedback.trim() ? '#1e293b' : 'rgba(255,255,255,0.3)',
                  fontSize: 14,
                  fontWeight: 600,
                  cursor: feedback.trim() ? 'pointer' : 'default',
                  fontFamily: 'inherit',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: 6,
                  transition: 'all 0.2s',
                }}
              >
                <Send size={14} />
                {sending ? 'กำลังส่ง...' : 'ส่งข้อความ'}
              </button>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="donate-footer">
          <span className="donate-heart">❤️</span> ขอบคุณทุกน้ำใจ<br />
          Made with love for Thailand 🇹🇭
        </div>
      </div>
    </div>
  );
}
