"use client";

import { MapContainer, TileLayer, Marker, Popup, ZoomControl, useMap } from "react-leaflet";
import "leaflet/dist/leaflet.css";
import L from "leaflet";
import { useEffect, useState } from "react";
import Link from "next/link";
import { ArrowRight, MapPin, Loader2 } from "lucide-react";

// Fix Leaflet icon issue
const iconPerson = new L.Icon({
    iconUrl: "https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-red.png",
    shadowUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png",
    iconSize: [25, 41],
    iconAnchor: [12, 41],
    popupAnchor: [1, -34],
    shadowSize: [41, 41]
});

const iconFound = new L.Icon({
    iconUrl: "https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-gold.png",
    shadowUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png",
    iconSize: [25, 41],
    iconAnchor: [12, 41],
    popupAnchor: [1, -34],
    shadowSize: [41, 41]
});

const iconShelter = new L.Icon({
    iconUrl: "https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-blue.png",
    shadowUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png",
    iconSize: [25, 41],
    iconAnchor: [12, 41],
    popupAnchor: [1, -34],
    shadowSize: [41, 41]
});

// Component to handle map movement
function MapController({ center }: { center: [number, number] }) {
    const map = useMap();
    useEffect(() => {
        map.flyTo(center, map.getZoom());
    }, [center, map]);
    return null;
}

export default function PetMap({ pets, shelters = [] }: { pets: any[], shelters?: any[] }) {
    // Default center (Hat Yai)
    const [center, setCenter] = useState<[number, number]>([7.00866, 100.47469]);
    const [loadingLocation, setLoadingLocation] = useState(false);

    // Try to get user location for initial center
    useEffect(() => {
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    setCenter([position.coords.latitude, position.coords.longitude]);
                },
                () => {
                    console.log("Could not get location, using default");
                }
            );
        }
    }, []);

    const handleGetCurrentLocation = () => {
        setLoadingLocation(true);
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    setCenter([position.coords.latitude, position.coords.longitude]);
                    setLoadingLocation(false);
                },
                (error) => {
                    console.error("Error getting location:", error);
                    setLoadingLocation(false);
                    alert("ไม่สามารถระบุตำแหน่งได้ กรุณาเปิด GPS");
                }
            );
        } else {
            alert("Browser ไม่รองรับ Geolocation");
            setLoadingLocation(false);
        }
    };

    return (
        <div className="relative w-full h-full">
            <MapContainer
                center={center}
                zoom={13}
                style={{ height: "100%", width: "100%" }}
                zoomControl={false}
            >
                <TileLayer
                    attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                    url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                />
                <ZoomControl position="bottomright" />
                <MapController center={center} />

                {/* Pet Markers */}
                {pets.map((pet) => (
                    <Marker
                        key={`pet-${pet.id}`}
                        position={[pet.lat, pet.lng]}
                        icon={pet.status === 'LOST' ? iconPerson : iconFound}
                    >
                        <Popup className="custom-popup">
                            <div className="w-64 p-1">
                                <div className="relative h-32 w-full rounded-lg overflow-hidden mb-3 bg-gray-100">
                                    <img
                                        src={pet.image_url}
                                        alt={pet.pet_name}
                                        className="w-full h-full object-cover"
                                    />
                                    <div className={`absolute top-2 right-2 px-2 py-1 rounded-md text-xs font-bold ${pet.status === 'LOST' ? 'bg-red-500 text-white' : 'bg-yellow-400 text-black'
                                        }`}>
                                        {pet.status === 'LOST' ? 'หาย' : 'พบเบาะแส'}
                                    </div>
                                </div>
                                <h3 className="font-bold text-lg text-gray-900 mb-1">
                                    {pet.pet_name || 'ไม่ทราบชื่อ'}
                                </h3>
                                <p className="text-sm text-gray-500 mb-3">
                                    {pet.breed} • {pet.color}
                                </p>
                                <Link href={`/pets/status/${pet.id}`}>
                                    <button className="w-full bg-gray-900 text-white py-2 rounded-lg text-sm font-bold flex items-center justify-center gap-2 hover:bg-gray-800 transition-colors">
                                        ดูรายละเอียด
                                        <ArrowRight className="w-4 h-4" />
                                    </button>
                                </Link>
                            </div>
                        </Popup>
                    </Marker>
                ))}

                {/* Shelter Markers */}
                {shelters.map((shelter) => (
                    <Marker
                        key={`shelter-${shelter.id}`}
                        position={[shelter.lat, shelter.lng]}
                        icon={iconShelter}
                    >
                        <Popup className="custom-popup">
                            <div className="w-64 p-1">
                                <div className="relative h-32 w-full rounded-lg overflow-hidden mb-3 bg-gray-100">
                                    {shelter.images && shelter.images[0] ? (
                                        <img
                                            src={shelter.images[0]}
                                            alt={shelter.name}
                                            className="w-full h-full object-cover"
                                        />
                                    ) : (
                                        <div className="w-full h-full flex items-center justify-center bg-gray-200">
                                            <MapPin className="w-8 h-8 text-gray-400" />
                                        </div>
                                    )}
                                    <div className="absolute top-2 right-2 px-2 py-1 rounded-md text-xs font-bold bg-blue-500 text-white">
                                        ศูนย์พักพิง
                                    </div>
                                </div>
                                <h3 className="font-bold text-lg text-gray-900 mb-1">
                                    {shelter.name}
                                </h3>
                                <p className="text-sm text-gray-500 mb-3 line-clamp-2">
                                    {shelter.description}
                                </p>
                                <Link href={`/shelters/${shelter.id}`}>
                                    <button className="w-full bg-blue-600 text-white py-2 rounded-lg text-sm font-bold flex items-center justify-center gap-2 hover:bg-blue-700 transition-colors">
                                        ดูข้อมูลศูนย์
                                        <ArrowRight className="w-4 h-4" />
                                    </button>
                                </Link>
                            </div>
                        </Popup>
                    </Marker>
                ))}
            </MapContainer>

            {/* Current Location FAB */}
            <button
                type="button"
                onClick={handleGetCurrentLocation}
                disabled={loadingLocation}
                className="absolute bottom-24 right-4 z-[1000] bg-white p-3 rounded-full shadow-md hover:shadow-lg transition-all border border-gray-200 text-gray-700 hover:text-blue-600 disabled:opacity-50"
                title="ตำแหน่งปัจจุบัน"
            >
                {loadingLocation ? (
                    <Loader2 className="w-6 h-6 animate-spin" />
                ) : (
                    <MapPin className="w-6 h-6" />
                )}
            </button>
        </div>
    );
}
