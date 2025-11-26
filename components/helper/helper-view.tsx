"use client";

import React, { useEffect, useState } from "react";
import { MapContainer, TileLayer, Marker, Popup } from "react-leaflet";
import "leaflet/dist/leaflet.css";
import "leaflet-defaulticon-compatibility/dist/leaflet-defaulticon-compatibility.css";
import "leaflet-defaulticon-compatibility";
import { supabase } from "@/lib/supabase";
import { CaseCard } from "./case-card";
import { Loader2, List, Map as MapIcon, Search } from "lucide-react";
import { ThaiButton } from "../ui/thai-button";
import { RiskMapMarker } from "./risk-map-marker";
import { EvacMarker } from "../evac/evac-marker";
import Link from "next/link";
import { Plus } from "lucide-react";
import "./map-styles.css";
import MarkerClusterGroup from "react-leaflet-cluster";
import { Layers, Filter, Grid, MapPin, Group } from "lucide-react";

export default function HelperView() {
    const [cases, setCases] = useState<any[]>([]);
    const [evacPoints, setEvacPoints] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [viewMode, setViewMode] = useState<"map" | "list">("map");
    const [showSOS, setShowSOS] = useState(true);
    const [showEvac, setShowEvac] = useState(true);

    // Filters
    const [showResolved, setShowResolved] = useState(false);
    const [showAll, setShowAll] = useState(false);
    const [selectedCategory, setSelectedCategory] = useState<string>("all");
    const [searchQuery, setSearchQuery] = useState("");
    const [riskFilter, setRiskFilter] = useState<string>("all");
    const [victimCountFilter, setVictimCountFilter] = useState<string>("all");

    // Pagination
    const [page, setPage] = useState(0);
    const [hasMore, setHasMore] = useState(true);
    const [loadingMore, setLoadingMore] = useState(false);

    // Display Mode
    const [displayMode, setDisplayMode] = useState<'cards' | 'pin' | 'group'>('cards');


    const fetchCases = async (reset = false) => {
        if (reset) {
            setLoading(true);
            setPage(0);
        } else {
            setLoadingMore(true);
        }

        const currentPage = reset ? 0 : page;
        const limit = 250;
        const from = currentPage * limit;
        const to = from + limit - 1;

        let query = supabase
            .from("sos_cases")
            .select("*, case_offers(id, amount)") // Include offers
            .range(from, to);

        // Apply filters
        if (!showAll) {
            query = query.neq("status", "CLOSED");
            if (!showResolved) query = query.neq("status", "RESOLVED");
        }

        if (selectedCategory !== "all") query = query.contains("categories", [selectedCategory]);
        if (riskFilter !== "all") query = query.eq("urgency_level", parseInt(riskFilter));
        if (victimCountFilter !== "all") {
            if (victimCountFilter === "1-10") {
                query = query.gte("victim_count", 1).lte("victim_count", 10);
            } else if (victimCountFilter === "10-50") {
                query = query.gt("victim_count", 10).lte("victim_count", 50);
            } else if (victimCountFilter === "50+") {
                query = query.gt("victim_count", 50);
            }
        }
        if (searchQuery) {
            // Search by name or address (using simple ILIKE for now)
            // Note: Supabase JS .or() syntax: .or('col1.eq.val,col2.eq.val')
            query = query.or(`reporter_name.ilike.%${searchQuery}%,address_text.ilike.%${searchQuery}%`);
        }

        // Order
        query = query.order("urgency_level", { ascending: false }).order("created_at", { ascending: false });

        const { data, error } = await query;

        if (data) {
            if (reset) {
                setCases(data);
                setPage(1); // Prepare for next page
            } else {
                setCases(prev => [...prev, ...data]);
                setPage(prev => prev + 1);
            }
            setHasMore(data.length === limit);
        }

        setLoading(false);
        setLoadingMore(false);
    };

    const loadMore = () => {
        if (!loadingMore && hasMore) {
            fetchCases(false);
        }
    };

    const fetchEvacPoints = async () => {
        const { data } = await supabase
            .from("evac_points")
            .select("*")
            .lt("report_count", 3);
        if (data) setEvacPoints(data);
    };

    // Debounce search
    useEffect(() => {
        const timer = setTimeout(() => {
            setPage(0);
            fetchCases(true);
        }, 500);
        return () => clearTimeout(timer);
    }, [searchQuery, selectedCategory, riskFilter, victimCountFilter, showResolved, showAll]);

    useEffect(() => {
        fetchEvacPoints();

        // Realtime subscription (only for updates, not inserts to avoid messing up pagination)
        const channel = supabase
            .channel("realtime-map")
            .on("postgres_changes", { event: "UPDATE", schema: "public", table: "sos_cases" }, (payload) => {
                // Update local state if the case exists
                setCases(prev => prev.map(c => c.id === payload.new.id ? payload.new : c));
            })
            .on("postgres_changes", { event: "*", schema: "public", table: "evac_points" }, () => {
                fetchEvacPoints();
            })
            .subscribe();

        return () => {
            supabase.removeChannel(channel);
        };
    }, []);

    const defaultCenter: [number, number] = [7.00866, 100.47469];

    // Extract unique categories
    const categories = Array.from(new Set(cases.flatMap(c => c.categories || []))).sort();

    // Handle Display Mode Change
    const handleDisplayModeChange = (mode: 'cards' | 'pin' | 'group') => {
        setDisplayMode(mode);
        if (mode === 'cards') {
            setViewMode('list');
        } else {
            setViewMode('map');
        }
    };

    const renderMarkers = () => (
        <>
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
        </>
    );

    return (
        <div className="relative h-[calc(100vh-60px)]">
            {/* Toggle View (Mobile) */}
            <div className="absolute top-4 right-4 z-[1000] flex flex-col gap-2 pointer-events-none md:pointer-events-auto items-end">
                <div className="pointer-events-auto flex flex-col gap-2 items-end">

                    {/* Display Mode Toggle */}
                    <div className="bg-white rounded-lg shadow-md p-1 flex gap-1">
                        <button
                            onClick={() => handleDisplayModeChange('cards')}
                            className={`p-2 rounded-md transition-all ${displayMode === 'cards' ? 'bg-blue-100 text-blue-600' : 'text-gray-500 hover:bg-gray-100'}`}
                            title="Cards (List)"
                        >
                            <List className="w-5 h-5" />
                        </button>
                        <button
                            onClick={() => handleDisplayModeChange('pin')}
                            className={`p-2 rounded-md transition-all ${displayMode === 'pin' ? 'bg-blue-100 text-blue-600' : 'text-gray-500 hover:bg-gray-100'}`}
                            title="Pin (Map)"
                        >
                            <MapPin className="w-5 h-5" />
                        </button>
                        <button
                            onClick={() => handleDisplayModeChange('group')}
                            className={`p-2 rounded-md transition-all ${displayMode === 'group' ? 'bg-blue-100 text-blue-600' : 'text-gray-500 hover:bg-gray-100'}`}
                            title="Group (Cluster)"
                        >
                            <Layers className="w-5 h-5" />
                        </button>
                    </div>

                    {/* Layer Toggles */}
                    <div className="bg-white/90 backdrop-blur rounded-lg shadow-md p-1 flex flex-col gap-1">
                        <button
                            onClick={() => setShowSOS(!showSOS)}
                            className={`px-3 py-1.5 text-xs font-bold rounded-md transition-all flex items-center justify-between gap-2 ${showSOS ? "bg-red-100 text-red-700" : "text-gray-500 hover:bg-gray-100"}`}
                        >
                            <span>SOS ({cases.length}+)</span>
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
            </div>

            {/* Add Evac Point FAB - Behind widget */}
            <Link href="/evac/new" className="absolute bottom-6 right-4 z-[900] md:bottom-8 md:right-8">
                <button className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-3 rounded-full shadow-lg transition-transform hover:scale-105 flex items-center gap-2 font-bold">
                    <Plus className="w-5 h-5" />
                    <span className="hidden md:inline">เพิ่มจุดอพยพ</span>
                </button>
            </Link>

            {/* Map View */}
            <div className={`h-full w-full ${viewMode === "list" ? "hidden md:block" : "block"}`}>
                <MapContainer center={defaultCenter} zoom={13} className="h-full w-full">
                    <TileLayer
                        attribution='&copy; <a href="https://www.maptiler.com/copyright/" target="_blank">&copy; MapTiler</a> <a href="https://www.openstreetmap.org/copyright" target="_blank">&copy; OpenStreetMap contributors</a>'
                        url={`https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=${process.env.NEXT_PUBLIC_MAPTILER_KEY}`}
                    />

                    {displayMode === 'group' ? (
                        <MarkerClusterGroup chunkedLoading>
                            {renderMarkers()}
                        </MarkerClusterGroup>
                    ) : (
                        renderMarkers()
                    )}

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

                    <div className="space-y-4 mb-4">
                        <div className="flex justify-between items-center">
                            <h2 className="text-xl font-bold">รายการขอความช่วยเหลือ</h2>
                            <span className="text-sm text-muted-foreground">{cases.length} รายการ</span>
                        </div>

                        {/* Search & Filters */}
                        <div className="space-y-2">
                            <div className="relative">
                                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                                <input
                                    type="text"
                                    placeholder="ค้นหาชื่อ, สถานที่..."
                                    value={searchQuery}
                                    onChange={(e) => setSearchQuery(e.target.value)}
                                    className="w-full pl-9 pr-4 py-2 rounded-lg border bg-gray-50 focus:bg-white focus:ring-2 focus:ring-primary/20 outline-none transition-all text-sm text-gray-900"
                                />
                            </div>

                            <div className="grid grid-cols-3 gap-2">
                                <select
                                    value={riskFilter}
                                    onChange={(e) => setRiskFilter(e.target.value)}
                                    className="p-2 text-xs border rounded-lg bg-white text-gray-900"
                                >
                                    <option value="all">ระดับความเสี่ยง (ทั้งหมด)</option>
                                    <option value="1">🔴 ด่วนมาก</option>
                                    <option value="2">🟠 ด่วน</option>
                                    <option value="3">🟡 พอรอได้</option>
                                </select>

                                <select
                                    value={victimCountFilter}
                                    onChange={(e) => setVictimCountFilter(e.target.value)}
                                    className="p-2 text-xs border rounded-lg bg-white text-gray-900"
                                >
                                    <option value="all">ผู้ประสบภัย (ทั้งหมด)</option>
                                    <option value="1-10">👥 1-10 คน</option>
                                    <option value="10-50">👥 10-50 คน</option>
                                    <option value="50+">👥 50+ คน</option>
                                </select>

                                <select
                                    value={selectedCategory}
                                    onChange={(e) => setSelectedCategory(e.target.value)}
                                    className="p-2 text-xs border rounded-lg bg-white text-gray-900"
                                >
                                    <option value="all">หมวดหมู่ (ทั้งหมด)</option>
                                    {categories.map(cat => (
                                        <option key={cat} value={cat}>{cat}</option>
                                    ))}
                                </select>
                            </div>

                            <div className="flex gap-4 text-xs">
                                <label className="flex items-center gap-1.5 cursor-pointer">
                                    <input
                                        type="checkbox"
                                        checked={showResolved}
                                        onChange={(e) => setShowResolved(e.target.checked)}
                                        disabled={showAll}
                                        className="rounded border-gray-300 text-primary focus:ring-primary disabled:opacity-50"
                                    />
                                    <span className={showAll ? 'text-gray-400' : 'text-gray-600'}>
                                        แสดงเคสที่ช่วยเหลือสำเร็จแล้ว
                                    </span>
                                </label>
                                <label className="flex items-center gap-1.5 cursor-pointer">
                                    <input
                                        type="checkbox"
                                        checked={showAll}
                                        onChange={(e) => setShowAll(e.target.checked)}
                                        className="rounded border-gray-300 text-primary focus:ring-primary"
                                    />
                                    <span className="text-gray-600">แสดงทั้งหมด (รวมเคสปิดแล้ว)</span>
                                </label>
                            </div>
                        </div>
                    </div>

                    <div className="flex-1 overflow-y-auto space-y-3 pb-20 md:pb-0 scrollbar-hide">
                        {loading && page === 0 ? (
                            <div className="flex justify-center py-8">
                                <Loader2 className="w-8 h-8 animate-spin text-primary" />
                            </div>
                        ) : (
                            <>
                                {cases.map((c) => (
                                    <CaseCard key={c.id} data={c} />
                                ))}

                                {cases.length === 0 && !loading && (
                                    <div className="text-center py-8 text-gray-500">
                                        ไม่พบข้อมูลที่ค้นหา
                                    </div>
                                )}

                                {hasMore && (
                                    <button
                                        onClick={loadMore}
                                        disabled={loadingMore}
                                        className="w-full py-3 text-sm text-primary font-bold hover:bg-primary/5 rounded-lg transition-colors flex items-center justify-center gap-2"
                                    >
                                        {loadingMore && <Loader2 className="w-4 h-4 animate-spin" />}
                                        {loadingMore ? "กำลังโหลด..." : "โหลดเพิ่มเติม"}
                                    </button>
                                )}
                            </>
                        )}
                    </div>
                </div >
            </div >
        </div >
    );
}
