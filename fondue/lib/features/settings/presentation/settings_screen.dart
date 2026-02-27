import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../auth/presentation/login_screen.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Account & Security'),
          _buildListTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comming Soon')));
            },
          ),
          _buildListTile(
            icon: Icons.delete_outline,
            title: 'Delete Account',
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: () {
               _showDeleteAccountDialog();
            },
          ),
          _buildListTile(
            icon: Icons.block,
            title: 'Blocked Users',
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedUsersScreen()));
            },
          ),
          
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined, color: AppTheme.primaryGreen),
            title: const Text('Push Notifications'),
            value: _notificationsEnabled,
            activeColor: AppTheme.primaryGreen,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),

           _buildSectionHeader('Data Management'),
          _buildListTile(
            icon: Icons.cleaning_services_outlined,
            title: 'Clear App Cache',
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache Cleared')));
            },
          ),

          _buildSectionHeader('About'),
           _buildListTile(
            icon: Icons.info_outline,
            title: 'Version',
            trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey)),
            onTap: () {},
          ),
           _buildListTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () {
               // Open Terms URL
            },
          ),
           _buildListTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
               // Call delete account logic
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deletion requested')));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
