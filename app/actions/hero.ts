"use server";

import { supabase } from "@/lib/supabase";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { revalidatePath } from "next/cache";

const apiKey = process.env.GOOGLE_GENERATIVE_AI_API_KEY || process.env.GEMINI_API_KEY;
const genAI = new GoogleGenerativeAI(apiKey || "");

export type Hero = {
    id: string;
    name: string;
    biography: string | null;
    image_url: string | null;
    rank?: string | null;
    social_link?: string | null;
    created_at?: string;
};

export async function getHeroes() {
    const { data, error } = await supabase
        .from("heroes")
        .select("*")
        .order("created_at", { ascending: false });

    if (error) {
        console.error("Error fetching heroes:", error);
        return [];
    }

    return data as Hero[];
}

export async function createHero(hero: Omit<Hero, "id" | "created_at">) {
    const { error } = await supabase.from("heroes").insert(hero);

    if (error) {
        console.error("Error creating hero:", error);
        return { success: false, error: error.message };
    }

    revalidatePath("/hall-of-heroes");
    return { success: true };
}

export async function updateHero(id: string, hero: Partial<Omit<Hero, "id" | "created_at">>) {
    const { error } = await supabase.from("heroes").update(hero).eq("id", id);

    if (error) {
        console.error("Error updating hero:", error);
        return { success: false, error: error.message };
    }

    revalidatePath("/hall-of-heroes");
    return { success: true };
}

export async function analyzeHeroSource(formData: FormData) {
    try {
        const file = formData.get("image") as File;
        const textContext = formData.get("text") as string;

        if (!apiKey) {
            return { success: false, error: "API Key missing" };
        }

        const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash-001" });

        let prompt = `
      Analyze the provided information (image of a social media post/news or text) about a Thai soldier or hero who sacrificed in the Cambodia war or similar conflicts.
      Extract information and return a JSON object.
      Required fields:
      - name: Full name of the hero (Thai)
      - rank: Rank if mentioned (e.g. "General", "Private") or null
      - biography: A summary of their heroism, sacrifice, and background (in Thai).
      - location: Location of the event if mentioned.
      - social_link: Any url mentioned?
      
      Do not include markdown. Just JSON.
    `;

        if (textContext) {
            prompt += `\nAdditional context text: ${textContext}`;
        }

        const parts: any[] = [prompt];

        if (file && file.size > 0) {
            const arrayBuffer = await file.arrayBuffer();
            const buffer = Buffer.from(arrayBuffer);
            const base64Image = buffer.toString("base64");
            parts.push({
                inlineData: {
                    data: base64Image,
                    mimeType: file.type || "image/jpeg",
                },
            });
        }

        const result = await model.generateContent(parts);
        const response = await result.response;
        const text = response.text();

        const jsonString = text.replace(/```json\n|\n```/g, "").trim();
        const data = JSON.parse(jsonString);

        return { success: true, data };
    } catch (error: any) {
        console.error("Error analyzing hero:", error);
        return { success: false, error: error.message };
    }
}
