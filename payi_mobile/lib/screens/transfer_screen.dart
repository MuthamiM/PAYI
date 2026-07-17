import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart' hide PermissionStatus;
import 'package:flutter_contacts/models/permissions/permission_status.dart' as fc;
import 'package:geolocator/geolocator.dart';
import '../providers/wallet_provider.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/widgets.dart';

class TransferScreen extends StatefulWidget {
  final String? initialRecipient;

  const TransferScreen({super.key, this.initialRecipient});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _amountController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRecipient != null && widget.initialRecipient!.contains('@')) {
      _emailController.text = widget.initialRecipient!;
    } else if (widget.initialRecipient != null) {
      _emailController.text = '${widget.initialRecipient!.toLowerCase()}@example.com';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _processTransfer() async {
    if (_amountController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount and recipient.')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      double? lat;
      double? lon;
      
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
            Position position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.low,
                timeLimit: Duration(seconds: 3),
              ),
            );
            lat = position.latitude;
            lon = position.longitude;
          }
        }
      } catch (locError) {
        debugPrint('Could not get location: $locError');
      }

      if (mounted) {
        await context.read<WalletProvider>().sendMoney(
          amount,
          ApiService.currentAuthCurrency,
          'Global',
          _emailController.text.split('@').first,
          _emailController.text,
          latitude: lat,
          longitude: lon,
        );
      }

      if (mounted) {
        context.read<WalletProvider>().fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Transfer successful!'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transfer failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickContact() async {
    final status = await FlutterContacts.permissions.request(PermissionType.read);
    if (status == fc.PermissionStatus.granted || status == fc.PermissionStatus.limited) {
      try {
        final pickedId = await FlutterContacts.native.showPicker();
        if (pickedId != null) {
          final contact = await FlutterContacts.get(pickedId, properties: {ContactProperty.phone});
          if (contact != null && contact.phones.isNotEmpty) {
            setState(() {
              _emailController.text = contact.phones.first.number;
            });
          }
        }
      } catch (e) {
        debugPrint('Error picking contact: $e');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts permission denied.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Send Money',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        
                        // Recipient Section
                        StaggeredSlideIn(
                          index: 0,
                          child: GlassContainer(
                            borderRadius: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'RECIPIENT EMAIL OR PHONE',
                                  style: TextStyle(
                                    color: mutedColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: isDark
                                        ? Colors.white.withAlpha(8)
                                        : AppColors.surfaceLight,
                                    hintText: 'user@example.com or phone',
                                    prefixIcon: Icon(Icons.alternate_email, color: primaryColor, size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(Icons.contact_phone_outlined, color: primaryColor),
                                      onPressed: _pickContact,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),

                        // Amount Section
                        StaggeredSlideIn(
                          index: 1,
                          child: GlassContainer(
                            borderRadius: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SEND AMOUNT (USD)',
                                  style: TextStyle(
                                    color: mutedColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _amountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.0,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: isDark
                                        ? Colors.white.withAlpha(8)
                                        : AppColors.surfaceLight,
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Text(
                                        '\$',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 36,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Submit Button
                StaggeredSlideIn(
                  index: 2,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: _isLoading ? null : AppColors.primaryGradient,
                      color: _isLoading ? primaryColor.withAlpha(100) : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isLoading
                          ? null
                          : [
                              BoxShadow(
                                color: primaryColor.withAlpha(80),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _processTransfer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Confirm & Send',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
