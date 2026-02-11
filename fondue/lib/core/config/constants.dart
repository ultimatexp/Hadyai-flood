class AppConstants {
  static const String supabaseUrl = 'https://tympremgrvknekswiaar.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5bXByZW1ncnZrbmVrc3dpYWFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNDE2NDIsImV4cCI6MjA3OTYxNzY0Mn0.MfBsvQoPY5wjIOLqPrZ2Ycy37T0Ycfjcp90dyx3SM1k';
  static const String mapTilerKey = 'OqzbN9FxAPieSnpLNztS';
  // TODO: Use --dart-define=GOOGLE_GEMINI_KEY=... or .env file
  static const String googleGeminiKey = String.fromEnvironment('GOOGLE_GEMINI_KEY', defaultValue: '');
  // Production API URL
  // Production API URL (Use this for release)
  static const String apiBaseUrl = 'https://thaiflood2025.com'; 
  
  // Local API URL (Uncomment the one matching your device)
  // static const String apiBaseUrl = 'http://192.168.1.14:3000'; // LAN IP (Try this if 10.0.2.2 fails)
  // static const String apiBaseUrl = 'http://10.0.2.2:3000'; // Android Emulator
  // static const String apiBaseUrl = 'http://localhost:3000'; // iOS Simulator 
}
