import { EvacForm } from "@/components/evac/evac-form";
import { ChevronLeft } from "lucide-react";
import Link from "next/link";

export default function NewEvacPointPage() {
    return (
        <div className="min-h-screen bg-background pb-20">
            <header className="sticky top-0 z-50 bg-background/80 backdrop-blur-md border-b px-4 py-3 flex items-center gap-3">
                <Link href="/" className="p-2 -ml-2 hover:bg-accent rounded-full transition-colors">
                    <ChevronLeft className="w-6 h-6" />
                </Link>
                <h1 className="font-bold text-lg">เพิ่มจุดอพยพ</h1>
            </header>

            <main className="container max-w-md mx-auto p-4">
                <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 mb-6 text-sm text-blue-800">
                    <p className="font-bold mb-1">📢 ช่วยกันแจ้งจุดอพยพ</p>
                    <p>ข้อมูลของคุณจะช่วยให้ผู้ประสบภัยค้นหาที่ปลอดภัยได้ง่ายขึ้น กรุณาให้ข้อมูลที่เป็นจริง</p>
                </div>

                <EvacForm />
            </main>
        </div>
    );
}
