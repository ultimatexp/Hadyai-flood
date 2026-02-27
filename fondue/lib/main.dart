import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/constants.dart';
import 'core/theme/app_theme.dart';
import 'core/services/push_notification_service.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Initialize Firebase and Push Notifications
  await PushNotificationService().initialize();
  
  // Initialize LINE SDK
  await LineSDK.instance.setup("2009079720").catchError((e) {
    debugPrint("LineSDK Setup Error: $e");
  });

  runApp(const ProviderScope(child: FondueApp()));
}

class FondueApp extends StatelessWidget {
  const FondueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fondue',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const DashboardScreen(),
    );
  }
}
