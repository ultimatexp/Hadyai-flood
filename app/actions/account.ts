"use server";

import { createClient } from "@supabase/supabase-js";

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

export async function getUserPets(userId: string) {
    // Get pets owned by user
    const { data: ownedPets, error: ownedError } = await supabase
        .from("pets")
        .select("*, is_owner:user_id")
        .eq("user_id", userId)
        .order("created_at", { ascending: false });

    if (ownedError) {
        console.error("Error fetching owned pets:", ownedError);
        return { success: false, error: ownedError.message };
    }

    // Get monitored pets
    const { data: monitoredPets, error: monitoredError } = await supabase
        .from("pet_monitors")
        .select("pet_id, pets(*)")
        .eq("user_id", userId);

    if (monitoredError) {
        console.error("Error fetching monitored pets:", monitoredError);
        return { success: false, error: monitoredError.message };
    }

    // Combine and mark ownership
    const ownedWithFlag = (ownedPets || []).map(p => ({ ...p, is_monitored: false, is_owner: true }));
    const monitoredWithFlag = (monitoredPets || [])
        .filter((m: any) => m.pets && !ownedPets?.some((o: any) => o.id === m.pets.id))
        .map((m: any) => ({ ...m.pets, is_monitored: true, is_owner: false }));

    return { success: true, data: [...ownedWithFlag, ...monitoredWithFlag] };
}

export async function monitorPet(userId: string, petId: string) {
    const { error } = await supabase
        .from("pet_monitors")
        .insert({ user_id: userId, pet_id: petId });

    if (error) {
        if (error.code === '23505') { // Unique constraint violation
            return { success: true, message: 'Already monitoring' };
        }
        console.error("Error monitoring pet:", error);
        return { success: false, error: error.message };
    }

    return { success: true };
}

export async function unmonitorPet(userId: string, petId: string) {
    const { error } = await supabase
        .from("pet_monitors")
        .delete()
        .eq("user_id", userId)
        .eq("pet_id", petId);

    if (error) {
        console.error("Error unmonitoring pet:", error);
        return { success: false, error: error.message };
    }

    return { success: true };
}

export async function isMonitoringPet(userId: string, petId: string) {
    const { data, error } = await supabase
        .from("pet_monitors")
        .select("id")
        .eq("user_id", userId)
        .eq("pet_id", petId)
        .single();

    if (error && error.code !== 'PGRST116') { // PGRST116 = not found
        console.error("Error checking monitoring status:", error);
        return { success: false, error: error.message };
    }

    return { success: true, isMonitoring: !!data };
}

export async function getUserNotifications(userId: string) {
    const { data, error } = await supabase
        .from("notifications")
        .select("*")
        .eq("user_id", userId)
        .order("created_at", { ascending: false });

    if (error) {
        console.error("Error fetching notifications:", error);
        return { success: false, error: error.message };
    }

    return { success: true, data };
}

export async function markNotificationRead(id: string) {
    const { error } = await supabase
        .from("notifications")
        .update({ is_read: true })
        .eq("id", id);

    if (error) {
        return { success: false, error: error.message };
    }

    return { success: true };
}

export async function getUserChats(userId: string) {
    try {
        // 1. Get Family Cases (already implemented in family.ts, but we can fetch here for aggregation)
        const { data: familyCases, error: familyError } = await supabase
            .from("family_members")
            .select(`
                case_id,
                sos_cases (
                    id,
                    reporter_name,
                    status,
                    created_at
                )
            `)
            .eq("user_id", userId);

        if (familyError) throw familyError;

        // 2. Get Pet Chats
        // A. Pets owned by user that have comments
        const { data: ownedPets, error: ownedError } = await supabase
            .from("pets")
            .select("id, pet_name, image_url")
            .eq("user_id", userId);

        if (ownedError) throw ownedError;

        // B. Pets where user commented (as finder)
        const { data: commentedPets, error: commentedError } = await supabase
            .from("pet_comments")
            .select("pet_id, pets(id, pet_name, image_url)")
            .eq("user_id", userId);

        if (commentedError) throw commentedError;

        // Combine and format
        interface ChatItem {
            id: string;
            type: string;
            title: string;
            subtitle: string;
            link: string;
            image: string | null;
            updated_at: string;
        }
        const chats: ChatItem[] = [];

        // Add Family Chats
        if (familyCases) {
            familyCases.forEach((item: any) => {
                if (item.sos_cases) {
                    chats.push({
                        id: item.sos_cases.id,
                        type: 'family',
                        title: `เคส: ${item.sos_cases.reporter_name}`,
                        subtitle: `สถานะ: ${item.sos_cases.status}`,
                        link: `/case/${item.sos_cases.id}/family`, // We need to handle token logic, but for now link to generic
                        image: null,
                        updated_at: item.sos_cases.created_at // Ideally last message time
                    });
                }
            });
        }

        // Add Pet Chats (Owner)
        if (ownedPets) {
            ownedPets.forEach((pet: any) => {
                chats.push({
                    id: pet.id,
                    type: 'pet_owner',
                    title: `สัตว์เลี้ยงของคุณ: ${pet.pet_name}`,
                    subtitle: 'คลิกเพื่อดูแชท',
                    link: `/pets/status/${pet.id}`,
                    image: pet.image_url,
                    updated_at: new Date().toISOString() // Placeholder
                });
            });
        }

        // Add Pet Chats (Finder)
        if (commentedPets) {
            const addedIds = new Set(ownedPets?.map(p => p.id));
            commentedPets.forEach((item: any) => {
                if (item.pets && !addedIds.has(item.pets.id)) {
                    chats.push({
                        id: item.pets.id,
                        type: 'pet_finder',
                        title: `แจ้งเบาะแส: ${item.pets.pet_name}`,
                        subtitle: 'คลิกเพื่อดูแชท',
                        link: `/pets/status/${item.pets.id}`,
                        image: item.pets.image_url,
                        updated_at: new Date().toISOString() // Placeholder
                    });
                    addedIds.add(item.pets.id);
                }
            });
        }

        return { success: true, data: chats };

    } catch (error: any) {
        console.error("Error fetching user chats:", error);
        return { success: false, error: error.message };
    }
}
