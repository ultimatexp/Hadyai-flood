import React from "react";
import { LucideIcon } from "lucide-react";
import { ThaiButton } from "./thai-button";

interface EmptyStateProps {
    icon: LucideIcon;
    title: string;
    description?: string;
    actionLabel?: string;
    actionHref?: string;
    onAction?: () => void;
    variant?: "default" | "dark";
}

export function EmptyState({
    icon: Icon,
    title,
    description,
    actionLabel,
    actionHref,
    onAction,
    variant = "default",
}: EmptyStateProps) {
    const isDark = variant === "dark";

    return (
        <div className="flex flex-col items-center justify-center py-16 px-6 text-center">
            {/* Icon Circle */}
            <div className={`
                w-20 h-20 rounded-full flex items-center justify-center mb-5
                ${isDark
                    ? "bg-gray-800 border border-gray-700"
                    : "bg-gray-50 border border-gray-100 dark:bg-gray-800 dark:border-gray-700"
                }
            `}>
                <Icon className={`w-10 h-10 ${isDark ? "text-gray-500" : "text-gray-300 dark:text-gray-500"}`} />
            </div>

            {/* Title */}
            <h3 className={`text-lg font-bold mb-2 ${isDark ? "text-white" : "text-gray-900 dark:text-gray-100"}`}>
                {title}
            </h3>

            {/* Description */}
            {description && (
                <p className={`text-sm max-w-xs mb-6 leading-relaxed ${isDark ? "text-gray-400" : "text-gray-500 dark:text-gray-400"}`}>
                    {description}
                </p>
            )}

            {/* Action Button */}
            {actionLabel && (actionHref || onAction) && (
                actionHref ? (
                    <a href={actionHref}>
                        <ThaiButton size="sm">{actionLabel}</ThaiButton>
                    </a>
                ) : (
                    <ThaiButton size="sm" onClick={onAction}>{actionLabel}</ThaiButton>
                )
            )}
        </div>
    );
}
