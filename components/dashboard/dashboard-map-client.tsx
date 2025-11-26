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
import { EvacMarker } from "@/components/evac/evac-marker";

const MapContainer = dynamic(() => import("react-leaflet").then(mod => mod.MapContainer), { ssr: false });
const TileLayer = dynamic(() => import("react-leaflet").then(mod => mod.TileLayer), { ssr: false });
const Marker = dynamic(() => import("react-leaflet").then(mod => mod.Marker), { ssr: false });
const Popup = dynamic(() => import("react-leaflet").then(mod => mod.Popup), { ssr: false });
const ZoomControl = dynamic(() => import("react-leaflet").then(mod => mod.ZoomControl), { ssr: false });

interface DashboardMapProps {
    cases: any[];
    evacPoints: any[];
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

export default function DashboardMap({ cases, evacPoints }: DashboardMapProps) {
    const [mounted, setMounted] = useState(false);
    const [showResolved, setShowResolved] = useState(false);
    const [selectedCategory, setSelectedCategory] = useState<string>("all");
    const [victimCountFilter, setVictimCountFilter] = useState<string>("all");
    const [showEvac, setShowEvac] = useState(true);

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

    // Extract unique categories
    const categories = Array.from(new Set(cases.flatMap(c => c.categories || []))).sort();

    // Filter cases
    const filteredCases = cases.filter(c => {
        // Filter by resolved status
        if (!showResolved && c.status === "RESOLVED") return false;

        // Filter by category
        if (selectedCategory !== "all" && (!c.categories || !c.categories.includes(selectedCategory))) return false;

        // Filter by victim count
        if (victimCountFilter !== "all") {
            const count = c.victim_count || 1;
            if (victimCountFilter === "1-10" && (count < 1 || count > 10)) return false;
            if (victimCountFilter === "10-50" && (count <= 10 || count > 50)) return false;
            if (victimCountFilter === "50+" && count <= 50) return false;
        }

        return true;
    });

    // Calculate center based on filtered cases or default to Hat Yai
    const defaultCenter: [number, number] = [7.0, 100.47];
    const center = filteredCases.length > 0 && filteredCases[0].lat && filteredCases[0].lng
        ? [filteredCases[0].lat, filteredCases[0].lng] as [number, number]
        : defaultCenter;

    return (
        <div className="relative h-screen w-full">
            <MapContainer
                center={center}
                zoom={12}
                className="h-full w-full z-0"
                scrollWheelZoom={true}
                zoomControl={false} // Disable default zoom control
            >
                <ZoomControl position="bottomright" /> {/* Add custom zoom control at bottom-right */}

                <TileLayer
                    url={`https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=${process.env.NEXT_PUBLIC_MAPTILER_KEY}`}
                    attribution='&copy; <a href="https://www.maptiler.com/">MapTiler</a>'
                />

                {filteredCases.map((caseItem) => {
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

                {/* Evacuation Points */}
                {showEvac && evacPoints.map((evac) => (
                    <EvacMarker key={evac.id} data={evac} />
                ))}
            </MapContainer>

            {/* Status Widget Overlay */}
            <StatusWidget cases={cases} />

            {/* Compact Filters Bar */}
            <div className="absolute top-4 left-1/2 -translate-x-1/2 z-[1000] bg-white/95 backdrop-blur-md rounded-full shadow-xl px-4 py-2 flex items-center gap-3">
                {/* Category Filter */}
                <select
                    value={selectedCategory}
                    onChange={(e) => setSelectedCategory(e.target.value)}
                    className="px-3 py-1 text-xs border-none rounded-full bg-gray-100 text-gray-900 cursor-pointer hover:bg-gray-200 transition-colors"
                >
                    <option value="all">หมวดหมู่: ทั้งหมด</option>
                    {categories.map(cat => (
                        <option key={cat} value={cat}>{cat}</option>
                    ))}
                </select>

                {/* Victim Count Filter */}
                <select
                    value={victimCountFilter}
                    onChange={(e) => setVictimCountFilter(e.target.value)}
                    className="px-3 py-1 text-xs border-none rounded-full bg-gray-100 text-gray-900 cursor-pointer hover:bg-gray-200 transition-colors"
                >
                    <option value="all">ผู้ประสบภัย: ทั้งหมด</option>
                    <option value="1-10">1-10 คน</option>
                    <option value="10-50">10-50 คน</option>
                    <option value="50+">50+ คน</option>
                </select>

                <div className="w-px h-6 bg-gray-300"></div>

                {/* Toggle Buttons */}
                <button
                    onClick={() => setShowResolved(!showResolved)}
                    className={`px-3 py-1 text-xs rounded-full font-medium transition-colors ${showResolved
                        ? "bg-green-500 text-white"
                        : "bg-gray-100 text-gray-700 hover:bg-gray-200"
                        }`}
                >
                    {showResolved ? "✓ สำเร็จแล้ว" : "ซ่อนสำเร็จแล้ว"}
                </button>

                <button
                    onClick={() => setShowEvac(!showEvac)}
                    className={`px-3 py-1 text-xs rounded-full font-medium transition-colors ${showEvac
                        ? "bg-blue-500 text-white"
                        : "bg-gray-100 text-gray-700 hover:bg-gray-200"
                        }`}
                >
                    {showEvac ? "✓ ศูนย์พักพิง" : "ซ่อนศูนย์พักพิง"}
                </button>
            </div>

            {/* Back Button */}
            <Link href="/">
                <button className="absolute top-4 left-4 z-[1000] bg-white hover:bg-gray-100 text-gray-800 font-bold py-2 px-4 rounded-lg shadow-lg transition-colors flex items-center gap-2">
                    ← กลับหน้าหลัก
                </button>
            </Link>

            {/* Refresh Indicator */}
            <div className="absolute bottom-4 left-4 z-[1000] bg-white/90 backdrop-blur-sm text-gray-700 text-xs py-2 px-3 rounded-lg shadow-md">
                🔄 อัปเดตอัตโนมัติ | แสดง {filteredCases.length} จาก {cases.length} เคส
            </div>
        </div>
    );
}
