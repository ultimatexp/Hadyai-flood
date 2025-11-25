import { EvacDetail } from "@/components/evac/evac-detail";
import { supabase } from "@/lib/supabase";
import { ChevronLeft } from "lucide-react";
import Link from "next/link";
import { notFound } from "next/navigation";

export default async function EvacPointPage({
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

    // If token is provided in URL, verify it matches
    const isOwner = token === point.edit_token;

    return (
        <div className="min-h-screen bg-background">
            <header className="sticky top-0 z-50 bg-background/80 backdrop-blur-md border-b px-4 py-3 flex items-center gap-3">
                <Link href="/" className="p-2 -ml-2 hover:bg-accent rounded-full transition-colors">
                    <ChevronLeft className="w-6 h-6" />
                </Link>
                <h1 className="font-bold text-lg truncate flex-1">{point.title}</h1>
            </header>

            <main className="container max-w-md mx-auto">
                <EvacDetail
                    data={point}
                    editToken={isOwner ? point.edit_token : null}
                />
            </main>
        </div>
    );
}
