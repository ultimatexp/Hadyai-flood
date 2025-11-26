"use server";

import { supabase } from "@/lib/supabase";
// import { nanoid } from "nanoid"; // Not used

// Note: In a real app, we should verify the user is an admin/helper here.
// For now, we assume the caller has access to the admin page which should be protected.

export async function generateFamilyToken(caseId: string) {
    // 1. Check if token already exists
    const { data: existing } = await supabase
        .from("sos_cases")
        .select("family_token")
        .eq("id", caseId)
        .single();

    if (existing?.family_token) {
        return { success: true, token: existing.family_token };
    }

    // 2. Generate new token
    // Using a simple random string if nanoid isn't available, but let's try to use a simple custom function if needed
    // or just use crypto.randomUUID() for simplicity and uniqueness
    const token = crypto.randomUUID().replace(/-/g, "").substring(0, 12); // 12 chars hex

    // 3. Update database
    const { error } = await supabase
        .from("sos_cases")
        .update({ family_token: token })
        .eq("id", caseId);

    if (error) {
        console.error("Error generating family token:", error);
        return { success: false, error: error.message };
    }

    return { success: true, token };
}

export async function getFamilyCase(caseId: string, token: string) {
    const { data, error } = await supabase
        .from("sos_cases")
        .select(`
            *,
            case_events (*),
            rescuer:users!rescuer_id (
                user_id,
                name,
                phone_number,
                promptpay_number
            ),
            case_offers (
                id,
                amount
            )
        `)
        .eq("id", caseId)
        .eq("family_token", token)
        .single();

    if (error || !data) {
        console.error("getFamilyCase error:", error);
        return { success: false, error: error?.message || "Invalid token or case not found" };
    }

    return { success: true, data };
}

export async function logTip(caseId: string, volunteerId: string, amount: number) {
    const { error } = await supabase
        .from("tips")
        .insert({
            case_id: caseId,
            volunteer_id: volunteerId,
            amount: amount
        });

    if (error) {
        console.error("Error logging tip:", error);
        return { success: false, error: error.message };
    }

    return { success: true };
}

export async function enrollFamilyMember(userId: string, caseId: string, name: string, relationship: string, phone?: string) {
    // 1. Check if already enrolled
    const { data: existing } = await supabase
        .from("family_members")
        .select("id")
        .eq("user_id", userId)
        .eq("case_id", caseId)
        .single();

    if (existing) {
        return { success: true, message: "Already enrolled" };
    }

    // 2. Insert new record
    const { error } = await supabase
        .from("family_members")
        .insert({
            user_id: userId,
            case_id: caseId,
            name,
            relationship,
            phone
        });

    if (error) {
        console.error("Error enrolling family member:", error);
        return { success: false, error: error.message };
    }

    return { success: true };
}

export async function getEnrolledCases(userId: string) {
    const { data, error } = await supabase
        .from("family_members")
        .select(`
            case_id,
            sos_cases (
                id,
                reporter_name,
                status,
                urgency_level,
                created_at,
                family_token
            )
        `)
        .eq("user_id", userId)
        .order("created_at", { ascending: false });

    if (error) {
        return { success: false, error: error.message };
    }

    return { success: true, data: data.map((d: any) => d.sos_cases) };
}

export async function checkEnrollment(userId: string, caseId: string) {
    const { data, error } = await supabase
        .from("family_members")
        .select("id")
        .eq("user_id", userId)
        .eq("case_id", caseId)
        .single();

    if (error || !data) {
        return { success: false, enrolled: false };
    }

    return { success: true, enrolled: true };
}

export async function addOffer(caseId: string, amount: number, token: string) {
    // Verify family token
    const { data: caseData } = await supabase
        .from("sos_cases")
        .select("id")
        .eq("id", caseId)
        .eq("family_token", token)
        .single();

    if (!caseData) {
        return { success: false, error: "Invalid token" };
    }

    // Check if offer exists
    const { data: existingOffer } = await supabase
        .from("case_offers")
        .select("id")
        .eq("case_id", caseId)
        .single();

    if (existingOffer) {
        // Update existing offer
        const { error } = await supabase
            .from("case_offers")
            .update({ amount, updated_at: new Date().toISOString() })
            .eq("id", existingOffer.id);

        if (error) {
            return { success: false, error: error.message };
        }
    } else {
        // Create new offer
        const { error } = await supabase
            .from("case_offers")
            .insert({ case_id: caseId, amount });

        if (error) {
            return { success: false, error: error.message };
        }
    }

    return { success: true };
}

export async function getOffer(caseId: string) {
    const { data, error } = await supabase
        .from("case_offers")
        .select("*")
        .eq("case_id", caseId)
        .single();

    if (error) {
        return { success: false, offer: null };
    }

    return { success: true, offer: data };
}
