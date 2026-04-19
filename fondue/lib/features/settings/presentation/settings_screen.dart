import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fondue/l10n/app_localizations.dart';
import 'package:fondue/l10n/app_localizations_context.dart';

import '../../../../core/theme/app_theme.dart';
import '../../moderation/presentation/blocked_users_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildSectionHeader(l10n.settingsSectionAccount),
          _buildListTile(
            icon: Icons.lock_outline,
            title: l10n.settingsChangePassword,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.settingsComingSoon)));
            },
          ),
          _buildListTile(
            icon: Icons.delete_outline,
            title: l10n.settingsDeleteAccount,
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: () {
              _showDeleteAccountDialog();
            },
          ),
          _buildListTile(
            icon: Icons.block,
            title: l10n.settingsBlockedUsers,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedUsersScreen()));
            },
          ),
          _buildSectionHeader(l10n.settingsSectionNotifications),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined, color: AppTheme.primaryGreen),
            title: Text(l10n.settingsPushNotifications),
            value: _notificationsEnabled,
            activeThumbColor: AppTheme.primaryGreen,
            activeTrackColor: AppTheme.primaryGreen.withValues(alpha: 0.35),
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          _buildSectionHeader(l10n.settingsSectionData),
          _buildListTile(
            icon: Icons.cleaning_services_outlined,
            title: l10n.settingsClearCache,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.settingsCacheCleared)));
            },
          ),
          _buildSectionHeader(l10n.settingsSectionAbout),
          _buildListTile(
            icon: Icons.info_outline,
            title: l10n.settingsVersion,
            trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey)),
            onTap: () {},
          ),
          _buildListTile(
            icon: Icons.description_outlined,
            title: l10n.settingsTermsOfService,
            onTap: () {
              // Open Terms URL
            },
          ),
          _buildListTile(
            icon: Icons.privacy_tip_outlined,
            title: l10n.settingsPrivacyPolicy,
            onTap: () {
              // Open Privacy Policy URL
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    Color? textColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppTheme.primaryGreen),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.black87,
          fontSize: 16,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showDeleteAccountDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(l10n.settingsDeleteDialogTitle),
          content: Text(l10n.settingsDeleteDialogBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.settingsCancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.settingsDeletionRequested)),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.settingsDelete),
            ),
          ],
        );
      },
    );
  }
}
