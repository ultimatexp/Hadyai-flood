"use server";

import { supabase } from "@/lib/supabase";

export async function syncUserRole(userId: string, role: 'volunteer' | 'member') {
    // 1. Check if user exists
    const { data: existing } = await supabase
        .from("users")
        .select("role")
        .eq("user_id", userId)
        .single();

    if (existing) {
        return { success: true, role: existing.role };
    }

    // 2. Insert new user with role
    const { error } = await supabase
        .from("users")
        .insert({
            user_id: userId,
            role: role
        });

    if (error) {
        console.error("Error syncing user role:", error);
        return { success: false, error: error.message };
    }

    return { success: true, role: role };
}

export async function getUserProfile(userId: string) {
    const { data, error } = await supabase
        .from("users")
        .select("*")
        .eq("user_id", userId)
        .single();

    if (error) {
        return { success: false, error: error.message };
    }

    return { success: true, data };
}

export async function updateUserProfile(userId: string, data: { name: string; promptpay_number?: string }) {
    const { error } = await supabase
        .from("users")
        .update(data)
        .eq("user_id", userId);

    if (error) {
        console.error("Error updating profile:", error);
        return { success: false, error: error.message };
    }

    return { success: true };
}
