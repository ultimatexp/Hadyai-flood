import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const String supabaseUrl = 'https://tympremgrvknekswiaar.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5bXByZW1ncnZrbmVrc3dpYWFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNDE2NDIsImV4cCI6MjA3OTYxNzY0Mn0.MfBsvQoPY5wjIOLqPrZ2Ycy37T0Ycfjcp90dyx3SM1k';
  static const String mapTilerKey = 'OqzbN9FxAPieSnpLNztS';

  static const String _geminiKeyGoogleGemini =
      String.fromEnvironment('GOOGLE_GEMINI_KEY', defaultValue: '');
  static const String _geminiKeyGenerativeAi =
      String.fromEnvironment('GOOGLE_GENERATIVE_AI_API_KEY', defaultValue: '');
  static const String _geminiKeyGeminiApi =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  /// Google AI (Gemini) key: compile-time `--dart-define` first, then `fondue/.env` (asset).
  ///
  /// Put `GOOGLE_GEMINI_KEY`, `GOOGLE_GENERATIVE_AI_API_KEY`, or `GEMINI_API_KEY` in
  /// `fondue/.env` (gitignored). CI/release can still inject via `--dart-define`.
  static String get googleGeminiKey {
    if (_geminiKeyGoogleGemini.isNotEmpty) return _geminiKeyGoogleGemini;
    if (_geminiKeyGenerativeAi.isNotEmpty) return _geminiKeyGenerativeAi;
    if (_geminiKeyGeminiApi.isNotEmpty) return _geminiKeyGeminiApi;
    if (dotenv.isInitialized) {
      String? nonEmpty(String key) {
        final v = dotenv.maybeGet(key);
        if (v == null) return null;
        final t = v.trim();
        return t.isEmpty ? null : t;
      }

      final fromFile = nonEmpty('GOOGLE_GEMINI_KEY') ??
          nonEmpty('GOOGLE_GENERATIVE_AI_API_KEY') ??
          nonEmpty('GEMINI_API_KEY');
      if (fromFile != null) return fromFile;
    }
    return '';
  }
  // Production API URL
  // Production API URL (Use this for release)
  static const String apiBaseUrl = 'https://thaiflood2025.com'; 
  
  // Local API URL (Uncomment the one matching your device)
  // static const String apiBaseUrl = 'http://192.168.1.14:3000'; // LAN IP (Try this if 10.0.2.2 fails)
  // static const String apiBaseUrl = 'http://10.0.2.2:3000'; // Android Emulator
  // static const String apiBaseUrl = 'http://localhost:3000'; // iOS Simulator 
}
