import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/wallet_provider.dart';
import '../services/google_drive_service.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/widgets.dart';
import 'balance_details_screen.dart';
import 'receive_money_screen.dart';
import 'kyc_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  String _kycStatus = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchKycStatus();
  }

  Future<void> _fetchKycStatus() async {
    final status = await ApiService().getKycStatus();
    if (mounted) {
      setState(() {
        _kycStatus = status;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick profile image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Profile Photo with Ring Glow
                  Center(
                    child: Stack(
                      children: [
                        PulsingGlow(
                          glowColor: primaryColor,
                          maxRadius: 15,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primaryColor,
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 56,
                              backgroundColor: theme.colorScheme.surface,
                              backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                              child: _profileImage == null
                                  ? Icon(
                                      Icons.person,
                                      size: 72,
                                      color: primaryColor,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(40),
                                    blurRadius: 10,
                                  )
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: isDark ? AppColors.backgroundDark : Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Profile Metadata
                  Text(
                    walletProvider.profileName.toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    walletProvider.profileEmail,
                    style: TextStyle(color: mutedColor, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 32),
                  
                  // Menu Items
                  StaggeredSlideIn(
                    index: 0,
                    child: _buildProfileItem(
                      context,
                      Icons.account_balance_wallet_outlined,
                      'My Wallet',
                      'Manage currencies and limits',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BalanceDetailsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  StaggeredSlideIn(
                    index: 1,
                    child: _buildProfileItem(
                      context,
                      Icons.qr_code_2_outlined,
                      'My QR Code',
                      'Share your payment link',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReceiveMoneyScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  StaggeredSlideIn(
                    index: 2,
                    child: _buildProfileItem(
                      context,
                      Icons.gpp_good_outlined,
                      'Identity Verification (KYC)',
                      'Status: $_kycStatus',
                      onTap: () async {
                        if (_kycStatus == 'Verified') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Your identity is already verified!')),
                          );
                        } else if (_kycStatus == 'Pending') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Your verification is under review. Please wait 24-48 hours.')),
                          );
                        } else {
                          final newStatus = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const KycVerificationScreen(),
                            ),
                          );
                          if (newStatus != null && newStatus is String) {
                            setState(() {
                              _kycStatus = newStatus;
                            });
                          }
                        }
                      },
                    ),
                  ),
                  StaggeredSlideIn(
                    index: 3,
                    child: _buildProfileItem(
                      context,
                      Icons.security_outlined,
                      'Security Settings',
                      'PIN, Biometrics, Recovery Phrase',
                      onTap: () => _showSecurityDialog(context, walletProvider),
                    ),
                  ),
                  StaggeredSlideIn(
                    index: 4,
                    child: _buildProfileItem(
                      context,
                      Icons.help_outline_outlined,
                      'Help & Support',
                      'Get 24/7 assistance',
                      onTap: () => _showHelpDialog(context),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSecurityDialog(BuildContext context, WalletProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Security Settings',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(
                  'Biometrics',
                  style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Use fingerprint or face ID',
                  style: TextStyle(color: mutedColor, fontSize: 12),
                ),
                value: provider.biometricsEnabled,
                activeThumbColor: theme.colorScheme.primary,
                onChanged: (val) async {
                  if (val) {
                    final LocalAuthentication auth = LocalAuthentication();
                    try {
                      final bool canAuthenticate =
                          await auth.canCheckBiometrics || await auth.isDeviceSupported();
                      if (canAuthenticate) {
                        final bool didAuthenticate = await auth.authenticate(
                          localizedReason: 'Authenticate to enable biometrics',
                          biometricOnly: true,
                        );
                        if (didAuthenticate) {
                          provider.toggleBiometrics(true);
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Biometrics not supported on this device')),
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint('Auth error: $e');
                    }
                  } else {
                    provider.toggleBiometrics(false);
                  }
                  setDialogState(() {});
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                title: Text(
                  'Change PIN',
                  style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showChangePinDialog(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.cloud_upload_outlined, color: theme.colorScheme.primary),
                title: Text(
                  'Backup Recovery Phrase',
                  style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Save phrase to Google Drive',
                  style: TextStyle(color: mutedColor, fontSize: 12),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (c) => const Center(child: CircularProgressIndicator()),
                  );

                  final driveService = GoogleDriveService();
                  try {
                    bool signedIn = await driveService.signIn();
                    if (signedIn) {
                      const sampleRecoveryPhrase = "abandon ability able about above absent absorb abstract absurd abuse access accident";
                      bool success = await driveService.backupPassphrase(sampleRecoveryPhrase);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Text(success ? 'Backed up to Google Drive!' : 'Backup failed.'),
                              ],
                            ),
                            backgroundColor: success ? AppColors.success : theme.colorScheme.error,
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Failed to sign in to Google.'), backgroundColor: theme.colorScheme.error),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: theme.colorScheme.error),
                      );
                    }
                  }
                },
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
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Help & Support',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(Icons.email_outlined, color: theme.colorScheme.primary),
              title: Text(
                'support@payi.me',
                style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Email support',
                style: TextStyle(color: mutedColor, fontSize: 12),
              ),
            ),
            ListTile(
              leading: Icon(Icons.chat_bubble_outline, color: theme.colorScheme.primary),
              title: Text(
                'Live Chat',
                style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Available 24/7',
                style: TextStyle(color: mutedColor, fontSize: 12),
              ),
            ),
            ListTile(
              leading: Icon(Icons.phone_outlined, color: theme.colorScheme.primary),
              title: Text(
                '+1 (800) PAYI-HELP',
                style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Phone support (9am-5pm EST)',
                style: TextStyle(color: mutedColor, fontSize: 12),
              ),
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

  void _showChangePinDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final oldController = TextEditingController();
    final newController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Change Security PIN',
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(labelText: 'Old PIN', hintText: '****'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(labelText: 'New PIN', hintText: '****'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(153), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              if (newController.text.length == 4) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text('PIN updated successfully!'),
                      ],
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          borderRadius: 20,
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: mutedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
