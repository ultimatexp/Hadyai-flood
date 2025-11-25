"use client";

import dynamic from "next/dynamic";
import { Loader2 } from "lucide-react";

const HelperView = dynamic(() => import("./helper-view"), {
    ssr: false,
    loading: () => (
        <div className="h-screen w-full flex items-center justify-center">
            <Loader2 className="w-8 h-8 animate-spin text-muted-foreground" />
        </div>
    ),
});

export default HelperView;
