
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'dart:io';

class AuthRepository {
  final SupabaseClient _client;
  // Initialize GoogleSignIn. Scopes might be needed
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // scopes: ['email', 'profile'], // Default is usually fine
  );

  AuthRepository(this._client);

  Future<AuthResponse> signInWithGoogle() async {
    try {
      // 1. Native Google Sign-In
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw 'Google Sign-In canceled';
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw 'Missing Google Auth Token';
      }

      // 2. Sign in to Supabase
      return await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw 'Missing Apple ID token';
      }

      // Nonce and other parameters might be needed for stricter security,
      // but standard implementation often works with just idToken for Supabase
      return await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> signInWithLine() async {
    try {
      final result = await LineSDK.instance.login();
      final userProfile = result.userProfile;
      final userId = userProfile?.userId;
      final displayName = userProfile?.displayName ?? 'LINE User';

      if (userId == null) {
        throw 'Missing LINE user ID';
      }

      // Generate temp email/password (Strategy: Email = UID@fondue.com)
      final tempEmail = '$userId@fondue.com';
      final tempPassword = 'LINE_${userId}_FONDUE';

      try {
        // Try to sign in directly
        return await _client.auth.signInWithPassword(
          email: tempEmail,
          password: tempPassword,
        );
      } on AuthException catch (e) {
        // If user not found or email not confirmed
        if (e.message.contains('Invalid login credentials') || e.statusCode == '400') {
           // Try to sign up
           try {
             await _client.auth.signUp(
              email: tempEmail,
              password: tempPassword,
              data: {'display_name': displayName, 'provider': 'line'},
            );
           } on AuthException catch (signupError) {
             // If signup fails because user exists but maybe email not confirmed, or other issue
             if (signupError.code == 'user_already_exists') {
                // Should have been caught by signIn, but just in case
             } else {
               rethrow;
             }
           }

          // Immediately try to sign in again. 
          // NOTE: If Supabase "Confirm Email" is ENABLED, this will fail with "Email not confirmed".
          // You MUST disable "Confirm Email" in Supabase for this strategy to work.
          return await _client.auth.signInWithPassword(
            email: tempEmail,
            password: tempPassword,
          );
        } else {
          rethrow;
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Helper to expose current user
  User? get currentUser => _client.auth.currentUser;

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _client.auth.signOut();
  }
}
