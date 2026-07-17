import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../screens/auth_screen.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/widgets.dart';
import 'topup_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              _buildSectionHeader(context, 'General'),
              GlassContainer(
                padding: EdgeInsets.zero,
                borderRadius: 24,
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(Icons.dark_mode_outlined, color: isDark ? theme.colorScheme.onSurface.withAlpha(153) : theme.colorScheme.primary),
                      title: Text(
                        'Dark Mode',
                        style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
                      ),
                      value: walletProvider.isDarkMode,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (val) => walletProvider.toggleDarkMode(val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: Icon(Icons.fingerprint, color: walletProvider.biometricsEnabled ? theme.colorScheme.primary : theme.colorScheme.onSurface.withAlpha(153)),
                      title: Text(
                        'Biometric Login',
                        style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
                      ),
                      value: walletProvider.biometricsEnabled,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (val) => walletProvider.toggleBiometrics(val),
                    ),
                    const Divider(height: 1),
                    _buildSettingsItem(
                      context,
                      Icons.notifications_none_outlined,
                      'Notifications',
                      'Push, Email, SMS alerts',
                      onTap: () => _showNotificationsDialog(context),
                    ),
                    const Divider(height: 1),
                    _buildSettingsItem(
                      context,
                      Icons.language_outlined,
                      'Language',
                      'English',
                      onTap: () => _showLanguageDialog(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              _buildSectionHeader(context, 'Account & Privacy'),
              GlassContainer(
                padding: EdgeInsets.zero,
                borderRadius: 24,
                child: Column(
                  children: [
                    _buildSettingsItem(
                      context,
                      Icons.lock_outline,
                      'Privacy Settings',
                      'Manage visibility and activity',
                      onTap: () => _showPrivacyDialog(context),
                    ),
                    const Divider(height: 1),
                    _buildSettingsItem(
                      context,
                      Icons.credit_card_outlined,
                      'Billing Options',
                      'Manage top-up methods',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TopupScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              _buildSectionHeader(context, 'System'),
              GlassContainer(
                padding: EdgeInsets.zero,
                borderRadius: 24,
                child: Column(
                  children: [
                    _buildSettingsItem(
                      context,
                      Icons.info_outline_rounded,
                      'About PAYI',
                      'Version 1.0.0 (Build 1)',
                      onTap: () => _showAboutDialog(context),
                    ),
                    const Divider(height: 1),
                    _buildSettingsItem(
                      context,
                      Icons.logout_rounded,
                      'Log out',
                      'Exit current session',
                      isDestructive: true,
                      onTap: () => _showLogoutDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _PrefsDialog(
        title: 'Notification Preferences',
        items: const ['Push Notifications', 'Email Notifications', 'SMS Alerts'],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Select Language',
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'Swahili', 'French', 'Spanish']
              .map(
                (lang) => ListTile(
                  title: Text(
                    lang,
                    style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
                  ),
                  trailing: lang == 'English'
                      ? Icon(Icons.check_circle_outline, color: theme.colorScheme.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Language set to $lang'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _PrefsDialog(
        title: 'Privacy Settings',
        items: const [
          'Show profile to contacts',
          'Allow transaction visibility',
          'Share activity status',
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'About PAYI',
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PAYI — Cross-Border Payments',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0 (Build 1)',
              style: TextStyle(color: mutedColor, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Text(
              'Send and receive money instantly across borders. Pay bills, top-up wallets, and manage your finances with PAYI.',
              style: TextStyle(color: theme.colorScheme.onSurface, height: 1.5, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Text(
              '© 2026 PAYI Inc. All rights reserved.',
              style: TextStyle(color: mutedColor, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Log Out',
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to log out of PAYI?',
          style: TextStyle(color: mutedColor, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: mutedColor, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ApiService.currentAuthEmail = '';
              ApiService.currentAuthPhone = '';
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);
    
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? theme.colorScheme.error : theme.colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: mutedColor, fontSize: 12, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: mutedColor,
      ),
      onTap: onTap,
    );
  }
}

class _PrefsDialog extends StatefulWidget {
  final String title;
  final List<String> items;

  const _PrefsDialog({required this.title, required this.items});

  @override
  State<_PrefsDialog> createState() => _PrefsDialogState();
}

class _PrefsDialogState extends State<_PrefsDialog> {
  late List<bool> _values;

  @override
  void initState() {
    super.initState();
    _values = List.filled(widget.items.length, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AlertDialog(
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        widget.title,
        style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          widget.items.length,
          (i) => SwitchListTile(
            title: Text(
              widget.items[i],
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            value: _values[i],
            activeColor: theme.colorScheme.primary,
            onChanged: (val) => setState(() => _values[i] = val),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text('Preferences saved!'),
                  ],
                ),
                backgroundColor: AppColors.success,
              ),
            );
          },
          child: Text(
            'Save',
            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
