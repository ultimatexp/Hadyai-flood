import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLocaleMode { system, thai, english }

const _prefsKey = 'fondue_locale_mode';

AppLocaleMode? _bootstrappedMode;

Future<void> bootstrapAppLocaleMode() async {
  final prefs = await SharedPreferences.getInstance();
  _bootstrappedMode = _decode(prefs.getString(_prefsKey));
}

String _encode(AppLocaleMode mode) => switch (mode) {
      AppLocaleMode.system => 'system',
      AppLocaleMode.thai => 'th',
      AppLocaleMode.english => 'en',
    };

AppLocaleMode _decode(String? raw) => switch (raw) {
      'th' => AppLocaleMode.thai,
      'en' => AppLocaleMode.english,
      _ => AppLocaleMode.system,
    };

final appLocaleModeProvider = NotifierProvider<AppLocaleModeNotifier, AppLocaleMode>(AppLocaleModeNotifier.new);

class AppLocaleModeNotifier extends Notifier<AppLocaleMode> {
  @override
  AppLocaleMode build() => _bootstrappedMode ?? AppLocaleMode.system;

  Future<void> setMode(AppLocaleMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _encode(mode));
    state = mode;
  }
}
