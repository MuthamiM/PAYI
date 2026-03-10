import 'package:flutter/material.dart';
import '../theme/colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('General'),
          _buildSettingsToggle('Dark Mode', true),
          _buildSettingsItem(
            Icons.notifications,
            'Notifications',
            'Push, Email, SMS',
          ),
          _buildSettingsItem(Icons.language, 'Language', 'English'),

          _buildSectionHeader('Account'),
          _buildSettingsItem(Icons.lock, 'Privacy', 'Manage visibility'),
          _buildSettingsItem(Icons.receipt, 'Billing', 'Payment methods'),

          _buildSectionHeader('System'),
          _buildSettingsItem(Icons.info_outline, 'About PAYI', 'Version 1.0.0'),
          _buildSettingsItem(
            Icons.logout,
            'Log out',
            'Exit current session',
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primaryTeal,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    IconData icon,
    String title,
    String subtitle, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.error : AppColors.textMuted,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.error : AppColors.textLight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: AppColors.textMuted,
      ),
      onTap: () {},
    );
  }

  Widget _buildSettingsToggle(String title, bool value) {
    return SwitchListTile(
      secondary: const Icon(Icons.dark_mode, color: AppColors.textMuted),
      title: Text(title, style: const TextStyle(color: AppColors.textLight)),
      value: value,
      activeColor: AppColors.primaryTeal,
      onChanged: (val) {},
    );
  }
}
