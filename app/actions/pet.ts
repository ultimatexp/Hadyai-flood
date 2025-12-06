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

export async function getPetDetails(id: string) {
    try {
        const { data, error } = await supabase
            .from('pets')
            .select('*')
            .eq('id', id)
            .single();

        if (error) {
            console.error('Error fetching pet:', error);
            return { success: false, error: error.message };
        }

        return { success: true, data };
    } catch (error: any) {
        console.error('Unexpected error:', error);
        return { success: false, error: error.message };
    }
}

export async function updatePetStatus(id: string, status: string) {
    try {
        const { data, error } = await supabase
            .from('pets')
            .update({ status })
            .eq('id', id)
            .select()
            .single();

        if (error) {
            console.error('Error updating pet status:', error);
            return { success: false, error: error.message };
        }

        return { success: true, data };
    } catch (error: any) {
        console.error('Unexpected error:', error);
        return { success: false, error: error.message };
    }
}

export async function addPetImages(petId: string, newImageUrls: string[]) {
    try {
        // First get the current images
        const { data: pet, error: fetchError } = await supabase
            .from('pets')
            .select('images, image_url')
            .eq('id', petId)
            .single();

        if (fetchError) {
            console.error('Error fetching pet:', fetchError);
            return { success: false, error: fetchError.message };
        }

        // Merge existing images with new ones
        const existingImages = pet.images || [];
        const updatedImages = [...existingImages, ...newImageUrls];

        // Update the pet record
        const { data, error } = await supabase
            .from('pets')
            .update({ images: updatedImages })
            .eq('id', petId)
            .select()
            .single();

        if (error) {
            console.error('Error updating pet images:', error);
            return { success: false, error: error.message };
        }

        return { success: true, data };
    } catch (error: any) {
        console.error('Unexpected error:', error);
        return { success: false, error: error.message };
    }
}

export async function updatePetDetails(petId: string, updates: {
    pet_name?: string;
    breed?: string;
    color?: string;
    marks?: string;
    description?: string;
    sex?: string;
    contact_info?: string;
    reward?: string;
}) {
    try {
        const { data, error } = await supabase
            .from('pets')
            .update(updates)
            .eq('id', petId)
            .select()
            .single();

        if (error) {
            console.error('Error updating pet details:', error);
            return { success: false, error: error.message };
        }

        return { success: true, data };
    } catch (error: any) {
        console.error('Unexpected error:', error);
        return { success: false, error: error.message };
    }
}
