import 'dart:convert';
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
}
