const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env.local' });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY
);

// Convert RGB to HSL for better color categorization
function rgbToHsl(r, g, b) {
    r /= 255;
    g /= 255;
    b /= 255;

    const max = Math.max(r, g, b);
    const min = Math.min(r, g, b);
    let h, s, l = (max + min) / 2;

    if (max === min) {
        h = s = 0;
    } else {
        const d = max - min;
        s = l > 0.5 ? d / (2 - max - min) : d / (max + min);

        switch (max) {
            case r: h = ((g - b) / d + (g < b ? 6 : 0)) / 6; break;
            case g: h = ((b - r) / d + 2) / 6; break;
            case b: h = ((r - g) / d + 4) / 6; break;
        }
    }

    return [h * 360, s * 100, l * 100];
}

// Determine color name from RGB
function getColorName(rgb) {
    const [r, g, b] = rgb;
    const [h, s, l] = rgbToHsl(r, g, b);

    // Black/White/Gray based on lightness and saturation
    if (l < 15) return 'black';
    if (l > 85 && s < 10) return 'white';
    if (s < 15) {
        if (l < 40) return 'dark gray';
        if (l < 70) return 'gray';
        return 'light gray';
    }

    // Colors based on hue
    if (h < 15 || h >= 345) return 'red';
    if (h < 45) return 'orange';
    if (h < 70) return 'yellow';
    if (h < 150) return 'green';
    if (h < 200) return 'cyan';
    if (h < 260) return 'blue';
    if (h < 330) return 'purple';
    return 'pink';
}

// Get dominant color from RGB array
function getDominantColorName(dominantColors, percentages) {
    if (!dominantColors || dominantColors.length === 0) return null;

    // Parse if string
    const colors = typeof dominantColors === 'string' ? JSON.parse(dominantColors) : dominantColors;
    const pcts = typeof percentages === 'string' ? JSON.parse(percentages) : percentages;

    // Get the most dominant color (first one = highest percentage)
    const primaryColor = getColorName(colors[0]);

    // Check for bicolor patterns
    if (colors.length > 1 && pcts[1] > 0.2) {
        const secondaryColor = getColorName(colors[1]);
        if (primaryColor !== secondaryColor) {
            return `${primaryColor} and ${secondaryColor}`;
        }
    }

    return primaryColor;
}

async function fixAllPetColors() {
    console.log('🎨 Starting color correction...\n');

    // Fetch all pets with color data
    const { data: pets, error } = await supabase
        .from('pets')
        .select('id, pet_name, color, color_main, dominant_colors, color_percentages')
        .not('dominant_colors', 'is', null);

    if (error) {
        console.error('Error fetching pets:', error);
        return;
    }

    console.log(`Found ${pets.length} pets with color data\n`);

    let updated = 0;
    let skipped = 0;

    for (const pet of pets) {
        const correctColor = getDominantColorName(pet.dominant_colors, pet.color_percentages);

        if (!correctColor) {
            skipped++;
            continue;
        }

        const currentColor = pet.color_main || pet.color;

        if (currentColor !== correctColor) {
            console.log(`📝 ${pet.pet_name}: "${currentColor}" → "${correctColor}"`);

            const { error: updateError } = await supabase
                .from('pets')
                .update({
                    color_main: correctColor,
                    color: correctColor
                })
                .eq('id', pet.id);

            if (updateError) {
                console.error(`  ❌ Failed to update: ${updateError.message}`);
            } else {
                updated++;
            }
        } else {
            skipped++;
        }
    }

    console.log(`\n✅ Complete!`);
    console.log(`  - Updated: ${updated} pets`);
    console.log(`  - Skipped: ${skipped} pets (already correct)`);
}

fixAllPetColors().catch(console.error);
