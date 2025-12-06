import { supabase } from "@/lib/supabase";
import { NextResponse } from "next/server";

export async function GET(request: Request) {
    try {
        // Check for authorization (optional, but recommended for cron jobs)
        // const authHeader = request.headers.get('authorization');
        // if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
        //     return new Response('Unauthorized', { status: 401 });
        // }

        // Calculate the date 180 days ago
        const cutoffDate = new Date();
        cutoffDate.setDate(cutoffDate.getDate() - 180);
        const cutoffISO = cutoffDate.toISOString();

        // Delete pets created before the cutoff date
        const { data, error, count } = await supabase
            .from('pets')
            .delete({ count: 'exact' })
            .lt('created_at', cutoffISO);

        if (error) {
            console.error("Error cleaning up pets:", error);
            return NextResponse.json({ success: false, error: error.message }, { status: 500 });
        }

        return NextResponse.json({
            success: true,
            message: `Deleted ${count} expired pet listings.`,
            deleted_count: count,
            cutoff_date: cutoffISO
        });

    } catch (error: any) {
        console.error("Cleanup cron failed:", error);
        return NextResponse.json({ success: false, error: error.message }, { status: 500 });
    }
}
