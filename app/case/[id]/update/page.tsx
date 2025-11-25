import StatusUpdateForm from "@/components/case/status-update-form";
import { ThaiButton } from "@/components/ui/thai-button";
import { supabase } from "@/lib/supabase";
import { AlertTriangle, ChevronLeft } from "lucide-react";
import Link from "next/link";
import { notFound } from "next/navigation";

export default async function UpdatePage({
    params,
    searchParams
}: {
    params: Promise<{ id: string }>,
    searchParams: Promise<{ token?: string }>
}) {
    const { id } = await params;
    const { token } = await searchParams;

    if (!token) {
        return (
            <div className="min-h-screen flex flex-col items-center justify-center p-6 text-center space-y-4">
                <AlertTriangle className="w-16 h-16 text-red-500" />
                <h1 className="text-2xl font-bold">ไม่พบ Token</h1>
                <p className="text-muted-foreground">ลิงก์นี้ไม่ถูกต้องหรือหมดอายุ</p>
                <Link href="/">
                    <ThaiButton>กลับหน้าหลัก</ThaiButton>
                </Link>
            </div>
        );
    }

    const { data: caseData } = await supabase
        .from("sos_cases")
        .select("*")
        .eq("id", id)
        .eq("edit_token", token)
        .single();

    if (!caseData) {
        return (
            <div className="min-h-screen flex flex-col items-center justify-center p-6 text-center space-y-4">
                <AlertTriangle className="w-16 h-16 text-red-500" />
                <h1 className="text-2xl font-bold">ไม่พบข้อมูล หรือ Token ไม่ถูกต้อง</h1>
                <Link href="/">
                    <ThaiButton>กลับหน้าหลัก</ThaiButton>
                </Link>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-background">
            <header className="sticky top-0 z-10 bg-background/80 backdrop-blur-md border-b p-4 flex items-center gap-4">
                <Link href={`/case/${id}`}>
                    <ThaiButton variant="ghost" size="sm" className="px-2">
                        <ChevronLeft className="w-6 h-6" />
                    </ThaiButton>
                </Link>
                <h1 className="text-xl font-bold">จัดการเคส</h1>
            </header>

            <StatusUpdateForm caseData={caseData} token={token} />
        </div>
    );
}
