import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/gemini_service.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});
