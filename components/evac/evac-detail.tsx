"use client";

import { useState, useEffect } from "react";
import { ThaiButton } from "@/components/ui/thai-button";
import { MagnificentTag } from "@/components/ui/magnificent-tag";
import { MapPin, Phone, Users, Clock, AlertTriangle, CheckCircle2, ThumbsUp, Flag, Navigation, Share2, Edit2 } from "lucide-react";
import { formatDistanceToNow } from "date-fns";
import { th } from "date-fns/locale";
import dynamic from "next/dynamic";
import Link from "next/link";
import { voteEvacPoint } from "@/lib/actions/evac";
import "leaflet/dist/leaflet.css";
import "leaflet-defaulticon-compatibility/dist/leaflet-defaulticon-compatibility.css";

const MapContainer = dynamic(() => import("react-leaflet").then(mod => mod.MapContainer), { ssr: false });
const TileLayer = dynamic(() => import("react-leaflet").then(mod => mod.TileLayer), { ssr: false });
const Marker = dynamic(() => import("react-leaflet").then(mod => mod.Marker), { ssr: false });

interface EvacDetailProps {
    data: any;
    editToken?: string | null;
}

export function EvacDetail({ data, editToken }: EvacDetailProps) {
    const [verifyCount, setVerifyCount] = useState(data.verify_count || 0);
    const [hasVoted, setHasVoted] = useState(false);
    const [origin, setOrigin] = useState("");
    const [copied, setCopied] = useState(false);

    useEffect(() => {
        // Dynamic import for Leaflet icon compatibility to avoid window is not defined
        import("leaflet-defaulticon-compatibility");

        setOrigin(window.location.origin);
        // Check local storage for vote
        if (localStorage.getItem(`voted_evac_${data.id}`)) {
            setHasVoted(true);
        }
    }, [data.id]);

    const handleVote = async (action: "VERIFY" | "REPORT") => {
        if (hasVoted) return;

        // Optimistic update
        if (action === "VERIFY") setVerifyCount((p: number) => p + 1);

        setHasVoted(true);
        localStorage.setItem(`voted_evac_${data.id}`, "true");

        await voteEvacPoint(data.id, action, "browser-fingerprint"); // Simplified fingerprint
    };

    const copyLink = () => {
        const url = `${origin}/evac/${data.id}`;
        navigator.clipboard.writeText(url);
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
    };

    const openGoogleMaps = () => {
        window.open(`https://www.google.com/maps/search/?api=1&query=${data.lat},${data.lng}`, "_blank");
    };

    const STATUS_CONFIG: any = {
        OPEN: { color: "bg-green-100 text-green-700", label: "เปิดรับคน" },
        LIMITED: { color: "bg-yellow-100 text-yellow-700", label: "รับได้จำกัด" },
        FULL: { color: "bg-orange-100 text-orange-700", label: "เต็มแล้ว" },
        CLOSED: { color: "bg-gray-100 text-gray-700", label: "ปิด" },
    };

    const status = STATUS_CONFIG[data.open_status] || STATUS_CONFIG.OPEN;

    return (
        <div className="space-y-6 pb-24">
            {/* Map Preview */}
            <div className="h-[250px] w-full bg-muted relative">
                <MapContainer center={[data.lat, data.lng]} zoom={15} className="h-full w-full" scrollWheelZoom={false} dragging={false}>
                    <TileLayer
                        url={`https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=${process.env.NEXT_PUBLIC_MAPTILER_KEY}`}
                    />
                    <Marker position={[data.lat, data.lng]} />
                </MapContainer>
                <button
                    onClick={openGoogleMaps}
                    className="absolute bottom-4 right-4 z-[500] bg-white p-3 rounded-full shadow-lg text-primary hover:scale-110 transition-transform"
                >
                    <Navigation className="w-6 h-6" />
                </button>
            </div>

            <div className="px-4 space-y-6">
                {/* Header */}
                <div className="space-y-2">
                    <div className="flex justify-between items-start">
                        <h1 className="text-2xl font-bold">{data.title}</h1>
                        <span className={`px-3 py-1 rounded-full text-sm font-bold whitespace-nowrap ${status.color}`}>
                            {status.label}
                        </span>
                    </div>
                    <div className="flex items-center gap-2 text-sm text-muted-foreground">
                        <Clock className="w-4 h-4" />
                        <span>อัปเดต {formatDistanceToNow(new Date(data.updated_at), { addSuffix: true, locale: th })}</span>
                    </div>
                </div>

                {/* Verification Status */}
                <div className="flex items-center gap-4 p-4 bg-secondary/30 rounded-xl">
                    <div className="flex items-center gap-2">
                        <CheckCircle2 className="w-5 h-5 text-green-600" />
                        <span className="font-bold text-green-700">{verifyCount} ยืนยัน</span>
                    </div>
                    <div className="h-4 w-px bg-border" />
                    <div className="text-sm text-muted-foreground">
                        ช่วยยืนยันข้อมูลนี้หากคุณอยู่ที่นี่
                    </div>
                </div>

                {/* Capacity & Contact */}
                <div className="grid grid-cols-2 gap-4">
                    <div className="p-4 bg-card border rounded-xl space-y-1">
                        <div className="flex items-center gap-2 text-muted-foreground text-sm">
                            <Users className="w-4 h-4" />
                            รองรับได้อีก
                        </div>
                        <p className="text-xl font-bold">{data.capacity ? `${data.capacity} คน` : "-"}</p>
                    </div>
                    <div className="p-4 bg-card border rounded-xl space-y-1">
                        <div className="flex items-center gap-2 text-muted-foreground text-sm">
                            <Phone className="w-4 h-4" />
                            เบอร์ติดต่อ
                        </div>
                        {data.contact_phone ? (
                            <a href={`tel:${data.contact_phone}`} className="text-xl font-bold text-primary hover:underline block truncate">
                                {data.contact_phone}
                            </a>
                        ) : (
                            <p className="text-xl font-bold">-</p>
                        )}
                    </div>
                </div>

                {/* Facilities */}
                <div className="space-y-3">
                    <h3 className="font-semibold">สิ่งอำนวยความสะดวก</h3>
                    <div className="flex flex-wrap gap-2">
                        {data.facilities?.length > 0 ? (
                            data.facilities.map((f: string) => (
                                <MagnificentTag key={f} label={f} size="md" />
                            ))
                        ) : (
                            <p className="text-muted-foreground text-sm">- ไม่ระบุ -</p>
                        )}
                    </div>
                </div>

                {/* Note */}
                {data.note && (
                    <div className="space-y-3">
                        <h3 className="font-semibold">รายละเอียดเพิ่มเติม</h3>
                        <p className="p-4 bg-muted rounded-xl text-sm leading-relaxed">{data.note}</p>
                    </div>
                )}

                {/* Owner Section */}
                {editToken && (
                    <div className="mt-8 p-4 border border-blue-200 bg-blue-50 rounded-xl space-y-3">
                        <h3 className="font-bold text-blue-800 flex items-center gap-2">
                            <Edit2 className="w-4 h-4" /> สำหรับเจ้าของจุดอพยพ
                        </h3>
                        <p className="text-sm text-blue-700">คุณสามารถแก้ไขข้อมูลหรืออัปเดตสถานะได้</p>
                        <Link href={`/evac/${data.id}/update?token=${editToken}`} className="block">
                            <ThaiButton className="w-full bg-blue-600 hover:bg-blue-700">
                                แก้ไขข้อมูล / อัปเดตสถานะ
                            </ThaiButton>
                        </Link>
                    </div>
                )}
            </div>

            {/* Fixed Bottom Actions */}
            <div className="fixed bottom-0 left-0 right-0 p-4 bg-background/80 backdrop-blur-md border-t flex gap-3 z-40">
                <ThaiButton
                    variant="outline"
                    className={`flex-1 ${hasVoted ? "opacity-50" : ""}`}
                    onClick={() => handleVote("VERIFY")}
                    disabled={hasVoted}
                >
                    <ThumbsUp className="mr-2 w-4 h-4" /> ยืนยันข้อมูล
                </ThaiButton>
                <ThaiButton
                    variant="ghost"
                    className={`flex-1 text-red-600 hover:bg-red-50 hover:text-red-700 ${hasVoted ? "opacity-50" : ""}`}
                    onClick={() => handleVote("REPORT")}
                    disabled={hasVoted}
                >
                    <Flag className="mr-2 w-4 h-4" /> แจ้งปัญหา
                </ThaiButton>
                <button
                    onClick={copyLink}
                    className="p-3 rounded-xl border hover:bg-accent transition-colors"
                >
                    <Share2 className="w-5 h-5" />
                </button>
            </div>
        </div>
    );
}
