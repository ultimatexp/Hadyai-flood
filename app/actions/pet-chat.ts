"use server";

import { supabase } from "@/lib/supabase";

export async function addPetComment(petId: string, userId: string, message: string, role: 'owner' | 'finder', imageUrl?: string) {
    const { error } = await supabase
        .from("pet_comments")
        .insert({
            pet_id: petId,
            user_id: userId,
            message: message,
            sender_role: role,
            image_url: imageUrl
        });

    if (error) {
        console.error("Error adding pet comment:", error);
        return { success: false, error: error.message };
    }

    return { success: true };
}

export async function getPetComments(petId: string) {
    const { data, error } = await supabase
        .from("pet_comments")
        .select(`
            id,
            message,
            sender_role,
            created_at,
            user_id,
            image_url,
            users (
                name
            )
        `)
        .eq("pet_id", petId)
        .order("created_at", { ascending: true });

    if (error) {
        console.error("Error fetching pet comments:", error);
        return { success: false, error: error.message };
    }

    return { success: true, data };
}
