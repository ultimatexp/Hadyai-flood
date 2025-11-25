"use client";

import usePlacesAutocomplete, {
    getGeocode,
    getLatLng,
} from "use-places-autocomplete";
import { Input } from "@/components/ui/input";
import { Search } from "lucide-react";
import { useState } from "react";

interface LocationSearchProps {
    onSelect: (lat: number, lng: number) => void;
}

export const LocationSearch = ({ onSelect }: LocationSearchProps) => {
    const {
        ready,
        value,
        suggestions: { status, data },
        setValue,
        clearSuggestions,
    } = usePlacesAutocomplete({
        requestOptions: {
            // Define search scope here if needed
            componentRestrictions: { country: "th" },
        },
        debounce: 300,
    });

    const handleSelect = async (address: string) => {
        setValue(address, false);
        clearSuggestions();

        try {
            const results = await getGeocode({ address });
            const { lat, lng } = await getLatLng(results[0]);
            onSelect(lat, lng);
        } catch (error) {
            console.error("Error: ", error);
        }
    };

    return (
        <div className="relative w-full z-[2000]">
            <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                    value={value}
                    onChange={(e) => setValue(e.target.value)}
                    disabled={!ready}
                    className="pl-9 bg-white shadow-md border-0"
                    placeholder="ค้นหาสถานที่..."
                />
            </div>
            {status === "OK" && (
                <ul className="absolute top-full left-0 right-0 mt-1 bg-white rounded-md shadow-lg border border-border max-h-60 overflow-auto py-1">
                    {data.map(({ place_id, description }) => (
                        <li
                            key={place_id}
                            onClick={() => handleSelect(description)}
                            className="px-4 py-2 hover:bg-accent cursor-pointer text-sm truncate"
                        >
                            {description}
                        </li>
                    ))}
                </ul>
            )}
        </div>
    );
};
