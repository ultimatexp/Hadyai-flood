import 'dart:async';
import 'dart:io' show File;

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fondue/l10n/app_localizations.dart';
import 'core/config/constants.dart';
import 'core/locale/app_locale_preference.dart';
import 'core/locale/app_locale_resolution.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/push_chat_navigation.dart';
import 'core/services/push_notification_service.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

/// Loads bundled [assets/google_ai.env], then merges optional `fondue/.env` when
/// present on the host (e.g. `flutter run` from `fondue/` or repo root on desktop).
Future<void> _loadGeminiDotEnv() async {
  await dotenv.load(fileName: 'assets/google_ai.env', isOptional: true);
  if (kIsWeb) return;
  try {
    final candidates = [File('.env'), File('fondue/.env')];
    String? contents;
    for (final f in candidates) {
      if (await f.exists()) {
        contents = await f.readAsString();
        break;
      }
    }
    if (contents == null || contents.trim().isEmpty) return;
    final previous = Map<String, String>.from(dotenv.env);
    dotenv.loadFromString(envString: contents, mergeWith: previous);
  } catch (e, st) {
    debugPrint('Optional .env merge skipped: $e\n$st');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadGeminiDotEnv();
  await bootstrapAppLocaleMode();
  await Firebase.initializeApp();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    switch (data.event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.initialSession:
        unawaited(PushNotificationService().syncTokenToProfile());
        break;
      default:
        break;
    }
  });

  // Initialize Firebase and Push Notifications
  await PushNotificationService().initialize();
  
  // Initialize LINE SDK
  await LineSDK.instance.setup("2009079720").catchError((e) {
    debugPrint("LineSDK Setup Error: $e");
  });

  runApp(const ProviderScope(child: FondueApp()));
}

class FondueApp extends ConsumerStatefulWidget {
  const FondueApp({super.key});

  @override
  ConsumerState<FondueApp> createState() => _FondueAppState();
}

class _FondueAppState extends ConsumerState<FondueApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(PushNotificationService().consumeInitialNotificationIfAny());
    });
  }

  @override
  Widget build(BuildContext context) {
    final localeMode = ref.watch(appLocaleModeProvider);
    final explicitLocale = switch (localeMode) {
      AppLocaleMode.system => null,
      AppLocaleMode.thai => const Locale('th'),
      AppLocaleMode.english => const Locale('en'),
    };

    return MaterialApp(
      title: 'Fondue',
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      navigatorKey: fondueNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      locale: explicitLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: fondueLocaleListResolution,
      localeResolutionCallback: fondueLocaleResolution,
      home: const DashboardScreen(),
    );
  }
}
