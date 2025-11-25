import { DivIcon } from "leaflet";
import { Marker, Popup } from "react-leaflet";
import { renderToStaticMarkup } from "react-dom/server";
import { Phone, User, Zap, Droplets, Utensils } from "lucide-react";
import Image from "next/image";
import { MagnificentTag } from "@/components/ui/magnificent-tag";

interface RiskMapCardProps {
    data: any;
    onClick?: () => void;
}

const RiskCard = ({ data }: { data: any }) => {
    const urgencyColors = {
        1: "bg-red-500 border-red-600",    // Critical
        2: "bg-orange-500 border-orange-600", // High
        3: "bg-yellow-500 border-yellow-600", // Medium
    };

    const statusColors: Record<string, string> = {
        NEW: "bg-blue-500",
        ACKNOWLEDGED: "bg-indigo-500",
        IN_PROGRESS: "bg-orange-500",
        RESOLVED: "bg-green-500",
        CLOSED: "bg-gray-500",
    };

    const statusLabels: Record<string, string> = {
        NEW: "รอช่วย",
        ACKNOWLEDGED: "รับเรื่อง",
        IN_PROGRESS: "กำลังช่วย",
        RESOLVED: "เสร็จ",
        CLOSED: "ปิด",
    };

    const urgencyColor = urgencyColors[data.urgency_level as 1 | 2 | 3] || "bg-gray-500 border-gray-600";
    const photoUrl = data.photos?.[0]?.url;

    // Check for specific needs
    const needsPower = data.categories?.some((c: string) =>
        c.toLowerCase().includes('power') || c.includes('แบต') || c.includes('ไฟ') || c.includes('ชาร์จ')
    );
    const needsWater = data.categories?.some((c: string) =>
        c.toLowerCase().includes('water') || c.includes('น้ำ') || c.includes('ดื่ม')
    );
    const needsFood = data.categories?.some((c: string) =>
        c.toLowerCase().includes('food') || c.includes('อาหาร') || c.includes('ข้าว') || c.includes('กิน')
    );

    return (
        <div className={`relative w-64 bg-white rounded-full shadow-xl border-2 flex items-center p-3 gap-3 transform transition-transform hover:scale-105 ${urgencyColor.replace("bg-", "border-")}`}>

            {/* Prominent Needs Indicators (Floating Top-Left) */}
            <div className="absolute -top-3 -left-2 z-10 flex gap-1">
                {needsPower && (
                    <div className="bg-white rounded-full p-1.5 shadow-sm border border-yellow-200 animate-bounce" style={{ animationDuration: '2s' }}>
                        <Zap className="w-5 h-5 text-yellow-500 fill-yellow-500 drop-shadow-[0_0_8px_rgba(234,179,8,0.8)]" />
                    </div>
                )}
                {needsWater && (
                    <div className="bg-white rounded-full p-1.5 shadow-sm border border-blue-200 animate-bounce" style={{ animationDuration: '2.2s', animationDelay: '0.1s' }}>
                        <Droplets className="w-5 h-5 text-blue-500 fill-blue-500 drop-shadow-[0_0_8px_rgba(59,130,246,0.8)]" />
                    </div>
                )}
                {needsFood && (
                    <div className="bg-white rounded-full p-1.5 shadow-sm border border-orange-200 animate-bounce" style={{ animationDuration: '2.4s', animationDelay: '0.2s' }}>
                        <Utensils className="w-5 h-5 text-orange-500 fill-orange-500 drop-shadow-[0_0_8px_rgba(249,115,22,0.8)]" />
                    </div>
                )}
            </div>

            {/* Content */}
            <div className="flex-1 min-w-0">
                <div className="flex justify-between items-center">
                    <h3 className="font-bold text-sm truncate text-gray-900 max-w-[100px]">{data.reporter_name}</h3>
                    <div className="flex gap-1">
                        {/* Status Badge */}
                        <span className={`text-[10px] font-bold px-1.5 py-0.5 rounded-full text-white ${statusColors[data.status] || "bg-gray-500"} `}>
                            {statusLabels[data.status] || data.status}
                        </span>
                        {/* Urgency Badge */}
                        <span className={`text-[10px] font-bold px-1.5 py-0.5 rounded-full text-white ${urgencyColor}`}>
                            {data.urgency_level === 1 ? "ด่วนมาก" : data.urgency_level === 2 ? "ด่วน" : "รอได้"}
                        </span>
                    </div>
                </div>

                <div className="flex items-center gap-2 mt-0.5">
                    {/* Tags (Show only 1 to save space) */}
                    {data.categories?.[0] && (
                        <div className="max-w-[100px] truncate">
                            <MagnificentTag label={data.categories[0]} size="sm" />
                        </div>
                    )}

                    {/* Phone */}
                    {data.contacts?.[0] && (
                        <div className="flex items-center text-[10px] text-gray-500">
                            <Phone className="w-3 h-3 mr-1" />
                            {data.contacts[0]}
                        </div>
                    )}
                </div>
            </div>

            {/* Triangle Pointer */}
            <div className={`absolute -bottom-1.5 left-1/2 -translate-x-1/2 w-3 h-3 bg-white border-r-2 border-b-2 transform rotate-45 ${urgencyColor.replace("bg-", "border-")}`}></div>
        </div>
    );
};

export const RiskMapMarker = ({ data, onClick }: RiskMapCardProps) => {
    const iconMarkup = renderToStaticMarkup(<RiskCard data={data} />);

    const customIcon = new DivIcon({
        html: iconMarkup,
        className: "custom-map-marker",
        iconSize: [256, 64], // Width w-64 (16rem=256px)
        iconAnchor: [128, 70], // Center bottom
        popupAnchor: [0, -70],
    });

    return (
        <Marker position={[data.lat, data.lng]} icon={customIcon} eventHandlers={{ click: onClick }} />
    );
};
