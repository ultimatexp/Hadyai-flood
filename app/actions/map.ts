"use server";

import { supabase } from "@/lib/supabase";

export async function getAllPetLocations() {
    try {
        const { data, error } = await supabase
            .from("pets")
            .select("id, lat, lng, status, image_url, pet_name, pet_type, breed, color, created_at")
            .not("lat", "is", null)
            .not("lng", "is", null);

        if (error) {
            console.error("Error fetching pet locations:", error);
            return { success: false, error: error.message };
        }

        return { success: true, data };
    } catch (error: any) {
        console.error("Unexpected error fetching pet locations:", error);
        return { success: false, error: error.message };
    }
}
