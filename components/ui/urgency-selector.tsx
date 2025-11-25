import { cn } from "@/lib/utils";
import { AlertCircle, AlertTriangle, Clock } from "lucide-react";
import React from "react";

interface UrgencySelectorProps {
    value?: number;
    onChange: (value: number) => void;
}

export const UrgencySelector: React.FC<UrgencySelectorProps> = ({ value, onChange }) => {
    const options = [
        {
            value: 1,
            label: "ด่วนมาก",
            desc: "อันตรายถึงชีวิต / เจ็บป่วย",
            icon: AlertCircle,
            color: "bg-red-500",
            border: "border-red-500",
            bg: "bg-red-50",
            text: "text-red-700",
        },
        {
            value: 2,
            label: "ด่วน",
            desc: "ขาดแคลน / ต้องการย้าย",
            icon: AlertTriangle,
            color: "bg-orange-500",
            border: "border-orange-500",
            bg: "bg-orange-50",
            text: "text-orange-700",
        },
        {
            value: 3,
            label: "พอรอได้",
            desc: "ยังพอมีเสบียง / ปลอดภัย",
            icon: Clock,
            color: "bg-yellow-500",
            border: "border-yellow-500",
            bg: "bg-yellow-50",
            text: "text-yellow-700",
        },
    ];

    return (
        <div className="grid grid-cols-1 gap-3">
            {options.map((opt) => (
                <button
                    key={opt.value}
                    type="button"
                    onClick={() => onChange(opt.value)}
                    className={cn(
                        "flex items-center p-4 rounded-xl border-2 transition-all text-left gap-4",
                        value === opt.value
                            ? `${opt.border} ${opt.bg} shadow-sm`
                            : "border-border bg-card hover:bg-accent"
                    )}
                >
                    <div
                        className={cn(
                            "w-12 h-12 rounded-full flex items-center justify-center text-white shrink-0",
                            opt.color
                        )}
                    >
                        <opt.icon className="w-6 h-6" />
                    </div>
                    <div>
                        <div className={cn("font-bold text-lg", value === opt.value ? opt.text : "text-foreground")}>
                            {opt.label}
                        </div>
                        <div className="text-sm text-muted-foreground">{opt.desc}</div>
                    </div>
                </button>
            ))}
        </div>
    );
};
