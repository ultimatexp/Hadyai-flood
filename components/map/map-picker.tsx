"use client";

import { useEffect, useState } from "react";
import { MapContainer, TileLayer, Marker, useMapEvents, useMap } from "react-leaflet";
import "leaflet/dist/leaflet.css";
import "leaflet-defaulticon-compatibility/dist/leaflet-defaulticon-compatibility.css";
import "leaflet-defaulticon-compatibility";
import { Loader2, MapPin } from "lucide-react";
import { ThaiButton } from "../ui/thai-button";

interface MapPickerProps {
    lat?: number;
    lng?: number;
    onLocationSelect: (lat: number, lng: number) => void;
}

function LocationMarker({ lat, lng, onSelect }: { lat?: number; lng?: number; onSelect: (lat: number, lng: number) => void }) {
    const map = useMap();

    useMapEvents({
        click(e) {
            onSelect(e.latlng.lat, e.latlng.lng);
        },
    });

    useEffect(() => {
        if (lat && lng) {
            map.flyTo([lat, lng], map.getZoom());
        }
    }, [lat, lng, map]);

    return lat && lng ? <Marker position={[lat, lng]} /> : null;
}

import { useLoadScript } from "@react-google-maps/api";
import { LocationSearch } from "./location-search";

// ... imports

const libraries: ("places")[] = ["places"];

export default function MapPicker({ lat, lng, onLocationSelect }: MapPickerProps) {
    const [loading, setLoading] = useState(false);
    const [isMounted, setIsMounted] = useState(false);

    const { isLoaded } = useLoadScript({
        googleMapsApiKey: process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY || "",
        libraries,
    });

    // Ensure component only renders on client side
    useEffect(() => {
        setIsMounted(true);
    }, []);

    const handleGetCurrentLocation = () => {
        setLoading(true);
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    onLocationSelect(position.coords.latitude, position.coords.longitude);
                    setLoading(false);
                },
                (error) => {
                    console.error("Error getting location:", error);
                    setLoading(false);
                    alert("ไม่สามารถระบุตำแหน่งได้ กรุณาเปิด GPS หรือปักหมุดเอง");
                }
            );
        } else {
            alert("Browser ไม่รองรับ Geolocation");
            setLoading(false);
        }
    };

    // Default center (Hadyai)
    const defaultCenter: [number, number] = [7.00866, 100.47469];

    // Don't render map until mounted on client
    if (!isMounted) {
        return (
            <div className="h-[400px] w-full bg-gray-100 animate-pulse rounded-xl flex items-center justify-center text-gray-400">
                กำลังโหลดแผนที่...
            </div>
        );
    }

    return (
        <div className="space-y-4">
            <div className="relative h-[400px] w-full rounded-xl overflow-hidden border-2 border-border shadow-sm z-0">
                {/* Search Bar Overlay */}
                {isLoaded && (
                    <div className="absolute top-4 left-4 right-4 z-[1000]">
                        <LocationSearch onSelect={onLocationSelect} />
                    </div>
                )}

                <MapContainer center={lat && lng ? [lat, lng] : defaultCenter} zoom={13} scrollWheelZoom={true} className="h-full w-full">
                    <TileLayer
                        attribution='&copy; <a href="https://www.maptiler.com/copyright/" target="_blank">&copy; MapTiler</a> <a href="https://www.openstreetmap.org/copyright" target="_blank">&copy; OpenStreetMap contributors</a>'
                        url={`https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=${process.env.NEXT_PUBLIC_MAPTILER_KEY}`}
                    />
                    <LocationMarker lat={lat} lng={lng} onSelect={onLocationSelect} />
                </MapContainer>

                {/* Center Marker Overlay (Visual Guide) */}
                {!lat && (
                    <div className="absolute inset-0 pointer-events-none flex items-center justify-center z-[1000]">
                        <MapPin className="w-10 h-10 text-primary -mt-10 animate-bounce" />
                    </div>
                )}
            </div>

            <ThaiButton
                type="button"
                variant="outline"
                onClick={handleGetCurrentLocation}
                isLoading={loading}
                className="w-full"
            >
                <MapPin className="mr-2 w-5 h-5" />
                ใช้ตำแหน่งปัจจุบัน
            </ThaiButton>
        </div>
    );
}
