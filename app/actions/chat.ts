"use server";

import { supabase } from "@/lib/supabase";

export async function addComment(caseId: string, userId: string, message: string, role: 'volunteer' | 'member', imageUrl?: string) {
    const { error } = await supabase
        .from("case_comments")
        .insert({
            case_id: caseId,
            user_id: userId,
            message: message,
            sender_role: role,
            image_url: imageUrl
        });

    if (error) {
        console.error("Error adding comment:", error);
        return { success: false, error: error.message };
    }

    return { success: true };
}

export async function getComments(caseId: string) {
    const { data, error } = await supabase
        .from("case_comments")
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
        .eq("case_id", caseId)
        .order("created_at", { ascending: true });

    if (error) {
        console.error("Error fetching comments:", error);
        return { success: false, error: error.message };
    }

    return { success: true, data };
}
