import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../core/config/constants.dart';

class GeminiService {
  late final GenerativeModel _model;

  static bool get isConfigured => AppConstants.googleGeminiKey.isNotEmpty;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-001',
      apiKey: AppConstants.googleGeminiKey,
    );
  }

  static void _ensureGeminiApiKey() {
    if (!isConfigured) {
      throw StateError('Gemini API key is missing.');
    }
  }

  Future<Map<String, dynamic>> analyzePetImage(XFile imageFile) async {
    // Primary path: server-side analysis (no API key on device).
    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/api/analyze-pet');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final raw = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && raw['success'] == true && raw['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(raw['data'] as Map);
      }
      final code = raw['code']?.toString();
      if (code == 'AI_TEMPORARY_UNAVAILABLE' ||
          code == 'MISSING_SERVER_GEMINI_KEY' ||
          code == 'AI_RATE_LIMITED') {
        return <String, dynamic>{
          'analysis_unavailable': true,
          'reason': code,
          'server_error': raw['error']?.toString(),
        };
      }
      if (code != null && code.isNotEmpty) {
        return <String, dynamic>{
          'analysis_unavailable': true,
          'reason': code,
          'server_error': raw['error']?.toString(),
        };
      }
      final serverError = raw['error']?.toString();
      if (serverError != null && serverError.isNotEmpty) {
        throw Exception(serverError);
      }
      throw Exception('Server analysis failed (${response.statusCode})');
    } catch (serverError) {
      // Fallback: local Gemini only if key exists (developer/local scenarios).
      if (!isConfigured) {
        return <String, dynamic>{
          'analysis_unavailable': true,
          'reason': 'server_failed_and_no_device_key',
        };
      }
      _ensureGeminiApiKey();
      final imageBytes = await imageFile.readAsBytes();
      final prompt = Content.multi([
        TextPart('''
          Analyze this image, which might be a photo of a pet OR a screenshot of a social media post about a lost/found pet.
          Return ONE JSON object only. No markdown, no code fences.
          Fields: species(dog/cat), color_main, color_secondary, color_pattern, fur_length, sex(male/female/unknown), has_collar, collar_color, clothes, white_patch_location, heterochromia, pet_name, description, breed, location_text, contact_info, reward.
          If not pet-related return {"error":"Not a pet"}.
          If not clearly dog/cat return {"error":"Not a dog or cat"}.
        '''),
        DataPart('image/jpeg', imageBytes),
      ]);
      try {
        final response = await _model.generateContent([prompt]);
        final text = response.text;
        if (text == null) throw Exception('No response from AI');
        final jsonString = text.replaceAll(RegExp(r'```json\n|\n```'), '').trim();
        return json.decode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Failed to analyze image: $e (server fallback: $serverError)');
      }
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
    _ensureGeminiApiKey();
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
