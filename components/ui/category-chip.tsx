import { cn } from "@/lib/utils";
import { LucideIcon } from "lucide-react";
import React from "react";

interface CategoryChipProps {
    label: string;
    icon: LucideIcon;
    selected?: boolean;
    onClick?: () => void;
}

export const CategoryChip: React.FC<CategoryChipProps> = ({
    label,
    icon: Icon,
    selected,
    onClick,
}) => {
    return (
        <button
            type="button"
            onClick={onClick}
            className={cn(
                "flex flex-col items-center justify-center p-4 rounded-2xl border-2 transition-all duration-200 gap-2",
                selected
                    ? "border-primary bg-primary/5 text-primary shadow-sm scale-[1.02]"
                    : "border-border bg-card text-muted-foreground hover:border-primary/50 hover:bg-accent"
            )}
        >
            <Icon className={cn("w-8 h-8", selected ? "text-primary" : "text-muted-foreground")} />
            <span className="font-medium text-sm">{label}</span>
        </button>
    );
};
