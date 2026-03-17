import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/constants.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-001',
      apiKey: AppConstants.googleGeminiKey,
    );
  }

  Future<Map<String, dynamic>> analyzePetImage(XFile imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    
    final prompt = Content.multi([
      TextPart('''
        Analyze this image, which might be a photo of a pet OR a screenshot of a social media post about a lost/found pet.
        Extract relevant information and return a JSON object.
        Do not include markdown formatting (like ```json), just the raw JSON.
        
        Required fields:
        - species: "Cat", "Dog", "Bird" or "Other" (Capitalized)
        - pet_name: Name of the pet if mentioned (or null)
        - color: Description of color/pattern
        - description: A summary of visual details AND text content (e.g. "Lost at Central Park, wearing red collar. Reward 5000 baht.")
        - breed: Breed if visually obvious or mentioned (optional)
        - sex: "Male", "Female", or "Unknown"
        - location_text: Specific location mentioned in text (or null)
        - contact_info: Phone number, Line ID, or Facebook name mentioned in text (or null)
        - reward: Reward amount if mentioned (or null)
        
        If it's not a pet related image, return { "error": "Not a pet" }
      '''),
      DataPart('image/jpeg', imageBytes),
    ]);

    try {
      final response = await _model.generateContent([prompt]);
      final text = response.text;
      
      if (text == null) throw Exception('No response from AI');

      // Clean markdown if present
      final jsonString = text.replaceAll(RegExp(r'```json\n|\n```'), '').trim();
      
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Gemini Analysis Error: $e');
      throw Exception('Failed to analyze image: $e');
    }
  }

  /// Analyze a pet food label image against a pet's profile
  Future<Map<String, dynamic>> analyzePetFood({
    required Uint8List imageBytes,
    required String species,
    String? breed,
    String? ageText,
    double? weightKg,
    List<String> allergies = const [],
    List<String> conditions = const [],
    List<Map<String, dynamic>> toxicIngredients = const [],
  }) async {
    // Build the toxic ingredients context
    final toxicList = toxicIngredients
        .map((t) => '- ${t['ingredient']} (${t['severity']}): ${t['notes']}')
        .join('\n');

    final prompt = Content.multi([
      TextPart('''
You are a veterinary nutrition expert AI. Analyze this pet food label/packaging image.

PET PROFILE:
- Species: $species
- Breed: ${breed ?? 'Unknown'}
- Age: ${ageText ?? 'Unknown'}
- Weight: ${weightKg != null ? '${weightKg}kg' : 'Unknown'}
- Known Allergies: ${allergies.isNotEmpty ? allergies.join(', ') : 'None'}
- Health Conditions: ${conditions.isNotEmpty ? conditions.join(', ') : 'None'}

KNOWN TOXIC INGREDIENTS FOR $species:
$toxicList

INSTRUCTIONS:
1. OCR the ingredient list and nutritional info from the image
2. Check if this food is appropriate for the species (e.g., don't feed dog food to cats)
3. Check ingredients against the pet's known allergies
4. Check ingredients against the toxic ingredients list
5. Evaluate nutritional adequacy for the pet's age/weight/breed
6. Provide an overall verdict

Return ONLY a JSON object (no markdown, no backticks):
{
  "product_name": "Brand Name - Product Line" or null if unclear,
  "target_species": "Dog" or "Cat" etc. (what species the food is designed for),
  "ingredients": ["ingredient1", "ingredient2", ...],
  "guaranteed_analysis": {"protein": "27%", "fat": "15%", "fiber": "5%", "moisture": "10%"},
  "verdict": "SUITABLE" or "CAUTION" or "NOT_RECOMMENDED",
  "score": 1-10 (ingredient quality score),
  "warnings": ["Warning message 1", "Warning message 2", ...],
  "analysis_text": "Detailed analysis paragraph explaining the verdict, nutritional assessment, and recommendations."
}

VERDICT RULES:
- "NOT_RECOMMENDED": If ANY toxic ingredient is found, OR food is for wrong species, OR contains a known allergen
- "CAUTION": If nutritional balance is questionable, or some mild concerns exist
- "SUITABLE": If food is appropriate, safe, and nutritionally adequate

If the image is NOT a pet food label, return: {"error": "Not a pet food label"}
      '''),
      DataPart('image/jpeg', imageBytes),
    ]);

    try {
      final response = await _model.generateContent([prompt]);
      final text = response.text;

      if (text == null) throw Exception('No response from AI');

      final jsonString = text
          .replaceAll(RegExp(r'```json\n?'), '')
          .replaceAll(RegExp(r'\n?```'), '')
          .trim();

      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Gemini Food Analysis Error: $e');
      throw Exception('Failed to analyze pet food: $e');
    }
  }
}
