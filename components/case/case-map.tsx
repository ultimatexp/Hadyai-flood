"use client";

import { MapContainer, TileLayer, Marker } from "react-leaflet";
import "leaflet/dist/leaflet.css";
import "leaflet-defaulticon-compatibility/dist/leaflet-defaulticon-compatibility.css";
import "leaflet-defaulticon-compatibility";
import { Navigation } from "lucide-react";
import { ThaiButton } from "@/components/ui/thai-button";

interface CaseMapProps {
    lat: number;
    lng: number;
}

export default function CaseMap({ lat, lng }: CaseMapProps) {
    const openGoogleMaps = () => {
        window.open(`https://www.google.com/maps/search/?api=1&query=${lat},${lng}`, "_blank");
    };

    return (
        <div className="relative h-full w-full">
            <MapContainer
                center={[lat, lng]}
                zoom={15}
                scrollWheelZoom={false}
                className="h-full w-full z-0"
            >
                <TileLayer
                    attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                    url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                />
                <Marker position={[lat, lng]}></Marker>
            </MapContainer>
            <ThaiButton
                className="absolute bottom-4 right-4 z-[400] bg-blue-600 hover:bg-blue-700 text-white shadow-lg"
                onClick={openGoogleMaps}
            >
                <Navigation className="mr-2 h-4 w-4" /> นำทาง
            </ThaiButton>
        </div>
    );
}
