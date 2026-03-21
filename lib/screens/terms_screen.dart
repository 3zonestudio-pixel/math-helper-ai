import 'package:flutter/material.dart';
import '../theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(isDark),
            const SizedBox(height: 24),
            _section(isDark, '1. Acceptance of Terms',
                'By downloading, installing, or using Math Helper AI ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.'),
            _section(isDark, '2. Description of Service',
                'Math Helper AI is an educational tool that helps users solve math problems through:\n\n'
                '• Text input and OCR-based camera scanning\n'
                '• Local math solvers (arithmetic, algebra, calculus)\n'
                '• Optional AI-powered solutions via user-configured API endpoints\n'
                '• Step-by-step explanations in multiple languages\n\n'
                'The App is intended for educational and personal learning purposes only.'),
            _section(isDark, '3. User Responsibilities',
                '• You agree to use the App solely for lawful, educational purposes.\n\n'
                '• You are responsible for the accuracy and legality of any API key or endpoint you configure in the App.\n\n'
                '• You must not use the App to cheat on exams, assignments, or any academic assessments where such use is prohibited.\n\n'
                '• You must not attempt to reverse-engineer, decompile, or extract source code from the App.'),
            _section(isDark, '4. Accuracy & Disclaimer',
                '• While we strive for accurate results, math solutions provided by the App (both local and AI-generated) may contain errors.\n\n'
                '• The App is provided "AS IS" and "AS AVAILABLE" without warranties of any kind, express or implied.\n\n'
                '• We do not guarantee that the App will be error-free, uninterrupted, or free of harmful components.\n\n'
                '• You should always verify important results independently.'),
            _section(isDark, '5. Intellectual Property',
                '• The App, including its design, code, icons, and content, is the intellectual property of the developer.\n\n'
                '• You are granted a limited, non-exclusive, non-transferable license to use the App for personal, non-commercial purposes.\n\n'
                '• You may not copy, modify, distribute, or create derivative works based on the App.'),
            _section(isDark, '6. Third-Party Services',
                '• The App may connect to third-party AI API services if you choose to configure one.\n\n'
                '• We are not responsible for the availability, accuracy, or policies of any third-party service.\n\n'
                '• Your use of third-party services is subject to their respective terms and conditions.'),
            _section(isDark, '7. Limitation of Liability',
                'To the maximum extent permitted by applicable law:\n\n'
                '• The developer shall not be liable for any indirect, incidental, special, consequential, or punitive damages.\n\n'
                '• The developer shall not be liable for any loss arising from reliance on solutions provided by the App.\n\n'
                '• Total liability shall not exceed the amount paid for the App (if any).'),
            _section(isDark, '8. Termination',
                '• You may stop using the App at any time by uninstalling it.\n\n'
                '• We reserve the right to modify, suspend, or discontinue the App at any time without notice.\n\n'
                '• Upon termination, all data stored locally on your device remains under your control.'),
            _section(isDark, '9. Changes to Terms',
                'We reserve the right to update these Terms of Service at any time. Changes will be reflected in the App and on our website. Your continued use of the App after modifications constitutes acceptance of the updated terms.'),
            _section(isDark, '10. Governing Law',
                'These Terms shall be governed by and interpreted in accordance with applicable laws. Any disputes arising from these Terms or the use of the App shall be resolved through appropriate legal channels.'),
            _section(isDark, '11. Contact',
                'If you have questions about these Terms of Service, please contact us through the App\'s support channel.'),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Last modified: March 21, 2026',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.textLight.withAlpha(130) : Colors.grey[500],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _header(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.gavel_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Terms of Service',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Please read these terms carefully before using the App.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withAlpha(200),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(bool isDark, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: isDark ? AppTheme.cardDark : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                body,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  color: isDark ? AppTheme.textLight : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
