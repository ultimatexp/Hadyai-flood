import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/user_profile_repository.dart';
import '../../settings/presentation/privacy_policy_screen.dart';
import '../../settings/presentation/terms_conditions_screen.dart';

/// Hard gate: user must accept terms before using the app.
class TermsGateScreen extends StatefulWidget {
  const TermsGateScreen({super.key});

  @override
  State<TermsGateScreen> createState() => _TermsGateScreenState();
}

class _TermsGateScreenState extends State<TermsGateScreen> {
  bool _accepted = false;
  bool _saving = false;

  Future<void> _accept() async {
    setState(() => _saving = true);
    try {
      final repo = UserProfileRepository(Supabase.instance.client);
      await repo.acceptTerms();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save acceptance: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms Required'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To continue, you must agree to our Terms & Privacy Policy.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'Zero tolerance for objectionable content and abusive users. You can report content and block users, and we review reports within 24 hours.',
              style: TextStyle(color: Colors.grey[700], height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accepted ? Colors.green : Colors.grey[300]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _accepted,
                    onChanged: (v) => setState(() => _accepted = v ?? false),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                                );
                              },
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
                                );
                              },
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: !_accepted || _saving ? null : _accept,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Agree & Continue'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _saving ? null : _signOut,
                child: const Text('Sign out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

