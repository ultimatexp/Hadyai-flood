"use client";

import { cn } from "@/lib/utils";
import { Droplets, Zap, Utensils, Bed, Accessibility, PawPrint, Bath } from "lucide-react";

interface FacilitiesSelectorProps {
    selected: string[];
    onChange: (selected: string[]) => void;
}

const FACILITIES = [
    { id: "water", label: "น้ำดื่ม", icon: Droplets },
    { id: "electricity", label: "ไฟฟ้า/ชาร์จแบต", icon: Zap },
    { id: "food", label: "อาหาร", icon: Utensils },
    { id: "sleeping", label: "ที่นอน", icon: Bed },
    { id: "toilet", label: "ห้องน้ำ", icon: Bath },
    { id: "disabled", label: "รองรับผู้พิการ", icon: Accessibility },
    { id: "pets", label: "รับสัตว์เลี้ยง", icon: PawPrint },
];

export function FacilitiesSelector({ selected, onChange }: FacilitiesSelectorProps) {
    const toggle = (id: string) => {
        if (selected.includes(id)) {
            onChange(selected.filter((i) => i !== id));
        } else {
            onChange([...selected, id]);
        }
    };

    return (
        <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
            {FACILITIES.map((item) => {
                const isSelected = selected.includes(item.id);
                const Icon = item.icon;
                return (
                    <button
                        key={item.id}
                        type="button"
                        onClick={() => toggle(item.id)}
                        className={cn(
                            "flex items-center gap-2 p-3 rounded-xl border text-sm font-medium transition-all",
                            isSelected
                                ? "border-primary bg-primary/5 text-primary shadow-sm"
                                : "border-border bg-card text-muted-foreground hover:bg-accent hover:text-accent-foreground"
                        )}
                    >
                        <Icon className={cn("w-4 h-4", isSelected ? "text-primary" : "text-muted-foreground")} />
                        {item.label}
                    </button>
                );
            })}
        </div>
    );
}
