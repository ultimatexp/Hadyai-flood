/* eslint-disable @next/next/no-img-element */
'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';

export default function DonateThankYouPage() {
  const [sessionId, setSessionId] = useState<string | null>(null);

  useEffect(() => {
    if (typeof window === 'undefined') return;
    const id = new URLSearchParams(window.location.search).get('session_id');
    if (id) setSessionId(id);
  }, []);

  return (
    <div className="thankyou-page">
      <style jsx global>{`
        .thankyou-page {
          min-height: 100dvh;
          background: linear-gradient(160deg, #0f172a 0%, #1e1b4b 40%, #312e81 70%, #1e1b4b 100%);
          font-family: 'Prompt', 'Sarabun', sans-serif;
          color: white;
          overflow-x: hidden;
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 24px 18px 40px;
        }

        .thankyou-card {
          width: 100%;
          max-width: 520px;
          background: rgba(255, 255, 255, 0.08);
          backdrop-filter: blur(20px);
          border: 1px solid rgba(255, 255, 255, 0.12);
          border-radius: 22px;
          padding: 26px 22px;
          box-shadow: 0 20px 60px rgba(0, 0, 0, 0.35);
        }

        .thankyou-emoji {
          font-size: 56px;
          display: block;
          text-align: center;
          margin-bottom: 12px;
          animation: float 3s ease-in-out infinite;
        }

        @keyframes float {
          0%,
          100% {
            transform: translateY(0px);
          }
          50% {
            transform: translateY(-10px);
          }
        }

        .thankyou-title {
          text-align: center;
          font-size: 26px;
          font-weight: 900;
          background: linear-gradient(135deg, #fbbf24, #f472b6, #a78bfa);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
          background-clip: text;
          margin: 0 0 10px;
          line-height: 1.25;
        }

        .thankyou-subtitle {
          text-align: center;
          font-size: 14px;
          color: rgba(255, 255, 255, 0.75);
          line-height: 1.8;
          margin: 0 auto 18px;
          max-width: 420px;
        }

        .thankyou-message {
          margin-top: 14px;
          padding: 16px 16px;
          border-radius: 16px;
          border: 1px solid rgba(34, 197, 94, 0.35);
          background: rgba(34, 197, 94, 0.12);
          color: #bbf7d0;
          font-size: 14px;
          line-height: 1.7;
          text-align: center;
        }

        .thankyou-meta {
          margin-top: 12px;
          font-size: 12px;
          color: rgba(255, 255, 255, 0.5);
          text-align: center;
          word-break: break-all;
        }

        .thankyou-actions {
          display: grid;
          grid-template-columns: 1fr;
          gap: 10px;
          margin-top: 18px;
        }

        .thankyou-btn {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          padding: 12px 14px;
          border-radius: 14px;
          font-size: 15px;
          font-weight: 800;
          text-decoration: none;
          transition: transform 0.15s, box-shadow 0.15s, opacity 0.15s;
          border: 1px solid rgba(255, 255, 255, 0.14);
        }

        .thankyou-btn-primary {
          background: linear-gradient(135deg, #6366f1, #8b5cf6);
          color: white;
          border: none;
        }

        .thankyou-btn-secondary {
          background: rgba(255, 255, 255, 0.06);
          color: rgba(255, 255, 255, 0.9);
        }

        .thankyou-btn:hover {
          transform: translateY(-1px);
          box-shadow: 0 10px 28px rgba(99, 102, 241, 0.35);
        }

        .thankyou-footer {
          margin-top: 16px;
          text-align: center;
          font-size: 12px;
          color: rgba(255, 255, 255, 0.45);
          line-height: 1.6;
        }
      `}</style>

      <div className="thankyou-card">
        <span className="thankyou-emoji">🙏</span>
        <h1 className="thankyou-title">ขอบคุณจากใจจริง</h1>
        <p className="thankyou-subtitle">
          น้ำใจของคุณช่วยให้ทีมงานมีแรงและมีเวลาพัฒนาแอปเพื่อคนไทยต่อไป
          <br />
          เราซาบซึ้งมากครับ 💛
        </p>

        <div className="thankyou-message">
          หากต้องการ “ฝากข้อความถึงทีมงาน” หรือ “เลี้ยงกาแฟเพิ่มอีกแก้ว”
          <br />
          กลับไปที่หน้าบริจาคได้เลยครับ
        </div>

        {sessionId ? <div className="thankyou-meta">Stripe session: {sessionId}</div> : null}

        <div className="thankyou-actions">
          <Link className="thankyou-btn thankyou-btn-secondary" href="/donate">
            ไปหน้าเลี้ยงกาแฟ
          </Link>
        </div>

        <div className="thankyou-footer">Thank you for supporting Hadyai Flood / Fondue.</div>
      </div>
    </div>
  );
}

