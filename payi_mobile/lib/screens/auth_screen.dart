import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/colors.dart';
import '../services/api_service.dart';
import '../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.backgroundDark)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
            });

            // Check if we reached the dashboard, meaning Clerk auth login was successful
            if (url.contains('/dashboard.html')) {
              _extractUserEmail();
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse('http://192.168.1.158:5088/auth.html'),
      ); // Use the SaaS Auth page!
  }

  Future<void> _extractUserEmail() async {
    // Wait a brief moment for Clerk JS payload to mount and map user claims
    await Future.delayed(const Duration(seconds: 2));

    try {
      final Object result = await _controller.runJavaScriptReturningResult(
        "window.Clerk && window.Clerk.user ? window.Clerk.user.primaryEmailAddress.emailAddress : 'missing'",
      );

      String email = result.toString().replaceAll('"', '').replaceAll("'", "");

      if (email != 'missing' && email.isNotEmpty) {
        // Hydrate the API service with the authenticated user's email
        ApiService.currentAuthEmail = email;

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardSaaSScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint("Error extracting email from Clerk WebView: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryTeal),
                    SizedBox(height: 16),
                    Text(
                      'Loading Secure Auth...',
                      style: TextStyle(color: AppColors.primaryTeal),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
