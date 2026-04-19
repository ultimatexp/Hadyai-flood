import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fondue/core/locale/app_locale_preference.dart';
import 'package:fondue/core/theme/app_theme.dart';
import 'package:fondue/l10n/app_localizations_context.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mode = ref.watch(appLocaleModeProvider);

    Widget? check(AppLocaleMode m) =>
        mode == m ? const Icon(Icons.check, color: AppTheme.primaryGreen) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.languageTitle),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.languageOptionDevice),
            trailing: check(AppLocaleMode.system),
            onTap: () => ref.read(appLocaleModeProvider.notifier).setMode(AppLocaleMode.system),
          ),
          ListTile(
            title: Text(l10n.languageOptionThai),
            trailing: check(AppLocaleMode.thai),
            onTap: () => ref.read(appLocaleModeProvider.notifier).setMode(AppLocaleMode.thai),
          ),
          ListTile(
            title: Text(l10n.languageOptionEnglish),
            trailing: check(AppLocaleMode.english),
            onTap: () => ref.read(appLocaleModeProvider.notifier).setMode(AppLocaleMode.english),
          ),
        ],
      ),
    );
  }
}
