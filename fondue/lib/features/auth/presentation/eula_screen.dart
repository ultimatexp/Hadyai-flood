import 'package:flutter/material.dart';

class EULAScreen extends StatelessWidget {
  const EULAScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Use (EULA)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'End User License Agreement (EULA)',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Acceptance of Terms\n'
              'By downloading and using "Fondue", you agree to be bound by this EULA.\n\n'
              '2. User-Generated Content\n'
              'Users may upload photos and descriptions of lost/found pets. You agree not to post objectionable content, including but not limited to:\n'
              '- Hate speech or harassment\n'
              '- Nudity or sexual content\n'
              '- Illegal activities\n'
              '- Violence\n\n'
              '3. No Tolerance Policy\n'
              'We have a zero-tolerance policy for objectionable content and abusive users. Content reported as violating these terms will be removed, and users may be blocked or banned.\n\n'
              '4. Reporting and Blocking\n'
              'You can flag inappropriate content via the "Report" button on any post. You can also block abusive users. We review reports within 24 hours.\n\n'
              '5. Data Privacy\n'
              'Your data is handled according to our Privacy Policy.\n\n'
              '6. Termination\n'
              'We reserve the right to terminate your access to the app if you violate these terms.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('I Understand'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
