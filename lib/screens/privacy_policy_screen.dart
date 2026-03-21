import 'package:flutter/material.dart';
import '../theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(isDark),
            const SizedBox(height: 24),
            _section(isDark, '1. Information We Collect',
                'Math Helper AI is designed with privacy at its core. '
                'We do not require account creation, login, or any personal information to use the app.\n\n'
                '• Problem Input: Math problems you type or scan are processed locally on your device or sent to your configured AI API endpoint. We do not store, log, or access your input on our servers.\n\n'
                '• Device Information: We do not collect device identifiers, IP addresses, or hardware information.\n\n'
                '• Usage Analytics: We do not use any analytics, telemetry, or crash-reporting services.\n\n'
                '• Camera & Photos: The app accesses your camera solely for OCR (optical character recognition) of math problems. Images are processed locally and are never uploaded or stored externally.'),
            _section(isDark, '2. How Your Data Is Used',
                '• Local Processing: All math solving, history, and favorites are stored locally on your device using Hive (an on-device database). This data never leaves your device.\n\n'
                '• AI API Calls: If you configure an external AI endpoint in Settings, the app sends only the math problem text to that endpoint. No personal data, device info, or metadata is included in the request.\n\n'
                '• Caching: AI responses are cached locally on your device to improve performance. Cached data is not shared.'),
            _section(isDark, '3. Data Storage & Security',
                '• All data (history, favorites, settings, cached responses) is stored exclusively on your device.\n\n'
                '• No data is transmitted to our servers — we do not operate any data-collection servers.\n\n'
                '• If you configure a third-party AI API key, that key is stored locally in your device\'s shared preferences. We recommend keeping your API key confidential.'),
            _section(isDark, '4. Third-Party Services',
                '• The app does not include any third-party SDKs for advertising, analytics, or social media.\n\n'
                '• If you choose to use an external AI API, your data is subject to that provider\'s privacy policy. We encourage you to review their terms before configuring an API key.\n\n'
                '• Google ML Kit (on-device) is used for text recognition. Processing happens entirely on your device.'),
            _section(isDark, '5. Children\'s Privacy',
                'Math Helper AI does not knowingly collect any personal information from anyone, including children under 13. The app is suitable for all ages as it does not require or collect personal data.'),
            _section(isDark, '6. Data Deletion',
                'Since all data is stored locally on your device:\n\n'
                '• You can clear your history and favorites from within the app at any time.\n\n'
                '• Uninstalling the app removes all associated data from your device.'),
            _section(isDark, '7. Cookies & Tracking',
                'The app does not use cookies, web beacons, pixels, or any other tracking technologies. The companion website (math-helper-ai-site.pages.dev) is a static site with no cookies or trackers.'),
            _section(isDark, '8. Changes to This Policy',
                'We may update this Privacy Policy from time to time. Any changes will be reflected in the app and on our website with an updated "Last modified" date. Continued use of the app after changes constitutes acceptance.'),
            _section(isDark, '9. Contact Us',
                'If you have any questions or concerns about this Privacy Policy, please contact us through the app\'s support channel.'),
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
          const Icon(Icons.shield_outlined, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Privacy Policy',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your privacy matters. We collect zero personal data.',
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
