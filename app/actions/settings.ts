"use server";

import { createClient } from "@supabase/supabase-js";
import { revalidatePath } from "next/cache";

// Initialize Supabase client with Service Role Key for admin privileges
const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    {
        auth: {
            autoRefreshToken: false,
            persistSession: false
        }
    }
);

export async function getAppSettings(key: string) {
    const { data, error } = await supabase
        .from("app_settings")
        .select("value")
        .eq("key", key)
        .single();

    if (error) {
        if (error.code === 'PGRST116') {
            // Not found, return null
            return null;
        }
        console.error(`Error fetching setting ${key}:`, error);
        return null;
    }

    return data?.value;
}

export async function updateAppSetting(key: string, value: any) {
    const { error } = await supabase
        .from("app_settings")
        .upsert({
            key,
            value,
            updated_at: new Date().toISOString()
        });

    if (error) {
        console.error(`Error updating setting ${key}:`, error);
        throw new Error("Failed to update setting");
    }

    revalidatePath("/");
    revalidatePath("/admin/settings");
}
