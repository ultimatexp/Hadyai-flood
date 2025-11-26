import DashboardMap from "@/components/dashboard/dashboard-map";
import { supabase } from "@/lib/supabase";

export const revalidate = 0; // Disable caching for real-time updates

export default async function DashboardPage() {
    const { data: cases, error } = await supabase
        .from("sos_cases")
        .select("*")
        .order("created_at", { ascending: false });

    const { data: evacPoints } = await supabase
        .from("evac_points")
        .select("*");

    if (error) {
        console.error("Error fetching cases:", error);
        return (
            <div className="min-h-screen flex items-center justify-center">
                <p className="text-red-600">เกิดข้อผิดพลาดในการโหลดข้อมูล</p>
            </div>
        );
    }

    return <DashboardMap cases={cases || []} evacPoints={evacPoints || []} />;
}
