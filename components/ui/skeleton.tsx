import { cn } from "@/lib/utils";

interface SkeletonProps {
    className?: string;
}

export function Skeleton({ className }: SkeletonProps) {
    return (
        <div
            className={cn(
                "animate-pulse rounded-lg bg-gray-200 dark:bg-gray-700",
                className
            )}
        />
    );
}

/* Preset skeleton layouts for common patterns */

export function SkeletonCard() {
    return (
        <div className="bg-white dark:bg-gray-900 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800 overflow-hidden">
            <Skeleton className="aspect-video w-full rounded-none" />
            <div className="p-4 space-y-3">
                <Skeleton className="h-5 w-3/4" />
                <Skeleton className="h-4 w-full" />
                <Skeleton className="h-4 w-1/2" />
                <div className="flex gap-3 pt-2">
                    <Skeleton className="h-8 w-16 rounded-full" />
                    <Skeleton className="h-8 w-16 rounded-full" />
                </div>
            </div>
        </div>
    );
}

export function SkeletonListItem() {
    return (
        <div className="bg-white dark:bg-gray-900 p-4 rounded-xl border border-gray-100 dark:border-gray-800 flex items-center gap-4">
            <Skeleton className="w-12 h-12 rounded-full flex-shrink-0" />
            <div className="flex-1 space-y-2">
                <Skeleton className="h-4 w-2/3" />
                <Skeleton className="h-3 w-1/3" />
            </div>
            <Skeleton className="h-8 w-20 rounded-lg" />
        </div>
    );
}

export function SkeletonHeroCard() {
    return (
        <div className="bg-zinc-900 rounded-2xl border border-amber-900/30 overflow-hidden">
            <Skeleton className="aspect-[3/4] w-full rounded-none bg-zinc-800" />
            <div className="p-4 space-y-2">
                <Skeleton className="h-5 w-2/3 bg-zinc-800" />
                <Skeleton className="h-3 w-1/2 bg-zinc-800" />
            </div>
        </div>
    );
}

export function SkeletonMap() {
    return (
        <div className="relative w-full h-[400px] bg-gray-100 dark:bg-gray-800 rounded-xl animate-pulse flex items-center justify-center">
            <div className="text-center space-y-2">
                <div className="w-12 h-12 bg-gray-200 dark:bg-gray-700 rounded-full mx-auto flex items-center justify-center">
                    <svg className="w-6 h-6 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                </div>
                <p className="text-sm text-gray-400">กำลังโหลดแผนที่...</p>
            </div>
        </div>
    );
}
