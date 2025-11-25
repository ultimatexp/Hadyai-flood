"use client";

import dynamic from "next/dynamic";

const DashboardMapClient = dynamic(
    () => import("@/components/dashboard/dashboard-map-client"),
    {
        ssr: false,
        loading: () => (
            <div className="h-screen w-full flex items-center justify-center bg-gray-100">
                <div className="text-center">
                    <div className="w-16 h-16 border-4 border-primary border-t-transparent rounded-full animate-spin mx-auto mb-4" />
                    <p className="text-gray-600">กำลังโหลดแผนที่...</p>
                </div>
            </div>
        ),
    }
);

interface DashboardMapProps {
    cases: any[];
}

export default function DashboardMap(props: DashboardMapProps) {
    return <DashboardMapClient {...props} />;
}
