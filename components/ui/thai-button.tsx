import { cn } from "@/lib/utils";
import { Loader2 } from "lucide-react";
import React from "react";

interface ThaiButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
    variant?: "primary" | "danger" | "success" | "outline" | "ghost";
    size?: "lg" | "md" | "sm";
    isLoading?: boolean;
}

export const ThaiButton = React.forwardRef<HTMLButtonElement, ThaiButtonProps>(
    ({ className, variant = "primary", size = "lg", isLoading, children, ...props }, ref) => {
        const variants = {
            primary: "bg-primary text-primary-foreground hover:bg-primary/90 shadow-lg shadow-primary/20",
            danger: "bg-destructive text-destructive-foreground hover:bg-destructive/90 shadow-lg shadow-destructive/20",
            success: "bg-green-600 text-white hover:bg-green-700 shadow-lg shadow-green-600/20",
            outline: "border-2 border-input bg-background hover:bg-accent hover:text-accent-foreground",
            ghost: "hover:bg-accent hover:text-accent-foreground",
        };

        const sizes = {
            lg: "h-14 px-8 text-xl rounded-2xl",
            md: "h-11 px-6 text-lg rounded-xl",
            sm: "h-9 px-4 text-sm rounded-lg",
        };

        return (
            <button
                ref={ref}
                className={cn(
                    "inline-flex items-center justify-center font-semibold transition-all active:scale-95 disabled:pointer-events-none disabled:opacity-50",
                    variants[variant],
                    sizes[size],
                    className
                )}
                disabled={isLoading || props.disabled}
                {...props}
            >
                {isLoading && <Loader2 className="mr-2 h-5 w-5 animate-spin" />}
                {children}
            </button>
        );
    }
);

ThaiButton.displayName = "ThaiButton";
