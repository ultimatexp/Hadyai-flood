import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import '../data/auth_repository.dart';
import '../../../core/theme/app_theme.dart';

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
      appBar: AppBar(
        title: Text(_showEmailForm ? (_isSignUp ? 'Sign Up' : 'Log In') : 'Welcome'),
        leading: _showEmailForm 
          ? IconButton(
              icon: const Icon(Icons.arrow_back), 
              onPressed: () => setState(() => _showEmailForm = false),
            )
          : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.pets, size: 80, color: AppTheme.accentOrange),
            const SizedBox(height: 32),

            if (_showEmailForm) ...[
              // Email Login Form
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.accentOrange
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                  : Text(_isSignUp ? 'Sign Up' : 'Log In', style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                child: Text(_isSignUp ? 'Already have an account? Log In' : 'Create an account'),
              ),
            ] else ...[
              // Social Login Options
              // Social Login Buttons
              _buildSocialButton(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: Icons.g_mobiledata,
                label: 'Continue with Google',
                backgroundColor: Colors.white,
                textColor: Colors.black87,
                iconColor: Colors.red,
              ),
              const SizedBox(height: 12),
              
              if (Platform.isIOS) ...[
                _buildSocialButton(
                  onPressed: _isLoading ? null : _signInWithApple,
                  icon: Icons.apple,
                  label: 'Continue with Apple',
                  backgroundColor: Colors.black,
                  textColor: Colors.white,
                  iconColor: Colors.white,
                ),
                const SizedBox(height: 12),
              ],
  
              _buildSocialButton(
                onPressed: _isLoading ? null : _signInWithLine,
                icon: Icons.chat_bubble,
                label: 'Continue with LINE',
                backgroundColor: const Color(0xFF00B900),
                textColor: Colors.white,
                iconColor: Colors.white,
              ),
              const SizedBox(height: 12),

              // Email Button
               _buildSocialButton(
                onPressed: () => setState(() => _showEmailForm = true),
                icon: Icons.email_outlined,
                label: 'Continue with Email',
                backgroundColor: Colors.white,
                textColor: Colors.black87,
                iconColor: AppTheme.accentOrange,
              ),
            ],
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, color: iconColor, size: 24),
      label: Text(label, style: TextStyle(color: textColor, fontSize: 16)),
    );
  }
}

