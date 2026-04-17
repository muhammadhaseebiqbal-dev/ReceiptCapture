import 'package:flutter/material.dart';
import '../shared/theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        children: const [
          _TermsSection(
            title: '1. Acceptance of Terms',
            content:
                'By using Receipt Capture, you agree to these terms and to use the app responsibly and lawfully.',
          ),
          _TermsSection(
            title: '2. Intended Use',
            content:
                'Receipt Capture is designed for storing and managing receipt information. You are responsible for the accuracy of the data you enter.',
          ),
          _TermsSection(
            title: '3. Data and Security',
            content:
                'The app provides local data protection controls, including encryption settings. You are responsible for device-level security, backups, and access control.',
          ),
          _TermsSection(
            title: '4. Service Availability',
            content:
                'We may update or improve app features over time. Some functions may change based on updates, platform requirements, or maintenance needs.',
          ),
          _TermsSection(
            title: '5. Limitation of Liability',
            content:
                'Receipt Capture is provided as-is. To the extent allowed by law, the app provider is not liable for indirect or consequential losses resulting from app usage.',
          ),
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  final String title;
  final String content;

  const _TermsSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(content, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}