"use server";

import { supabase } from "@/lib/supabase";

export async function getCaseByPhone(phone: string) {
    // Normalize phone number (remove dashes, spaces)
    const cleanPhone = phone.replace(/[-\s]/g, "");

    const { data, error } = await supabase
        .from("sos_cases")
        .select("id, status, created_at, lat, lng, address_text, urgency_level")
        .contains("contacts", [cleanPhone])
        .neq("status", "CLOSED") // Only show active cases
        .order("created_at", { ascending: false });

    if (error) {
        return { error: error.message };
    }

    return { data };
}
