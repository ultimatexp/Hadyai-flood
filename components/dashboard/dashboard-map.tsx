"use client";

import { AlertTriangle, CheckCircle2, Clock, MapPin, Navigation, Truck } from "lucide-react";
import { useEffect, useState } from "react";
import dynamic from "next/dynamic";
import "leaflet/dist/leaflet.css";
import "leaflet-defaulticon-compatibility/dist/leaflet-defaulticon-compatibility.css";
import "leaflet-defaulticon-compatibility";
import StatusWidget from "@/components/dashboard/status-widget";
import Link from "next/link";
import L from "leaflet";

const MapContainer = dynamic(() => import("react-leaflet").then(mod => mod.MapContainer), { ssr: false });
const TileLayer = dynamic(() => import("react-leaflet").then(mod => mod.TileLayer), { ssr: false });
const Marker = dynamic(() => import("react-leaflet").then(mod => mod.Marker), { ssr: false });
const Popup = dynamic(() => import("react-leaflet").then(mod => mod.Popup), { ssr: false });

interface DashboardMapProps {
    cases: any[];
}

// Custom marker icons based on status
const getMarkerIcon = (status: string) => {
    const colors: Record<string, string> = {
        NEW: "#ef4444",
        ACKNOWLEDGED: "#3b82f6",
        IN_PROGRESS: "#f97316",
        RESOLVED: "#22c55e",
    };

    const color = colors[status] || "#6b7280";

    return L.divIcon({
        className: "custom-marker",
        html: `
            <div style="
                background-color: ${color};
                width: 32px;
                height: 32px;
                border-radius: 50% 50% 50% 0;
                transform: rotate(-45deg);
                border: 3px solid white;
                box-shadow: 0 2px 8px rgba(0,0,0,0.3);
            ">
                <div style="
                    width: 100%;
                    height: 100%;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    transform: rotate(45deg);
                    color: white;
                    font-size: 16px;
                    font-weight: bold;
                ">!</div>
            </div>
        `,
        iconSize: [32, 32],
        iconAnchor: [16, 32],
        popupAnchor: [0, -32],
    });
};

export default function DashboardMap({ cases }: DashboardMapProps) {
    const [mounted, setMounted] = useState(false);

    useEffect(() => {
        setMounted(true);
    }, []);

    if (!mounted) {
        return (
            <div className="h-screen w-full flex items-center justify-center bg-gray-100">
                <div className="text-center">
                    <div className="w-16 h-16 border-4 border-primary border-t-transparent rounded-full animate-spin mx-auto mb-4" />
                    <p className="text-gray-600">กำลังโหลดแผนที่...</p>
                </div>
            </div>
        );
    }

    // Calculate center based on cases or default to Hat Yai
    const defaultCenter: [number, number] = [7.0, 100.47];
    const center = cases.length > 0 && cases[0].lat && cases[0].lng
        ? [cases[0].lat, cases[0].lng] as [number, number]
        : defaultCenter;

    return (
        <div className="relative h-screen w-full">
            <MapContainer
                center={center}
                zoom={12}
                className="h-full w-full z-0"
                scrollWheelZoom={true}
            >
                <TileLayer
                    url={`https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=${process.env.NEXT_PUBLIC_MAPTILER_KEY}`}
                    attribution='&copy; <a href="https://www.maptiler.com/">MapTiler</a>'
                />

                {cases.map((caseItem) => {
                    if (!caseItem.lat || !caseItem.lng) return null;

                    return (
                        <Marker
                            key={caseItem.id}
                            position={[caseItem.lat, caseItem.lng]}
                            icon={getMarkerIcon(caseItem.status)}
                        >
                            <Popup>
                                <div className="p-2 min-w-[250px]">
                                    <h3 className="font-bold text-lg mb-2">{caseItem.reporter_name}</h3>

                                    <div className="space-y-2 text-sm">
                                        <div className="flex items-center gap-2">
                                            <span className={`px-2 py-1 rounded-full text-xs font-bold ${caseItem.status === "NEW" ? "bg-red-100 text-red-700" :
                                                caseItem.status === "ACKNOWLEDGED" ? "bg-blue-100 text-blue-700" :
                                                    caseItem.status === "IN_PROGRESS" ? "bg-orange-100 text-orange-700" :
                                                        "bg-green-100 text-green-700"
                                                }`}>
                                                {caseItem.status === "NEW" ? "รอความช่วยเหลือ" :
                                                    caseItem.status === "ACKNOWLEDGED" ? "รับเรื่องแล้ว" :
                                                        caseItem.status === "IN_PROGRESS" ? "กำลังช่วยเหลือ" : "ช่วยเหลือสำเร็จ"}
                                            </span>
                                        </div>

                                        {caseItem.categories && caseItem.categories.length > 0 && (
                                            <div className="flex flex-wrap gap-1">
                                                {caseItem.categories.map((cat: string, idx: number) => (
                                                    <span key={idx} className="px-2 py-0.5 bg-gray-100 text-gray-700 rounded text-xs">
                                                        {cat}
                                                    </span>
                                                ))}
                                            </div>
                                        )}

                                        {caseItem.contacts && caseItem.contacts.length > 0 && (
                                            <div className="text-gray-600">
                                                📞 {caseItem.contacts[0]}
                                            </div>
                                        )}

                                        {caseItem.note && (
                                            <div className="text-gray-600 text-xs line-clamp-2">
                                                {caseItem.note}
                                            </div>
                                        )}
                                    </div>

                                    <Link href={`/case/${caseItem.id}`}>
                                        <button className="mt-3 w-full bg-primary hover:bg-primary/90 text-white font-bold py-2 px-4 rounded-lg transition-colors">
                                            ดูรายละเอียด
                                        </button>
                                    </Link>
                                </div>
                            </Popup>
                        </Marker>
                    );
                })}
            </MapContainer>

            {/* Status Widget Overlay */}
            <StatusWidget cases={cases} />

            {/* Back Button */}
            <Link href="/">
                <button className="absolute top-4 left-4 z-[1000] bg-white hover:bg-gray-100 text-gray-800 font-bold py-2 px-4 rounded-lg shadow-lg transition-colors flex items-center gap-2">
                    ← กลับหน้าหลัก
                </button>
            </Link>

            {/* Refresh Indicator */}
            <div className="absolute bottom-4 left-4 z-[1000] bg-white/90 backdrop-blur-sm text-gray-700 text-xs py-2 px-3 rounded-lg shadow-md">
                🔄 อัปเดตอัตโนมัติ
            </div>
        </div>
    );
}
