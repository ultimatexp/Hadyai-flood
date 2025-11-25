"use client";

import dynamic from "next/dynamic";

const LandingMap = dynamic(() => import("./landing-map"), {
    ssr: false,
    loading: () => <div className="absolute inset-0 bg-muted/20 z-0" />,
});

export default LandingMap;
