'use client';

import { useState } from 'react';
import { Heart, Coffee, ArrowLeft, Copy, Check, Sparkles } from 'lucide-react';
import Link from 'next/link';

export default function DonatePage() {
  const [copied, setCopied] = useState(false);
  const PROMPTPAY_NUMBER = '0877484066';

  const handleCopy = () => {
    navigator.clipboard.writeText(PROMPTPAY_NUMBER);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
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

        .copy-btn {
          display: flex;
          align-items: center;
          gap: 4px;
          padding: 6px 12px;
          background: rgba(99,102,241,0.1);
          border: 1px solid rgba(99,102,241,0.2);
          border-radius: 8px;
          color: #6366f1;
          font-size: 12px;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.2s;
          font-family: inherit;
        }
        .copy-btn:hover { background: rgba(99,102,241,0.2); }
        .copy-btn.copied { background: rgba(34,197,94,0.1); border-color: rgba(34,197,94,0.2); color: #22c55e; }

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
            เราสร้างแอปนี้เพื่อชาวหาดใหญ่ทุกคน 💛<br />
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
          <div className="qr-number">
            <span className="qr-number-text">087-748-4066</span>
            <button
              className={`copy-btn ${copied ? 'copied' : ''}`}
              onClick={handleCopy}
            >
              {copied ? <><Check size={12} /> คัดลอกแล้ว</> : <><Copy size={12} /> คัดลอก</>}
            </button>
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

        {/* Encouragement message */}
        <div className="message-card">
          <div className="message-title">
            <Sparkles size={18} /> ทำไมต้องบริจาค?
          </div>
          <div className="message-text">
            <p>
              🛢️ <strong>เช็คน้ำมัน</strong> ช่วยให้คุณรู้ว่าปั๊มไหนมีน้ำมัน ปั๊มไหนหมด — ประหยัดเวลา ไม่ต้องวิ่งหาปั๊มเปล่า
            </p>
            <p>
              🐾 <strong>ตามหาสัตว์เลี้ยง</strong> ช่วยให้สัตว์เลี้ยงที่หลุดกลับบ้านได้เร็วขึ้น
            </p>
            <p>
              🌊 <strong>รายงานน้ำท่วม</strong> เตือนภัยให้ชาวหาดใหญ่ปลอดภัย
            </p>
            <p>
              ทุกบาททำให้เราดูแลเซิร์ฟเวอร์ พัฒนาฟีเจอร์ใหม่ และทำแอปนี้ดีขึ้นเรื่อยๆ ครับ 🙏
            </p>
          </div>
        </div>

        <div className="message-card">
          <div className="message-title">
            <Heart size={18} /> ขอบคุณจากใจ
          </div>
          <div className="message-text">
            <p>
              แอปนี้สร้างด้วยใจโดยทีมอาสาสมัครที่รักหาดใหญ่ 💛 เราไม่มีโฆษณา ไม่ขายข้อมูล ไม่เก็บค่าสมาชิก
            </p>
            <p>
              การสนับสนุนของคุณ ไม่ว่าจะเท่าไหร่ ล้วนมีความหมาย — มันบอกว่า <em>&ldquo;ทีมงานสู้ๆ นะ พวกเราเห็นค่านะ&rdquo;</em> 😊
            </p>
          </div>
        </div>

        {/* Footer */}
        <div className="donate-footer">
          <span className="donate-heart">❤️</span> ขอบคุณทุกน้ำใจ<br />
          Made with love for หาดใหญ่
        </div>
      </div>
    </div>
  );
}
