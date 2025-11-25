import { SOSSuccessView } from "@/components/case/sos-success-view";
import CaseDetail from "@/components/case/case-detail";
import { ThaiButton } from "@/components/ui/thai-button";
import { supabase } from "@/lib/supabase";
import { ChevronLeft } from "lucide-react";
import Link from "next/link";
import { notFound } from "next/navigation";

export default async function CasePage({
    params,
    searchParams
}: {
    params: Promise<{ id: string }>,
    searchParams: Promise<{ token?: string; created?: string }>
}) {
    const { id } = await params;
    const { token, created } = await searchParams;

    const { data: caseData } = await supabase
        .from("sos_cases")
        .select("*")
        .eq("id", id)
        .single();

    if (!caseData) {
        notFound();
    }

    const isOwner = token && token === caseData.edit_token;
    const editToken = isOwner ? caseData.edit_token : null;

    // Sanitize data to prevent leaking token to public
    const safeCaseData = { ...caseData };
    delete safeCaseData.edit_token;

    if (created === "true") {
        return <SOSSuccessView caseData={safeCaseData} editToken={editToken} />;
    }

    return (
        <div className="min-h-screen bg-background">
            <header className="sticky top-0 z-10 bg-background/80 backdrop-blur-md border-b p-4 flex items-center gap-4">
                <Link href="/helper">
                    <ThaiButton variant="ghost" size="sm" className="px-2">
                        <ChevronLeft className="w-6 h-6" />
                    </ThaiButton>
                </Link>
                <h1 className="text-xl font-bold">รายละเอียดเคส</h1>
            </header>

            <CaseDetail caseData={safeCaseData} isOwner={!!isOwner} editToken={editToken} />
        </div>
    );
}
