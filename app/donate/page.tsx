'use client';

import { useState, useEffect } from 'react';
import { ArrowLeft, MessageCircle, Send } from 'lucide-react';
import Link from 'next/link';

export default function DonatePage() {
  const [feedback, setFeedback] = useState('');
  const [feedbackSent, setFeedbackSent] = useState(false);
  const [sending, setSending] = useState(false);
  const [donorName, setDonorName] = useState('');
  const [customThb, setCustomThb] = useState('');
  const [checkoutLoading, setCheckoutLoading] = useState(false);
  const [checkoutError, setCheckoutError] = useState<string | null>(null);
  const [banner, setBanner] = useState<string | null>(null);

  useEffect(() => {
    if (typeof window === 'undefined') return;
    const q = new URLSearchParams(window.location.search).get('donation');
    if (q === 'success') {
      setBanner('ขอบคุณที่เลี้ยงกาแฟทีมงาน — น้ำใจของคุณถึงเราแล้ว 💛');
      window.history.replaceState({}, '', '/donate');
    } else if (q === 'cancel') {
      setBanner('ยกเลิกการเลี้ยงกาแฟ — ลองใหม่เมื่อพร้อมได้ครับ');
      window.history.replaceState({}, '', '/donate');
    }
  }, []);

  const startStripeCheckout = async (amountThb: number) => {
    setCheckoutError(null);
    setCheckoutLoading(true);
    try {
      const res = await fetch('/api/donations/checkout', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          amountThb,
          displayName: donorName.trim() || undefined,
        }),
      });
      const data = (await res.json()) as { url?: string; error?: string };
      if (!res.ok) {
        if (res.status === 503 && (data.error ?? '').toLowerCase().includes('stripe')) {
          setCheckoutError(
            'ระบบชำระเงินยังไม่พร้อมบนเซิร์ฟเวอร์นี้ (ตั้งค่า STRIPE_SECRET_KEY ใน Vercel / .env แล้วลองใหม่)',
          );
        } else {
          setCheckoutError(data.error ?? 'เริ่มชำระเงินไม่สำเร็จ');
        }
        return;
      }
      if (data.url) {
        window.location.href = data.url;
        return;
      }
      setCheckoutError('ไม่ได้รับลิงก์ชำระเงิน');
    } catch {
      setCheckoutError('เครือข่ายมีปัญหา ลองใหม่ภายหลัง');
    } finally {
      setCheckoutLoading(false);
    }
  };

  const onCustomDonate = () => {
    const n = parseInt(customThb.replace(/\D/g, ''), 10);
    if (!Number.isFinite(n) || n < 10) {
      setCheckoutError('กรุณากรอกจำนวนเงินเป็นบาทเต็ม (ขั้นต่ำ 10)');
      return;
    }
    void startStripeCheckout(n);
  };

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

        .donate-banner {
          background: rgba(34, 197, 94, 0.15);
          border: 1px solid rgba(34, 197, 94, 0.35);
          color: #bbf7d0;
          padding: 12px 14px;
          border-radius: 12px;
          font-size: 14px;
          line-height: 1.5;
          margin-bottom: 20px;
          text-align: center;
        }

        .stripe-card {
          background: rgba(255,255,255,0.08);
          backdrop-filter: blur(20px);
          border: 1px solid rgba(255,255,255,0.12);
          border-radius: 20px;
          padding: 22px 20px;
          margin-bottom: 22px;
          min-width: 0;
          overflow: hidden;
        }

        .stripe-title {
          display: flex;
          align-items: center;
          gap: 8px;
          font-size: 16px;
          font-weight: 700;
          margin-bottom: 6px;
          color: #e0e7ff;
        }

        .stripe-desc {
          font-size: 12px;
          color: rgba(255,255,255,0.55);
          margin-bottom: 16px;
          line-height: 1.5;
        }

        .stripe-name-input {
          width: 100%;
          padding: 10px 12px;
          margin-bottom: 14px;
          border-radius: 10px;
          border: 1px solid rgba(255,255,255,0.15);
          background: rgba(255,255,255,0.06);
          color: white;
          font-size: 14px;
          font-family: inherit;
          outline: none;
        }
        .stripe-name-input::placeholder { color: rgba(255,255,255,0.35); }
        .stripe-name-input:focus { border-color: rgba(129, 140, 248, 0.8); }

        .stripe-grid {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 10px;
          margin-bottom: 14px;
        }

        .stripe-title-icon {
          width: 28px;
          height: 28px;
          object-fit: contain;
          flex-shrink: 0;
          filter: drop-shadow(0 1px 4px rgba(0,0,0,0.35));
        }

        .stripe-tier {
          flex-direction: column;
          gap: 6px;
          padding: 14px 6px 12px;
          min-height: 118px;
        }

        .stripe-tier-icon {
          width: 44px;
          height: 44px;
          object-fit: contain;
          flex-shrink: 0;
          filter: drop-shadow(0 2px 8px rgba(0,0,0,0.3));
        }

        /* Café Amazon: official OG promo art from cafe-amazon.com — crop toward cup/logo on the right */
        .stripe-tier-icon--photo {
          object-fit: cover;
          border-radius: 10px;
          box-sizing: border-box;
          border: 1px solid rgba(255,255,255,0.22);
        }
        .stripe-tier-icon--cafe-amazon {
          object-position: 84% 44%;
        }

        /* Starbucks siren (Wikimedia / Wikipedia fair-use file) — light backing for contrast on purple */
        .stripe-tier-icon--starbucks {
          object-fit: contain;
          background: rgba(255,255,255,0.14);
          border-radius: 50%;
          padding: 3px;
        }

        .stripe-tier-label {
          font-size: 11px;
          font-weight: 700;
          line-height: 1.25;
          text-align: center;
          max-width: 100%;
          padding: 0 2px;
        }

        .stripe-tier-price {
          font-size: 14px;
          font-weight: 800;
          opacity: 0.92;
          letter-spacing: 0.02em;
        }

        .stripe-cta {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 6px;
          padding: 12px 10px;
          border-radius: 12px;
          border: none;
          font-size: 15px;
          font-weight: 700;
          font-family: inherit;
          cursor: pointer;
          background: linear-gradient(135deg, #6366f1, #8b5cf6);
          color: white;
          transition: transform 0.15s, box-shadow 0.15s;
          box-sizing: border-box;
        }
        .stripe-grid .stripe-cta {
          width: 100%;
        }
        .stripe-cta:hover:not(:disabled) {
          transform: translateY(-1px);
          box-shadow: 0 6px 20px rgba(99,102,241,0.45);
        }
        .stripe-cta:disabled {
          opacity: 0.55;
          cursor: default;
        }

        .stripe-custom-row {
          display: flex;
          flex-wrap: wrap;
          gap: 8px;
          align-items: stretch;
        }

        .stripe-custom-input {
          flex: 1 1 120px;
          min-width: 0;
          padding: 10px 12px;
          border-radius: 10px;
          border: 1px solid rgba(255,255,255,0.15);
          background: rgba(255,255,255,0.06);
          color: white;
          font-size: 14px;
          font-family: inherit;
          outline: none;
        }
        .stripe-custom-input:focus { border-color: rgba(129, 140, 248, 0.8); }

        .stripe-custom-row .stripe-cta {
          flex: 0 0 auto;
          width: auto;
          min-width: 132px;
          padding-left: 14px;
          padding-right: 14px;
          white-space: nowrap;
        }

        .stripe-custom-row .stripe-cta .stripe-btn-icon {
          width: 22px;
          height: 22px;
          object-fit: contain;
          flex-shrink: 0;
        }

        @media (max-width: 360px) {
          .stripe-custom-row .stripe-cta {
            flex: 1 1 100%;
            width: 100%;
          }
        }

        .stripe-error {
          margin-top: 10px;
          font-size: 13px;
          color: #fecaca;
          text-align: center;
          line-height: 1.5;
          padding: 0 4px;
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

        {banner && <div className="donate-banner">{banner}</div>}

        {/* Stripe */}
        <div className="stripe-card">
          <div className="stripe-title">
            <img className="stripe-title-icon" src="/icons/donate.svg" alt="" width={28} height={28} />
            เลี้ยงกาแฟด้วยบัตร / Apple Pay
          </div>
          <p className="stripe-desc">
            ชำระผ่าน Stripe (THB) — ระบุชื่อเพื่อขึ้นกระดานเกียรติยศในแอป (ไม่บังคับ)
          </p>
          <input
            className="stripe-name-input"
            placeholder="ชื่อที่แสดงบนกระดาน (ไม่บังคับ)"
            value={donorName}
            onChange={(e) => setDonorName(e.target.value)}
            maxLength={60}
            disabled={checkoutLoading}
          />
          <div className="stripe-grid">
            <button
              type="button"
              className="stripe-cta stripe-tier"
              disabled={checkoutLoading}
              onClick={() => void startStripeCheckout(30)}
            >
              <img className="stripe-tier-icon" src="/icons/donate.svg" alt="" width={44} height={44} />
              <span className="stripe-tier-label">กาแฟรถเข็น</span>
              <span className="stripe-tier-price">฿30</span>
            </button>
            <button
              type="button"
              className="stripe-cta stripe-tier"
              disabled={checkoutLoading}
              onClick={() => void startStripeCheckout(50)}
            >
              <img
                className="stripe-tier-icon stripe-tier-icon--photo stripe-tier-icon--cafe-amazon"
                src="/brand/cafe-amazon.png"
                alt="Café Amazon"
                width={44}
                height={44}
              />
              <span className="stripe-tier-label">Café Amazon</span>
              <span className="stripe-tier-price">฿50</span>
            </button>
            <button
              type="button"
              className="stripe-cta stripe-tier"
              disabled={checkoutLoading}
              onClick={() => void startStripeCheckout(99)}
            >
              <img
                className="stripe-tier-icon stripe-tier-icon--starbucks"
                src="/brand/starbucks.svg"
                alt="Starbucks"
                width={44}
                height={44}
              />
              <span className="stripe-tier-label">Starbucks</span>
              <span className="stripe-tier-price">฿99</span>
            </button>
          </div>
          <div className="stripe-custom-row">
            <input
              className="stripe-custom-input"
              inputMode="numeric"
              placeholder="จำนวนอื่น (บาทเต็ม)"
              value={customThb}
              onChange={(e) => setCustomThb(e.target.value)}
              disabled={checkoutLoading}
            />
            <button type="button" className="stripe-cta" disabled={checkoutLoading} onClick={onCustomDonate}>
              <img className="stripe-btn-icon" src="/icons/donate.svg" alt="" width={22} height={22} />
              เลี้ยงกาแฟ
            </button>
          </div>
          {checkoutLoading && (
            <div style={{ textAlign: 'center', marginTop: 10, fontSize: 12, color: 'rgba(255,255,255,0.65)' }}>
              กำลังเปิด Stripe เพื่อเลี้ยงกาแฟ…
            </div>
          )}
          {checkoutError && <div className="stripe-error">{checkoutError}</div>}
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
