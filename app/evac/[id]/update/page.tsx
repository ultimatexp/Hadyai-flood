import { EvacUpdateForm } from "@/components/evac/evac-update-form";
import { supabase } from "@/lib/supabase";
import { ChevronLeft } from "lucide-react";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";

export default async function EvacUpdatePage({
    params,
    searchParams
}: {
    params: Promise<{ id: string }>,
    searchParams: Promise<{ token?: string }>
}) {
    const { id } = await params;
    const { token } = await searchParams;

    const { data: point, error } = await supabase
        .from("evac_points")
        .select("*")
        .eq("id", id)
        .single();

    if (error || !point) {
        notFound();
    }

    // Verify token
    if (!token || token !== point.edit_token) {
        redirect(`/evac/${id}`);
    }

    return (
        <div className="min-h-screen bg-background pb-20">
            <header className="sticky top-0 z-50 bg-background/80 backdrop-blur-md border-b px-4 py-3 flex items-center gap-3">
                <Link href={`/evac/${point.id}?token=${token}`} className="p-2 -ml-2 hover:bg-accent rounded-full transition-colors">
                    <ChevronLeft className="w-6 h-6" />
                </Link>
                <h1 className="font-bold text-lg">แก้ไขข้อมูลจุดอพยพ</h1>
            </header>

            <main className="container max-w-md mx-auto p-4">
                <EvacUpdateForm initialData={point} token={token} />
            </main>
        </div>
    );
}
