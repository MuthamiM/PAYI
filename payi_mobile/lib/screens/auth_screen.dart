import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:local_auth/local_auth.dart';
import '../services/api_service.dart';
import '../services/phone_currency_service.dart';
import '../theme/colors.dart';
import 'terms_screen.dart';
import '../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _loadingStatus = '';

  late AnimationController _waveController;
  late AnimationController _fadeController;
  late AnimationController _logoController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _logoScale;
  late Animation<double> _logoPulse;
  bool _isBiometricsAvailable = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoPulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fadeController.forward();
    });
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      
      final file = File('${Directory.systemTemp.path}/payi_auth.json');
      bool enabled = false;
      if (await file.exists()) {
        final text = await file.readAsString();
        if (text.isNotEmpty) {
          final data = jsonDecode(text);
          enabled = data['biometricsEnabled'] ?? false;
        }
      }

      if (mounted) {
        setState(() {
          _isBiometricsAvailable = isSupported && canCheck && enabled;
        });
      }
    } catch (_) {}
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final file = File('${Directory.systemTemp.path}/payi_auth.json');
      if (!await file.exists()) {
        _showError('No saved credentials. Log in with password first.');
        return;
      }

      final text = await file.readAsString();
      if (text.isEmpty) {
        _showError('No saved credentials. Log in with password first.');
        return;
      }

      final data = jsonDecode(text);
      final savedEmail = data['email'] as String?;
      final savedPassword = data['password'] as String?;

      if (savedEmail == null || savedPassword == null || savedEmail.isEmpty || savedPassword.isEmpty) {
        _showError('No saved credentials. Log in with password first.');
        return;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Scan fingerprint or face to log in to PAYI',
      );

      if (didAuthenticate) {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _handleAuth();
      }
    } catch (e) {
      _showError('Biometric authentication failed: $e');
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fadeController.dispose();
    _logoController.dispose();
    _shimmerController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _fadeController.reverse().then((_) {
      setState(() => _isSignUp = !_isSignUp);
      _fadeController.forward();
    });
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all required fields.');
      return;
    }

    if (_isSignUp) {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final confirm = _confirmPasswordController.text.trim();

      if (name.isEmpty || phone.isEmpty) {
        _showError('Name and phone number are required.');
        return;
      }
      if (password != confirm) {
        _showError('Passwords do not match.');
        return;
      }
      if (password.length < 6) {
        _showError('Password must be at least 6 characters.');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _loadingStatus = _isSignUp ? 'Creating account...' : 'Signing in...';
    });

    try {
      final api = ApiService();
      if (_isSignUp) {
        final phone = _phoneController.text.trim();
        final currency = PhoneCurrencyService.getCurrencyFromPhone(phone);
        
        await api.register(
          email: email,
          name: _nameController.text.trim(),
          phone: phone,
          password: password,
          currency: currency,
        );
        
        if (mounted) {
          setState(() => _loadingStatus = 'Logging in...');
        }
      }

      final loginData = await api.login(email, password);

      // Set auth state from login response or local inputs
      ApiService.currentAuthEmail = email;
      ApiService.currentAuthToken = loginData['token'] ?? '';
      
      if (_isSignUp) {
        final phone = _phoneController.text.trim();
        ApiService.currentAuthPhone = phone;
        ApiService.currentAuthCurrency = PhoneCurrencyService.getCurrencyFromPhone(phone);
      } else {
        ApiService.currentAuthPhone = loginData['phone'] ?? '';
        ApiService.currentAuthCurrency = loginData['currency'] ?? 'USD';
      }

      // Save credentials for biometric login
      try {
        final file = File('${Directory.systemTemp.path}/payi_auth.json');
        Map<String, dynamic> data = {};
        if (await file.exists()) {
          final text = await file.readAsString();
          if (text.isNotEmpty) {
            data = jsonDecode(text);
          }
        }
        data['email'] = email;
        data['password'] = password;
        await file.writeAsString(jsonEncode(data));
      } catch (_) {}

      if (mounted) {
        setState(() => _loadingStatus = 'Success! Redirecting...');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardSaaSScreen()),
        );
      }
    } on TimeoutException catch (_) {
      _showError('Connection timed out. Please check your internet or server status.');
    } catch (e) {
      if (!_isSignUp) {
        _showSadAnimalDialog();
      } else {
        _showError('Authentication failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingStatus = '';
        });
      }
    }
  }

  void _showForgotPassword() {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Reset Password',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email address to receive a reset link.',
              style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(153)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'email@example.com',
                prefixIcon: Icon(Icons.email_outlined, color: theme.colorScheme.primary, size: 20),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = controller.text.trim();
              if (email.isEmpty) return;
              
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await ApiService().resetPassword(email);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Reset link sent to your email.')),
                );
              } catch (e) {
                _showError('Failed to send reset link: $e');
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSadAnimalDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        // Auto-dismiss after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        });

        final theme = Theme.of(dialogContext);
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 200,
              height: 220,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: theme.colorScheme.error.withAlpha(100),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.error.withAlpha(40),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Sad cat face drawn with CustomPaint
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CustomPaint(
                      painter: _SadCatPainter(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Login failed',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final onSurfaceColor = theme.colorScheme.onSurface;
    final mutedColor = theme.colorScheme.onSurface.withAlpha(120);

    return Scaffold(
      body: Stack(
        children: [
          // ── Animated gradient background with floating orbs ──
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(size.width, size.height),
                painter: _PremiumWavePainter(
                  _waveController.value,
                  isDark: isDark,
                  theme: theme,
                ),
              );
            },
          ),

          // ── Content ──
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.06),

                  // ── Animated Logo with Glow ──
                  ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withAlpha(60),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Hero(
                        tag: 'logo',
                        child: SvgPicture.asset(
                          'assets/logo.svg',
                          width: 90,
                          height: 90,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Title with gradient text ──
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        onSurfaceColor,
                        primaryColor,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      _isSignUp ? 'Create Account' : 'Welcome Back',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1.0,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isSignUp
                        ? 'Sign up to start sending money globally'
                        : 'Sign in to your PAYI account',
                    style: TextStyle(
                      fontSize: 15,
                      color: mutedColor,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Glassmorphic Form Card ──
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withAlpha(10)
                                : Colors.white.withAlpha(200),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withAlpha(15)
                                  : AppColors.surfaceLightBorder,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(isDark ? 40 : 8),
                                blurRadius: 40,
                                offset: const Offset(0, 16),
                              ),
                              BoxShadow(
                                color: primaryColor.withAlpha(isDark ? 15 : 8),
                                blurRadius: 60,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _isSignUp ? 'Sign Up' : 'Sign In',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: onSurfaceColor,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // ── Name (Sign Up only) ──
                              if (_isSignUp) ...[
                                _buildLabel('Full Name'),
                                const SizedBox(height: 8),
                                _buildPremiumTextField(
                                  controller: _nameController,
                                  hint: 'John Doe',
                                  icon: Icons.person_outline,
                                ),
                                const SizedBox(height: 18),
                              ],

                              // ── Email ──
                              _buildLabel('Email'),
                              const SizedBox(height: 8),
                              _buildPremiumTextField(
                                controller: _emailController,
                                hint: 'you@example.com',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),

                              // ── Phone (Sign Up only) ──
                              if (_isSignUp) ...[
                                const SizedBox(height: 18),
                                _buildLabel('Phone Number'),
                                const SizedBox(height: 8),
                                _buildPremiumTextField(
                                  controller: _phoneController,
                                  hint: '+254 712 345 678',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                ),
                              ],

                              const SizedBox(height: 18),
                              _buildLabel('Password'),
                              const SizedBox(height: 8),
                              _buildPremiumTextField(
                                controller: _passwordController,
                                hint: '••••••••',
                                icon: Icons.lock_outline,
                                obscure: _obscurePassword,
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: mutedColor,
                                    size: 20,
                                  ),
                                ),
                              ),

                              if (!_isSignUp) ...[
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _showForgotPassword,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              // ── Confirm Password (Sign Up only) ──
                              if (_isSignUp) ...[
                                const SizedBox(height: 18),
                                _buildLabel('Confirm Password'),
                                const SizedBox(height: 8),
                                _buildPremiumTextField(
                                  controller: _confirmPasswordController,
                                  hint: '••••••••',
                                  icon: Icons.lock_outline,
                                  obscure: _obscureConfirm,
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                    icon: Icon(
                                      _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: mutedColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 28),

                              // ── Premium Submit Button ──
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: _isLoading
                                            ? null
                                            : AppColors.primaryGradient,
                                        color: _isLoading
                                            ? primaryColor.withAlpha(100)
                                            : null,
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
                                        onPressed: _isLoading ? null : _handleAuth,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      color: isDark ? Colors.white : AppColors.backgroundDark,
                                                      strokeWidth: 2.5,
                                                    ),
                                                  ),
                                                  if (_loadingStatus.isNotEmpty) ...[
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      _loadingStatus,
                                                      style: TextStyle(
                                                        color: isDark ? Colors.white : AppColors.backgroundDark,
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              )
                                            : Text(
                                                _isSignUp ? 'Create Account' : 'Sign In',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark ? AppColors.backgroundDark : Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  if (!_isSignUp && _isBiometricsAvailable) ...[
                                    const SizedBox(width: 14),
                                    Container(
                                      height: 56,
                                      width: 56,
                                      decoration: BoxDecoration(
                                        color: primaryColor.withAlpha(20),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: primaryColor.withAlpha(80),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: IconButton(
                                        onPressed: _authenticateWithBiometrics,
                                        icon: Icon(
                                          Icons.fingerprint,
                                          color: primaryColor,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              const SizedBox(height: 22),

                              // ── Toggle Sign In / Sign Up ──
                              Center(
                                child: GestureDetector(
                                  onTap: _toggleMode,
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(fontSize: 14, color: mutedColor),
                                      children: [
                                        TextSpan(
                                          text: _isSignUp
                                              ? 'Already have an account? '
                                              : "Don't have an account? ",
                                        ),
                                        TextSpan(
                                          text: _isSignUp ? 'Sign In' : 'Sign Up',
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Terms ──
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsScreen()),
                      );
                    },
                    child: Text(
                      'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: mutedColor,
                        height: 1.6,
                        decoration: TextDecoration.underline,
                        decorationColor: mutedColor.withAlpha(80),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    final thm = Theme.of(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: thm.colorScheme.onSurface.withAlpha(140),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    final thm = Theme.of(context);
    final isDark = thm.brightness == Brightness.dark;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: TextStyle(
        fontSize: 15,
        color: thm.colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: thm.colorScheme.onSurface.withAlpha(80),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.only(left: 4, right: 4),
          child: Icon(icon, color: thm.colorScheme.primary, size: 20),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark
            ? Colors.white.withAlpha(8)
            : AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withAlpha(10)
                : AppColors.surfaceLightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withAlpha(10)
                : AppColors.surfaceLightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: thm.colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}

// ── Premium Wave Painter with floating orbs ──
class _PremiumWavePainter extends CustomPainter {
  final double animationValue;
  final bool isDark;
  final ThemeData theme;

  _PremiumWavePainter(this.animationValue, {required this.isDark, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    // Deep gradient background
    final gradientColors = isDark
        ? const [Color(0xFF06080D), Color(0xFF0B1018), Color(0xFF0D151F)]
        : [
            theme.scaffoldBackgroundColor,
            const Color(0xFFEFF4FC),
            theme.colorScheme.primary.withAlpha(15),
          ];

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Floating orbs (subtle glowing circles)
    _drawOrb(canvas, size, 0.15, 0.2, 120, const Color(0x0800C9A7));
    _drawOrb(canvas, size, 0.85, 0.15, 100, const Color(0x068B5CF6));
    _drawOrb(canvas, size, 0.5, 0.8, 150, const Color(0x0506B6D4));

    // Accent waves with better smoothing
    _drawWave(canvas, size, 0.35, 35, const Color(0x1A00C9A7), 0);
    _drawWave(canvas, size, 0.42, 25, const Color(0x1206B6D4), 0.25);
    _drawWave(canvas, size, 0.48, 30, const Color(0x0A8B5CF6), 0.5);
  }

  void _drawOrb(Canvas canvas, Size size, double cx, double cy, double radius, Color color) {
    final orbX = size.width * cx + sin(animationValue * 2 * pi) * 20;
    final orbY = size.height * cy + cos(animationValue * 2 * pi + 1) * 15;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withAlpha(0)],
      ).createShader(Rect.fromCircle(center: Offset(orbX, orbY), radius: radius));

    canvas.drawCircle(Offset(orbX, orbY), radius, paint);
  }

  void _drawWave(Canvas canvas, Size size, double yFraction, double amplitude, Color color, double offset) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final y = size.height * yFraction;

    path.moveTo(0, y);

    for (double x = 0; x <= size.width; x++) {
      final waveY = y +
          amplitude * sin((x / size.width * 2 * pi) + (animationValue + offset) * 2 * pi) +
          amplitude * 0.5 * sin((x / size.width * 4 * pi) + (animationValue + offset) * 2 * pi + 1);
      path.lineTo(x, waveY);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PremiumWavePainter oldDelegate) => true;
}

class _SadCatPainter extends CustomPainter {
  final Color color;

  _SadCatPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Head (circle)
    canvas.drawCircle(Offset(cx, cy + 5), 35, paint);

    // Left ear (triangle)
    final leftEar = Path()
      ..moveTo(cx - 28, cy - 22)
      ..lineTo(cx - 38, cy - 48)
      ..lineTo(cx - 10, cy - 32)
      ..close();
    canvas.drawPath(leftEar, paint);

    // Right ear (triangle)
    final rightEar = Path()
      ..moveTo(cx + 28, cy - 22)
      ..lineTo(cx + 38, cy - 48)
      ..lineTo(cx + 10, cy - 32)
      ..close();
    canvas.drawPath(rightEar, paint);

    // Left eye (filled dot)
    final eyePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 14, cy + 2), 4, eyePaint);

    // Right eye (filled dot)
    canvas.drawCircle(Offset(cx + 14, cy + 2), 4, eyePaint);

    // Left tear drop
    final tearPaint = Paint()
      ..color = color.withAlpha(150)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 14, cy + 12), 2.5, tearPaint);

    // Right tear drop
    canvas.drawCircle(Offset(cx + 14, cy + 12), 2.5, tearPaint);

    // Sad mouth (frown arc)
    final mouthRect = Rect.fromCenter(
      center: Offset(cx, cy + 26),
      width: 22,
      height: 14,
    );
    canvas.drawArc(mouthRect, 3.14, 3.14, false, paint);

    // Whiskers (left)
    canvas.drawLine(Offset(cx - 20, cy + 15), Offset(cx - 45, cy + 10), paint..strokeWidth = 1.5);
    canvas.drawLine(Offset(cx - 20, cy + 18), Offset(cx - 45, cy + 20), paint);

    // Whiskers (right)
    canvas.drawLine(Offset(cx + 20, cy + 15), Offset(cx + 45, cy + 10), paint);
    canvas.drawLine(Offset(cx + 20, cy + 18), Offset(cx + 45, cy + 20), paint);
  }

  @override
  bool shouldRepaint(covariant _SadCatPainter oldDelegate) =>
      oldDelegate.color != color;
}
