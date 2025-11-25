import HelperView from "@/components/helper";
import { ThaiButton } from "@/components/ui/thai-button";
import { ChevronLeft } from "lucide-react";
import Link from "next/link";
import { LogoutButton } from "@/components/auth/logout-button";

export default function HelperPage() {
    return (
        <div className="min-h-screen bg-background flex flex-col">
            <header className="bg-background/80 backdrop-blur-md border-b p-4 flex items-center gap-4 z-10">
                <Link href="/">
                    <ThaiButton variant="ghost" size="sm" className="px-2">
                        <ChevronLeft className="w-6 h-6" />
                    </ThaiButton>
                </Link>
                <h1 className="text-xl font-bold">อาสาช่วยเหลือ</h1>
                <div className="ml-auto">
                    <LogoutButton />
                </div>
            </header>

            <main className="flex-1 relative">
                <HelperView />
            </main>
        </div>
    );
}
