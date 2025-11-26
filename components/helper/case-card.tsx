import { ThaiButton } from "@/components/ui/thai-button";
import { MapPin, Phone, Clock, AlertTriangle } from "lucide-react";
import { MagnificentTag } from "@/components/ui/magnificent-tag";
import Link from "next/link";
import { formatDistanceToNow } from "date-fns";
import { th } from "date-fns/locale";

interface CaseCardProps {
    data: any;
    compact?: boolean;
    onClick?: () => void;
}

export const CaseCard: React.FC<CaseCardProps> = ({ data, compact, onClick }) => {
    const urgencyColors = {
        1: "bg-red-100 text-red-700 border-red-200",
        2: "bg-orange-100 text-orange-700 border-orange-200",
        3: "bg-yellow-100 text-yellow-700 border-yellow-200",
    };

    const statusColors = {
        NEW: "bg-blue-100 text-blue-700",
        ACKNOWLEDGED: "bg-purple-100 text-purple-700",
        IN_PROGRESS: "bg-yellow-100 text-yellow-700",
        RESOLVED: "bg-green-100 text-green-700",
        CLOSED: "bg-gray-100 text-gray-700",
    };

    const statusLabels: Record<string, string> = {
        NEW: "รอความช่วยเหลือ",
        ACKNOWLEDGED: "รับเรื่องแล้ว",
        IN_PROGRESS: "กำลังช่วยเหลือ",
        RESOLVED: "ช่วยเหลือแล้ว",
        CLOSED: "ปิดเคส",
    };

    return (
        <div
            onClick={onClick}
            className={`bg-card rounded-xl border p-4 shadow-sm hover:shadow-md transition-shadow cursor-pointer ${compact ? 'space-y-2' : 'space-y-4'}`}
        >
            <div className="flex justify-between items-start">
                <div className="flex gap-2 flex-wrap">
                    <span className={`px-2 py-0.5 rounded-md text-xs font-bold border ${urgencyColors[data.urgency_level as 1 | 2 | 3]}`}>
                        {data.urgency_level === 1 ? "ด่วนมาก" : data.urgency_level === 2 ? "ด่วน" : "พอรอได้"}
                    </span>
                    <span className={`px-2 py-0.5 rounded-md text-xs font-bold ${statusColors[data.status as keyof typeof statusColors]}`}>
                        {statusLabels[data.status as string] || data.status}
                    </span>
                    {data.case_offers && data.case_offers.length > 0 && (
                        <span className="px-2 py-0.5 rounded-md text-xs font-bold bg-gradient-to-r from-yellow-400 to-yellow-600 text-white shadow-sm">
                            💰 {data.case_offers[0].amount.toLocaleString()} ฿
                        </span>
                    )}
                    {data.victim_count && data.victim_count > 1 && (
                        <span className="px-2 py-0.5 rounded-md text-xs font-bold bg-blue-100 text-blue-700 border border-blue-200">
                            👥 {data.victim_count} คน
                        </span>
                    )}
                </div>
                <span className="text-xs text-muted-foreground flex items-center">
                    <Clock className="w-3 h-3 mr-1" />
                    {formatDistanceToNow(new Date(data.created_at), { addSuffix: true, locale: th })}
                </span>
            </div>

            <div>
                <h3 className="font-bold text-lg line-clamp-1">{data.reporter_name}</h3>
                <div className="flex items-start text-sm text-muted-foreground mt-1">
                    <MapPin className="w-4 h-4 mr-1 shrink-0 mt-0.5" />
                    <span className="line-clamp-2">{data.address_text || "ไม่มีรายละเอียดที่อยู่"}</span>
                </div>
            </div>

            {/* Categories */}
            <div className="flex flex-wrap gap-1.5 mb-3">
                {data.categories?.slice(0, 3).map((cat: string) => (
                    <MagnificentTag key={cat} label={cat} size="sm" />
                ))}
                {data.categories?.length > 3 && (
                    <span className="text-xs text-muted-foreground self-center">
                        +{data.categories.length - 3}
                    </span>
                )}
            </div>

            {!compact && (
                <div className="pt-2 flex gap-2">
                    <Link href={`/case/${data.id}`} className="flex-1" onClick={(e) => e.stopPropagation()}>
                        <ThaiButton size="sm" variant="outline" className="w-full">
                            ดูรายละเอียด
                        </ThaiButton>
                    </Link>
                    <a href={`tel:${data.contacts?.[0]}`} className="flex-1" onClick={(e) => e.stopPropagation()}>
                        <ThaiButton size="sm" variant="success" className="w-full">
                            <Phone className="w-4 h-4 mr-2" /> โทร
                        </ThaiButton>
                    </a>
                </div>
            )}
        </div>
    );
};
