"use client";

import { DivIcon } from "leaflet";
import { Marker, Popup } from "react-leaflet";
import { renderToStaticMarkup } from "react-dom/server";
import { Building2, School, Church, Hospital, MapPin, Users, Phone } from "lucide-react";
import { MagnificentTag } from "@/components/ui/magnificent-tag";

interface EvacMarkerProps {
    data: any;
    onClick?: () => void;
}

const STATUS_CONFIG: any = {
    OPEN: { color: "bg-green-500", border: "border-green-600", label: "ว่าง" },
    LIMITED: { color: "bg-yellow-500", border: "border-yellow-600", label: "จำกัด" },
    FULL: { color: "bg-orange-500", border: "border-orange-600", label: "เต็ม" },
    CLOSED: { color: "bg-gray-500", border: "border-gray-600", label: "ปิด" },
};

const TYPE_ICONS: any = {
    school: School,
    temple: Church,
    community: Building2,
    hospital: Hospital,
    other: MapPin,
};

const EvacCard = ({ data }: { data: any }) => {
    const status = STATUS_CONFIG[data.open_status] || STATUS_CONFIG.OPEN;
    const TypeIcon = TYPE_ICONS[data.type] || MapPin;

    return (
        <div className={`relative w-64 bg-white rounded-xl shadow-xl border-2 flex flex-col p-3 gap-2 transform transition-transform hover:scale-105 ${status.border.replace("border-", "border-")}`}>

            {/* Header */}
            <div className="flex justify-between items-start">
                <div className="flex items-center gap-2 overflow-hidden">
                    <div className={`p-1.5 rounded-lg ${status.color} text-white shrink-0`}>
                        <TypeIcon className="w-4 h-4" />
                    </div>
                    <h3 className="font-bold text-sm truncate text-gray-900">{data.title}</h3>
                </div>
                <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full text-white ${status.color}`}>
                    {status.label}
                </span>
            </div>

            {/* Details */}
            <div className="flex items-center gap-3 text-xs text-gray-600">
                {data.capacity && (
                    <div className="flex items-center gap-1">
                        <Users className="w-3 h-3" />
                        <span>รับได้อีก {data.capacity}</span>
                    </div>
                )}
                {data.contact_phone && (
                    <div className="flex items-center gap-1">
                        <Phone className="w-3 h-3" />
                        <span>{data.contact_phone}</span>
                    </div>
                )}
            </div>

            {/* Facilities Preview */}
            {data.facilities && data.facilities.length > 0 && (
                <div className="flex flex-wrap gap-1 mt-1">
                    {data.facilities.slice(0, 3).map((f: string) => (
                        <MagnificentTag key={f} label={f} size="sm" className="text-[9px] px-1.5 py-0" />
                    ))}
                    {data.facilities.length > 3 && (
                        <span className="text-[9px] text-gray-400">+{data.facilities.length - 3}</span>
                    )}
                </div>
            )}

            {/* Triangle Pointer */}
            <div className={`absolute -bottom-1.5 left-1/2 -translate-x-1/2 w-3 h-3 bg-white border-r-2 border-b-2 transform rotate-45 ${status.border.replace("border-", "border-")}`}></div>
        </div>
    );
};

export const EvacMarker = ({ data, onClick }: EvacMarkerProps) => {
    const iconMarkup = renderToStaticMarkup(<EvacCard data={data} />);

    const customIcon = new DivIcon({
        html: iconMarkup,
        className: "custom-evac-marker",
        iconSize: [256, 100], // Approximate size
        iconAnchor: [128, 110], // Center bottom
        popupAnchor: [0, -110],
    });

    return (
        <Marker position={[data.lat, data.lng]} icon={customIcon} eventHandlers={{ click: onClick }} />
    );
};
