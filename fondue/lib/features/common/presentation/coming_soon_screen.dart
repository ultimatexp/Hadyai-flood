import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_theme.dart';

class ComingSoonScreen extends StatelessWidget {
  final String title;
  final String? subtitle;

  const ComingSoonScreen({
    super.key,
    this.title = 'Coming Soon',
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        title: Text(title),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie Animation
              SizedBox(
                width: 200,
                height: 200,
                child: Lottie.asset(
                  'assets/lottie/Dog Paw Loading.json',
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Coming Soon!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                subtitle ?? 'We\'re working hard to bring you this feature.\nStay tuned!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Back Button
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  side: const BorderSide(color: AppTheme.primaryGreen),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
