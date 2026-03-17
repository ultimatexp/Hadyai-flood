import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'เช็คน้ำมัน — สถานีไหนมี สถานีไหนหมด',
  description: 'ตรวจสอบสถานะน้ำมันทั่วไทย แบบเรียลไทม์ โดยชุมชนช่วยรายงาน',
};

export default function FuelLayout({ children }: { children: React.ReactNode }) {
  return <>{children}</>;
}
