import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:payi_mobile/core/services/api_service.dart';

class KycVerificationScreen extends StatefulWidget {
  const KycVerificationScreen({super.key});

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  final ImagePicker _picker = ImagePicker();
  
  File? _faceImage;
  File? _idImage;
  
  bool _isSubmitting = false;
  String _statusMessage = '';

  Future<void> _pickFaceImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);
      if (image != null) {
        setState(() {
          _faceImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to open camera: $e')));
      }
    }
  }

  Future<void> _pickIdImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery); // Allow gallery for IDs, or camera
      if (image != null) {
        setState(() {
          _idImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick ID image: $e')));
      }
    }
  }

  Future<void> _submitKyc() async {
    if (_faceImage == null || _idImage == null) {
      setState(() => _statusMessage = 'Please provide both your Face and ID photos.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusMessage = 'Submitting your documents...';
    });

    try {
      final api = ApiService();
      final status = await api.submitKyc(_faceImage!.path, _idImage!.path);
      
      if (mounted) {
        // Show a pending verification dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            final dialogTheme = Theme.of(ctx);
            return AlertDialog(
              backgroundColor: dialogTheme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  Icon(Icons.hourglass_top_rounded, size: 64, color: Colors.amber.shade600),
                  const SizedBox(height: 16),
                  Text(
                    'Verification Pending',
                    style: TextStyle(
                      color: dialogTheme.colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your documents have been submitted successfully. Our team will review and verify your identity within 24-48 hours.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: dialogTheme.colorScheme.onSurface.withAlpha(178),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You will be notified once verified.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.amber.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx); // close dialog
                        Navigator.pop(context, status); // go back to profile
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dialogTheme.colorScheme.primary,
                        foregroundColor: dialogTheme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );

        setState(() {
          _isSubmitting = false;
          _statusMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _statusMessage = 'Error submitting KYC: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Identity Verification (KYC)'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Secure your account',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'To comply with financial regulations and secure your wallet, we need to verify your identity.',
              style: TextStyle(color: mutedColor, fontSize: 16),
            ),
            const SizedBox(height: 32),
            
            // 1. Face Capture
            Text(
              '1. Take a Selfie',
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickFaceImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _faceImage != null ? Colors.green : theme.colorScheme.primary.withAlpha(128)),
                ),
                child: _faceImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_faceImage!, fit: BoxFit.cover, alignment: Alignment.topCenter),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_front, size: 48, color: theme.colorScheme.primary),
                          const SizedBox(height: 8),
                          Text('Tap to take a selfie', style: TextStyle(color: theme.colorScheme.primary)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),

            // 2. ID Document
            Text(
              '2. Upload ID Document',
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Passport, National ID, or Driving License',
              style: TextStyle(color: mutedColor, fontSize: 14),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickIdImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _idImage != null ? Colors.green : theme.colorScheme.primary.withAlpha(128)),
                ),
                child: _idImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_idImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.badge, size: 48, color: theme.colorScheme.primary),
                          const SizedBox(height: 8),
                          Text('Tap to upload ID', style: TextStyle(color: theme.colorScheme.primary)),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            if (_statusMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('Error') || _statusMessage.contains('Please') 
                        ? Colors.redAccent 
                        : Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitKyc,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Verify Identity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
