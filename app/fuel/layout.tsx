import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'เช็คน้ำมัน — สถานีไหนมี สถานีไหนหมด',
  description: 'ตรวจสอบสถานะน้ำมันทั่วไทย แบบเรียลไทม์ โดยชุมชนช่วยรายงาน',
  openGraph: {
    title: 'เช็คน้ำมัน — สถานีไหนมี สถานีไหนหมด',
    description: 'ตรวจสอบสถานะน้ำมันทั่วไทย แบบเรียลไทม์ โดยชุมชนช่วยรายงาน ปั๊มไหนมี ปั๊มไหนหมด รู้ก่อนไป!',
    url: 'https://thaiflood2025.com/fuel',
    siteName: 'ThaiFlood2025',
    images: [
      {
        url: 'https://thaiflood2025.com/og-fuel.png',
        width: 1200,
        height: 630,
        alt: 'เช็คน้ำมัน — ตรวจสอบสถานะน้ำมันแบบเรียลไทม์',
      },
    ],
    locale: 'th_TH',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'เช็คน้ำมัน — สถานีไหนมี สถานีไหนหมด',
    description: 'ตรวจสอบสถานะน้ำมันทั่วไทย แบบเรียลไทม์ โดยชุมชนช่วยรายงาน',
    images: ['https://thaiflood2025.com/og-fuel.png'],
  },
};

export default function FuelLayout({ children }: { children: React.ReactNode }) {
  return <>{children}</>;
}
