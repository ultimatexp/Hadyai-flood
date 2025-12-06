import { ThaiButton } from "@/components/ui/thai-button";
import { AlertTriangle, HeartHandshake, MapPin, Search, Camera, UserSearch, PawPrint, User } from "lucide-react";
import Link from "next/link";
import LandingMap from "@/components/map/landing-map-wrapper";
import { DataDeletionCountdown } from "@/components/ui/data-deletion-countdown";

export default function Home() {
  return (
    <main className="min-h-screen flex flex-col items-center justify-center p-6 relative overflow-hidden">
      {/* Background Map */}
      <div className="absolute inset-0 z-0 opacity-60">
        <LandingMap />
        <div className="absolute inset-0 bg-gradient-to-b from-white/90 via-white/70 to-white/90 dark:from-black/80 dark:via-black/60 dark:to-black/80 z-[1]" />
      </div>

      {/* Pet Mode Toggle */}
      <div className="absolute top-6 left-6 z-50">
        <Link href="/find-pet">
          <button className="bg-white/80 dark:bg-black/50 backdrop-blur-md p-3 rounded-full shadow-lg hover:bg-orange-50 dark:hover:bg-orange-900/30 transition-all border-2 border-orange-100 dark:border-orange-900/50 group">
            <PawPrint className="w-8 h-8 text-orange-500 group-hover:scale-110 transition-transform" />
            <span className="sr-only">Pet Mode</span>
          </button>
        </Link>
      </div>

      {/* My Account Shortcut */}
      <div className="absolute top-6 right-6 z-50">
        <Link href="/my-account">
          <button className="bg-white/80 dark:bg-black/50 backdrop-blur-md p-3 rounded-full shadow-lg hover:bg-blue-50 dark:hover:bg-blue-900/30 transition-all border-2 border-blue-100 dark:border-blue-900/50 group">
            <User className="w-8 h-8 text-blue-500 group-hover:scale-110 transition-transform" />
            <span className="sr-only">My Account</span>
          </button>
        </Link>
      </div>

      <div className="max-w-md w-full space-y-12 text-center relative z-10">
        <div className="space-y-4">
          <div className="w-20 h-20 bg-red-100/90 dark:bg-red-900/80 backdrop-blur rounded-full flex items-center justify-center mx-auto animate-pulse shadow-lg">
            <MapPin className="w-10 h-10 text-primary" />
          </div>
          <h1 className="text-4xl font-bold tracking-tight text-foreground drop-shadow-sm">
            คนไทยช่วยกัน
          </h1>
          <p className="text-muted-foreground text-lg font-medium drop-shadow-sm bg-white/50 dark:bg-black/50 p-2 rounded-lg backdrop-blur-sm">
            ระบบขอความช่วยเหลือผู้ประสบภัยน้ำท่วม
            <br />
            <span className="text-sm opacity-80">ไม่ต้องลงทะเบียน • ใช้งานง่าย • รวดเร็ว</span>
          </p>
        </div>

        <div className="grid gap-6">
          <Link href="/sos/new" className="block w-full">
            <button className="w-full bg-red-600 hover:bg-red-700 text-white text-xl font-bold py-4 rounded-2xl shadow-lg shadow-red-600/30 transition-transform hover:scale-105 flex items-center justify-center gap-3 animate-pulse">
              <AlertTriangle className="w-8 h-8" />
              ขอความช่วยเหลือด่วน
            </button>
          </Link>

          <Link href="/status" className="block w-full">
            <button className="w-full bg-white hover:bg-gray-50 text-gray-800 text-lg font-bold py-3 rounded-2xl shadow-md border border-gray-200 transition-transform hover:scale-105 flex items-center justify-center gap-2">
              <Search className="w-5 h-5" />
              ติดตามสถานะ
            </button>
          </Link>

          <Link href="/helper" className="w-full">
            <ThaiButton variant="success" size="lg" className="w-full h-20 text-xl shadow-green-600/25 border-2 border-white/20">
              <HeartHandshake className="mr-3 w-6 h-6" />
              ฉันเป็นอาสา
            </ThaiButton>
          </Link>

          {/* Face Search Features */}
          <div className="pt-4 border-t border-gray-200">
            <p className="text-sm text-gray-600 mb-3 font-medium">ค้นหาผู้ได้รับผลกระทบ</p>
            <div className="grip gap-3">
              <Link href="/find" className="block w-full">
                <button className="w-full bg-purple-600 hover:bg-purple-700 text-white text-lg font-bold py-3 rounded-xl shadow-md transition-transform hover:scale-105 flex items-center justify-center gap-2 mb-3">
                  <UserSearch className="w-5 h-5" />
                  ค้นหาด้วยใบหน้า
                </button>
              </Link>
              <Link href="/upload-victim" className="block w-full">
                <button className="w-full bg-gray-700 hover:bg-gray-800 text-white text-lg font-bold py-3 rounded-xl shadow-md transition-transform hover:scale-105 flex items-center justify-center gap-2">
                  <Camera className="w-5 h-5" />
                  อัพโหลดรูปผู้ได้รับผลกระทบ
                </button>
              </Link>
            </div>
          </div>



          <Link href="/dashboard" className="block w-full">
            <button className="w-full bg-blue-600 hover:bg-blue-700 text-white text-lg font-bold py-3 rounded-2xl shadow-md transition-transform hover:scale-105 flex items-center justify-center gap-2">
              <MapPin className="w-5 h-5" />
              แผนที่สถานการณ์แบบเรียลไทม์
            </button>
          </Link>
        </div>

        <DataDeletionCountdown />
      </div>
    </main>
  );
}
