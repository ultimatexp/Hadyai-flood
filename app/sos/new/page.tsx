import SOSWizard from "@/components/sos/sos-wizard";
import { ThaiButton } from "@/components/ui/thai-button";
import { ChevronLeft } from "lucide-react";
import Link from "next/link";

export default function SOSNewPage() {
    return (
        <div className="min-h-screen bg-background pb-10">
            <header className="sticky top-0 z-10 bg-background/80 backdrop-blur-md border-b p-4 flex items-center gap-4">
                <Link href="/">
                    <ThaiButton variant="ghost" size="sm" className="px-2">
                        <ChevronLeft className="w-6 h-6" />
                    </ThaiButton>
                </Link>
                <h1 className="text-xl font-bold">ขอความช่วยเหลือ</h1>
            </header>

            <main className="p-4 pt-6">
                <SOSWizard />
            </main>
        </div>
    );
}
