import { Zap, Droplets, Utensils } from "lucide-react";
import { cn } from "@/lib/utils";

interface MagnificentTagProps {
    label: string;
    className?: string;
    size?: "sm" | "md" | "lg";
}

export const MagnificentTag = ({ label, className, size = "md" }: MagnificentTagProps) => {
    const lowerLabel = label.toLowerCase();

    const isPower = lowerLabel.includes('power') || lowerLabel.includes('แบต') || lowerLabel.includes('ไฟ') || lowerLabel.includes('ชาร์จ');
    const isWater = lowerLabel.includes('water') || lowerLabel.includes('น้ำ') || lowerLabel.includes('ดื่ม');
    const isFood = lowerLabel.includes('food') || lowerLabel.includes('อาหาร') || lowerLabel.includes('ข้าว') || lowerLabel.includes('กิน');

    const sizeClasses = {
        sm: "px-1.5 py-0.5 text-[10px]",
        md: "px-3 py-1 text-sm",
        lg: "px-4 py-2 text-base",
    };

    const iconSizes = {
        sm: "w-3 h-3 mr-1",
        md: "w-4 h-4 mr-1.5",
        lg: "w-5 h-5 mr-2",
    };

    if (isPower) {
        return (
            <span className={cn(
                "inline-flex items-center font-bold rounded-full transition-all",
                "bg-yellow-100 text-yellow-700 border border-yellow-200",
                "shadow-[0_0_10px_rgba(234,179,8,0.3)] animate-pulse",
                sizeClasses[size],
                className
            )}>
                <Zap className={cn("fill-yellow-500 text-yellow-600", iconSizes[size])} />
                {label}
            </span>
        );
    }

    if (isWater) {
        return (
            <span className={cn(
                "inline-flex items-center font-bold rounded-full transition-all",
                "bg-blue-100 text-blue-700 border border-blue-200",
                "shadow-[0_0_10px_rgba(59,130,246,0.3)] animate-pulse",
                sizeClasses[size],
                className
            )}>
                <Droplets className={cn("fill-blue-500 text-blue-600", iconSizes[size])} />
                {label}
            </span>
        );
    }

    if (isFood) {
        return (
            <span className={cn(
                "inline-flex items-center font-bold rounded-full transition-all",
                "bg-orange-100 text-orange-700 border border-orange-200",
                "shadow-[0_0_10px_rgba(249,115,22,0.3)] animate-pulse",
                sizeClasses[size],
                className
            )}>
                <Utensils className={cn("fill-orange-500 text-orange-600", iconSizes[size])} />
                {label}
            </span>
        );
    }

    // Default tag
    return (
        <span className={cn(
            "inline-flex items-center font-medium rounded-lg bg-secondary text-secondary-foreground",
            sizeClasses[size],
            className
        )}>
            {label}
        </span>
    );
};
