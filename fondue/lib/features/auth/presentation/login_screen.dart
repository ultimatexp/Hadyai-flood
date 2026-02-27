import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import '../data/auth_repository.dart';
import '../../../core/theme/app_theme.dart';
import 'eula_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isSignUp) {
        final response = await Supabase.instance.client.auth.signUp(email: email, password: password);
        if (mounted) {
          if (response.session != null) {
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sign up successful! Please check your email.')),
            );
          }
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  

  // --- Google Sign-In (Native) ---
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final repo = AuthRepository(Supabase.instance.client);
      await repo.signInWithGoogle();
      
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Apple Sign-In (Native) ---
  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      final repo = AuthRepository(Supabase.instance.client);
      await repo.signInWithApple();

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Apple Sign-In Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LINE Sign-In ---
  Future<void> _signInWithLine() async {
    setState(() => _isLoading = true);
    try {
      final repo = AuthRepository(Supabase.instance.client);
      await repo.signInWithLine();

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('LINE Sign-In Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _showEmailForm = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _showEmailForm 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
              onPressed: () => setState(() => _showEmailForm = false),
            )
          : IconButton(
              icon: const Icon(Icons.close, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              
              // Lottie Mascot Hero
              Center(
                child: SizedBox(
                  width: 160,
                  height: 160,
                  child: Lottie.asset(
                    'assets/lottie/ck pets world.json',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // App Title
              const Text(
                'Fondue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFF6D00),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Help reunite lost pets with their families',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
              ),
              
              const SizedBox(height: 36),
              
              // Animated Content Switch
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _showEmailForm
                    ? _buildEmailForm()
                    : _buildSocialOptions(),
              ),
              
              const SizedBox(height: 28),
              
              // EULA Link
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EULAScreen()),
                ),
                child: Text(
                  'By continuing, you agree to our\nTerms of Use (EULA) and Privacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialOptions() {
    return Column(
      key: const ValueKey('social'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Google
        _buildPremiumSocialButton(
          onPressed: _isLoading ? null : _signInWithGoogle,
          icon: Icons.g_mobiledata,
          label: 'Continue with Google',
          backgroundColor: Colors.white,
          textColor: Colors.black87,
          iconColor: const Color(0xFFDB4437),
          iconSize: 28,
        ),
        const SizedBox(height: 12),
        
        // Apple (iOS only)
        if (Platform.isIOS) ...[
          _buildPremiumSocialButton(
            onPressed: _isLoading ? null : _signInWithApple,
            icon: Icons.apple,
            label: 'Continue with Apple',
            backgroundColor: Colors.black,
            textColor: Colors.white,
            iconColor: Colors.white,
          ),
          const SizedBox(height: 12),
        ],

        // LINE
        _buildPremiumSocialButton(
          onPressed: _isLoading ? null : _signInWithLine,
          icon: Icons.chat_bubble,
          label: 'Continue with LINE',
          backgroundColor: const Color(0xFF00B900),
          textColor: Colors.white,
          iconColor: Colors.white,
        ),
        
        const SizedBox(height: 20),
        
        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[300])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('or', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            ),
            Expanded(child: Divider(color: Colors.grey[300])),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Email
        _buildPremiumSocialButton(
          onPressed: () => setState(() => _showEmailForm = true),
          icon: Icons.email_outlined,
          label: 'Continue with Email',
          backgroundColor: Colors.white,
          textColor: Colors.black87,
          iconColor: AppTheme.accentOrange,
        ),
      ],
    );
  }

  Widget _buildEmailForm() {
    return Column(
      key: const ValueKey('email'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email Field
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email_outlined),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.accentOrange, width: 2),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        
        // Password Field
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.accentOrange, width: 2),
            ),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 24),
        
        // Submit Button
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9800), Color(0xFFFF6D00)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FilledButton(
            onPressed: _isLoading ? null : _submit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading 
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  _isSignUp ? 'Sign Up' : 'Log In',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _isSignUp = !_isSignUp),
          child: Text(
            _isSignUp ? 'Already have an account? Log In' : 'Create an account',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumSocialButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
    double iconSize = 22,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: iconSize),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
