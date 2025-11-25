"use client";

import { MapContainer, TileLayer, ZoomControl } from "react-leaflet";
import "leaflet/dist/leaflet.css";
import "leaflet-defaulticon-compatibility/dist/leaflet-defaulticon-compatibility.css";
import "leaflet-defaulticon-compatibility";

export default function LandingMap() {
    // Default center (Hadyai)
    const defaultCenter: [number, number] = [7.00866, 100.47469];

    return (
        <MapContainer
            center={defaultCenter}
            zoom={13}
            scrollWheelZoom={false}
            className="h-full w-full absolute inset-0 z-0"
            zoomControl={false}
            dragging={false}
            doubleClickZoom={false}
        >
            <TileLayer
                attribution='&copy; <a href="https://www.maptiler.com/copyright/" target="_blank">&copy; MapTiler</a> <a href="https://www.openstreetmap.org/copyright" target="_blank">&copy; OpenStreetMap contributors</a>'
                url={`https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=${process.env.NEXT_PUBLIC_MAPTILER_KEY}`}
            />
            <ZoomControl position="bottomright" />
        </MapContainer>
    );
}
