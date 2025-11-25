"use client";

import dynamic from "next/dynamic";
import { Loader2 } from "lucide-react";

const MapPicker = dynamic(() => import("./map-picker"), {
    ssr: false,
    loading: () => (
        <div className="h-[400px] w-full rounded-xl border-2 border-border flex items-center justify-center bg-muted">
            <Loader2 className="w-8 h-8 animate-spin text-muted-foreground" />
            <span className="ml-2 text-muted-foreground">กำลังโหลดแผนที่...</span>
        </div>
    ),
});

export default MapPicker;
