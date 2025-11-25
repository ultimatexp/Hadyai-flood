"use client";

import { AlertTriangle, CheckCircle2, Clock, Truck, ChevronDown, ChevronUp } from "lucide-react";
import { useState } from "react";

interface StatusWidgetProps {
    cases: any[];
}

export default function StatusWidget({ cases }: StatusWidgetProps) {
    const [isExpanded, setIsExpanded] = useState(true);

    const statusCounts = {
        NEW: cases.filter(c => c.status === "NEW").length,
        ACKNOWLEDGED: cases.filter(c => c.status === "ACKNOWLEDGED").length,
        IN_PROGRESS: cases.filter(c => c.status === "IN_PROGRESS").length,
        RESOLVED: cases.filter(c => c.status === "RESOLVED").length,
    };

    const total = cases.length;

    const stats = [
        {
            label: "รอความช่วยเหลือ",
            count: statusCounts.NEW,
            icon: AlertTriangle,
            color: "text-red-600",
            bgColor: "bg-red-50",
            borderColor: "border-red-200",
        },
        {
            label: "รับเรื่องแล้ว",
            count: statusCounts.ACKNOWLEDGED,
            icon: Clock,
            color: "text-blue-600",
            bgColor: "bg-blue-50",
            borderColor: "border-blue-200",
        },
        {
            label: "กำลังช่วยเหลือ",
            count: statusCounts.IN_PROGRESS,
            icon: Truck,
            color: "text-orange-600",
            bgColor: "bg-orange-50",
            borderColor: "border-orange-200",
        },
        {
            label: "ช่วยเหลือสำเร็จ",
            count: statusCounts.RESOLVED,
            icon: CheckCircle2,
            color: "text-green-600",
            bgColor: "bg-green-50",
            borderColor: "border-green-200",
        },
    ];

    return (
        <div className="absolute top-32 left-4 z-[1000] bg-white/95 backdrop-blur-md rounded-2xl shadow-2xl w-80 border border-gray-200 overflow-hidden transition-all duration-300">
            {/* Header - Always Visible */}
            <div
                className="p-4 flex items-center justify-between cursor-pointer hover:bg-gray-50 transition-colors"
                onClick={() => setIsExpanded(!isExpanded)}
            >
                <div>
                    <h2 className="text-lg font-bold text-gray-800">สถานะการช่วยเหลือ</h2>
                    <p className="text-xs text-gray-500">ทั้งหมด {total} เคส</p>
                </div>
                <button className="p-1 rounded-full hover:bg-gray-200 transition-colors">
                    {isExpanded ? <ChevronUp className="w-5 h-5 text-gray-500" /> : <ChevronDown className="w-5 h-5 text-gray-500" />}
                </button>
            </div>

            {/* Content - Collapsible */}
            <div className={`transition-all duration-300 ease-in-out ${isExpanded ? "max-h-[500px] opacity-100" : "max-h-0 opacity-0"}`}>
                <div className="p-4 pt-0">
                    <div className="space-y-3">
                        {stats.map((stat) => (
                            <div
                                key={stat.label}
                                className={`flex items-center justify-between p-3 rounded-xl border ${stat.bgColor} ${stat.borderColor}`}
                            >
                                <div className="flex items-center gap-3">
                                    <div className={`p-2 rounded-lg bg-white ${stat.color}`}>
                                        <stat.icon className="w-5 h-5" />
                                    </div>
                                    <span className="font-medium text-gray-700 text-sm">{stat.label}</span>
                                </div>
                                <span className={`text-2xl font-bold ${stat.color}`}>{stat.count}</span>
                            </div>
                        ))}
                    </div>

                    {/* Progress Bar */}
                    <div className="mt-4 pt-4 border-t border-gray-200">
                        <div className="flex justify-between text-xs text-gray-600 mb-2">
                            <span>ความคืบหน้า</span>
                            <span>{total > 0 ? Math.round((statusCounts.RESOLVED / total) * 100) : 0}%</span>
                        </div>
                        <div className="w-full bg-gray-200 rounded-full h-2 overflow-hidden">
                            <div
                                className="bg-green-500 h-full transition-all duration-500 rounded-full"
                                style={{ width: `${total > 0 ? (statusCounts.RESOLVED / total) * 100 : 0}%` }}
                            />
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
