"use client";

import React, { useEffect, useState } from "react";
import { MapContainer, TileLayer, Marker, Popup } from "react-leaflet";
import "leaflet/dist/leaflet.css";
import "leaflet-defaulticon-compatibility/dist/leaflet-defaulticon-compatibility.css";
import "leaflet-defaulticon-compatibility";
import { supabase } from "@/lib/supabase";
import { CaseCard } from "./case-card";
import { Loader2, List, Map as MapIcon } from "lucide-react";
import { ThaiButton } from "../ui/thai-button";
import { RiskMapMarker } from "./risk-map-marker";
import { EvacMarker } from "../evac/evac-marker";
import Link from "next/link";
import { Plus } from "lucide-react";
import "./map-styles.css";

export default function HelperView() {
    const [cases, setCases] = useState<any[]>([]);
    const [evacPoints, setEvacPoints] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [viewMode, setViewMode] = useState<"map" | "list">("map");
    const [showSOS, setShowSOS] = useState(true);
    const [showEvac, setShowEvac] = useState(true);

    useEffect(() => {
        fetchCases();
        fetchEvacPoints();

        const channel = supabase
            .channel("realtime-map")
            .on("postgres_changes", { event: "*", schema: "public", table: "sos_cases" }, (payload) => {
                fetchCases(); // Simple re-fetch for now
            })
            .on("postgres_changes", { event: "*", schema: "public", table: "evac_points" }, (payload) => {
                fetchEvacPoints();
            })
            .subscribe();

        return () => {
            supabase.removeChannel(channel);
        };
    }, []);

    const fetchCases = async () => {
        const { data, error } = await supabase
            .from("sos_cases")
            .select("*")
            .neq("status", "CLOSED") // Hide closed cases
            .order("urgency_level", { ascending: true })
            .order("created_at", { ascending: false });

        if (data) setCases(data);
        setLoading(false);
    };

    const fetchEvacPoints = async () => {
        const { data } = await supabase
            .from("evac_points")
            .select("*")
            .lt("report_count", 3); // Hide reported points

        if (data) setEvacPoints(data);
    };

    const defaultCenter: [number, number] = [7.00866, 100.47469];

    if (loading) {
        return (
            <div className="flex items-center justify-center h-[50vh]">
                <Loader2 className="w-8 h-8 animate-spin text-primary" />
            </div>
        );
    }

    return (
        <div className="relative h-[calc(100vh-60px)]">
            {/* Toggle View (Mobile) */}
            <div className="absolute top-4 right-4 z-[1000] flex flex-col gap-2">
                <ThaiButton
                    size="sm"
                    variant="outline"
                    className="bg-white shadow-md md:hidden"
                    onClick={() => setViewMode(viewMode === "map" ? "list" : "map")}
                >
                    {viewMode === "map" ? <List className="mr-2" /> : <MapIcon className="mr-2" />}
                    {viewMode === "map" ? "รายการ" : "แผนที่"}
                </ThaiButton>

                {/* Layer Toggles */}
                <div className="bg-white/90 backdrop-blur rounded-lg shadow-md p-1 flex flex-col gap-1">
                    <button
                        onClick={() => setShowSOS(!showSOS)}
                        className={`px-3 py-1.5 text-xs font-bold rounded-md transition-all flex items-center justify-between gap-2 ${showSOS ? "bg-red-100 text-red-700" : "text-gray-500 hover:bg-gray-100"}`}
                    >
                        <span>SOS ({cases.length})</span>
                        <div className={`w-2 h-2 rounded-full ${showSOS ? "bg-red-500" : "bg-gray-300"}`} />
                    </button>
                    <button
                        onClick={() => setShowEvac(!showEvac)}
                        className={`px-3 py-1.5 text-xs font-bold rounded-md transition-all flex items-center justify-between gap-2 ${showEvac ? "bg-green-100 text-green-700" : "text-gray-500 hover:bg-gray-100"}`}
                    >
                        <span>จุดอพยพ ({evacPoints.length})</span>
                        <div className={`w-2 h-2 rounded-full ${showEvac ? "bg-green-500" : "bg-gray-300"}`} />
                    </button>
                </div>
            </div>

            {/* Add Evac Point FAB */}
            <Link href="/evac/new" className="absolute bottom-6 right-4 z-[1000] md:bottom-8 md:right-8">
                <button className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-3 rounded-full shadow-lg transition-transform hover:scale-105 flex items-center gap-2 font-bold">
                    <Plus className="w-5 h-5" />
                    <span>เพิ่มจุดอพยพ</span>
                </button>
            </Link>

            {/* Map View */}
            <div className={`h-full w-full ${viewMode === "list" ? "hidden md:block" : "block"}`}>
                <MapContainer center={defaultCenter} zoom={13} className="h-full w-full">
                    <TileLayer
                        attribution='&copy; <a href="https://www.maptiler.com/copyright/" target="_blank">&copy; MapTiler</a> <a href="https://www.openstreetmap.org/copyright" target="_blank">&copy; OpenStreetMap contributors</a>'
                        url={`https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=${process.env.NEXT_PUBLIC_MAPTILER_KEY}`}
                    />
                    {showSOS && cases.map((c) => (
                        c.lat && c.lng && (
                            <RiskMapMarker
                                key={c.id}
                                data={c}
                                onClick={() => {
                                    window.location.href = `/case/${c.id}`;
                                }}
                            />
                        )
                    ))}
                    {showEvac && evacPoints.map((p) => (
                        p.lat && p.lng && (
                            <EvacMarker
                                key={p.id}
                                data={p}
                                onClick={() => {
                                    window.location.href = `/evac/${p.id}`;
                                }}
                            />
                        )
                    ))}
                </MapContainer>
            </div>

            {/* List View (Bottom Sheet on Mobile, Sidebar on Desktop) */}
            <div className={`
        absolute inset-x-0 bottom-0 z-[999] bg-background rounded-t-3xl shadow-[0_-4px_20px_rgba(0,0,0,0.1)] 
        transition-transform duration-300 transform
        md:top-0 md:left-0 md:bottom-0 md:w-[400px] md:rounded-none md:border-r md:translate-y-0
        ${viewMode === "list" ? "translate-y-0 h-full rounded-none" : "translate-y-[calc(100%-180px)] md:translate-y-0"}
      `}>
                <div className="p-4 h-full flex flex-col">
                    <div className="w-12 h-1.5 bg-muted rounded-full mx-auto mb-4 md:hidden" />

                    <div className="flex justify-between items-center mb-4">
                        <h2 className="text-xl font-bold">รายการขอความช่วยเหลือ</h2>
                        <span className="text-sm text-muted-foreground">{cases.length} เคส</span>
                    </div>

                    <div className="flex-1 overflow-y-auto space-y-3 pb-20 md:pb-0">
                        {cases.map((c) => (
                            <CaseCard key={c.id} data={c} />
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );
}
