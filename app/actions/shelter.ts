"use server";

import { supabase } from "@/lib/supabase";

export interface ShelterData {
    name: string;
    description: string;
    images: string[];
    needed_items: string;
    pet_count_dog: number;
    pet_count_cat: number;
    donation_address: string;
    lat: number;
    lng: number;
    contact_info: string;
    user_id: string;
}

export async function createShelter(data: ShelterData) {
    const { error } = await supabase
        .from("shelters")
        .insert(data);

    if (error) {
        console.error("Error creating shelter:", error);
        return { success: false, error: error.message };
    }

    return { success: true };
}

export async function getShelters() {
    const { data, error } = await supabase
        .from("shelters")
        .select("*")
        .order("created_at", { ascending: false });

    if (error) {
        console.error("Error fetching shelters:", error);
        return { success: false, error: error.message };
    }

    return { success: true, data };
}

export async function getShelter(id: string) {
    const { data, error } = await supabase
        .from("shelters")
        .select("*")
        .eq("id", id)
        .single();

    if (error) {
        console.error("Error fetching shelter:", error);
        return { success: false, error: error.message };
    }

    return { success: true, data };
}

export async function updateShelter(id: string, data: Partial<ShelterData>) {
    const { error } = await supabase
        .from("shelters")
        .update(data)
        .eq("id", id);

    if (error) {
        console.error("Error updating shelter:", error);
        return { success: false, error: error.message };
    }

    return { success: true };
}

export async function addShelterComment(shelterId: string, userId: string, content: string, imageUrl?: string) {
    const { error } = await supabase
        .from("shelter_comments")
        .insert({
            shelter_id: shelterId,
            user_id: userId,
            content: content,
            image_url: imageUrl
        });

    if (error) {
        console.error("Error adding comment:", error);
        return { success: false, error: error.message };
    }

    return { success: true };
}

export async function deleteShelterComment(commentId: string, userId: string) {
    const { error } = await supabase
        .from("shelter_comments")
        .delete()
        .eq("id", commentId)
        .eq("user_id", userId);

    if (error) {
        console.error("Error deleting comment:", error);
        return { success: false, error: error.message };
    }

    return { success: true };
}

export async function getShelterComments(shelterId: string) {
    const { data, error } = await supabase
        .from("shelter_comments")
        .select("*")
        .eq("shelter_id", shelterId)
        .order("created_at", { ascending: false });

    if (error) {
        console.error("Error fetching comments:", error);
        return { success: false, error: error.message };
    }

    return { success: true, data };
}

export async function toggleShelterLike(shelterId: string, userId: string) {
    // Check if already liked
    const { data: existing } = await supabase
        .from("shelter_likes")
        .select("*")
        .eq("shelter_id", shelterId)
        .eq("user_id", userId)
        .single();

    if (existing) {
        // Unlike
        const { error } = await supabase
            .from("shelter_likes")
            .delete()
            .eq("shelter_id", shelterId)
            .eq("user_id", userId);

        if (error) return { success: false, error: error.message };
        return { success: true, liked: false };
    } else {
        // Like
        const { error } = await supabase
            .from("shelter_likes")
            .insert({
                shelter_id: shelterId,
                user_id: userId
            });

        if (error) return { success: false, error: error.message };
        return { success: true, liked: true };
    }
}

export async function getShelterLikeStatus(shelterId: string, userId?: string) {
    const { count, error } = await supabase
        .from("shelter_likes")
        .select("*", { count: 'exact', head: true })
        .eq("shelter_id", shelterId);

    if (error) return { success: false, error: error.message };

    let liked = false;
    if (userId) {
        const { data } = await supabase
            .from("shelter_likes")
            .select("*")
            .eq("shelter_id", shelterId)
            .eq("user_id", userId)
            .single();
        liked = !!data;
    }

    return { success: true, count: count || 0, liked };
}
